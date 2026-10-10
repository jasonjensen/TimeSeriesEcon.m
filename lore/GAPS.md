# Parity gap list

The working list of differences between **TimeSeriesEcon.m** and its sister
libraries. Each entry names the upstream source so a fix can mirror it, and the
priority follows the project order: feature parity, then syntax equivalence,
then performance.

## Upstream commits compared

| Library | Repository | Commit | Date |
|---|---|---|---|
| Julia | `bankofcanada/TimeSeriesEcon.jl` | `fc0a0d0` | 2025-12-22 |
| Python | `Nic2020/TimeSeriesEconPy` | `f941907` (0.0.1.dev3) | 2026-09-15 |
| MATLAB | `jasonjensen/TimeSeriesEcon.m` | `50fe8e3` | 2026-07-15 |

The Julia upstream has had no commits since `fc0a0d0`, which is also the commit
the Python port pins (`tsecon._mirror.MIRRORS_JULIA_SHA`). The earlier Julia
comparison in `TEST_PARITY_REPORT.md` therefore still holds; everything new
below comes from 107 Python commits since 2026-05-15, of which roughly 70 are
DataEcon interchange (2026-09-09 .. 09-15) and the rest are bug fixes,
benchmarks, CI and docs.

The weekly upstream check reads this table and only looks at commits after the
pinned ones; update the table whenever a comparison is redone.

## Status key

- **Open**: confirmed gap, not yet worked on.
- **Decide**: needs a call from the maintainer before work starts.
- **N/A**: does not apply to MATLAB (reason given).

## P1: correctness (bugs Python fixed that MATLAB still has)

These were confirmed by reading `+tse/TSeries.m`, `+tse/MVTSeries.m` and
`+tse/MITRange.m`. Julia gets all of them right, so fixing them is pure parity.

### G1. TSeries read with reversed, strided or empty ranges — Fixed in PR

Python: `efaf64f` *Fix date-range selection and assignment across series
types*, tests in `tests/test_date_range_selection.py`.

`TSeries.doGet` (`+tse/TSeries.m`, `case 'tse.MITRange'`) bounds-checks
`startMIT`/`stopMIT` as if `start <= stop`:

- a reversed range such as `MITRange(qq(2020,4), qq(2020,1), -1)` whose start
  is past the end of storage is caught only by MATLAB's own indexing error,
  not `tseries:bounds`;
- a strided range whose *stop* lies outside storage but whose *selected dates*
  are all inside (e.g. `start+4 : -2 : start-1`) is wrongly rejected or not,
  depending on direction;
- an empty range outside storage raises instead of returning an empty result.

Expected (Julia/Python): bounds are checked on the dates the range actually
selects; empty ranges select nothing but still enforce frequency; unit-step
forward ranges return a TSeries, any other step returns a plain vector.

### G2. TSeries assignment with reversed, strided or empty ranges — Fixed in PR

Same Python commit. In `TSeries.doSet`:

- `issubrange` assumes `start <= stop`, so a reversed range triggers a
  spurious resize, and `rangeof_span` with a reversed range can grow storage
  to the wrong span;
- an empty range can grow storage (Python: must not);
- strided assignment from a numeric vector has no length check, and a char
  right-hand side is silently stored as character codes.

(Python also had to make rejected assignments atomic. MATLAB gets that for
free: `TSeries` is a value class, so an error leaves the caller's variable
untouched.)

Python test to mirror: `test_reverse_assignment_grows_owner_and_preserves_gaps`
— assigning `[40 20 0 -20]` to `start+4 : -2 : start-2` on a 2-element series
gives `[-20 NaN 0 2 20 NaN 40]` starting at `start-2`.

### G3. MVTSeries range rows ignore the step — Fixed in PR

Same Python commit ("table selections that ignored the step"). In
`+tse/MVTSeries.m` the row-range path (`doMvtsGet` around line 1115 and the
`(rng, cols)` path around line 1165) always slices `kStart:kEnd` and labels the
result with `startMIT`, so `x(MITRange(a, 2, b))` returns every row in between
and `x(MITRange(b, a, -1))` returns nothing or errors. Assignment has the same
problem. Expected: same rules as G1/G2, with column selection (`x(rng, 'a')`,
`x(rng, {'b','a'})`) following them too.

### G4. MITRange equality for empty and non-landing ranges — Fixed in PR

Python: `69126db` *Fix empty and nonempty date-range equality*, tests in
`tests/test_empty_range_equality.py`.

`MITRange.eq` compares `startMIT`, `stopMIT` and `stepSize` literally. Julia
(and now Python) compare the *selected dates*:

- all empty ranges of the same frequency are equal, whatever their anchor or
  step;
- `MITRange(a, a+5, 2)` equals `MITRange(a, a+4, 2)` (same dates);
- an empty range never equals a non-empty one.

`isequal` should follow. Found while fixing: `MITRange - n` always errored
(the constructor arguments were in the wrong order), and `~=` was undefined.

Also found: `MVTSeries` assignment `x(rng, cols) = y` with a series on the
right ignored `rng` and wrote every overlapping date. Julia reads `y` at the
range's dates (`x[rng, cols] = y[rng, cols]`); MATLAB now does too.

## P2: features missing from MATLAB

### G5. MVTSeries `cov`, `cor`, `quantile` — Fixed in PR

Julia supports `cov(mv)`, `cor(mv)` and `quantile` through the `AbstractMatrix`
fallback, plus BDaily overloads with `skip_all_nans` / `skip_holidays` /
`holidays_map` (`src/tsmath.jl` 289-298). Python has them with the same
keywords (`src/tsecon/_stats.py`). `MVTSeries.m` defines `mean`, `std`, `var`,
`median` but not these three.

### G6. `stdm`, `varm`, `bdvalues` — Fixed in PR

`stdm`/`varm` (known-mean std/var, with BDaily keywords) exist in Julia
(`tsmath.jl` 246-247) and Python. `bdvalues` exists in Julia
(`tseries.jl`, `mvtseries.jl`) and Python. None are in MATLAB.

Found while fixing G5/G6, all now matching Julia:

- `std`, `var` and `median` of an MVTSeries without `'dims'` reduced the
  per-column results again (e.g. the median of column medians) instead of
  using every value.
- `min(mv, 'dims', 1)` called `min(v, 1)`, an elementwise min against 1.
- MVTSeries `mean`/`median`/`std`/`var` ignored the BDaily skip options.
- `cov(a, b)` on two TSeries returned MATLAB's 2x2 matrix; Julia returns the
  scalar. `cov`/`cor` of two series now also require the same frequency and
  start date, as in Julia.

### G7. DataEcon coverage of Julia-written files — Open

`tse.daec` (moved from DataEcon, PR #8) reads and writes scalars of every
MATLAB width, MIT and Duration scalars and arrays, MITRange values, Bool,
TSeries, MVTSeries, N-d arrays with any mix of plain, date and name axes, text
arrays, nested structs, attributes and in-memory files.

`tests/TestDaecFixtures.m` reads every object (3,873) in the 24 Julia-written
fixtures of TimeSeriesEconPy and compares the result byte for byte with the
stored data. 3,247 read as stored. `tests/fixtures/daec/known_gaps.tsv` lists
the other 626:

- **Refused, no MATLAB type (337):** Float16, Int128/UInt128 and ComplexF16
  elements. Float16 could be read as single without loss; the 128-bit and
  ComplexF16 values have no MATLAB equivalent, and Python reads them as
  stored-only objects.
- **Refused, malformed or foreign (51):** controls Julia never writes or
  Python also rejects: dates that are not 8 bytes wide, a frequency on
  non-date elements, strings with embedded zeros, invalid UTF-8 or no
  terminator, and Bool markers on values other than 0 and 1. Before PR #9
  these were silently misread.
- **Complex values with zero imaginary parts become real (most of the 96
  eltype,bytes and 50 eltype misreads):** TSeries and MVTSeries drop the
  complex flag, including on empty complex series.
- **Empty date and duration arrays lose their frequency (86):** an empty
  `tse.MIT`/`tse.Duration` array carries no frequency in MATLAB.
- **Integer MVTSeries become double:** Int64 and UInt64 matrices with a
  date axis.
- **Bool markers on 0/1 payloads wider than Int8** read as logical, which
  re-encodes as Int8 (as Julia's loader does).
- **Unit dates at the Int64 extremes (4):** MITRange lengths overflow.
- **Markers other than Bool are ignored:** `Rational`, `Symbol`, `Date`,
  `Complex{Int64}` and other `jtype`/`jeltype` values read as their stored
  payload. These pass the byte check, so they are not in the list.

Next: decide which of these to close (Float16 as single, complex flag, empty
date frequency, integer MVTSeries) and which stay documented limitations.

### G8. Stale docs and no upstream pin — Open

- `README.md` still says DataEcon is "Not included"; `docs/design/decisions.md`
  #11 still says x13 and DataEcon are out of scope. Both are now ported.
- There is no DataEcon page under `docs/reference/` (Python has
  `docs/dataecon.md`).
- Python records the mirrored Julia commit in code (`MIRRORS_JULIA_SHA`) and
  runs a weekly upstream diff. MATLAB has no equivalent; the table at the top
  of this file plays that role for now.

## P3: Python-only additions (syntax equivalence / convenience)

These exist in Python but not in Julia. Worth having only where a MATLAB
user would expect them.

### G9. Table interop — Decide

Python: `to_pandas` / `from_pandas`, `to_polars` / `from_polars`. The MATLAB
analogue would be `timetable` (and possibly `table`) conversion, e.g.
`tse.to_timetable(mv)` / `tse.from_timetable(tt)`. Needs a decision on naming
and how BDaily/Weekly/Unit frequencies map to timetable row times.

### G10. JSON serialization — Decide

Python: `tsecon.io.json`, lossless round trip of TSeries, MVTSeries,
Workspace, MIT, MITRange and Frequency with a `_type` discriminator. A MATLAB
reader/writer for the *same* JSON format would give a text interchange path
between the Python and MATLAB ports that needs no native library.

### G11. Name aliases — Decide

| Python | MATLAB today | Julia |
|---|---|---|
| `strip_tseries` | `strip_ts` | `strip` |
| `get_holidays_map` | `getoption('bdaily_holidays_map')` | — |
| `prettyprint_frequency` | — | `prettyprint_frequency` |
| `option_scope` (context manager) | — | — |
| `fconvert_parts`, `fconvert_mit`, `fconvert_range`, `fconvert_tseries` | `fconvert` only | `fconvert` (+ internal `fconvert_parts`) |
| `hcat` / `vcat` free functions | `[a, b]` / methods | `hcat` / `vcat` |

`prettyprint_frequency` is in Julia's exports, so it is a P2-grade gap; the
rest are cheap aliases.

### G12. Python returns where MATLAB follows Julia — no action

Recorded so nobody "fixes" them:

- `mean(mv, axis=0)` returns a one-row MVTSeries in Python; Julia and MATLAB
  (`mean(mv, 'dims', 1)`) return a plain row.
- `compare` returns a `CompareResult` with a list of differences in Python;
  Julia and MATLAB return a logical.

## Not applicable

| Python change | Why it does not apply |
|---|---|
| Column ownership, `*_inplace` functions (`2541e76`) | MATLAB value classes copy on write; a column is never a live view. |
| NumPy dispatch guards, NumPy/pickle compatibility baselines (`e95faa5`, `d537aa3`) | NumPy/pickle specific. |
| `_repr_html_` | Jupyter specific. |
| Cython kernels, `*_is_cython`, `available_backends` | Python build specific; MATLAB performance is tracked in `benchmarks/`. |
| Wheel/CI/PyPI commits | Packaging. |
| `Workspace` type, `copyto(MVTSeries, Workspace)` | Decision #07: MATLAB uses `struct`. |
| `rec_linear` | Python-only (not in Julia); decision #09. |
| matplotlib/plotly backends | MATLAB has native plotting (`TestPlot.m`). |

## Carried over from `TEST_PARITY_REPORT.md`

Still open from the Julia comparison (test coverage rather than features):

- BDaily statistics with `skip_all_nans` / `skip_holidays` (partly covered by
  `TestBDailyStatistics.m`; re-check against `test_business.jl`).
- BDaily shift/diff/pct with explicit holiday maps.
- Exhaustive step-range indexing tests from `test_tseries.jl` 150-380 — these
  overlap G1-G3 and should be written together with those fixes.

## Octave notes (for step 4)

Collected while checking fixes in Octave 8.4 on a patched scratch copy:

- `SetAccess = immutable` is not supported; `private` works.
- Package `private/` functions are not visible from classdef methods.
- `import` inside functions is not implemented.
- `strings` and the `string` class do not exist, so every `MVTSeries` path
  fails (column names are stored as a string array).
- `idivide(int64(-5), int64(-2), 'fix')` returns 3, not 2, so
  `MITRange.length` is wrong for some negative steps.
- `Frequency.m` declares external methods, which Octave only allows in
  `@`-folders.
