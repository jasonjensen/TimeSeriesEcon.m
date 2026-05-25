# TimeSeriesEcon.m

A MATLAB port of the Julia package
[TimeSeriesEcon.jl](https://github.com/bankofcanada/TimeSeriesEcon.jl)
(Bank of Canada), and a sister package to the Python port
[TimeSeriesEconPy](https://nic2020.github.io/TimeSeriesEconPy/). It provides
discrete-time series data types for macroeconomics built around moments in time
(`MIT`), univariate time series (`TSeries`), and multivariate time series
(`MVTSeries`) — keeping the same vocabulary across Julia, Python, and MATLAB so
models translate idiom-for-idiom.

## Install

There is nothing to compile. Clone the repository and add it to the MATLAB path:

```matlab
addpath('/path/to/TimeSeriesEcon.m');   % the folder that contains +tse
import tse.*
```

Requires MATLAB R2019b or newer.

## Quick start

```matlab
import tse.*

t = TSeries(qq(2020, 1), [100.0; 101.2; 102.3; 103.5]);
disp(t)
mean(t)                 % 101.75
g = pct(t);             % quarter-on-quarter % change
y = fconvert(Yearly(), t, 'method', 'mean');   % convert to annual
```

## What's included

- `MIT` / `Duration` / `MITRange`, and the `Frequency` hierarchy
  (`Yearly`, `HalfYearly`, `Quarterly`, `Monthly`, `Weekly`, `Daily`, `BDaily`,
  `Unit`).
- `TSeries` and `MVTSeries` with range-intersection arithmetic, resize-on-assign,
  shifts, differences, growth rates, moving windows, and reductions.
- Frequency conversion (`fconvert`), recursive evaluation (`rec`), `overlay` /
  `compare` / `reindex`, BDaily holiday calendars, plotting, and an extensive
  `matlab.unittest` test suite.
- X-13ARIMA-SEATS (`tse.x13`): build and serialise specs, run `x13as`, and read
  the results (`x13.series`, `x13.arima`, `x13.x11`, `x13.run`,
  `x13.deseasonalize`, …). The `x13as` binary is not bundled — set its path with
  `tse.setoption('x13path', ...)`.

**Not included:** the DataEcon binary file format, and (within `x13`) the bundled
`x13as` binary and the per-table English description text.

## Documentation

User-facing documentation can be found on the [Documentation site](https://jasonjensen.github.io/TimeSeriesEcon.m/), as well as in the [`docs/`](./docs) folder.

- [Home]((https://jasonjensen.github.io/TimeSeriesEcon.m/)) and the [Tutorial](https://jasonjensen.github.io/TimeSeriesEcon.m/tutorials/1_timeseriesecon/)
- [Reference](https://jasonjensen.github.io/TimeSeriesEcon.m/reference/frequencies/) (one page per topic)
- Design notes, including migration guides
  [from Julia](https://jasonjensen.github.io/TimeSeriesEcon.m/design/migration_from_julia/) and
  [from Python](https://jasonjensen.github.io/TimeSeriesEcon.m/design/migration_from_python/)
- [FAQ](https://jasonjensen.github.io/TimeSeriesEcon.m/faq/) and [API index](https://jasonjensen.github.io/TimeSeriesEcon.m/api_index/)

The pages are plain Markdown (readable on GitHub). They can also be built into a
site with `mkdocs` using [`mkdocs.yml`](./mkdocs.yml) (`mkdocs serve`). Inside MATLAB,
`help tse` gives the package overview and `help tse.<name>` documents any
function or class.

## Running the tests

```matlab
addpath('/path/to/TimeSeriesEcon.m');
results = runAllTests;   % from the tests/ folder
```

## Project history

See the [lore](.lore) folder for some design documents, including an older
[TEST_PARITY_REPORT.md](./lore/TEST_PARITY_REPORT.md) for test-coverage parity with
the Julia upstream.
