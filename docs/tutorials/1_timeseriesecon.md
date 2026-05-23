# Tutorial 1 — TimeSeriesEcon

A narrative port of the upstream Julia tutorial
[TutorialsEcon.jl / 1.TimeSeriesEcon](https://bankofcanada.github.io/DocsEcon.jl/dev/Tutorials/1.TimeSeriesEcon/main/),
showing MATLAB idioms in the code blocks and dropping a *Julia ↔ MATLAB* note
per section so anyone migrating from the Julia (or Python) codebase can find the
original passage.

Every example assumes you have added the package to your path and imported it:

```matlab
addpath('/path/to/TimeSeriesEcon.m');   % the folder that contains +tse
import tse.*
```

With `import tse.*` in scope you can write `qq(2020, 1)` instead of
`tse.qq(2020, 1)`. Output blocks below are illustrative.

| #  | Section | |
|----|---------|--|
| 1  | [Frequency and Time](#1-frequency-and-time) | 🟢 |
| 2  | [Ranges (`MITRange`)](#2-ranges) | 🟢 |
| 3  | [TSeries — Creation](#3-tseries-creation) | 🟢 |
| 4  | [TSeries — Access](#4-tseries-access) | 🟢 |
| 5  | [Arithmetic with TSeries](#5-arithmetic-with-tseries) | 🟢 |
| 6  | [Shifts](#6-shifts) | 🟢 |
| 7  | [Diff and undiff](#7-diff-and-undiff) | 🟢 |
| 8  | [Moving average](#8-moving-average) | 🟢 |
| 9  | [Recursive assignments](#9-recursive-assignments) | 🟢 |
| 10 | [Multivariate Time Series](#10-multivariate-time-series-mvtseries) | 🟢 |
| 11 | [Plotting](#11-plotting) | 🟢 |
| 12 | [Workspaces (structs)](#12-workspaces) | 🟢 |
| 13 | [MVTSeries vs Workspace](#13-mvtseries-vs-workspace) | 🟢 |
| 14 | [`overlay`](#14-overlay) | 🟢 |
| 15 | [`compare`](#15-compare) | 🟢 |
| 15a | [`reindex`](#15a-reindex) | 🟢 |
| 16 | [BDaily holidays](#16-bdaily-holidays) | 🟢 |
| 17 | [Options](#17-options) | 🟢 |

## 1. Frequency and Time { #1-frequency-and-time }

In a time series the values are evenly spaced in time and each value is labelled
with the moment in which it occurred. The package provides the same concepts the
Julia upstream does: a **`Frequency`** describes the *spacing*, an **`MIT`**
(moment-in-time) labels one *point*, and a **`Duration`** measures the distance
between two `MIT`s of the same frequency.

### Frequencies

The abstract class `Frequency` represents a sampling cadence; every concrete
frequency is a special case. Four are *year-period* (calendar) frequencies —
`Yearly`, `HalfYearly`, `Quarterly`, `Monthly` — defined by a number of periods
per year. Three are *calendar-date* frequencies tied to the Gregorian calendar:
`Weekly`, `BDaily` (business-daily, Mon–Fri), and `Daily`. The last, `Unit`, is
not calendar-based and simply counts observations.

Usually you do not construct `Frequency` objects directly — you get them from the
constructor functions like `qq()` below. `Yearly`, `HalfYearly`, and `Quarterly`
have default end-months (12, 6, 3); `Weekly` has a default end-day of 7 (Sunday):

```matlab
Yearly()              % default end month = 12 (December)
Yearly(3)             % fiscal year ending in March
Quarterly()           % default end month = 3
Quarterly(2)          % a broadcaster's calendar
Weekly()              % Weekly(7), weeks ending Sunday
```

### Moments and durations

`MIT` values label particular moments; `Duration` values measure the distance
between two `MIT`s of the same frequency.

```matlab
class(qq(2020, 1))            % 'tse.MIT'
class(mm(2021, 5) - mm(2020, 3))   % 'tse.Duration'
```

#### Creating MIT instances

The MATLAB equivalents of Julia's `2020Q1` / `2020M3` / `2020Y` literal
suffixes are the constructor functions `qq` / `mm` / `yy`, taking
`(year, period)` (or just `(year)` for `yy`):

```matlab
qq(2022, 1)     % 2022Q1
qq(2020, 3)     % 2020Q3
yy(2020)        % 2020Y
mm(2022, 5)     % 2022M5
```

There is no dedicated `hh()` shorthand for half-yearly; build it through the
general `MIT(frequency, year, period)` constructor. The same pattern handles
variant end-months:

```matlab
MIT(HalfYearly(), 2022, 1)        % 2022H1
MIT(HalfYearly(), 2022, 2)        % 2022H2
MIT(Quarterly(2), 2022, 1)        % Quarterly ending February
MIT(Yearly(11), 2020, 1)          % Yearly ending November
```

For the calendar-date frequencies (`Daily`, `BDaily`, `Weekly`), pass a
`datetime` or an ISO date string:

```matlab
week('2022-01-03')      % 2022-01-03
bday('2022-01-03')      % 2022-01-03
day('2022-01-03')       % 2022-01-03
```

`bday(...)` from a date that lands on a weekend raises by default (matching
Julia's `:strict` bias). Pass `'bias'` to opt in to a rounding rule:

```matlab
bday('2022-01-01', 'bias', 'previous')   % 2021-12-31
bday('2022-01-01', 'bias', 'next')       % 2022-01-03
bday('2022-01-01', 'bias', 'nearest')    % 2021-12-31
```

### Arithmetic with time

`MIT - MIT` yields a `Duration` of the shared frequency. You may add or subtract
a `Duration` (or a plain integer, treated as a `Duration` in the `MIT`'s own
frequency) to get another `MIT`, and add or subtract `Duration`s freely. Adding
two `MIT`s is an error — it has no economic meaning.

```matlab
d = qq(2001, 2) - qq(2000, 1);   % a Quarterly Duration
int64(d)                          % 5

qq(2000, 1) + 6                   % 2001Q3  (integer treated as 6 quarters)
```

Mixing frequencies raises, and multiplying an `MIT` by an integer is not allowed:

```matlab
qq(2000, 1) + (mm(2020,1) - mm(2019,1))   % error: tseries:mixedFreq
qq(2000, 1) * 5                            % error: tseries:invalidArith
```

### Other operations

`frequencyof(...)` returns the frequency of its argument; `ppy(...)` gives the
periods per year; `year(...)` / `period(...)` / `mit2yp(...)` extract calendar
coordinates.

```matlab
frequencyof(yy(2000))                 % a Yearly frequency object
m = qq(2020, 3);
ppy(m)                                % 4   (MATLAB's ppy accepts an MIT *or* a Frequency)
year(m)                               % 2020
period(m)                             % 3
mit2yp(m)                             % [2020 3]
```

As in Julia, `ppy` returns the hardcoded sentinel (52 / 365 / 260) for `Weekly`
/ `Daily` / `BDaily`, and `year` / `period` / `mit2yp` are not defined for
`Weekly` (a week can straddle a year boundary).

!!! info "Julia ↔ MATLAB"
    Corresponds to *Frequency and Time* upstream. The most visible difference is
    the absence of `2020Q1` literal sugar — MATLAB has no user-defined numeric
    literals, so we use constructor functions (`qq(2020, 1)`). Unlike Julia,
    `Quarterly{3}` parametric types become an `endPeriod` argument:
    `Quarterly(3)`. `MIT == int` compares the underlying offset only.

## 2. Ranges { #2-ranges }

`MITRange(start, stop)` is the equivalent of Julia's `2000M1:2001M9` unit-step
range; both bounds are inclusive. The colon operator is also overloaded on
`MIT`, so `mm(2000,1):mm(2001,9)` produces the same range. Standard collection
operations work: `length`, `numel`, indexing `rng(k)`, `first`, `last`,
iteration via `for m = collect(rng)`, `intersect`, `union`.

```matlab
rng = MITRange(mm(2000, 1), mm(2001, 9));   % or  mm(2000,1):mm(2001,9)
length(rng)        % 21
first(rng)         % 2000M1
last(rng)          % 2001M9
rng(3)             % 2000M3
```

Julia's broadcast `rng .+ 6` (shift the whole range) is written directly on the
endpoints, or with `+` on the range:

```matlab
rng + 6                                  % shift by 6 periods
MITRange(rng.startMIT + 6, rng.stopMIT + 6)   % same thing, explicit
```

For step ranges, the step is the **middle** argument (a nonzero integer in the
range's own frequency):

```matlab
rng2 = MITRange(mm(2000, 1), 2, mm(2000, 8));   % step 2
collect(rng2)                                    % 2000M1, 2000M3, 2000M5, 2000M7
```

A **negative step** walks the range backward, mirroring Julia's `10U:-1:1U`.
This is the natural way to write a backcasting recurrence (see
[§9](#9-recursive-assignments)):

```matlab
back_rng = MITRange(qq(2021, 4), -1, qq(2020, 1));
collect(back_rng)         % 2021Q4, 2021Q3, ...
```

Calendar-date ranges work the same way; `day`/`bday` accept two date strings as
a range shortcut:

```matlab
day('2022-01-01', '2022-01-31')     % a Daily MITRange
bday('2022-01-01', '2022-01-31')    % a BDaily MITRange (weekend ends rounded in)
```

!!! info "Julia ↔ MATLAB"
    Corresponds to *Ranges* upstream. Julia's `bd"2022-01-01:2022-01-31"`
    string-macro becomes `bday('2022-01-01', '2022-01-31')`. The step lives in
    the middle: `MITRange(a, step, b)` (Julia writes `a:step:b`).

## 3. TSeries — Creation { #3-tseries-creation }

`TSeries` is the workhorse 1-D time-series type: a column of values plus an
`MIT`-labelled time axis. The basic constructor takes a starting `MIT` and a
column vector of values:

```matlab
t = TSeries(qq(2020, 1), [0.1; 0.2; 0.3; 0.4; 0.5]);
disp(t)
```

You can also construct from a range. Without a value argument the storage is
NaN-filled; pass a scalar, a vector, or an initialiser function:

```matlab
rng = MITRange(qq(2020, 1), qq(2021, 4));
TSeries(rng)            % NaN-filled
TSeries(rng, pi)        % scalar fill
TSeries(rng, @zeros)    % callable form, fn(n,1) -> column
TSeries(rng, @ones)
TSeries(rng, @rand)
```

A typed series forces an element type: `TSeries('double', rng)`,
`TSeries('int32', n)`, etc. `copy(t)` makes an independent duplicate (MATLAB
value semantics mean a plain assignment `s = t` already behaves like a copy on
write).

!!! info "Julia ↔ MATLAB"
    Corresponds to *Creation of TSeries*. The Julia function-as-initialiser
    idiom `TSeries(rng, zeros)` ports as `TSeries(rng, @zeros)` (a function
    handle taking `(n,1)`). Because MATLAB classes use value semantics, the
    Julia aliasing caveat does not apply — assignment copies on write, and
    there is no `copy=true` flag.

## 4. TSeries — Access { #4-tseries-access }

### Reading

Indexing by `MIT` returns a scalar; by `MITRange` returns a new `TSeries`; by
integer or integer range falls through to the underlying values (a plain numeric
vector, no date labels):

```matlab
rng = MITRange(qq(2000, 1), qq(2001, 1));
t = TSeries(rng, (1:numel(rng))');
t(qq(2000, 1))                          % scalar at that date
t(MITRange(qq(2000, 2), qq(2000, 4)))   % sub-TSeries
t(1)                                     % first value (integer index)
t(2:4)                                   % numeric vector (labels dropped)
```

Out-of-range MIT or integer reads raise `tseries:bounds`. MATLAB has no `begin`
/ `end` keyword *inside* package indexing, so the "last *n* by date" idiom uses
`lastdate` / `firstdate`:

```matlab
t(MITRange(lastdate(t) - 2, lastdate(t)))         % last 3
t(MITRange(firstdate(t) + 1, lastdate(t) - 1))    % drop first and last
```

### Writing

```matlab
t(qq(2000, 2)) = 5;                                  % single position
t(MITRange(firstdate(t), firstdate(t) + 2)) = [1 2 3];   % vector
t(MITRange(lastdate(t) - 2, lastdate(t))) = 42;      % scalar broadcast
t(:) = pi;                                            % reset all
```

Unlike a plain array, a `TSeries` **resizes on assignment outside its stored
range**. Any gap that is neither in the old range nor the assignment range is
NaN-filled:

```matlab
t(MITRange(qq(1999, 1), qq(1999, 2))) = -3.7;   % grows t backward
```

Resize works only for `MIT`-keyed assignment. An out-of-bounds **integer** index
still raises.

!!! info "Julia ↔ MATLAB"
    Corresponds to *Access to Elements of TSeries*. Julia's `begin`/`end` inside
    `[]` become `firstdate(t)` / `lastdate(t)`. Julia's `t .= 42` vs `t = 42`
    distinction collapses to `t(:) = 42` (broadcast) vs `t = 42` (rebinds the
    variable). Resize-on-MIT-assign carries over unchanged.

## 5. Arithmetic with TSeries { #5-arithmetic-with-tseries }

When two `TSeries` are added or subtracted, the result spans the **intersection**
of their ranges (anything outside is treated as missing). Operating with a
scalar preserves the range. Frequency mismatches raise.

```matlab
x = TSeries(MITRange(qq(2020, 1), qq(2020, 4)), [1;2;3;4]);
y = TSeries(MITRange(qq(2020, 3), qq(2021, 2)), [10;20;30;40]);
x + y       % spans 2020Q3:2020Q4 (the overlap)
x - y
2 * y       % whole range preserved
y / 2
```

Element-wise math uses the standard MATLAB operators and functions; the result
preserves the range:

```matlab
log(x)
1 + x
y .^ 3
```

Mixing a `TSeries` with a same-length numeric vector works in either order and
preserves the `TSeries`'s range:

```matlab
x + 3 * ones(numel(x), 1)
```

!!! info "Julia ↔ MATLAB"
    Corresponds to *Arithmetic with TSeries*. Julia separates whole-object from
    element-wise arithmetic via the `.` prefix; MATLAB's element-wise operators
    (`.*`, `./`, `.^`) and broadcasting (implicit expansion) cover both. Range
    intersection on `+`/`-` and scalar broadcasting are identical to Julia.

## 6. Shifts { #6-shifts }

`lag(x)` and `lead(x)` shift the **labels** of the data, not the data.
`shift(x, k)` is the primitive: positive `k` is a lead, negative `k` is a lag
(matching Julia). All three are methods, so call them as `x.lag()` or `lag(x)`.

```matlab
lag(x)         % labels shifted back one period
lead(x)        % labels shifted forward
lag(x, 3)
shift(x, -1)   % same as lag(x)
```

!!! info "Julia ↔ MATLAB"
    Corresponds to *Shifts*. Julia's in-place `lag!` / `lead!` have no separate
    MATLAB spelling — reassign the result (`x = lag(x)`). The sign convention on
    `shift` is unchanged.

## 7. Diff and undiff { #7-diff-and-undiff }

`diff_ts(x)` defaults to `k = -1` (first difference at lag 1). The result drops
the first `|k|` observations. (`diff` is not overloaded because Julia's sign
convention differs from MATLAB's built-in `diff`; use `diff_ts`.)

```matlab
dx = diff_ts(x);
```

`undiff(dx)` is the inverse — a cumulative sum lifted onto the range. In its
plain form the first level is lost (because `diff` could not observe it). To
recover the original exactly, anchor it to a known `(date, value)`:

```matlab
undiff(dx)                                 % cumsum from a 0 baseline
undiff(dx, x.firstdate, x(x.firstdate))    % recover x exactly
```

!!! info "Julia ↔ MATLAB"
    Corresponds to *Diff and Undiff*. Julia's anchor syntax
    `firstdate(x) => first(x)` becomes the two trailing arguments
    `undiff(dx, anchorDate, anchorValue)`. The `k = -1` default matches Julia.

## 8. Moving average { #8-moving-average }

`moving_average(t, n)` (alias `moving`) averages over a window of length `|n|`.
A positive `n` is backward-looking, a negative `n` is forward-looking; the window
always includes the current value. `moving_sum(t, n)` is the un-normalised
variant.

```matlab
tt = TSeries(qq(2020, 1), (1:10)');
moving_average(tt, -4)   % forward-looking 4-window
moving_average(tt, 6)    % backward-looking 6-window
moving_sum(tt, 4)
```

!!! info "Julia ↔ MATLAB"
    Corresponds to *Moving Average*. Window-sign convention matches Julia.
    `moving` is `moving_average`; `moving_sum` is the explicit sum form. Both
    work on `MVTSeries` column-by-column.

## 9. Recursive assignments { #9-recursive-assignments }

Time-series recurrences look like

```
a[t] = (1 - rho) * a_ss + rho * a[t-1].
```

Julia's `@rec` macro rewrites the body so each step sees the previously-written
value. MATLAB has no macros, so the equivalent is a higher-order function:
`rec(rng, target, fn)` calls `target(t) = fn(target, t)` once per step, in
order, committing each write before the next step runs. Because `TSeries` is a
value type, **reassign the result**:

```matlab
a_ss = 1.0;
rho  = 0.6;
a = TSeries(MITRange(qq(2020, 1), qq(2022, 1)), a_ss);
a(a.firstdate) = a(a.firstdate) + 0.1;   % impulse

a = rec(rangeof(a, 'drop', 1), a, ...
        @(s, t) (1 - rho) * a_ss + rho * s(t - 1));
disp(a)
```

This mirrors Julia's
`@rec rangeof(a, drop=1) a[t] = (1-ρ)*a_ss + ρ*a[t-1]`. The `rangeof(x, 'drop',
k)` helper skips the first `k` periods (or last `k` if `k < 0`) — the canonical
recurrence-range idiom, because the body reads `s(t-1)` and the first such read
needs `t-1` in range.

```matlab
rangeof(a)               % full range
rangeof(a, 'drop', 1)    % skip first
rangeof(a, 'drop', -1)   % skip last
```

`rec` also accepts a fast `@(v, i)` body that receives the raw values vector and
an integer index — useful for tight AR-style loops that don't need MIT
arithmetic.

### Backcasting (reversed range)

A backcast runs the recurrence backward in time. In Julia this is
`@rec t=10U:-1:1U s[t] = s[t+1] - g`. Feed `rec` a reversed `MITRange`
(negative step); no new entry point is needed because `rec` iterates the range
in its given direction:

```matlab
g = 0.05;
back = TSeries(MITRange(qq(2020, 1), qq(2022, 4)), 0.0);
back(back.lastdate) = a_ss;
back = rec(MITRange(back.lastdate - 1, -1, back.firstdate), back, ...
           @(s, t) s(t + 1) - g);
disp(back)
```

!!! info "Julia ↔ MATLAB"
    Corresponds to *Recursive assignments*. Julia's parse-time `@rec` macro
    becomes the higher-order `rec(rng, target, fn)`; the semantics match (each
    step commits before the next). MATLAB value semantics require `target =
    rec(...)`. There is no `rec_linear` (the Python Cython narrowing); for pure
    AR(p) you can still use the general `rec`, and for `a[t] = a[t-1] + c` reach
    for `undiff`.

## 10. Multivariate Time Series (`MVTSeries`) { #10-multivariate-time-series-mvtseries }

`MVTSeries` is a 2-D `TSeries`: every column shares a frequency, a range, and an
element type. Rows are labelled by `MIT`, columns by name.

### Construction

```matlab
mv = MVTSeries(qq(2020, 1), {'a', 'b'}, rand(6, 2));   % start, names, matrix
disp(mv)

MVTSeries(MITRange(qq(2020, 1), qq(2021, 3)), {'one','too','tree'}, @zeros)
```

### Access

```matlab
mv(qq(2020, 2), 'a')                       % scalar at (date, column)
mv(qq(2020, 2))                            % whole row (numeric)
mv('a')                                    % one column as a TSeries
mv.a                                       % same, attribute-style
mv({'a', 'b'})                             % sub-MVTSeries with those columns
mv(MITRange(qq(2020, 1), qq(2020, 4)))     % sub-MVTSeries (all columns, rows sliced)
```

### Iterating columns

`columns(mv)` returns a struct mapping each name to a `TSeries`:

```matlab
cols = columns(mv);
for name = string(fieldnames(cols))'
    fprintf('Average of %s is %.4f\n', name, mean(cols.(name)));
end
```

Per-column or per-row summaries use the `'dims'` option on the reductions:

```matlab
mean(mv, 'dims', 1)    % per-column → 1xN numeric (one value per column)
mean(mv, 'dims', 2)    % per-row → length-N TSeries
```

!!! info "Julia ↔ MATLAB"
    Corresponds to *Multivariate Time Series*. Julia's `Symbol` column names
    become MATLAB strings/char. `columns(data)` returns a struct here (vs a
    Julia generator). Julia's `mean(mvts; dims=1)` maps to
    `mean(mv, 'dims', 1)` (per-column) and `dims=2` to per-row, same as Julia.

## 11. Plotting { #11-plotting }

`TSeries` and `MVTSeries` define a `plot` method. For a `TSeries` the x-axis is
numeric for year-period frequencies (with MIT tick labels) and a `datetime`
ruler for calendar frequencies; pass standard `plot` line options through.

```matlab
t = TSeries(qq(2020, 1), cumsum(randn(12, 1)));
plot(t, 'LineWidth', 2);

plot(t, 'mit_loc', 'middle');                          % point position in period
plot(t, 'trange', MITRange(qq(2020, 2), qq(2021, 4))); % restrict the window
```

For an `MVTSeries`, `plot` draws one line per column with a legend; `'vars'`
selects columns:

```matlab
mv = MVTSeries(qq(2020, 1), {'x','y','z'}, cumsum(randn(16, 3)));
plot(mv);
plot(mv, 'vars', {'x', 'z'});
```

!!! info "Julia ↔ MATLAB"
    Corresponds to *Plotting*. The Julia upstream uses a Plots.jl recipe; here
    plotting is an overloaded `plot` method built on MATLAB graphics, with the
    same `mit_loc` / `trange` / `vars` knobs. See
    [the plotting reference](../reference/plotting.md).

## 12. Workspaces { #12-workspaces }

Julia and Python have a dedicated `Workspace` type — an ordered,
attribute-accessible bag of heterogeneous things (ranges, scalars, series of any
frequency, nested workspaces). **In MATLAB the idiomatic equivalent is the
native `struct`**, so there is no separate `Workspace` class:

```matlab
w = struct();
w.rng = rangeof(a);          % the AR(1) impulse response from §9
w.start = w.rng.startMIT;
w.a = a;                     % value semantics: w.a is an independent copy
w.alpha = 0.1;
disp(w)

w = rmfield(w, 'start');     % drop a member (Julia: delete!(w, :start))
```

The package's workspace-style helpers — [`overlay`](#14-overlay) and
[`compare_ts`](#15-compare) — operate on structs field-by-field, so the common
Workspace operations carry over.

!!! info "Julia ↔ MATLAB"
    Corresponds to *Workspaces*. Julia's `Workspace` / Python's `Workspace`
    become a plain MATLAB `struct`: `w.x = ...` to set, `w.x` to read,
    `rmfield(w, 'x')` to delete, `fieldnames(w)` to enumerate. `overlay` and
    `compare_ts` accept structs directly.

## 13. MVTSeries vs Workspace { #13-mvtseries-vs-workspace }

The two overlap deliberately:

* **`MVTSeries` is a matrix.** All columns share a frequency, a range, and an
  element type, stored in one contiguous 2-D buffer — which makes statistics and
  linear algebra cheap. Adding or removing a column reallocates.
* **A `struct` (workspace) is a dictionary.** It holds heterogeneous values,
  series of *different* frequencies, nested structs, scalars — anything — and
  grows or shrinks freely. Linear algebra on the struct is not defined.

Rule of thumb: if every value is a same-frequency series you'll reduce
column-wise, reach for `MVTSeries`; otherwise use a `struct`. Convert by pulling
`columns(mv)` (MVTSeries → struct) or building an `MVTSeries` from the struct's
series fields.

!!! info "Julia ↔ MATLAB"
    Corresponds to *MVTSeries vs Workspace*. Same trade-off; the only difference
    is that the "workspace" is a native `struct` rather than a dedicated type.

## 14. `overlay` { #14-overlay }

`overlay` composes series so each observation is the **first non-missing** value
found left-to-right ("missing" = the type-appropriate NaN sentinel, see
`tse.istypenan`). With `TSeries` inputs the result spans the union of ranges:

```matlab
x1 = TSeries(MITRange(qq(2020, 1), qq(2020, 4)), 1.0);
x1(MITRange(qq(2020, 2), qq(2020, 3))) = NaN;
x2 = TSeries(MITRange(qq(2019, 3), qq(2020, 2)), 2.0);
x3 = TSeries(MITRange(qq(2020, 2), qq(2021, 1)), 3.0);
overlay(x1, x2, x3)
overlay(MITRange(qq(2020,1), qq(2020,4)), x1, x2, x3)   % forced output range
```

When the inputs are `MVTSeries` or `struct`s, `overlay` recurses field-by-field:
members present in several inputs are themselves overlaid, members in only one
are taken from there.

```matlab
w1 = struct('x', x1, 'a', 1);
w3 = struct('x', x3, 'a', 3, 'c', 3);
overlay(w1, w3)
```

!!! info "Julia ↔ MATLAB"
    Corresponds to *`overlay`*. Same dispatch and first-valid-wins rule. A forced
    output range is the optional leading `MITRange` argument (Julia's positional
    first argument). The Julia `LikeWorkspace` union maps to MATLAB structs and
    `MVTSeries`.

## 15. `compare` { #15-compare }

`compare_ts(a, b, ...)` compares two series (or scalars/arrays, or structs
field-by-field) under `isapprox`-style tolerance and returns a logical.

```matlab
y1 = TSeries(qq(2020, 1), ones(10, 1));
y2 = y1;
y2(qq(2020, 3)) = y2(qq(2020, 3)) + 1e-7;

compare_ts(y1, y2)                 % false (exact)
compare_ts(y1, y2, 'atol', 1e-5)   % true (within tolerance)
```

`'nans', true` treats NaN-vs-NaN as equal (Julia's `isapprox(...; nans=true)`);
`'ignoreMissing', true` compares only the overlapping range; `'trange'`
restricts the comparison window; `'quiet', false` prints a diff.

```matlab
n1 = TSeries(qq(2020, 1), [1.0; NaN]);
n2 = n1;
compare_ts(n1, n2)                 % false
compare_ts(n1, n2, 'nans', true)   % true
```

!!! info "Julia ↔ MATLAB"
    Corresponds to *`compare` and `@compare`*. Julia's `@compare` macro folds
    into the plain function. The kwarg surface (`atol`, `rtol`, `nans`,
    `ignoreMissing`, `trange`, `quiet`) matches name-for-name (camelCase
    `ignoreMissing`). The MATLAB form returns a logical rather than a structured
    result object.

## 15a. `reindex` { #15a-reindex }

`reindex(x, from, to)` shifts every MIT-keyed position in `x` so that `from`
becomes `to`; values are preserved. It dispatches over `MIT`, `MITRange`, and
`TSeries`. The frequencies of `from` and `to` need not match — this is how you
re-label a quarterly model output onto a `Unit` axis, for example.

```matlab
mu = qq(2020, 1);
nu = MIT(Unit(), 1);
reindex(qq(2022, 4), mu, nu)                       % 12U
reindex(MITRange(qq(2021, 1), qq(2022, 4)), mu, nu)
ts = TSeries(qq(2021, 1), [1.0; 2.0; 3.0]);
reindex(ts, mu, nu)                                % firstdate becomes 5U
```

!!! info "Julia ↔ MATLAB"
    Corresponds to *`reindex`*. Julia's `reindex(t, from => to)` `Pair` becomes
    the two positional arguments `reindex(t, from, to)`. The `'copy'` keyword is
    accepted for parity (MATLAB value semantics make it a no-op in most cases).

## 16. BDaily holidays { #16-bdaily-holidays }

A holidays map is a `TSeries{BDaily}` of logicals — `true` for working business
days, `false` for holidays. Install one into the process with
`set_holidays_map(...)`; functions called with `'skip_holidays', true` (e.g.
`fconvert`, `cleanedvalues`) then consult it.

### Loading a calendar by country / subdivision

`set_holidays_map('CA', 'ON')` loads a bundled calendar (derived, like the Julia
upstream, from the `python-holidays` project). The map spans
`bday('1970-01-01')` to `bday('2049-12-31')`.

```matlab
opts = get_holidays_options();        % supported country codes
caSubs = get_holidays_options('CA');  % subdivisions for Canada

set_holidays_map('CA', 'ON');         % Ontario, Canada
m = getoption('bdaily_holidays_map');
isHoliday = ~logical(m(bday('2024-02-19')));   % Family Day is a holiday in ON
clear_holidays_map();
```

### `skip_holidays` in aggregation

When converting a BDaily series to a lower frequency, `'skip_holidays', true`
excludes holiday observations from the aggregation:

```matlab
set_holidays_map('CA', 'ON');
t = TSeries(bday('2021-01-01'), (1:60)');
fconvert(Monthly(), t, 'method', 'mean', 'skip_holidays', true);
clear_holidays_map();
```

`cleanedvalues(t, 'skip_holidays', true)` returns the holiday-filtered values
directly.

!!! info "Julia ↔ MATLAB"
    Corresponds to *BDaily Holidays*. The `skip_all_nans` / `skip_holidays` /
    `holidays_map` knobs port directly. The bundled calendar data
    (`+tse/private/holidays.bin`) is copied from the Julia upstream. Country /
    subdivision codes match the upstream `python-holidays` conventions; use
    `get_holidays_options(country)` to discover them.

## 17. Options { #17-options }

A small process-global store holds the package's settings, read and written with
`getoption` / `setoption`:

```matlab
getoption('bdaily_creation_bias')        % default 'strict'
setoption('bdaily_creation_bias', 'next');
```

The functionally active option is `bdaily_holidays_map`, which
`set_holidays_map` populates and `fconvert` / `cleanedvalues` consult (see
[§16](#16-bdaily-holidays)):

```matlab
set_holidays_map('CA', 'ON');
m = getoption('bdaily_holidays_map');    % a TSeries{BDaily} of logicals
clear_holidays_map();
getoption('bdaily_holidays_map')         % []  (cleared)
```

!!! info "Julia ↔ MATLAB"
    Corresponds to *Options*. Julia's `setoption(:foo, value)` symbol argument
    becomes a plain string: `setoption('foo', value)`. The `bdaily_creation_bias`
    option is stored for parity; the `bday` constructor takes an explicit
    `'bias'` argument per call.

---

## What's next

If you came from `TimeSeriesEcon.jl`, the
[migration guide](../design/migration_from_julia.md) collects the recurring
idiom differences in one place; if you came from
[TimeSeriesEconPy](https://nic2020.github.io/TimeSeriesEconPy/), see
[migration from Python](../design/migration_from_python.md). If you're starting
fresh, the [reference pages](../reference/frequencies.md) cover the public API.
