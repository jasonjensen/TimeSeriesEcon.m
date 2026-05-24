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

**Not included:** X-13ARIMA-SEATS (`x13`) and the DataEcon binary file format.

## Documentation

User-facing documentation lives in [`docs/`](./docs), mirroring the structure of
the [Python documentation](https://nic2020.github.io/TimeSeriesEconPy/):

- [Home](./docs/index.md) and the [Tutorial](./docs/tutorials/1_timeseriesecon.md)
- [Reference](./docs/reference/frequencies.md) (one page per topic)
- Design notes, including migration guides
  [from Julia](./docs/design/migration_from_julia.md) and
  [from Python](./docs/design/migration_from_python.md)
- [FAQ](./docs/faq.md) and [API index](./docs/api_index.md)

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

See [PLAN.md](./PLAN.md) and [PLAN_EXTENSIONS.md](./PLAN_EXTENSIONS.md) for the
original implementation plan and the extension plan, and
[TEST_PARITY_REPORT.md](./TEST_PARITY_REPORT.md) for test-coverage parity with
the Julia upstream.
