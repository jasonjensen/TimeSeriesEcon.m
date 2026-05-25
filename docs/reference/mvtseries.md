# MVTSeries

An `MVTSeries` is a multivariate time series: a 2-D buffer whose rows are
labelled by `MIT` and whose columns are labelled by name. Every column shares the
same frequency, range, and element type.

## Construction

| Call | Result |
|------|--------|
| `MVTSeries(mit, names, matrix)` | start date, names, `length × ncols` matrix |
| `MVTSeries(range, names, matrix)` | range + matching matrix |
| `MVTSeries(range, names, scalar)` | scalar fill |
| `MVTSeries(range, names, @fn)` | `fn(length, ncols)` initialiser |
| `MVTSeries(mit, names)` | empty (0 rows) with the given columns |

`names` is a cell array of char (`{'a','b'}`) or a string array.

## Indexing

| Expression | Result |
|------------|--------|
| `x(mit, name)` | scalar at (date, column) |
| `x(mit)` | the whole row (numeric) |
| `x(range)` | sub-`MVTSeries` (all columns, rows sliced) |
| `x(name)` or `x.name` | one column as a `TSeries` |
| `x({'a','b'})` | sub-`MVTSeries` with the chosen columns |
| `x(range, names)` | sub-`MVTSeries` (rows and columns) |

Assignment mirrors reading: `x.a = ts`, `x(mit, 'a') = v`,
`x(range, 'a') = vec`, and the composite `x.a(mit) = v` writes through to the
underlying matrix (growing it if needed).

## Inspection and columns

`firstdate`, `lastdate(x)`, `rangeof(x)`, `frequencyof(x)`, `x.colnames`,
`x.values` (the 2-D buffer), `columns(x)` (a struct mapping name → `TSeries`).

By default, MVTSeries displays are truncated. Use `showall(t)` or `dispall(t)` to show
the full range.

```matlab
import tse.*
mv = MVTSeries(qq(2020, 1), {'a','b','c'}, rand(8, 3));
mv.a                       % column a as a TSeries
mv(qq(2020, 2), 'b')       % scalar
cols = columns(mv);        % struct: cols.a, cols.b, cols.c
```

## Arithmetic and reductions

Element-wise arithmetic aligns on the range intersection and the shared columns.
Reductions accept a `'dims'` option:

```matlab
mean(mv, 'dims', 1)    % per-column → 1×N numeric
mean(mv, 'dims', 2)    % per-row → length-N TSeries
```

Shifts, differences, growth rates, and moving windows all work column-by-column,
just as on `TSeries`.

!!! info "Julia ↔ MATLAB"
    Julia's `Symbol` column names become MATLAB strings/char. `columns(data)`
    returns a `struct`. Julia's `mean(mvts; dims=1)` (per-column) →
    `mean(mv, 'dims', 1)`, `dims=2` (per-row) → `mean(mv, 'dims', 2)`.
