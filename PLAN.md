# TimeSeriesEcon.m — Implementation Plan

A plan for porting the core of
[`TimeSeriesEcon.jl`](https://github.com/bankofcanada/TimeSeriesEcon.jl)
to MATLAB. Scope: `MIT` / `Duration`, `TSeries`, `MVTSeries`, and a matching
unit-test suite. **Out of scope:** `fconvert`, `X13`, `DataEcon`.

The reference Julia source examined for this plan corresponds to version
`0.7.4` of `TimeSeriesEcon.jl`.

---

## 1. Goals and non-goals

### Goals
1. Faithfully reproduce the **public API surface** of `TimeSeriesEcon.jl` for
   the in-scope types: construction, indexing, arithmetic, broadcasting,
   shifting, differencing, percent-change, overlay, recursive evaluation,
   range arithmetic, and pretty-printing.
2. Keep **idiomatic MATLAB usage** wherever the Julia syntax doesn't carry
   over (e.g. `2020Q1` literals, macros, multiple dispatch, broadcasting dots).
3. Provide **speed competitive with native MATLAB arrays** on the hot path
   (vectorized arithmetic over the underlying numeric storage), while
   accepting a small constant overhead at the object boundary.
4. Ship a **unit-test suite** built with `matlab.unittest` that mirrors the
   Julia test files for in-scope features.

### Non-goals
- Frequency conversion (`fconvert/`), X-13 (`x13/`), DataEcon (`dataecon/`),
  plot recipes (`plotrecipes.jl`), serialization for distributed computing,
  business-daily holiday calendars, and TOML I/O. Most of these are either
  separate FFI bindings or rely on Julia ecosystem packages that have no
  meaningful MATLAB analogue, and the user asked them to be skipped.
- Bit-for-bit reproduction of Julia error messages.
- Bit-for-bit reproduction of the show/print layout (we will match the
  *shape* of the output — header, range, truncated rows — but not the
  exact spacing characters).

### MATLAB version target
- Baseline: **R2019b or later**. R2019b has the `arguments` block,
  `string` type, `containers.Map`/`dictionary` (R2022b), and a stable
  `matlab.unittest` framework.
- Where post-R2019b features (`dictionary`, `pattern`, dot-method indexing)
  would simplify the code, we will use them behind a small compatibility
  helper and document the minimum version in the function header.

---

## 2. Repository layout

The MATLAB convention is one top-level class/function per file. We will use
package directories (`+pkg`) to namespace everything under `+tseries`.

```
TimeSeriesEcon.m/
├── README.md
├── PLAN.md                          ← this document
├── LICENSE                          ← MIT/BSD-style, matching Julia source
├── startup_tseries.m                ← adds +tseries and tests to the path
│
├── +tseries/                        ← main package (`tse.MIT`, etc.)
│   ├── Contents.m                   ← short package overview
│   │
│   ├── Frequency.m                  ← abstract base
│   ├── Unit.m                       ← non-calendar frequency
│   ├── CalendarFrequency.m          ← abstract
│   ├── YPFrequency.m                ← abstract (year-period)
│   ├── Yearly.m
│   ├── HalfYearly.m
│   ├── Quarterly.m
│   ├── Monthly.m
│   ├── Weekly.m
│   ├── Daily.m
│   ├── BDaily.m
│   │
│   ├── MIT.m                        ← moment-in-time value class
│   ├── Duration.m                   ← duration value class
│   ├── MITRange.m                   ← UnitRange{MIT} replacement
│   │
│   ├── TSeries.m                    ← univariate time series (value class)
│   ├── MVTSeries.m                  ← multivariate time series (value class)
│   │
│   ├── frequencyof.m                ← top-level free function
│   ├── rangeof.m
│   ├── rangeof_span.m
│   ├── firstdate.m
│   ├── lastdate.m
│   ├── ppy.m
│   ├── endperiod.m
│   ├── sanitize_frequency.m
│   ├── typenan.m
│   ├── istypenan.m
│   │
│   ├── mm.m / qq.m / yy.m           ← year-period constructors
│   ├── daily.m / bdaily.m / weekly.m
│   ├── U.m / Y.m / H1.m / H2.m
│   ├── Q1.m / Q2.m / Q3.m / Q4.m
│   ├── M1.m … M12.m                 ← convenience constants
│   │
│   ├── shift.m / lead.m / lag.m
│   ├── overlay.m
│   ├── diff_ts.m                    ← `diff` is reserved, use diff_ts
│   ├── cumsum_ts.m                  ← similar reason
│   ├── pct.m / apct.m / ytypct.m
│   ├── moving.m / moving_sum.m / moving_average.m
│   ├── undiff.m
│   ├── reindex.m
│   ├── compare_ts.m
│   ├── rec.m                        ← replaces the @rec macro
│   ├── strip_ts.m                   ← `strip` is reserved
│   │
│   ├── isyearly.m / ishalfyearly.m / isquarterly.m / ismonthly.m
│   ├── isweekly.m / isdaily.m / isbdaily.m
│   │
│   └── private/                     ← package-internal helpers
│       ├── mit2yp.m
│       ├── yp2mit.m
│       ├── checkFrequency.m
│       ├── alignRanges.m
│       ├── resizeStorage.m
│       └── prettyprint_frequency.m
│
└── tests/
    ├── runAllTests.m                ← top-level runner (matlab.unittest)
    ├── TestMIT.m
    ├── TestDuration.m
    ├── TestRange.m
    ├── TestFrequency.m
    ├── TestTSeriesConstruct.m
    ├── TestTSeriesIndex.m
    ├── TestTSeriesBroadcast.m
    ├── TestTSeriesMath.m
    ├── TestTSeriesShow.m
    ├── TestMVTSeriesConstruct.m
    ├── TestMVTSeriesIndex.m
    ├── TestMVTSeriesBroadcast.m
    ├── TestMVTSeriesMath.m
    ├── TestMVTSeriesShow.m
    ├── TestOverlay.m
    ├── TestShiftLagLead.m
    ├── TestPctApct.m
    ├── TestRec.m
    └── TestLinalg.m
```

Why a `+tseries` package rather than the original `TimeSeriesEcon` name?
MATLAB package names should be lower-case to avoid clashing with classdef
file name expectations. Users will typically write `import tse.*` at
the top of their scripts, and `qq(2020,1)` etc. will resolve to
`tse.qq`.

---

## 3. Type design

### 3.1 Frequency hierarchy

Julia uses an abstract type tree with type parameters such as
`Quarterly{3}` and `Weekly{7}` so that the *end period* is part of the
type itself.

MATLAB has no value-parameterized types. We therefore represent every
frequency as an **instantiated value object** with two fields:

```matlab
classdef Frequency
    properties (SetAccess = immutable)
        endPeriod (1,1) double {mustBeInteger, mustBePositive} = 1
    end
    properties (Abstract, Constant)
        Name                     % e.g. 'Quarterly'
        PeriodsPerYear           % e.g. 4
        DefaultEndPeriod         % e.g. 3
    end
    methods
        function tf = eq(a,b); …; end   % same class & same endPeriod
        function s = char(F); …; end    % pretty-printed
        function tf = isfrequency(~); tf = true; end
    end
end
```

Concrete subclasses (`Yearly`, `HalfYearly`, `Quarterly`, `Monthly`,
`Weekly`, `Daily`, `BDaily`, `Unit`) inherit and either fix or validate
`endPeriod`:

```matlab
classdef Quarterly < tse.YPFrequency
    properties (Constant)
        Name = 'Quarterly'
        PeriodsPerYear = 4
        DefaultEndPeriod = 3
    end
    methods
        function F = Quarterly(endMonth)
            if nargin < 1, endMonth = 3; end
            mustBeMember(endMonth, 1:3)
            F.endPeriod = endMonth;
        end
    end
end
```

`Monthly` and `Unit` carry no `endPeriod` variation (always 1). `BDaily`
and `Daily` are fixed too.

**Frequency equality** is class-equality plus `endPeriod` equality. This
replaces Julia’s `Quarterly{3} == Quarterly{3}` parametric check.

**Less-than on frequency types** orders by `PeriodsPerYear` (used in a few
places in Julia and reproduced for parity). Implemented via `lt`.

### 3.2 MIT and Duration

These are the analogues of Julia’s `MIT{F}` and `Duration{F}`. Both are
**value classes** wrapping an `int64` and a `Frequency`. Internally MIT
stores a count of periods since the epoch defined by Julia (year 0
period 1 for YP frequencies, the day after 0001-01-01 for `Daily`, etc.)
so we can interoperate with serialized Julia data byte-for-byte.

```matlab
classdef MIT
    properties (SetAccess = immutable)
        value (1,1) int64
        frequency (1,1) tse.Frequency
    end
    methods
        function obj = MIT(F, value)
            obj.frequency = F;
            obj.value     = int64(value);
        end
        % overloaded operators (see §5)
        % overloaded indexing for ranges (see §6.3)
    end
end
```

`Duration` is the same shape but separate so we can keep distinct typing
rules (e.g. `MIT - MIT -> Duration`; `MIT + Duration -> MIT`; `Duration +
Integer -> Duration`).

We expose constructors via free functions:

| Julia                       | MATLAB                                |
| --------------------------- | ------------------------------------- |
| `MIT{Quarterly}(2020, 2)`   | `MIT(Quarterly(), 2020, 2)` or `qq(2020,2)` |
| `qq(2020, 2)`               | `qq(2020, 2)`                         |
| `2020Q1` literal            | `qq(2020,1)` (no operator-on-Int hack)|
| `MIT{Daily}("2022-01-01")`  | `daily('2022-01-01')`                 |
| `d"2022-01-01"`             | `daily('2022-01-01')`                 |
| `d"2022-01-01:2022-01-10"`  | `daily('2022-01-01','2022-01-10')`    |
| `bd"2022-01-01"`            | `bdaily('2022-01-01')`                |
| `bd"2022-01-01"n`           | `bdaily('2022-01-01','bias','next')`  |
| `weekly("2022-01-01", 6)`   | `weekly('2022-01-01', 6)`             |

The convenience names `Q1` … `Q4`, `H1`, `H2`, `M1` … `M12`, `Y`, `U`
become zero-argument MATLAB functions that *return a small helper value*
which a year integer can be multiplied by — except MATLAB has no
multiplication overload between `double` and a custom class on the left
without overloading `mtimes` for `double`. We instead expose them as
two-argument constructors and keep the single-argument call as the
documented form:

```matlab
qq(2020,1)            % preferred
mm(2020,12)
yy(2020)
```

For users porting Julia code mechanically, we additionally provide a
parser, `tse.mit('2020Q1')`, that accepts the Julia literal as a
string. This is the only MIT-from-literal-string entry point.

### 3.3 TSeries

```matlab
classdef TSeries
    properties
        firstdate (1,1) tse.MIT
        values                          % numeric column vector
    end
    methods
        % constructors, see §4
        % subsref / subsasgn,  see §6
        % overloaded operators, see §5
        % see Display.m / disp / showAllAt
    end
end
```

Notes:
- **Value class, not handle.** Julia `mutable struct` enables in-place
  resize on out-of-range assignment. MATLAB value classes can do the same
  via `subsasgn`: assignment of an out-of-range MIT returns an extended
  copy, which MATLAB then writes back to the caller's binding. This
  exactly matches Julia's "extend on assign" behaviour from the user
  perspective.
- **`values` is always a column vector** of any numeric type
  (`double`, `single`, `int32`, `logical`). Matching Julia's
  `TSeries{F,T}`.
- **Containers**: Julia allows alternative containers (`SubArray`, etc.)
  via the `C` type parameter. In MATLAB we do not expose this — internal
  storage is always `numeric`. Views into a TSeries are supported through
  `subsref` returning a new TSeries that shares the same `values` via
  MATLAB's copy-on-write.

### 3.4 MVTSeries

```matlab
classdef MVTSeries
    properties
        firstdate (1,1) tse.MIT
        colnames  (1,:) string
        values                  % numeric matrix, size(values,1) = length
                                % of range, size(values,2) = numel(colnames)
    end
    methods
        % see §6.4 for indexing rules
    end
end
```

Notes on differences from Julia:
- We **drop** the `columns::OrderedDict{Symbol,TSeries}` field. Maintaining
  cached `TSeries` views into matrix columns would require either handle
  semantics or a more elaborate book-keeping path. Instead, accessing
  `x.foo` returns a *fresh* `TSeries` whose `values` is `x.values(:,k)`
  (a column copy in MATLAB by default; with COW this is cheap until the
  caller mutates it). Setting `x.foo = newCol` writes into
  `x.values(:,k)`.
- `colnames` is `string`, not `Symbol`, since MATLAB has no symbol type.
  Strings are accepted on input via `string()` coercion.

This is the **biggest semantic compromise** in the port: Julia's columns
are live views, so `x.a[2020Q1] = 5` mutates the matrix. In MATLAB you
must write `x.a = setvalue(x.a, 2020Q1, 5)` or `x = setindex(x,
5,2020Q1,'a')`. We will provide a helper `setcol!`-style function:

```matlab
x = setcol(x, 'a', newTSeries);   % copies into x.values(:,k)
x.a(2020Q1) = 5;                  % delegated via subsasgn so it works
```

The second form works because MATLAB's `subsasgn` is called on `x` with
the full path `('a', 2020Q1)`, and our `subsasgn` on `MVTSeries` handles
the composite assignment by writing through to the underlying matrix.
This preserves Julia's UX at the cost of a slightly more elaborate
`subsasgn` implementation (see §6.4).

---

## 4. Constructors

We mirror Julia's many constructors. For TSeries:

```matlab
TSeries()                                    % empty (no args)
TSeries(n)                  % Unit-frequency, length n, uninitialized
TSeries(MIT)                % start date, length 0
TSeries(MITrange)           % range, NaN-filled double
TSeries(MITrange, scalar)   % range, filled with scalar
TSeries(MITrange, vec)      % range + values (length must match)
TSeries(MIT, vec)           % start date + values
TSeries(type, MITrange)     % type-specified storage, NaN-equivalent fill
TSeries(MITrange, @rand)    % function handle initializer

% built-ins
zeros_ts(MITrange)
ones_ts(MITrange)
falses_ts(MITrange)
trues_ts(MITrange)
fill_ts(value, MITrange)
similar_ts(other, type, range)
```

(We *cannot* override the built-in `zeros`, `ones`, `fill`, `similar` for
range-arguments the way Julia does, so we provide explicit
`*_ts` wrappers and document the convention.)

For MVTSeries:

```matlab
MVTSeries(MIT)                                       % (0,0)
MVTSeries(MIT, names)                                % (0,N)
MVTSeries(MITrange, names)                           % NaN-filled
MVTSeries(MITrange, names, undef)                    % alias
MVTSeries(MITrange, names, scalar)
MVTSeries(MITrange, names, matrix)                   % size must match
MVTSeries(MIT, names, matrix)                        % size determines range
MVTSeries(MIT, names, vector)                        % single-column reshape
MVTSeries(MITrange, name=value, name=value, ...)     % name-value pairs;
                                                     % values can be TSeries,
                                                     % vector, or scalar
MVTSeries(name=value, name=value, ...)               % range inferred from
                                                     % TSeries args (span)
fill_mv(value, MITrange, names)
zeros_mv / ones_mv …
similar_mv(other, type, range, names)
```

Hcat and vcat are implemented to mirror Julia's `hcat`/`vcat` semantics:
`horzcat(A,B,...)` produces a column-union MVTSeries on the union of the
ranges; `vertcat` extends rows. Name-value extra columns from `hcat` are
supported via a parameterless trailing struct or `(...,'NewVar',data)`.

---

## 5. Arithmetic & operator overloading

| Julia                       | MATLAB method to overload | Notes |
| --------------------------- | ------------------------- | ----- |
| `+`, `-`, `*`, `/`          | `plus`, `minus`, `mtimes`, `mrdivide` | |
| `.+`, `.-`, `.*`, `./`, `.^`| same as above (MATLAB has no syntactic dot) | implicit expansion handles broadcasting |
| `==`, `!=`, `<`, `<=`, `>=`, `>` | `eq`, `ne`, `lt`, `le`, `ge`, `gt` | |
| `-x` unary                  | `uminus`                  | |
| `\` left-divide             | `mldivide`                | |
| `transpose`, `adjoint`      | `transpose`, `ctranspose` | both delegate to underlying numeric |

### 5.1 Rules per type

**MIT**:
- `MIT - MIT` → `Duration` (same frequency required, else error)
- `MIT + Integer` → `MIT` (integer treated as Duration of same frequency)
- `MIT - Integer` → `MIT`
- `MIT + Duration` → `MIT` (matching frequency)
- `MIT + MIT` → **error**
- `MIT < MIT` defined iff same frequency
- `MIT == MIT` requires same class & same int value (so `qq(0,1) ==
  mm(0,1)` is `false` without throwing).

**Duration**:
- `Duration ± Duration` → `Duration` (matching frequency)
- `Duration ± Integer` → `Duration` (integer treated as same frequency)
- `Integer * Duration` → `Duration` (allowed because Julia allows it)

**TSeries `T = A op B`**:
- `op ∈ {+,-}` between two same-frequency TSeries → new TSeries over the
  intersection of ranges, element-wise.
- `op` between TSeries and scalar → element-wise.
- `op` between TSeries and vector of matching length → element-wise.
- Mixing frequencies anywhere → `error('tseries:mixedFreq', ...)`.

**MVTSeries**:
- Element-wise `+`/`-` between two MVTSeries: column names must match
  (or be a subset, see Julia behaviour); range becomes intersection.
- `scalar * MVTSeries` and `MVTSeries / scalar` defined.
- Matrix-multiply (`A * B`) defers to the underlying numeric storage.

### 5.2 Implicit expansion (MATLAB's broadcasting)

MATLAB's implicit expansion gives us most of Julia's dot-broadcasting for
free at the *numeric* layer. The work is in:

1. Promoting the result of an operation back into a TSeries/MVTSeries
   with the right range and column names (in `plus`, `minus`, etc., we
   construct the result wrapper).
2. Aligning the underlying numeric storage on the range intersection
   before computing.
3. Throwing on mixed frequency.

We add a private helper `private/alignBinary.m`:

```matlab
function [va, vb, frng, fcols] = alignBinary(a, b)
    % a, b can be TSeries, MVTSeries, or numeric arrays.
    % Returns numeric storage already trimmed/expanded to common range
    % and column intersection. frng / fcols describe the result wrapper.
end
```

`plus(A,B)`, `minus(A,B)`, etc. all become:

```matlab
function R = plus(A, B)
    [va, vb, frng, fcols] = tse.private.alignBinary(A, B);
    rv = va + vb;       % implicit expansion does the work
    R  = tse.private.makeResult(rv, frng, fcols, A, B);
end
```

`makeResult` decides whether to return TSeries, MVTSeries, or plain
numeric based on the input types and result shape.

---

## 6. Indexing

This is the most subtle area of the port because MATLAB's indexing has
its own dispatch rules.

### 6.1 Approach

We implement traditional `subsref` and `subsasgn`. (We considered
`matlab.mixin.indexing.RedefinesParen` from R2021b but it requires
careful interaction with `dot` and `brace` redefiners and is less
portable; baseline R2019b precludes it anyway.)

Both methods always operate on the **first** subscript element and then
recurse with `subsref(...,s(2:end))` for nested expressions.

### 6.2 Range type (`MITRange`)

Julia constructs `2020Q1:2021Q4` as `UnitRange{MIT{Quarterly{3}}}`. In
MATLAB the `:` colon operator works on doubles only. We define an
explicit `MITRange` class with `firstdate`, `lastdate`, `step`. The
constructor function `rangeof(...)` returns this. Users build ranges
with:

```matlab
rng = qq(2020,1) : qq(2021,4);          % via MIT.colon overload
rng = MITRange(qq(2020,1), qq(2021,4));
rng = MITRange(qq(2020,1), 2, qq(2021,4)); % step ranges
```

We overload `colon` on `MIT` to return `MITRange`. `length(rng)`,
`numel(rng)`, `rng(k)`, iteration with `for m = rng`, and `intersect`,
`union` are all implemented on `MITRange`.

### 6.3 TSeries indexing (numeric)

| Expression                | Result                                  | Implementation note |
| ------------------------- | --------------------------------------- | ------------------- |
| `t(i)` integer            | scalar number                           | `subsref` index 1 is double |
| `t(i:j)` integer range    | plain `double` vector                   | mirrors Julia |
| `t(bool)` logical vector  | plain numeric                           | |
| `t(mit)` MIT              | scalar number                           | bounds-checked |
| `t(mitRange)` MITRange    | new `TSeries`                           | range becomes the slice |
| `t(:)`                    | the TSeries itself (not flattened)      | matches Julia |
| `t(end)`                  | works because we define `end` method    | |
| `t(begin+1:end)`          | MATLAB has no `begin` — use `firstdate(t)+1:lastdate(t)` |
| `t(2:end)`                | **error**: cannot mix integer & MIT     | matching Julia |

Assignment rules mirror Julia’s: assigning an MIT outside the current
range **grows the TSeries** with NaN-padding; assigning an integer
outside range throws `BoundsError` analogue (`error('tseries:bounds',
...)`).

### 6.4 MVTSeries indexing

| Expression                              | Result                                 |
| --------------------------------------- | -------------------------------------- |
| `x(i)`, `x(i,j)` integer                | numeric                                |
| `x(:,k)` colon + integer                | numeric column                         |
| `x(mit)`                                | row vector at that date                |
| `x(mitRange)`                           | sub MVTSeries (all columns)            |
| `x(mit, name)` / `x(mit, names)`        | numeric scalar / row vector            |
| `x(mitRange, name)`                     | TSeries (single name)                  |
| `x(mitRange, names)`                    | sub MVTSeries                          |
| `x.name` (dot-indexing)                 | TSeries (built from view of `values`)  |
| `x.name(mit) = v`                       | composite — see below                  |

Composite assignment `x.name(mit) = v` is dispatched to `subsasgn(x,
S(1:2), v)` where `S(1).type == '.'` and `S(2).type == '()'`. Our
implementation:

1. Locate column index `k = colindex(x, name)`.
2. Compute row index `r = rowindex(x, mit)`. If out of range, **grow
   `x.values`** (and `firstdate`) with NaN padding, mirroring TSeries.
3. Write `x.values(r, k) = v`.

This preserves the Julia UX (`x.a[2020Q1] = 5` mutates underlying matrix)
without storing live TSeries views.

### 6.5 Logical-mask indexing

`t(t < 0) *= -1` becomes in MATLAB:
```matlab
t(t < 0) = -t(t < 0);
```
Our `lt` returns a `TSeries{logical}` and our `subsasgn` honours logical
masks both as a `TSeries{logical}` and as a plain logical vector.

---

## 7. Time-series operations

Direct ports of Julia's API:

| Julia                                            | MATLAB             |
| ------------------------------------------------ | ------------------ |
| `shift(t, k)` / `shift!(t, k)`                   | `shift(t,k)` returns shifted copy; in-place form via `t = shift(t,k)` |
| `lag(t, k=1)` / `lead(t, k=1)`                   | `lag(t,k)`, `lead(t,k)` |
| `diff(t, k=-1)`                                  | `diff_ts(t,k)` (no shadow of base `diff`) |
| `cumsum(t)`                                      | `cumsum(t)` overloaded |
| `pct(t, shift=-1, islog=false)`                  | `pct(t, shift, 'islog', tf)` |
| `apct(t, islog=false)`                           | `apct(t, islog)` |
| `ytypct(t)`                                      | `ytypct(t)` |
| `moving(t, n)`                                   | `moving(t, n)` |
| `moving_sum`, `moving_average`                   | identical names |
| `undiff(dvar, [date => value])`                  | `undiff(dvar, anchorDate, anchorValue)` |
| `overlay([rng,] t1, t2, …)`                      | `overlay(rng, t1, t2, …)` and `overlay(t1, t2, …)` |
| `reindex(ts, from => to)`                        | `reindex(ts, from, to)` |
| `strip!(t)` / `strip(t)`                         | `strip_ts(t)` and `t = strip_ts(t)` |
| `@rec rng ts[t] = …`                             | `rec(rng, @(t) ts(t) = …)` see §7.1 |
| `@showall x`                                     | `showAll(x)` |
| `@compare x y`                                   | `compare_ts(x, y, ...)` |

### 7.1 Replacing `@rec`

`@rec` rewrites a *loop body* into a `for` loop. In MATLAB we provide a
function `rec(range, target, depMITs, body)` that takes:

- `range`: an `MITRange`
- `target`: a handle to the assignment target (`@(t) ts(t)`)
- `depMITs`: a vector of relative offsets accessed by the body (e.g.
  `[-1 -2]` for Fibonacci)
- `body`: a function `@(t, deps) deps(1) + deps(2)`

It runs:
```matlab
for t = range
    deps = arrayfun(@(d) ts(t+d), depMITs);
    ts(t) = body(t, deps);
end
```

This trades a tiny amount of syntactic ergonomics for portability — and
in practice most callers loop directly:

```matlab
for t = MITRange(qq(2020,1)+2, qq(2025,4))
    ts(t) = ts(t-1) + ts(t-2);
end
```

We document both forms.

---

## 8. NaN handling, `typenan`, `istypenan`

- `typenan(double)` → `NaN`
- `typenan(single)` → `single(NaN)`
- `typenan(integer)` → `intmax(type)` (matches Julia, with the explicit
  caveat in the docstring that this is a sentinel, not a real NaN).
- `typenan(MIT)` → `MIT(F, intmax('int64'))`.
- `istypenan(x)` → true for `NaN`, `intmax` of integer, `MIT(intmax)`,
  `missing`, `[]`.

When a TSeries is **resized to a larger range**, the new cells are
filled with `typenan(eltype(t))`. The Julia behaviour we want to
preserve.

---

## 9. Display / pretty printing

Override `disp(t)`, `display(t)`, and `details(t)` so that:

```
12-element TSeries{Quarterly} with range 2020Q1:2022Q4:
    2020Q1 : 11
    2020Q2 : 12
       ⋮      ⋮
    2022Q3 : 21
    2022Q4 : 22
```

Truncation respects MATLAB's command window size via `matlab.desktop.commandwindow.size`
or a fallback (80×24).

For MVTSeries we reproduce the side-by-side column layout, truncating
column names longer than 10 chars with `…`, exactly as Julia does. The
algorithm closely follows `src/mvtseries/mvts_show.jl`.

`showAll(x)` reproduces the Julia `@showall` macro by printing the
object without truncation.

---

## 10. Errors

We use a consistent error-ID hierarchy so tests can `verifyError`:

| Julia                            | MATLAB error ID                    |
| -------------------------------- | ---------------------------------- |
| `ArgumentError("Mixing freq…")`  | `tseries:mixedFreq`                |
| `ArgumentError("Invalid arith…")`| `tseries:invalidArith`             |
| `BoundsError`                    | `tseries:bounds`                   |
| `DimensionMismatch`              | `tseries:dimMismatch`              |
| `MethodError` (no matching)      | `tseries:noMatch`                  |
| `InexactError`                   | `tseries:inexact`                  |

A single utility function builds these:

```matlab
function tse.private.thrw(id, fmt, varargin)
    msg = sprintf(fmt, varargin{:});
    throwAsCaller(MException(['tseries:' id], msg));
end
```

---

## 11. Test suite

Mirrors `test_mit.jl`, `test_tseries.jl`, `test_mvtseries.jl`, and the
in-scope parts of `test_various.jl`. Built on `matlab.unittest`.

### 11.1 Mapping

| Julia test file        | MATLAB test class(es)                                |
| ---------------------- | ---------------------------------------------------- |
| `test_mit.jl`          | `TestMIT`, `TestDuration`, `TestRange`, `TestFrequency` |
| `test_tseries.jl`      | `TestTSeriesConstruct`, `TestTSeriesIndex`, `TestTSeriesBroadcast`, `TestTSeriesMath`, `TestTSeriesShow`, `TestShiftLagLead`, `TestPctApct`, `TestOverlay`, `TestRec` |
| `test_mvtseries.jl`    | `TestMVTSeriesConstruct`, `TestMVTSeriesIndex`, `TestMVTSeriesBroadcast`, `TestMVTSeriesMath`, `TestMVTSeriesShow`, plus shared overlay/pct |
| `test_various.jl`      | `TestLinalg`, `TestFindAll`, `TestOverlay2`, `TestMisc` |

We **do not port** `test_business.jl`, `test_fconvert*.jl`,
`test_x13*.jl`, `test_dataecon.jl`, `test_serialize.jl`,
`test_workspace.jl`, `test_22.jl` (regression test for issue 22 in
fconvert).

### 11.2 Style

A representative test class:

```matlab
classdef TestMIT < matlab.unittest.TestCase
    methods (Test)
        function mit2yp_quarterly(tc)
            import tse.*
            tc.verifyEqual(mit2yp(MIT(Quarterly,5)), [1 2]);
            tc.verifyEqual(mit2yp(MIT(Quarterly,-1)), [-1 4]);
        end
        function mit_subtraction_returns_duration(tc)
            import tse.*
            d = qq(2020,1) - qq(2019,2);
            tc.verifyClass(d, 'tse.Duration');
            tc.verifyEqual(int64(d), int64(3));
        end
        function mixed_frequency_subtraction_throws(tc)
            tc.verifyError(@() tse.qq(2020,1) - tse.mm(2019,2), ...
                'tseries:mixedFreq');
        end
    end
end
```

The runner:

```matlab
function results = runAllTests()
    import matlab.unittest.TestSuite
    suite   = TestSuite.fromFolder(fullfile(fileparts(mfilename('fullpath'))));
    runner  = matlab.unittest.TestRunner.withTextOutput('Verbosity', 2);
    results = runner.run(suite);
end
```

`runAllTests` will also be the CI entry-point.

### 11.3 What we cannot test 1:1

A handful of Julia tests are tied to internals we are not porting:
broadcast-style introspection (`Base.Broadcast.preprocess`,
`BroadcastStyle`), serialization plumbing, and Plot recipes. We will
flag these in the test files with comments explaining the omission.

---

## 12. Phasing

Suggested order, each phase building on the previous. Each phase ends
with that phase's tests passing.

1. **Phase 1 — Frequency, MIT, Duration, MITRange.**
   `Frequency` hierarchy, `MIT`, `Duration`, free constructors `qq/mm/yy/
   daily/bdaily/weekly`, `frequencyof`, `ppy`, `endperiod`,
   `sanitize_frequency`, arithmetic, comparisons, `mit2yp`, `MITRange`
   with iteration, `intersect`, `union`, `length`, `step`.
   Ports `test_mit.jl`.

2. **Phase 2 — TSeries core.**
   Construction (all overloads), `firstdate`, `lastdate`, `rangeof`,
   `length`, `size`, `subsref` (integer / MIT / range / `:` / logical),
   `subsasgn` with growth semantics, `disp`, `summary`.
   Ports the construction and integer-indexing parts of
   `test_tseries.jl`.

3. **Phase 3 — TSeries arithmetic and broadcasting.**
   `plus`, `minus`, `mtimes`, `times`, `rdivide`, `power`, `uminus`,
   comparison ops, `cumsum`, `diff_ts`, `sum`/`mean`/`std` etc.,
   `overlay`, `shift`/`lag`/`lead`, `pct`, `apct`, `ytypct`, `moving`,
   `undiff`, `strip_ts`, `compare_ts`, `reindex`, `rec`, `typenan`,
   `istypenan`.
   Ports the rest of `test_tseries.jl`.

4. **Phase 4 — MVTSeries core.**
   Construction (all overloads), dot access, single-arg indexing,
   `colnames`, `columns`, `rawdata`, `firstdate`, `lastdate`,
   `rangeof`, `hcat`, `vcat`, `rename_columns`, `disp`.
   Ports the construction and integer-indexing parts of
   `test_mvtseries.jl`.

5. **Phase 5 — MVTSeries arithmetic and indexing.**
   Two-argument indexing (MIT × Symbol), boolean masks, composite dot
   indexing (`x.a(2020Q1) = …`), broadcasting against TSeries / matrix /
   scalar, `plus`/`minus`, reductions (`sum`/`prod`/`mean`/`std` with
   `dims`), `shift`/`lag`/`lead`/`diff`/`cumsum`/`pct`/`apct`/`ytypct`/
   `undiff`/`moving`, `mapslices`, `overlay`(multivariate).
   Completes `test_mvtseries.jl`.

6. **Phase 6 — Linalg & assorted.**
   `mtimes`/`mldivide`/`mrdivide`/`adjoint`/`transpose` for `TSeries`
   and `MVTSeries` (delegate to underlying numeric storage).
   `findall`/`find`, `isassigned`, `parent`, `LinearIndices` analogue.
   Ports `test_various.jl` (linalg and findall sections) and
   `TestMisc`.

7. **Phase 7 — Polish.**
   `Contents.m`, docstring sweep, examples, error-ID audit, profile and
   close obvious perf gaps (cache `frequencyof` checks, avoid
   round-tripping `int64` through `double` in hot paths).

A reasonable engineering pace is **one phase per 1–2 weeks** of focused
effort, with phases 4–5 being the largest.

---

## 13. Open design decisions

These are choices the implementer should confirm with the maintainer
before each affected phase. The default below is what this plan
recommends if no other guidance is given.

1. **Default frequency for `Quarterly()`/`Yearly()`** — match Julia
   (`Quarterly{3}`, `Yearly{12}`).
2. **Column live-views vs. copies in MVTSeries** — copies, with
   composite `subsasgn` to preserve UX (§3.4, §6.4). If a user
   absolutely needs handle-style mutation, document the `setvalue`
   helper.
3. **`begin` keyword** — MATLAB has no such keyword. We document the
   workarounds (use `firstdate(t)`, `1`, or end-relative arithmetic).
4. **String/symbol coercion** — accept char, string, cellstr for column
   names; canonicalise to `string`.
5. **Single vs. double precision default** — `double`, matching Julia.
6. **`fconvert`-style implicit conversions on arithmetic** — never. Mixed
   frequencies always throw, identical to Julia.
7. **Plotting** — not in scope. We will provide a `plot(t)` method on
   `TSeries` and `MVTSeries` that converts the MIT axis to a numeric
   x-axis label (datetime where possible) and calls the built-in
   `plot`. This is the only "out-of-scope" item we will quietly
   include because it is otherwise painful for users.

---

## 14. Risks & open problems

- **`begin`/`end` polyglot indexing.** MATLAB's `end` works fine, but
  there is no `begin`. The Julia idiom `t[begin+1:end-1]` becomes
  `t(firstdate(t)+1 : lastdate(t)-1)`. We need to make sure every
  example and docstring uses the MATLAB form.
- **Performance.** Each MIT operation crosses an object boundary. For
  scalar-heavy code (e.g. `rec` Fibonacci) this is several × slower
  than Julia. We should benchmark phase 3 hot paths and decide whether
  to provide a "fast path" in private helpers that strips MIT down to
  `int64`.
- **MATLAB version drift.** `dictionary` (R2022b) would simplify
  `MVTSeries` column lookup. We keep the implementation on
  `containers.Map`/`struct` for R2019b compatibility; can flip later.
- **`subsref`/`subsasgn` complexity.** This is where the bulk of
  porting effort will go. The composite assignment paths (`x.a(mit) =
  v` with auto-grow) need careful tests, including the asymmetric
  cases where `a` already exists vs. when it doesn't.
- **Display fidelity.** Reproducing the precise alignment of
  `mvts_show.jl` requires reimplementing parts of `Base.alignment` for
  numeric column widths; we ship a simpler `printmat`-style fallback
  if exact reproduction proves disproportionate.

---

## 15. Quick-reference: minimal user example

What we expect to support, end-to-end, by the end of Phase 5:

```matlab
import tse.*

% scalar dates and ranges
q1 = qq(2020,1);
q5 = qq(2021,1);
rng = q1 : q5;

% univariate
y = TSeries(rng, randn(numel(rng),1));
y(qq(2020,3)) = 0.5;        % overwrite a single date
y(qq(2022,1)) = 2.0;        % extends y with NaN padding to 2022Q1

% lag, diff, pct
dy   = diff_ts(y);
gy   = pct(y);
g4y  = ytypct(y);

% multivariate
X = MVTSeries(rng, ["a","b","c"], randn(numel(rng), 3));
X.a(qq(2020,2)) = 99;       % composite assign works
S = sum(X, 'dims', 2);      % returns a TSeries
M = X(qq(2020,1):qq(2020,4), ["a" "c"]);   % sub MVTSeries
```

---

*End of plan.*
