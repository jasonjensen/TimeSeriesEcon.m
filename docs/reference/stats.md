# Statistics (mean, std, cor)

Reductions on `TSeries` and `MVTSeries`. The single-series reductions are
methods that forward to the MATLAB built-ins over the underlying values, so they
take the same trailing options.

## TSeries reductions

| Call | Result |
|------|--------|
| `mean(t)`, `sum(t)`, `std(t)`, `var(t)`, `median(t)`, `min(t)`, `max(t)`, `prod(t)` | scalar reduction over the values |
| `any(t)`, `all(t)` | logical reductions |

```matlab
import tse.*
t = TSeries(qq(2020, 1), (1:8)');
mean(t)     % 4.5
std(t)      % sample standard deviation
```

Correlation and covariance between two series use the built-ins on the aligned
values:

```matlab
a = TSeries(qq(2020,1), randn(40,1));
b = TSeries(qq(2020,1), randn(40,1));
corr(a.values, b.values)        % scalar correlation
cov([a.values, b.values])       % 2x2 covariance matrix
```

## MVTSeries reductions

The reductions accept a `'dims'` option:

| Call | Result |
|------|--------|
| `mean(mv)` | scalar over the whole buffer |
| `mean(mv, 'dims', 1)` | per-column → `1 × ncols` numeric |
| `mean(mv, 'dims', 2)` | per-row → length-`nrows` `TSeries` |

`std`, `var`, `median`, `sum`, etc. behave the same way. For a correlation /
covariance matrix across columns, use the built-ins on `mv.values`:

```matlab
mv = MVTSeries(qq(2020,1), {'a','b','c'}, randn(40, 3));
corr(mv.values)     % 3x3 correlation matrix
cov(mv.values)      % 3x3 covariance matrix
```

## BDaily statistics with NaN / holiday skipping

For `BDaily` data, `cleanedvalues(t, ...)` returns the values with holidays
and/or NaNs removed, which you then reduce:

```matlab
mean(cleanedvalues(t, 'skip_all_nans', true))
mean(cleanedvalues(t, 'skip_holidays', true))   % requires a loaded holidays map
```

See [BDaily holidays](../tutorials/1_timeseriesecon.md#16-bdaily-holidays).

!!! info "Julia ↔ MATLAB"
    Julia's `Statistics.mean(mvts; dims=1)` (per-column) →
    `mean(mv, 'dims', 1)`; `dims=2` (per-row) → `mean(mv, 'dims', 2)`.
    Correlation/covariance use MATLAB's `corr`/`cov` on `.values` rather than a
    dedicated `cor`/`cov` overload.
