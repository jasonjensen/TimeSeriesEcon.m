# TimeSeriesEcon.m

A time-series language for macroeconomics, ported from
[TimeSeriesEcon.jl](https://github.com/bankofcanada/TimeSeriesEcon.jl) (Bank of
Canada) to MATLAB.

It is a sister package to the Python port
[TimeSeriesEconPy](https://nic2020.github.io/TimeSeriesEconPy/). All three keep
the same vocabulary — `Frequency`, `MIT`, `TSeries`, `MVTSeries` — so a model
translates idiom-for-idiom between Julia, Python, and MATLAB. This documentation
deliberately follows the structure of the Python docs so you can switch between
languages with minimal friction.

## Install

There is nothing to compile. Clone the repository and add it to the MATLAB path:

```matlab
addpath('/path/to/TimeSeriesEcon.m');   % the folder that contains +tse
```

Everything lives in the `tse` package, so call functions through the prefix
(`tse.qq(2020, 1)`) or add `import tse.*` at the top of a script. Requires a
reasonably recent MATLAB (R2019b or later).

## First TSeries

```matlab
import tse.*

t = TSeries(qq(2020, 1), [100.0; 101.2; 102.3; 103.5]);
disp(t)
fprintf('mean: %g\n', mean(t));
disp(t.firstdate)
```

```text
4-element TSeries{Quarterly} with range 2020Q1:2020Q4:
    2020Q1 : 100
    2020Q2 : 101.2
    2020Q3 : 102.3
    2020Q4 : 103.5
mean: 101.75
2020Q1
```

## What's inside

- **[Tutorial](tutorials/1_timeseriesecon.md)** — a narrative port of the
  upstream Julia tutorial, in MATLAB, with a *Julia ↔ MATLAB* note per section.
- **[Reference](reference/frequencies.md)** — the public API, grouped by topic.
- **[Design notes](design/decisions.md)** — the deviations from the Julia
  upstream that aren't obvious from the code, plus migration guides
  [from Julia](design/migration_from_julia.md) and
  [from Python](design/migration_from_python.md).
- **[API index](api_index.md)** — a flat listing of every public symbol.

## What's not included

Frequency conversion (`fconvert`), plotting, holidays, and the recursive engine
*are* implemented. **X-13ARIMA-SEATS (`x13`)** and the **DataEcon** binary file
format are out of scope — see [the x13 page](reference/x13.md).

## Quick links

- [GitHub repository](https://github.com/jasonjensen/timeseriesecon.m)
- [TimeSeriesEcon.jl (Julia upstream)](https://github.com/bankofcanada/TimeSeriesEcon.jl)
- [TimeSeriesEconPy (Python sister port)](https://nic2020.github.io/TimeSeriesEconPy/)
- [Migration from Julia](design/migration_from_julia.md)
- [Migration from Python](design/migration_from_python.md)
