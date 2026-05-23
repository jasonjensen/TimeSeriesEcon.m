# Math (shift, diff, moving, undiff)

Time-axis transforms on `TSeries` (and, where noted, `MVTSeries`). The shift
family and moving windows are **methods** — call them as `op(t, ...)` or
`t.op(...)`; `undiff` is a free function.

## Shifts

| Call | Effect |
|------|--------|
| `shift(t, k)` | shift labels by `k` (positive = lead, negative = lag) |
| `lag(t[, k])` | shift labels back `k` periods (default 1) |
| `lead(t[, k])` | shift labels forward `k` periods (default 1) |

Shifts move the *labels*, not the data; the values are unchanged.

## Differences

| Call | Effect |
|------|--------|
| `diff_ts(t[, k])` | difference at lag `k` (default `k = -1`, first difference) |
| `cumsum(t)` | running sum, same range |
| `undiff(dvar)` | inverse of `diff_ts` from a 0 baseline (first level lost) |
| `undiff(dvar, value)` | anchor value at `firstdate(dvar) - 1` |
| `undiff(dvar, mit, value)` | anchor a known `(date, value)` to recover the level exactly |

```matlab
import tse.*
x  = TSeries(qq(2020, 1), [1;3;6;10]);
dx = diff_ts(x);                              % NaN, 2, 3, 4 on the dropped-first range
x2 = undiff(dx, x.firstdate, x(x.firstdate)); % recovers x
```

## Growth rates

| Call | Effect |
|------|--------|
| `pct(t[, shift])` | percentage change (default vs previous period) |
| `apct(t)` | annualised percentage change |
| `ytypct(t)` | year-on-year percentage change |

## Moving windows

| Call | Effect |
|------|--------|
| `moving_average(t, n)` (alias `moving`) | moving mean over a window of length `\|n\|` |
| `moving_sum(t, n)` | moving sum |

A positive `n` is backward-looking, a negative `n` forward-looking; the window
always includes the current observation. All of the above also operate on
`MVTSeries` column-by-column.

## BDaily NaN / holiday skipping

`shift` / `lag` / `lead` / `diff_ts` / `pct` on `BDaily` series accept
`'skip_all_nans', true` and `'skip_holidays', true` (and an explicit
`'holidays_map', map`) to treat NaNs / holidays as gaps. See
[BDaily holidays](../tutorials/1_timeseriesecon.md#16-bdaily-holidays).

!!! info "Julia ↔ MATLAB"
    Julia's `diff(t)` is `diff_ts(t)` here (the built-in `diff` differs in
    sign). The undiff anchor `firstdate(x) => first(x)` becomes the trailing
    `undiff(dx, mit, value)`. In-place `lag!`/`lead!` → reassign the result.
