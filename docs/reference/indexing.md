# Indexing (lookup)

Beyond the scalar / range indexing covered in [TSeries](tseries.md), the package
provides `lookup` for a vectorised gather of many positions at once.

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
