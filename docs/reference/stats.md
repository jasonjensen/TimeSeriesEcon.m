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

`quantile(t, p)` gives quantiles, and `stdm(t, m)` / `varm(t, m)` give the
sample standard deviation and variance about a mean `m` you supply (Julia's
`Statistics.stdm` / `varm`).

`cov(a, b)` and `cor(a, b)` give the scalar covariance and correlation of two
series. As in Julia, both series must have the same frequency and start date;
pass their values to compare misaligned data.

```matlab
a = TSeries(qq(2020,1), randn(40,1));
b = TSeries(qq(2020,1), randn(40,1));
cor(a, b)       % scalar correlation
cov(a, b)       % scalar covariance
```

## MVTSeries reductions

The reductions accept a `'dims'` option:

| Call | Result |
|------|--------|
| `mean(mv)` | scalar over the whole buffer |
| `mean(mv, 'dims', 1)` | per-column → `1 × ncols` numeric |
| `mean(mv, 'dims', 2)` | per-row → length-`nrows` `TSeries` |

`std`, `var`, `median`, `sum`, `min`, `max` and `quantile(mv, p, ...)` behave
the same way; without `'dims'` they reduce over every value at once.
`cov(mv)` and `cor(mv)` return the covariance and correlation matrices of the
columns:

```matlab
mv = MVTSeries(qq(2020,1), {'a','b','c'}, randn(40, 3));
cor(mv)     % 3x3 correlation matrix
cov(mv)     % 3x3 covariance matrix
```

## BDaily statistics with NaN / holiday skipping

For `BDaily` data, `mean`, `median`, `std`, `var`, `quantile`, `stdm`, `varm`,
`cov` and `cor` on a `TSeries` or `MVTSeries` take `'skip_all_nans'`,
`'skip_holidays'` and `'holidays_map'`, as in Julia:

```matlab
mean(t, 'skip_holidays', true)              % requires a loaded holidays map
cor(mv, 'skip_all_nans', true)              % drops rows with any NaN
mean(mv, 'skip_all_nans', true, 'dims', 2)  % plain column (rows were dropped)
```

`cleanedvalues(t, ...)` returns the filtered values themselves, and
`bdvalues(t, 'holidays_map', map)` keeps the rows a map marks as business days:

```matlab
mean(cleanedvalues(t, 'skip_all_nans', true))
mean(cleanedvalues(t, 'skip_holidays', true))   % requires a loaded holidays map
```

See [BDaily holidays](../tutorials/1_timeseriesecon.md#16-bdaily-holidays).

!!! info "Julia ↔ MATLAB"
    Julia's `Statistics.mean(mvts; dims=1)` (per-column) →
    `mean(mv, 'dims', 1)`; `dims=2` (per-row) → `mean(mv, 'dims', 2)`.
    `cor`/`cov` follow Julia: two series give a scalar, an `MVTSeries` gives
    the matrix across its columns.
