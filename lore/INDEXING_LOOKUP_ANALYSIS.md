# `indexing_mit_lookup_100` — performance analysis & options

> Status: analysis + options only. No code changed. Awaiting a decision on
> which (if any) option to pursue.
>
> Caveat: MATLAB/Octave is not available in this environment, so every
> number below that is not already in `results.txt` is an **estimate** based
> on the relative costs visible in the benchmark table. Treat the orders of
> magnitude as reliable and the exact µs figures as indicative until you
> re-run `run_benchmarks.m`.

## TL;DR / recommendation

The current order of magnitude **is expected** and is essentially a property
of the MATLAB runtime, not of our code. The benchmark times a 100-iteration
loop of scalar `t(mit)` indexing; every iteration pays the fixed cost of an
overloaded `subsref` dispatch plus a handful of value-class property reads.
That fixed cost (~20–50 µs/call) cannot be inlined away while indexing goes
through `subsref`.

**Recommendation: keep the scalar path as-is, and close the gap by steering
real workloads to the vectorised `tse.lookup` API that already exists** (plus
two small, low-risk additions: document it, and add a vectorised benchmark
variant so the results table tells the honest story). Pursue the constant-factor
micro-opt (Option B) only if a real workload is shown to depend on scalar-loop
indexing speed; do **not** pursue the `RedefinesParen` rewrite (Option D) for
this alone.

---

## 1. What the benchmark actually measures

From `run_benchmarks.m`:

```matlab
function r = run_indexing_mit_lookup_100(state)
    t    = state.t;       % length-100 quarterly TSeries
    keys = state.keys;    % 1x100 MIT array (collect of an MITRange)
    s    = 0.0;
    for k = 1:numel(keys)
        s = s + double(t(keys(k)));   % <-- scalar MIT indexing, 100x
    end
    r = s;
end
```

It is a deliberately non-idiomatic, Python-style scalar loop: 100 separate
scalar lookups. It mirrors `scenarios.py` in the sister Python port so the two
languages run the *same* program. That is the right thing for a cross-language
comparison, but it means the benchmark exercises exactly the operation MATLAB
is worst at (per-element dispatch on a user class) and never touches the
vectorised path that MATLAB is good at.

## 2. Current numbers

| Scenario                     | MATLAB (µs) | Python (µs) | Ratio |
|------------------------------|------------:|------------:|------:|
| `indexing_mit_lookup_100`    |    4 911.7  |     108.7   | ~45×  |
| `indexing_int_lookup_100`    |    2 018.7  |       —     |   —   |

Per iteration that is ~49 µs (MIT keys) vs ~20 µs (integer keys), against
~1.1 µs/iteration in Python.

(Note: the headline number moved from ~3 071 µs in `PERFORMANCE_PLAN.md` to
~4 912 µs here. Per your note this is almost certainly run-to-run noise / host
load, not a real regression — the inline `subsref` fast path we shipped only
*removed* work from this path. The conclusions below do not depend on the exact
figure.)

## 3. Why — decomposing the per-call cost

The MIT-key and integer-key loops differ by ~29 µs/call. That difference is
the whole story:

| Cost component (per iteration)                              | int key | MIT key |
|------------------------------------------------------------|:-------:|:-------:|
| Overloaded `subsref` method dispatch (the fixed floor)     |   ✓     |   ✓     |
| `double(...)` wrapper call (in the harness, not our code)  |   ✓     |   ✓     |
| `keys(k)` — element extraction from an **MIT object array**  |   —     |   ✓     |
| `idx.frequency`, `idx.value` — MIT property reads          |   —     |   ✓     |
| `t.firstdate` (materialises an MIT) + `.value`             |   —     |   ✓     |
| `t.values(k)` numeric index                                |   ✓     |   ✓     |

Two facts fall out of this:

1. **~20 µs is an irreducible floor.** Even the integer-key loop, which takes
   the simplest possible path, costs ~20 µs/call. That is the price of one
   overloaded-`subsref` dispatch + the harness's `double()` call + loop
   overhead. We already inline the scalar-MIT case at the top of `subsref`
   (`TSeries.m:321`), so the `doGet` detour is *not* part of this cost.

2. **The extra ~29 µs is MIT value-class machinery**, not algorithm. Pulling a
   scalar MIT out of an object array (`keys(k)`) and reading its properties are
   each separate classdef operations that MATLAB cannot fold into the loop.

The arithmetic itself — `s + value` — is nanoseconds. There is no algorithmic
inefficiency to fix here; it is dispatch overhead end to end.

## 4. Why Python is ~45× faster (and why that's not a fair fight)

This is a runtime characteristic, not an implementation gap. Python's
`__getitem__` for a scalar key is a thin method that resolves to a NumPy/array
offset; CPython's per-call overhead for that is ~1 µs. MATLAB's overloaded
`subsref` on a *value* class carries much higher fixed per-call overhead, and
every property read on a value object is itself a dispatch. MATLAB is designed
to amortise that over **vectorised** calls, not per-element ones.

The corollary: we will not make per-element scalar object indexing competitive
with Python in MATLAB. We *can* make the vectorised equivalent competitive or
better — and we already have (`arith_mul_scalar` is faster than Python;
aligned/misaligned arithmetic are within ~2–5×).

## 5. Is the current order of magnitude expected? — Yes

Given §3–§4: yes. ~5 ms for 100 scalar object lookups is the expected cost of
100 overloaded-`subsref` dispatches in MATLAB. The optimisation work already
done (inline scalar-MIT fast path, int-coded frequencies, no validators on the
hot constructor) has removed the avoidable work; what remains is the runtime's
fixed per-call cost.

---

## 6. Options & trade-offs

### Option A — Keep as-is; document the vectorised alternative *(recommended baseline)*

We already ship `tse.lookup(t, keys)` (`+tse/lookup.m`), which collapses N
scalar dispatches into **one** call + vectorised index arithmetic:

```matlab
vals = tse.lookup(t, keys);   % keys = MIT array or MITRange
s    = sum(vals);
```

This is the idiomatic MATLAB pattern and is the real-world answer to "looking
up many dates". `t(mitrange)` and `t(mit_array)` also already do the gather in
a single dispatch.

- **Pros:** zero code risk; indexing stays clean and idiomatic; the fast path
  for users who care already exists. Nothing to maintain.
- **Cons:** the specific micro-benchmark stays ~45× Python, because it is hard-
  coded to loop. Looks bad in the table unless annotated.
- **Effort:** ~none (just docs).

### Option B — Constant-factor micro-opt of the scalar `subsref` path

Cache the firstdate's raw `int64` value on `TSeries` (e.g. a hidden
`fdvalue` property kept in sync wherever `firstdate` is assigned), so the hot
path reads a plain integer instead of materialising `t.firstdate` and reading
`.value`. The two `idx.*` reads are irreducible (we genuinely need the key's
value and frequency).

- **Pros:** shaves a few µs/call — best case brings ~49 µs toward the ~40 µs
  range (≈10–20%).
- **Cons:** **does not change the order of magnitude** (~37× Python instead of
  ~45×). Introduces a denormalised field that must be kept in sync in every
  place `firstdate` is set (constructors, `shift`/`lag`/`lead`, `resize`,
  `doGet` range slice, every direct-formula method). Real risk of subtle
  desync bugs for a small payoff. A *dependent* property does **not** help — its
  getter is itself the dispatch we are trying to avoid.
- **Effort:** small code, but meaningful review/test surface for the sync
  invariant.

### Option C — Promote & extend the vectorised API; add an honest benchmark variant *(recommended companion to A)*

1. Document `tse.lookup` in the README/indexing docs as *the* way to gather
   many dates.
2. Add a second benchmark scenario, e.g. `indexing_mit_lookup_vectorised_100`,
   that uses `tse.lookup`, so `results.txt` shows both the language-inherent
   scalar-loop cost **and** the idiomatic vectorised cost side by side.
3. (Optional) Add an `int64`-keyed fast lookup so callers holding precomputed
   offsets can do `t.values(offsets - fdv + 1)` with no per-key MIT reads at
   all — the absolute floor.

- **Pros:** turns the comparison honest and actionable; the vectorised line
  should land in the low-hundreds-of-µs (roughly Python-comparable) for 100
  keys; guides users to the right pattern.
- **Cons:** `tse.lookup` still loops once over the MIT array to extract `int64`
  values (`lookup.m:47`), so it is faster but not free unless keys are
  pre-materialised as integers; adding a scenario slightly grows the suite.
- **Effort:** small.

### Option D — Replace `subsref` with `matlab.mixin.indexing.RedefinesParen` (R2021b+)

The textbook way to speed up custom indexing. Implement `parenReference` etc.
instead of overloading `subsref`/`subsasgn`.

- **Pros:** potentially lower per-call overhead; cleaner indexing model.
- **Cons:** **payoff is uncertain and not guaranteed to be order-of-magnitude**
  — it still dispatches per element. Large, invasive refactor touching all
  indexing in `TSeries` and `MVTSeries`, plus their tests. Raises the minimum
  MATLAB version to R2021b. High risk-to-reward for this single benchmark.
- **Effort:** large.

### Summary table

| Option | Order-of-magnitude win? | Effort | Risk | Recommend |
|--------|:-----------------------:|:------:|:----:|:---------:|
| A — keep as-is + docs            | no (vectorised path already exists) | ~none | none   | ✅ baseline |
| B — cache firstdate int64        | no (~10–20% only)                   | small | medium | ⚠️ only if needed |
| C — promote `lookup` + benchmark | yes, *via vectorisation*            | small | low    | ✅ companion |
| D — `RedefinesParen` rewrite     | unlikely                            | large | high   | ❌ not now |

---

## 7. Recommendation

Adopt **A + C**:

- Leave scalar `t(mit)` indexing as-is — it is correct, idiomatic, and already
  has its avoidable overhead removed.
- Document `tse.lookup` as the supported way to gather many dates, and add a
  vectorised benchmark variant so the results table shows both the
  language-inherent scalar cost (~45× Python, expected) and the idiomatic
  vectorised cost (≈ Python-comparable).

Hold **B** in reserve: implement the cached-`int64` firstdate only if profiling
of a *real* model shows scalar-loop indexing on the critical path; the
maintenance cost of the sync invariant is not worth ~15% otherwise.

Do not pursue **D** for this benchmark. Revisit only if custom-indexing
overhead becomes a broad, measured bottleneck across many scenarios.

## 8. What I'd want to confirm by running

If you'd like to validate before deciding, the cheap experiments are:

1. Re-run `run_benchmarks('only', 'indexing_mit_lookup_100,indexing_int_lookup_100')`
   a few times to confirm the ~20 µs floor and the ~29 µs MIT delta are stable
   (not noise).
2. Time `tse.lookup(t, keys)` for the same 100 keys (Option C's variant) to
   confirm it lands near Python.
3. (If considering B) prototype the cached `int64` firstdate behind the scalar
   `subsref` path and measure whether the delta actually narrows toward the
   ~20 µs integer floor.
