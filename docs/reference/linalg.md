# Linear algebra

`TSeries` and `MVTSeries` forward matrix operations to their underlying numeric
storage, so coefficient matrices multiply a series the way they do in Julia. The
result is a **plain numeric array** with the time-axis labels stripped (matching
the Julia upstream, where the overloads forward to `*(_vals(A), _vals(B))`).

| Expression | Result |
|------------|--------|
| `A * t` | matrix `A` times the values of `t` → numeric vector |
| `scalar * t`, `t * scalar` | scaled `TSeries` (range preserved) |
| `t / scalar` | scaled `TSeries` |
| `A \ b`, `A / B` | least-squares / right division on the underlying values |
| `t'`, `transpose(t)`, `ctranspose(t)` | transpose of the values (numeric) |
| `parent(t)` | the underlying values array |

```matlab
import tse.*
t = TSeries(qq(2020, 1), (1:100)');
A = randn(100, 100);
y = A * t;            % 100x1 numeric vector (labels dropped)

s = 2.5 * t;          % a TSeries, range preserved
```

Element-wise `.*`, `./`, `.^` between two `TSeries` align on the range
intersection and return a `TSeries` — see [TSeries arithmetic](tseries.md). Only
the matrix forms (`*`, `\`, `/`, transpose) drop labels.

!!! info "Julia ↔ MATLAB"
    Mirrors `TimeSeriesEcon.jl/src/linalg.jl`. Julia overloads `*` for
    matrix-times-series and returns a bare `Vector`/`Matrix`; MATLAB does the
    same with `*`. (The Python sister port uses `@` for this, reserving `*` for
    element-wise.) `transpose`/`adjoint` return the bare numeric transpose.
