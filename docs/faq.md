# FAQ

## Where does TimeSeriesEcon.m come from?

It is a MATLAB port of
[`TimeSeriesEcon.jl`](https://github.com/bankofcanada/TimeSeriesEcon.jl), the
Bank of Canada's Julia time-series language, and a sister package to the Python
port [TimeSeriesEconPy](https://nic2020.github.io/TimeSeriesEconPy/). The three
keep the same vocabulary so a model written against any one translates
idiom-for-idiom to the others.

## How do I install it?

There is nothing to compile. Add the repository root (the folder containing
`+tse`) to the MATLAB path:

```matlab
addpath('/path/to/TimeSeriesEcon.m');
```

Then call through the package (`tse.qq(2020, 1)`) or `import tse.*`. MATLAB
R2019b or newer is recommended.

## How does it compare to MATLAB's `timetable`?

`timetable` is a general-purpose table with a datetime row axis. `tse` is a
time-series *primitive* library focused on macroeconomic modelling:

- first-class fiscal-year frequencies (`Yearly(3)`, `Quarterly(2)`);
- non-calendar `Unit` frequency and exact business-daily (`BDaily`) arithmetic;
- range-intersection arithmetic and resize-on-assign;
- lossless frequency conversion (`fconvert`) with the same method codes as the
  Julia upstream.

You can always drop down to plain arrays with `t.values` and `rangeof(t)` to
hand data to `timetable`, Econometrics Toolbox, etc.

## How does it compare to TimeSeriesEcon.jl?

Semantics are identical wherever MATLAB allows; the
[Migration from Julia](design/migration_from_julia.md) page is the one-page idiom
map. The main intentional omissions are `x13` and DataEcon file I/O.

## Why is there no `2020Q1` literal?

MATLAB has no user-defined numeric literals. Use the constructor functions
`qq(2020, 1)` / `mm(2020, 3)` / `yy(2020)`. See
[Frequency model](design/frequency_model.md).

## Why is there no `Workspace` type?

MATLAB's native `struct` already is an ordered, attribute-accessible bag of
heterogeneous values, so the port uses `struct` directly; `overlay` and
`compare_ts` accept structs. See [Workspaces](reference/workspace.md).

## Where do I file a bug?

[GitHub Issues](https://github.com/jasonjensen/timeseriesecon.m/issues).
