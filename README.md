# TimeSeriesEcon.m

A MATLAB port of the Julia package
[TimeSeriesEcon.jl](https://github.com/bankofcanada/TimeSeriesEcon.jl)
(Bank of Canada). The original Julia package provides discrete-time series
data types built around moments-in-time (`MIT`), univariate time series
(`TSeries`), and multivariate time series (`MVTSeries`).

This repository currently contains **only a design plan**, not code. The plan
covers the MIT / TSeries / MVTSeries surface area and an associated test
suite. Frequency conversion (`fconvert`), X-13ARIMA-SEATS bindings (`X13`),
and the binary I/O layer (`DataEcon`) are intentionally out of scope for this
port.

See [PLAN.md](./PLAN.md) for the comprehensive implementation plan.
