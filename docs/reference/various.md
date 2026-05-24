# Misc helpers (overlay, compare, reindex)

Three sibling functions from upstream `TimeSeriesEcon.jl/src/various.jl`. In
MATLAB the "workspace-like" dispatch covers `TSeries`, `MVTSeries`, and native
`struct`s.

## overlay

```matlab
r = tse.overlay(t1, t2, ...)
r = tse.overlay(rng, t1, t2, ...)     % forced output range
```

First-valid-wins composition. At each observation the leftmost argument that is
**not** "missing" (per `tse.istypenan` — NaN for floats, `intmax` for integers,
`false` for logicals) wins. With `TSeries` inputs the result spans the union of
input ranges (or the explicit `rng`). With `MVTSeries` / `struct` inputs it
recurses field-by-field.

```matlab
import tse.*
x1 = TSeries(MITRange(qq(2020,1), qq(2020,4)), 1.0);
x1(MITRange(qq(2020,2), qq(2020,3))) = NaN;
x2 = TSeries(MITRange(qq(2019,3), qq(2020,2)), 2.0);
overlay(x1, x2)
overlay(struct('a', x1, 'k', 1), struct('a', x2, 'k', 2))   % field-by-field
```

## compare

```matlab
tf = tse.compare(a, b, 'name', value, ...)
```

Recursive comparison of two series, arrays, scalars, or `struct`s under
`isapprox`-style tolerance; returns a scalar logical. Also available as a
method, so `compare(t1, t2)` works on a `TSeries` / `MVTSeries` without the
package prefix.

| Option | Default | Meaning |
|--------|---------|---------|
| `'atol'` | `0` | absolute tolerance |
| `'rtol'` | auto | relative tolerance |
| `'nans'` | `false` | treat NaN-vs-NaN as equal |
| `'ignoreMissing'` | `false` | compare only the overlapping range / shared fields |
| `'trange'` | `[]` | restrict the comparison window |
| `'quiet'` | `true` | suppress the printed diff |

```matlab
compare(a, b, 'atol', 1e-5)
compare(n1, n2, 'nans', true)
```

## reindex

```matlab
r = tse.reindex(x, from, to)
r = tse.reindex(x, from, to, 'copy', true)
```

Shift every MIT-keyed position in `x` so that `from` becomes `to`, preserving the
values. Dispatches over `MIT`, `MITRange`, and `TSeries`. The frequencies of
`from` and `to` need not match.

```matlab
reindex(qq(2022, 4), qq(2020, 1), MIT(Unit(), 1))     % 12U
ts = TSeries(qq(2021, 1), [1;2;3]);
reindex(ts, qq(2020, 1), MIT(Unit(), 1))              % firstdate -> 5U
```

!!! info "Julia ↔ MATLAB"
    `overlay` / `compare` take the same options as Julia (Julia's `@compare`
    macro folds into `compare`). Julia's `reindex(t, from => to)` `Pair`
    becomes `reindex(t, from, to)`. The `LikeWorkspace` union maps to MATLAB
    `struct` / `MVTSeries`; `reindex` itself dispatches over MIT / MITRange /
    TSeries.
