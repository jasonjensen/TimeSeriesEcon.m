# Plotting

`TSeries` and `MVTSeries` define a `plot` method that builds on MATLAB's
graphics. It is a port of the Julia upstream's `plotrecipes` (a Plots.jl recipe)
to native `plot`.

## TSeries

```matlab
h = plot(t, 'name', value, ..., <line options>)
```

For year-period frequencies the x-axis is numeric with MIT tick labels; for
calendar frequencies (`Daily`/`BDaily`/`Weekly`) it is a native `datetime`
ruler. Recognised options:

| Option | Meaning |
|--------|---------|
| `'mit_loc'` | x-position of each point within its period: `'left'` (default), `'middle'`, `'right'` |
| `'trange'` | an `MITRange` restricting the plotted window |

Any other arguments pass through to the built-in `plot` (e.g. `'LineWidth'`,
color/line specs). The line handle is returned.

```matlab
import tse.*
t = TSeries(qq(2000, 1), cumsum(randn(40, 1)));
plot(t, 'LineWidth', 1.5);
plot(t, 'mit_loc', 'middle', 'trange', MITRange(qq(2005,1), qq(2010,4)));
```

## MVTSeries

```matlab
h = plot(mv, 'vars', names, 'mit_loc', loc, 'trange', rng, <line options>)
```

Draws one line per (selected) column on a single axis with a legend. `'vars'`
selects and orders the columns; `'mit_loc'` and `'trange'` behave as for
`TSeries`.

```matlab
mv = MVTSeries(qq(2000, 1), {'x','y','z'}, cumsum(randn(40, 3)));
plot(mv);
plot(mv, 'vars', {'x', 'z'});
```

!!! info "Julia ↔ MATLAB"
    Corresponds to *Plotting*. The Julia upstream is a Plots.jl recipe with a
    default panel layout; here it is an overloaded `plot` method. The
    `mit_loc` / `trange` / `vars` knobs match. (The MVTSeries arm draws lines on
    one axis with a legend rather than a per-variable subplot grid.)
