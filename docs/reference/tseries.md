# TSeries

A `TSeries` is a univariate time series: a column of values plus an
`MIT`-labelled time axis. The stored range runs from `firstdate` to
`firstdate + numel(values) - 1`.

## Construction

| Call | Result |
|------|--------|
| `TSeries(mit, vec)` | start date + column of values |
| `TSeries(range, vec)` | range + matching values |
| `TSeries(range)` | NaN-filled over the range |
| `TSeries(range, scalar)` | filled with a scalar |
| `TSeries(range, @fn)` | `fn(n,1)` initialiser (e.g. `@zeros`, `@ones`, `@rand`) |
| `TSeries(mit)` | empty series starting at `mit` |
| `TSeries(n)` | Unit-frequency series of length `n` |
| `TSeries(type, ...)` | as above with a forced element type (`'double'`, `'int32'`, …) |

## Indexing

| Read | Result |
|------|--------|
| `t(mit)` | scalar at that date (bounds-checked) |
| `t(range)` | a new `TSeries` over the slice |
| `t(i)` / `t(i:j)` | underlying value(s) by integer index (labels dropped) |
| `t(:)` | the series itself |
| `t(boolvec)` / `t(logicalTSeries)` | masked values |

| Write | Effect |
|-------|--------|
| `t(mit) = v` | set one position; **grows the series** if `mit` is out of range |
| `t(range) = v` | set many (scalar broadcast or size-matched vector) |
| `t(i) = v` | integer index, in-range only |
| `t(:) = v` | fill all |

## Properties and inspection

`firstdate`, `lastdate(t)`, `rangeof(t[, 'drop', k])`, `frequencyof(t)`,
`length(t)`, `numel(t)`, `t.values` (raw column).

## Arithmetic, transforms, reductions (methods)

These are methods, callable as `t.op(...)` or `op(t, ...)`:

| Group | Methods |
|-------|---------|
| Arithmetic | `+ - .* ./ .^`, scalar `* /`, `uminus` — align on range intersection |
| Shifts | `shift(t,k)`, `lag(t[,k])`, `lead(t[,k])` |
| Differences | `diff_ts(t[,k])`, `cumsum(t)`, `undiff` (free function) |
| Growth | `pct(t[,shift])`, `apct(t)`, `ytypct(t)` |
| Moving | `moving_average(t,n)`, `moving_sum(t,n)`, `moving(t,n)` |
| Reductions | `sum`, `mean`, `std`, `var`, `median`, `min`, `max`, `prod`, `any`, `all` |
| Plot | `plot(t, ...)` — see [Plotting](plotting.md) |

```matlab
import tse.*
t = TSeries(qq(2020, 1), (1:8)');
disp(t)
g  = pct(t);                 % quarter-on-quarter % change
m4 = moving_average(t, 4);   % 4-quarter moving average
t(qq(2022, 1)) = 99;         % extends the series with NaN padding
```

!!! info "Julia ↔ MATLAB"
    Resize-on-assign and range-intersection arithmetic match Julia. Julia's
    `begin`/`end` inside `[]` become `firstdate(t)`/`lastdate(t)`. `diff` is
    spelled `diff_ts` (the built-in `diff` has a different sign convention).
