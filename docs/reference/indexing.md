# Indexing (lookup)

Beyond the scalar / range indexing covered in [TSeries](tseries.md), the package
provides `lookup` for a vectorised gather of many positions at once.

## Date ranges

`TSeries` and `MVTSeries` select exactly the dates an `MITRange` enumerates,
including strided and reversed ranges. A forward unit-step range returns a
labelled series; any other step returns a plain numeric array in the range's
order. Column selections (`x(rng, 'a')`, `x(rng, {'b', 'a'})`) follow the same
rule.

```matlab
import tse.*
s = TSeries(qq(2020, 1), [10; 20; 30; 40]);
backward = MITRange(qq(2020, 4), -1, qq(2020, 1));
s(backward)                 % [40; 30; 20; 10]
s(backward) = [4 3 2 1];    % s now holds [1; 2; 3; 4]
```

- An empty range selects nothing and an assignment through it does not grow
  the series, but the frequency is still checked.
- Bounds are checked on the dates the range lands on, so
  `s(MITRange(qq(2020, 3), -2, qq(2019, 4)))` returns `[30; 10]` even though
  the range's stop lies before the first stored date.
- A `TSeries` grows to cover the dates a range assignment lands on; an
  `MVTSeries` range assignment needs the rows to exist already.
- A `TSeries` or `MVTSeries` on the right-hand side is read at the range's
  dates (and must hold all of them); plain arrays are taken in the range's
  order.
- Two ranges are equal (`==`, `isequal`) when they select the same dates: all
  empty ranges of a frequency are equal, and a stop the step never lands on
  does not matter.

These rules match TimeSeriesEcon.jl and TimeSeriesEconPy.

## lookup

```matlab
out = tse.lookup(t, keys)
```

Returns `t.values(...)` for each key, in one vectorised operation. `keys` may be:

- an array of `MIT`s (`1×N` or `N×1`), or
- an `MITRange`.

All keys must share the series' frequency and be in range; the result is a column
vector of the same numeric type as `t.values`.

```matlab
import tse.*
t    = TSeries(qq(2020, 1), (1:20)');
keys = collect(MITRange(qq(2020, 1), qq(2021, 4)));
vals = lookup(t, keys);     % 8x1 column, gathered in one call
```

### Why `lookup` exists

A scalar loop of `t(mit)` calls is the natural spelling, but each call goes
through MATLAB's overloaded `subsref` dispatch, which has meaningful per-call
overhead. `lookup` collapses N such dispatches into one indexing operation —
prefer it for hot inner loops over many dates. (For a single date, plain
`t(mit)` is fine.)

!!! info "Julia ↔ MATLAB"
    There is no direct Julia counterpart — in Julia, `t[keys]` with a vector of
    MITs is already fast. `lookup` is a MATLAB-specific fast path; `t(keys)`
    with an MIT array also works and returns the same values.
