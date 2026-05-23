# Frequency conversion (fconvert)

`fconvert` converts an `MIT`, `MITRange`, or `TSeries` to another frequency.

```matlab
y = tse.fconvert(F_to, x, 'name', value, ...)
y = tse.fconvert(fn, F_to, x, ...)     % custom aggregator / disaggregator
```

`F_to` may be a `Frequency` instance (`tse.Quarterly()`), a class name
(`'Quarterly'`), or an integer frequency code. `x` is the thing being converted.

## Methods and options

| Option | Values |
|--------|--------|
| `'method'` (to **higher** frequency) | `'const'` (default), `'even'`, `'linear'` |
| `'method'` (to **lower** frequency) | `'mean'` (default), `'sum'`, `'min'`, `'max'`, `'point'`, `'begin'`, `'end'` |
| `'ref'` | `'begin'`, `'end'` (default); the within-period alignment point |
| `'trim'` | `'both'` (default), `'begin'`, `'end'` (range conversions) |
| `'round_to'` | `'previous'`, `'next'`, `'current'` (MIT → BDaily) |
| `'skip_all_nans'`, `'skip_holidays'` (logical), `'holidays_map'` | BDaily aggregation |

Aggregation (to a lower frequency) groups source observations into target
periods and reduces each group; disaggregation (to a higher frequency) spreads
each source value across the covered target periods.

## Examples

```matlab
import tse.*

q = TSeries(qq(2020, 1), (1:8)');
fconvert(Monthly(), q)                      % quarterly -> monthly (const)
fconvert(Monthly(), q, 'method', 'linear')  % linear interpolation
fconvert(Yearly(),  q, 'method', 'mean')    % quarterly -> yearly average
fconvert(Yearly(),  q, 'method', 'end')     % year-end value (point)

d = TSeries(day('2021-01-01'), (1:120)');
fconvert(Monthly(), d, 'method', 'mean')    % daily -> monthly average
fconvert(Monthly(), d, 'method', 'sum')

% Custom aggregator: any function vector -> scalar
fconvert(@(v) median(v), Quarterly(), TSeries(mm(2020,1), (1:24)'))
```

Supported pairs include YP↔YP (any direction), calendar (Daily/BDaily/Weekly)
→ YP/Weekly aggregation, YP/Weekly → Daily/BDaily disaggregation, and
Daily↔BDaily. Ranges and single MITs convert with the same `F_to` argument.

!!! info "Julia ↔ MATLAB"
    Mirrors `TimeSeriesEcon.jl/src/fconvert`. Julia passes the target as a type
    (`fconvert(Quarterly, t)`); MATLAB passes an instance, name, or code.
    Method/ref/trim names match Julia's symbol keywords. The function-first form
    `fconvert(f, F_to, t)` carries over directly.
