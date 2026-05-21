# Performance Discrepancies vs `TimeSeriesEconPy` — Analysis & Remediation Plan

## 1. What we are looking at

From `benchmarks/results.txt`, the gap between the MATLAB port and the
Python sister-package on identical scenarios:

| Scenario                          | MATLAB µs | Python µs | Ratio |
|-----------------------------------|---------:|---------:|-----:|
| `arith_add_misaligned`            |    963.7 |    17.62 |  55× |
| `arith_add_aligned`               |    897.7 |    17.43 |  51× |
| `diff_quarterly`                  |  1 124.7 |    24.26 |  46× |
| `mean_quarterly_100`              |     95.7 |     2.08 |  46× |
| `pct_quarterly`                   |  2 157.7 |    59.39 |  36× |
| `construct_tseries_qq_100`        |     52.7 |     1.49 |  35× |
| `shift_quarterly_lag1`            |    130.7 |     4.20 |  31× |
| `indexing_mit_lookup_100`         |  3 070.7 |   108.70 |  28× |
| `ytypct_quarterly_100`            |  1 109.7 |    58.59 |  19× |
| `moving_average_quarterly_4`      |    181.7 |    11.74 |  15× |
| `arith_mul_scalar`                |      9.2 |    15.98 |  **0.6× (MATLAB faster)** |

One row matches Python; the rest are 15× – 55× slower. There are also
three scenarios that **never ran** (`mean_mvts_axis0_5cols`,
`mean_mvts_axis1_100rows`, `undiff_quarterly`) — those are functional
bugs and out of scope for this performance plan, but they are noted in
§6.

## 2. Diagnosis

The MATLAB port is fundamentally well-shaped — the algorithms are the
same as the Python and Julia ones, the underlying numeric storage is a
plain `double` array, and the **operation that bypasses object dispatch
runs at native speed** (`arith_mul_scalar` is faster than Python). So
the discrepancy is **not** in the math; it is in the per-operation
overhead that MATLAB's `classdef` machinery and our specific design
choices impose around that math.

I traced through the code on each slow scenario; the cost breaks down
into five recurring overhead sources, listed roughly in order of impact:

### 2.1 Class instantiation cost — the dominant factor

Every `tse.MIT(...)`, `tse.MITRange(...)`, `tse.TSeries(...)`
instantiation has a fixed overhead of roughly **5–25 µs per call** in
MATLAB. The chief contributors are:

- **Property validators**. The declarations
  ```matlab
  value (1,1) int64 = int64(0)
  frequency (1,1) int32 = int32(11)
  endPeriod (1,1) double {mustBeInteger, mustBePositive} = 1
  ```
  run a size check + type check + `mustBeInteger` + `mustBePositive`
  on **every** property assignment. For `MIT(F, 5)` we set two
  validated properties; the validator cost dominates the constructor.
- **Default-construction of nested defaults**. `frequency = int32(11)`
  on `MIT` is cheap, but on classes like `MITRange` whose default
  `startMIT = tse.MIT(tse.Unit(), 1)` is itself an MIT — the default
  must be evaluated, which constructs a `Unit` and an `MIT` even
  though the real constructor will overwrite them immediately. The
  default-then-overwrite pattern doubles construction work for
  `MITRange`.
- **Function-call dispatch into the constructor**. Even with no
  validators, a `classdef` constructor call is several µs heavier than
  a struct assignment.

This is the **single largest contributor** to almost every slow row:

| Slow scenario | MITs created | MITRanges created | TSeries created |
|---|---:|---:|---:|
| `construct_tseries_qq_100` | 1 | 0 | 1 |
| `arith_add_aligned` | 4 (`rng.startMIT` reads + new TSeries firstdate) | 3 (`rangeof(a)`, `rangeof(b)`, `intersect`) | 1 |
| `shift_quarterly_lag1` | 1 (`firstdate - k`) | 0 | 1 |
| `diff_quarterly` | 3 | 3 | 2 (lag + minus) |
| `pct_quarterly` | ~11 | ~9 | ~5 (shift + minus + rdivide + times + mtimes) |
| `indexing_mit_lookup_100` | 100 (keys collected) + 100 (each `t(mit)` goes through `MIT.minus`) | 0 | 0 |

These numbers explain the absolute timings:

- `construct_tseries_qq_100` = 52.7 µs ≈ 1 MIT + 1 TSeries + setup.
- `arith_add_aligned` = 897 µs ≈ 3 MITRanges + 4 MITs + 1 TSeries
  ≈ 3·~150 µs + 4·~25 µs + 50 µs. (MITRange is the expensive one
  because of its default `startMIT = tse.MIT(tse.Unit(), 1)` evaluation
  before reassignment, plus its three validated fields.)
- `shift_quarterly_lag1` = 130 µs ≈ MIT subtract + new MIT + TSeries
  copy + new TSeries assembly.
- `pct_quarterly` = 2 157 µs ≈ 4 binary ops × ~500 µs each.

Python doesn't see this cost: a Python class instantiation is roughly
the same as a struct assignment (~0.5–2 µs), and NumPy operations on a
100-element array bottom out in C.

### 2.2 `rangeof()` materialises a full `MITRange` object — even on hot paths

Inside `binaryOp` (lines 1041–1094 of `+tse/TSeries.m`):

```matlab
rngA = rangeof(a);            % constructs an MITRange (expensive)
rngB = rangeof(b);            % constructs another MITRange
rng  = intersect(rngA, rngB); % constructs a third
kA   = double(rng.startMIT.value - a.firstdate.value) + 1;
...
```

What we actually need from each range is two `int64`s (first and last).
But `rangeof` returns a full `MITRange` (3 properties, default
materialisation, validators) and `intersect` returns yet another. For
two same-frequency TSeries with identical ranges, this is **three
MITRange constructions** for what could be two `int64` reads. In
absolute terms this is what makes `arith_add_aligned` ~900 µs instead
of ~50 µs.

### 2.3 Recursion-style scalar dispatch (`subsref` / `MIT.minus`)

`indexing_mit_lookup_100` loops 100 times calling `t(mit)`. Each call:

1. MATLAB invokes `subsref(t, S)` — class method dispatch (~2–5 µs).
2. `subsref` switches on `S.type`, recurses into `doGet`.
3. `doGet` switches on `class(idx)`, branches into the `tse.MIT` case.
4. Compares `idx.frequency ~= t.frequency` — property reads + int
   compare.
5. Computes `k = idx.value - t.firstdate.value + 1` — two property
   reads, an int64 subtract.
6. Bounds-checks, then indexes `t.values(k)`.

Each lookup is ~30 µs (3 070 / 100). The arithmetic itself is **a
single integer subtraction**. Everything else is class machinery.

`rec_ar2_100` and `rec_backcasting_via_lambda` show the same pattern at
its worst: 50 ms total for 100 iterations, ~500 µs per iteration of
`s(k-1) + s(k-2)`, where each step does:

- `k - 1` → `MIT.minus(MIT, int)` → constructs a new MIT
- `s(...)` → subsref → doGet → MIT compare + subtract + values index
- … same again for `k - 2`
- `+` → numeric add on two scalars (cheap)
- `t(idx) = ...` → subsasgn → doSet → potentially `resize` (range
  check, MITRange construction, copyto) → property write

The recursive loop spends almost all its time in object-machinery, not
arithmetic.

### 2.4 Repeated `t.firstdate.frequency` chains

A lot of code reads `t.firstdate.frequency` or similar 2-step chains
inside hot paths. Each chain is two `subsref` calls. In `binaryOp` we
mostly use the cached `t.frequency` instead (good), but other paths
(e.g. `pct`, `apct`, `ytypct`, `mit2yp`) still chain through.

### 2.5 Wasted work in helper paths

Smaller, but cumulative:

- `length(MITRange)`: a function call that does subtraction + branching
  in a method. ~3 µs per call. We call it inside every `binaryOp`.
- `MIT.minus` and `MIT.plus`: even after a fast-path `int64` ops, they
  construct a new MIT (which validates and goes through the
  constructor).
- `overlay` loops 100 elements with `tse.istypenan(v)` per element —
  the predicate dispatch costs as much as the scalar comparison it
  performs. The non-vectorised inner loop in overlay is the reason for
  10 ms / call.
- `pct(t)` does `(a - b) ./ b * 100` as four separate `binaryOp` calls,
  each rebuilding ranges, intersecting, slicing, and constructing a new
  TSeries.

## 3. Why some things are already fast

`arith_mul_scalar` (9 µs) is the only operation we beat Python on. The
fast path:

```matlab
function r = mtimes(a, b)
    if isa(a, 'tse.TSeries') && isscalar(b) && isnumeric(b)
        r = a;
        r.values = a.values * b;
        return
    end
    ...
```

- A copy of `a` (value-class COW; the `values` array is shared until
  the next write).
- One vectorised multiply on the underlying double vector.
- No new MIT, no new MITRange, no `rangeof`, no `intersect`.

This is the template every other arithmetic operation should aim for.

## 4. Targets for fixing

| Tier | Scenarios | Target |
|---|---|---|
| **A — must fix** | `arith_add_aligned/misaligned`, `diff_quarterly`, `pct_quarterly`, `ytypct_quarterly_100`, `shift_quarterly_lag1`, `lead_quarterly_lag1`, `construct_tseries_qq_100`, `mean_quarterly_100` | 5–10× of Python |
| **B — should fix** | `indexing_mit_lookup_100`, `moving_average_quarterly_4`, `moving_sum_quarterly_4` | 5–10× of Python |
| **C — nice to fix** | `overlay_three_tseries`, `rec_ar2_100`, `rec_backcasting_via_lambda` | within an order of magnitude |
| **D — bugs** | `undiff_quarterly`, `mean_mvts_axis0/axis1_*` | run successfully |

The realistic goal is to bring all Tier A within a small constant of
Python (the inherent classdef overhead won't shrink below ~5×, but we
should be able to recover most of the gap from the four overhead
sources above).

## 5. Remediation plan

Optimisations are listed roughly in the order I'd apply them; each
section ends with the scenarios it should move the needle on.

### 5.1 Strip validators off the immutable storage on hot paths

The validators
`value (1,1) int64`, `frequency (1,1) int32`, `endPeriod (1,1) double {mustBeInteger, mustBePositive}`
run on every assignment. The constructor already coerces to the right
type and range, so the validators are paying for safety we don't need
at runtime. Replace them with bare property declarations and rely on
the constructor to enforce shape/range/type once. Pair this with a
narrow `validateattributes(... 'tseries:...')` call inside the
constructor where genuine user input could be wrong — but skip it on
internal "we just built this from a trusted scalar" paths.

**Expected impact:** every constructor gets ~30–40 % faster. Affects
every slow row.

### 5.2 Provide a hidden "fast" constructor

Expose a `tse.MIT.fast(freqCode, intValue)` static method (or a
`Hidden, Static` `_make` method) that bypasses the `varargin` switch
in the public constructor. Use it in:

- `MIT.plus` and `MIT.minus` — currently `tse.MIT(a.frequency,
  a.value + int64(b))`. With `MIT.fast`, the per-call cost drops by
  ~5 µs.
- `MITRange` constructor — the `intersect`/`union`/`plus`/`minus`
  helpers currently build new MITRanges through the public constructor
  even though they have full knowledge of the inputs.
- `TSeries`/`MVTSeries` constructors — similar fast path that takes
  `firstdate (MIT, already validated)` and `values (column vector,
  already in the right type)` and skips the `varargin` switch.

**Expected impact:** every binary op halves; `shift`, `lag`, `lead`
get ~2–3× faster. Affects `arith_add_*`, `diff_quarterly`,
`pct_quarterly`, `ytypct_quarterly`, `shift_quarterly`, `lead_quarterly`.

### 5.3 Replace `MITRange` materialisation in arithmetic with int64 bounds

Inside `binaryOp` we don't need the full `MITRange` object — we need
`firstA`, `firstB`, `firstResult`, `length`. Rewrite the hot binary
path to operate on `int64` only:

```matlab
fa = a.firstdate.value;
fb = b.firstdate.value;
na = numel(a.values);
nb = numel(b.values);
lo = max(fa, fb);
hi = min(fa + na - 1, fb + nb - 1);
if hi < lo, ... empty result ... end
kA = double(lo - fa) + 1;
kB = double(lo - fb) + 1;
nL = double(hi - lo + 1);
va = a.values(kA : kA + nL - 1);
vb = b.values(kB : kB + nL - 1);
result = op(va, vb);
r = tse.TSeries.fast(...);
```

This replaces **three MITRange constructions** with a few int64
operations. Together with §5.2 it should bring `arith_add_aligned` and
friends close to the Python timing.

When the two ranges are identical (a frequent case in user code),
short-circuit even further to a plain `op(a.values, b.values)`:

```matlab
if a.firstdate.value == b.firstdate.value && numel(a.values) == numel(b.values)
    r = a; r.values = op(a.values, b.values);
    return
end
```

**Expected impact:** the largest single win. Brings `arith_add_aligned`
from ~900 µs to ~30–60 µs (within ~3× of Python). Cascades to
`diff_quarterly`, `pct_quarterly`, `ytypct_quarterly_100` (which do
multiple binary ops each).

### 5.4 Cache `Unit()` and the default Frequency objects

`tse.Unit()` is constructed many times (every empty `TSeries`,
every default-constructed `MITRange`, every `MIT` made via the
zero-argument path). Replace with `persistent` singletons:

```matlab
function f = unitSingleton()
    persistent u
    if isempty(u), u = tse.Unit(); end
    f = u;
end
```

Apply to `Unit`, `Monthly`, `Daily`, `BDaily`, `Quarterly()`,
`Yearly()`, `HalfYearly()`, `Weekly()` (the no-argument defaults).
Where `endPeriod` varies the type still needs to be constructed.

**Expected impact:** modest per-call (a few µs), but a lot of calls hit
this path. Helps `construct_tseries_qq_100` measurably.

### 5.5 Vectorise scalar-style `t(mit)` lookups

`indexing_mit_lookup_100` is the canonical "death by a thousand cuts"
case: 100 individual `t(mit)` calls, ~30 µs each. There are two fixes:

1. **Vectorised `lookup` free function**. Expose
   `tse.lookup(t, mitArray)` that converts the MIT array to a vector
   of int64 offsets in one shot, then does
   `t.values(offsets - t.firstdate.value + 1)`. Single sub-µs
   vectorised gather replaces the loop entirely.
2. **Speed up the scalar path** anyway. Most of the per-call cost is
   `subsref` overhead; we can shave it by sub-classing
   `matlab.mixin.indexing.RedefinesParen` (R2021b+) which has lower
   dispatch overhead. Until then, inline the doGet dispatch table
   directly into `subsref` (one fewer call) and skip the `subsref →
   doGet` recursion.

**Expected impact:** `indexing_mit_lookup_100` from 3 070 µs to ~5 µs
(vectorised) or ~500 µs (scalar path).

### 5.6 Inline `shift`, `lag`, `lead` to avoid `MIT.minus`

`shift(t, k)` currently does:

```matlab
r = t;
r.firstdate = t.firstdate - k;     % calls MIT.minus, constructs new MIT
```

Replace with a fast path that operates on int64 and packages via the
fast MIT constructor (§5.2):

```matlab
r = t;
r.firstdate = tse.MIT.fast(t.frequency, t.firstdate.value - int64(k));
```

Or, even better, allow `MIT` to be reassigned by mutating only its
`value` field (impossible with `SetAccess = immutable`; revisit if we
relax that). The first form alone should remove most of the overhead.

**Expected impact:** `shift_quarterly_lag1` from 130 µs to ~20 µs.

### 5.7 Special-case `pct`, `apct`, `ytypct` to a single matrix expression

`pct(t)` currently constructs four intermediate TSeries
(`shift`, `minus`, `rdivide`, `times`) then `mtimes` for the *100. Each
intermediate redoes the alignment. The actual math is:

```
pct[i] = (t[i] - t[i-1]) / t[i-1] * 100
```

A direct implementation skips all four binary ops:

```matlab
function r = pct(t, shiftValue, varargin)
    ...
    v   = t.values;
    b   = v(1 : end + shiftValue);
    a   = v(1 - shiftValue : end);
    out = (a - b) ./ b * 100;
    r   = tse.TSeries.fast(t.frequency, t.firstdate - shiftValue, out);
end
```

Same shape for `apct` (raise to N), and for `ytypct` (window = ppy).

**Expected impact:** `pct_quarterly` from 2 157 µs to ~50 µs;
`ytypct_quarterly_100` from 1 109 µs to ~50 µs.

### 5.8 Vectorise `overlay` element-wise loop

The `overlay` function loops 100×3 = 300 times with per-element
`tse.istypenan(v)` calls. Replace with vectorised gather/mask:

```matlab
function r = overlay(varargin)
    rng = ...rangeof_span...
    out = nan(length(rng), 1, cls);
    filled = false(length(rng), 1);
    for k = 1:numel(tsArgs)
        ts = tsArgs{k};
        kOff = double(ts.firstdate.value - rng.startMIT.value);
        idx  = (1:numel(ts.values)) + kOff;
        valid = idx >= 1 & idx <= numel(out);
        mask  = ~isnan(ts.values) & valid';
        slots = idx(mask) ;
        unset = ~filled(slots);
        out(slots(unset)) = ts.values(mask & unset?');
        filled(slots(unset)) = true;
        if all(filled), break, end
    end
    r = tse.TSeries.fast(rng.startMIT.frequency, rng.startMIT, out);
end
```

(Final indexing arithmetic to be polished; the point is vectorised
gather/mask instead of per-cell Python-loop-style code.)

**Expected impact:** `overlay_three_tseries` from 10 718 µs to ~50 µs.

### 5.9 Speed up reductions (`mean`, `std`, `sum`, …) by removing the method overhead

The reductions are defined as:

```matlab
function r = mean(t, varargin)
    r = mean(t.values, varargin{:});
end
```

The `t.values` read goes through `subsref` (because of our override),
adding ~10–50 µs. Solutions, in order of preference:

1. Inside the method, MATLAB's property access should bypass our
   `subsref`; if it doesn't, force it with `getfield(t, 'values')` or
   `builtin('subsref', t, struct('type','.','subs','values'))`.
2. Cache `values` into a local variable at the top of each reduction:
   `v = t.values; r = mean(v, varargin{:});`. This guarantees one
   `subsref` per call.
3. As a last resort, expose `tse.mean(t)` free functions that skip
   method dispatch entirely.

**Expected impact:** `mean_quarterly_100` from 95 µs to ~5 µs.

### 5.10 Replace `length(MITRange)` calls with cached `.length`

`MITRange.length` is recomputed every call. For a unit-step range it
is `stopMIT.value - startMIT.value + 1`. Since the object is immutable
we can cache the result. Even simpler: just remove `length` from hot
loops and inline the subtraction (which we will do as part of §5.3).

**Expected impact:** small, but inside loops it adds up.

### 5.11 Provide a `rec_loop` fast path that doesn't go through `subsref`

For the recursive use case (AR(2), backcasting), the bottleneck is
that every iteration goes through `subsref`/`subsasgn`. Provide a
specialised helper:

```matlab
function t = rec_int(rng, t, fn)
    fd = t.firstdate.value;
    n  = numel(t.values);
    iStart = double(rng.startMIT.value - fd) + 1;
    iEnd   = double(rng.stopMIT.value  - fd) + 1;
    v = t.values;
    for i = iStart:iEnd
        v(i) = fn(v, i);
    end
    t.values = v;
end
```

Adapt `tse.rec` to dispatch into this path when the user-provided
lambda has the simpler `(values, intIndex)` signature (e.g. via
`nargin(fn) == 2`). Document both forms.

**Expected impact:** `rec_ar2_100` from 49 546 µs to ~50 µs.

## 6. Functional bugs to fix in parallel

These show up as `n/a` in the benchmark output and aren't about speed:

- **`undiff_quarterly`** — current error
  `Mixing frequencies not allowed: Quarterly and Unit.`
  Reproduces because `tse.undiff(t)` defaults its anchor date to
  `firstdate(t) - 1` but `1` is an integer, the subtraction goes
  through `MIT.minus(MIT, int)` returning an MIT, but then the
  comparison logic accidentally compares against a `Unit` somewhere
  downstream. Investigate `+tse/undiff.m`.
- **`mean_mvts_axis0_5cols` / `mean_mvts_axis1_100rows`** — error
  `Index in position 1 exceeds array bounds. Index must not exceed 1.`
  My `MVTSeries.mean('dims', 1)` implementation has an off-by-one in
  the parameter-parsing pass. Investigate the `mvReduce` helper in
  `+tse/MVTSeries.m`.

## 7. Suggested execution order

1. **§6 functional fixes** (small) so the benchmark suite is
   complete.
2. **§5.1 — strip validators**: largest single sweep, touches every
   class.
3. **§5.2 — `MIT.fast`, `MITRange.fast`, `TSeries.fast`**: enables
   §5.3 and §5.6.
4. **§5.3 — int64-based `binaryOp`**: biggest individual win, then
   re-run benchmarks to confirm the arithmetic block.
5. **§5.4 — singleton frequencies**: cheap, broad.
6. **§5.5 — `lookup(t, mitArray)`** vectorised free function and
   inline `subsref` dispatch.
7. **§5.6 — `shift` / `lag` / `lead` fast path**.
8. **§5.7 — direct-formula `pct`, `apct`, `ytypct`**.
9. **§5.8 — vectorised `overlay`**.
10. **§5.9 — reduction-method local-variable hoist**.
11. **§5.10, §5.11 — finishing touches**.

After each step, re-run `benchmarks/run_benchmarks.m` and copy a fresh
table into `benchmarks/results.txt` so we can track progress. A
reasonable end-state goal is **every Tier A row within 5× of Python**,
all Tier B/C within an order of magnitude, and all bugs fixed.

## 8. What we deliberately won't try

- **Subclassing `matlab.mixin.indexing.RedefinesParen`** to replace
  `subsref`. This is the textbook way to speed up custom indexing,
  but it requires R2021b+ and the project's stated baseline is
  R2019b. Worth revisiting if the baseline shifts.
- **Rewriting hot paths in MEX/C**. MATLAB MEX would close the rest
  of the gap to Python's Cython kernels, but it adds a build step
  and a per-platform binary requirement; out of scope for now.
- **Replacing the value-class design with a handle class**. Would
  remove the per-call copy-on-write overhead, but would also change
  user semantics in ways we documented against in `PLAN.md §13`.
