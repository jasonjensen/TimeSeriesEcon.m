# NDTSeries

`tse.NDTSeries` is an N-dimensional series: an N-d array where each dimension
has a `tse.Axis`. An axis is a date range, a list of names, or a plain length,
and the axes can come in any order. A `TSeries` is the one-axis case (dates),
and an `MVTSeries` is the two-axis case (dates, then names).

NDTSeries is a MATLAB addition. Neither TimeSeriesEcon.jl nor TimeSeriesEconPy
has a labelled N-d series. It follows DataEcon's N-d objects, so it can be
stored in `.daec` files.

!!! note "Work in progress"
    This page covers construction, shape, axes, conversion, comparison and
    display. Indexing, time functions (`lag`, `diff`, `pct`, ...),
    reductions and arithmetic come in later steps.

## Axes

```matlab
tse.Axis(qq(2020,1):qq(2021,4))   % range axis
tse.Axis(qq(2020,1), 8)           % range axis from a first date and a length
tse.Axis(["gdp" "cpi"])           % names axis (string array or cellstr)
tse.Axis(3)                       % plain axis of length 3
```

An axis has `kind` (`"range"`, `"names"` or `"plain"`), `length`, `range`
(range axes) and `names` (names axes). `labels(ax)` gives a label for each
position, and `describe(ax)` gives a one-line summary.

`tse.daec.Axis(...)` still works, and returns a `tse.Axis`.

## Construction

```matlab
import tse.*
rng = qq(2020,1):qq(2021,4);

x = NDTSeries({rng, ["gdp" "cpi"], 3});           % NaN-filled 8×2×3
x = NDTSeries({rng, ["gdp" "cpi"], 3}, 0);        % filled with 0
x = NDTSeries({rng, ["gdp" "cpi"]}, rand(8, 2));  % values of matching size
x = NDTSeries({rng, 3}, @(sz) randn(sz));         % values from the size
x = NDTSeries('int64', {rng, 3}, 0);              % typed
x = NDTSeries([Axis(["a" "b"]), Axis(rng)]);      % from tse.Axis objects

x = NDTSeries(ts);      % from a TSeries
x = NDTSeries(mvts);    % from an MVTSeries
x = NDTSeries(arr);     % from a tse.daec.Array
```

The axes argument is a cell array with one entry per dimension (each entry is
anything `tse.Axis` accepts, or a `tse.Axis`), a `tse.Axis` array, or a single
`MITRange`. Values must be numeric or logical, and `size(values, k)` must equal
the length of axis `k`. The properties `axes` and `values` are read-only.

## Shape and axes

| Function | Result |
|---|---|
| `size(x)`, `size(x, d)`, `[m, n, ...] = size(x)` | Axis lengths, like an array |
| `naxes(x)`, `ndims(x)`, `numel(x)`, `length(x)`, `isempty(x)` | |
| `rangeof(x)`, `firstdate(x)`, `lastdate(x)`, `frequencyof(x)` | Of the date axis; `tse.rangeof(x)` etc. work too |
| `timedim(x)` | Index of the date axis |
| `names(x)`, `names(x, k)` | Names of the only names axis, or of axis `k` |
| `haskey(x, name)` | True if any names axis has `name` |
| `rawdata(x)`, `double(x)`, `isnumeric(x)`, `islogical(x)`, `copy(x)` | |
| `permute(x, order)` | Reorder the axes |
| `squeeze(x)` | Drop length-1 axes |

When a series has more than one date axis (for example vintage by date), the
date functions need `'dims', k`:

```matlab
v = NDTSeries({qq(2019,1):qq(2019,4), mm(2020,1):mm(2020,12)});
firstdate(v, 'dims', 2)          % 2020M1
rangeof(v, 'dims', 1, 'drop', 1) % 2019Q2:2019Q4
```

## Conversion

`toseries(x)` gives a `TSeries` for one date axis, and an `MVTSeries` for a date
axis and a names axis (in either order). `tse.daec.Array(x)` gives the storage
form.

## Comparison and display

`isequal`, `isequaln` and `tse.compare` (with `'atol'`, `'rtol'` and `'nans'`)
compare the axes and the values. `disp(x)` lists the axes and prints 2-d
slices labelled by the other axes. It shows at most 5 slices and 40 rows;
`showall(x)` prints everything, and `summary(x)` prints only the axes.

```
  8×2×3 NDTSeries of double
    axis 1: range  2020Q1:2021Q4
    axis 2: names  gdp, cpi
    axis 3: plain  1:3

  (:, :, 1)
            gdp  cpi
  2020Q1      0    0
  ...
```
