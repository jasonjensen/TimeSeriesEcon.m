# Design notes

`TimeSeriesEcon.m` is a *port* — not a fresh design — of
[`TimeSeriesEcon.jl`](https://github.com/bankofcanada/TimeSeriesEcon.jl). Most
shape decisions therefore start from "what does the Julia upstream do?" and end
at "what is the smallest deviation that is idiomatic MATLAB?". These notes record
the deviations that aren't obvious from reading the code.

## In this section

- [Frequency model](frequency_model.md) — how parametric `Quarterly{3}` becomes
  an `endPeriod` argument, why there is no `2020Q1` literal, the internal
  integer frequency codes.
- [Migration from Julia](migration_from_julia.md) — the one-page idiom map for
  readers coming from the Julia upstream.
- [Migration from Python](migration_from_python.md) — the idiom map for readers
  coming from the Python sister port.

## Locked decisions

| #  | Topic | Choice |
|----|-------|--------|
| 01 | Class kind | **Value classes**, not handle classes — to mirror Julia's value semantics (`MIT`, `Duration`, `TSeries`, `MVTSeries` all copy-on-write). |
| 02 | Package / namespace | Everything lives under `+tse`; call as `tse.qq(...)` or `import tse.*`. |
| 03 | Frequency representation | Stored internally as `int32` codes on the hot path; reconstructed to `Frequency` objects via `int2freq` for display / public API. |
| 04 | Parametric frequencies | Julia's `Quarterly{3}` becomes a constructor argument, `Quarterly(3)` (the `endPeriod`). |
| 05 | No numeric literals | MATLAB has no user-defined literals, so `2020Q1` → `qq(2020, 1)`. |
| 06 | Indexing | Custom `subsref` / `subsasgn`; MIT keys return scalars, ranges return series, integer keys fall through to the values. Resize-on-MIT-assign matches Julia. |
| 07 | Workspace | **No dedicated type** — use a native MATLAB `struct`. `overlay` / `compare` accept structs. |
| 08 | Statistics axis | Julia's `dims=` keyword becomes `'dims'` name-value (`mean(mv, 'dims', 1)`). |
| 09 | Recurrences | Julia's `@rec` macro becomes the higher-order `rec(rng, target, fn)`; no `rec_linear`. |
| 10 | Matrix product | `*` (and `\`, `/`, transpose) forward to the underlying numeric storage and drop labels, matching Julia. |
| 11 | Out of scope | `x13` and DataEcon file I/O are not ported. |
| 12 | Test stack | `matlab.unittest`, mirroring the Julia test suite where applicable (see `TEST_PARITY_REPORT.md`). |
| 13 | Holidays | Calendar data (`+tse/private/holidays.bin`) is **bundled** from the Julia upstream rather than fetched at runtime. |
| 14 | Errors | A small error-ID hierarchy (`tseries:mixedFreq`, `tseries:bounds`, `tseries:invalidArith`, `tseries:noMatch`, `tseries:dimMismatch`, `tseries:inexact`). |
| 15 | Performance | Hot paths (scalar indexing, binary ops, reductions) are tuned to minimise per-call class-dispatch overhead; see `benchmarks/`. |
