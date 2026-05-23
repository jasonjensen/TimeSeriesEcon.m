# TimeSeriesEcon.m — Extension Plan: `fconvert`, `x13`, `plotrecipes`

A plan for porting the three feature areas deliberately deferred in the
original [`PLAN.md`](../PLAN.md): frequency conversion (`fconvert`),
X‑13ARIMA‑SEATS seasonal adjustment (`x13`), and plotting (`plotrecipes`).
`DataEcon` remains out of scope (see [`DATAECON_COMPARISON.md`](../DATAECON_COMPARISON.md)).

Reference source: [`TimeSeriesEcon.jl`](https://github.com/bankofcanada/TimeSeriesEcon.jl),
`src/fconvert/`, `src/x13/`, `src/plotrecipes.jl`.

> This document plans *what* and *in what order*. It does not change code.
> Each feature section ends with a phasing breakdown, a test mapping, and a
> risk list. Effort estimates are relative; treat them as planning aids.

---

## 0. Summary & recommended sequencing

| Feature        | Self-contained? | External dep | Relative effort | Value |
|----------------|:---------------:|:------------:|:---------------:|:-----:|
| `fconvert`     | yes             | none         | medium (~2–3 wk)| high  |
| `plotrecipes`  | yes             | a plotting backend (MATLAB built-in `plot`) | small (~3–5 d) | medium |
| `x13`          | **no**          | **X‑13ARIMA‑SEATS binary** | very high (MVP ~3–4 wk, full ~2–3 mo) | high (for SA users) |

**Recommended order: `fconvert` → `plotrecipes` → `x13`.**

Rationale: `fconvert` is pure computation that builds directly on calendar
machinery we already have, and it unblocks the most workflows. `plotrecipes`
is small and independent, a good "quick win" second. `x13` is by far the
largest and the only one with a hard external-binary dependency and a
distribution problem, so it goes last and should ship as a staged MVP rather
than a big-bang full port.

We can treat each feature as an independent track — none blocks another except
that `x13`'s `deseasonalize` naturally wants `fconvert` available for any
frequency massaging, and good plots of converted series want `fconvert` done.

---

## 1. What we already have to build on

The core port (Phases 1–7) gives us everything the extensions need as a
foundation:

- **Calendar conversion primitives** in `+tse/private/`: `mitToDate`,
  `dateToDailyValue`, `dateToBDailyValue`, `dateToWeeklyValue`,
  `dateOfYearJan1`, `mit2yp`, `periodsPerYear`, `int2freq`/`freq2int`.
- **Range machinery**: `MITRange` with `intersect`, `union`, `collect`,
  `length`, stepping.
- **Containers**: `TSeries`, `MVTSeries` with growth-on-assign, reductions,
  and a fast `subsref`/`binaryOp` layer.
- **Frequency model**: int‑coded frequencies (`Unit=11`, `Daily=12`,
  `BDaily=13`, `Weekly=16+ep`, `Monthly=32`, `Quarterly=64+ep`,
  `HalfYearly=128+ep`, `Yearly=256+ep`) with `int2freq`/`freq2int`.

This means `fconvert`'s hardest sub‑problem — mapping dates between calendar
frequencies — is mostly a matter of reusing existing helpers.

---

## 2. Feature A — `fconvert` (frequency conversion)

### 2.1 Julia surface to reproduce

From `src/fconvert/` (three files: `fconvert_mit.jl`, `fconvert_tseries.jl`,
`fconvert_helpers.jl`). Public API:

```julia
fconvert(F_to::Type{<:Frequency}, t::TSeries; method, ref, ...)
fconvert(f::Function, F_to::Type{<:Frequency}, t::TSeries; ...)   # apply f per bucket
fconvert(F_to::Type{<:Frequency}, m::MIT; ref, bias)             # MIT-level
fconvert(F_to::Type{<:Frequency}, r::MITRange; trim, ...)        # range-level
```

Keyword arguments:

| arg              | values | default | role |
|------------------|--------|---------|------|
| `method`         | `:const`, `:even`, `:linear` (disagg); `:mean`, `:sum`, `:min`, `:max`, `:point` (agg) | `:mean` (→lower), `:const` (→higher) | aggregation/disaggregation technique |
| `ref`            | `:begin`, `:end`, `:middle` | `:end` | period-boundary alignment |
| `bias` (BDaily)  | `:previous`, `:next`, `:current` | — | nearest business day |
| `skip_all_nans`  | bool | `false` | NaN handling in BDaily aggregation |
| `skip_holidays`  | bool | `false` | exclude holidays |
| `holidays_map`   | `TSeries{BDaily}` / none | none | holiday calendar |
| `trim`           | bool | (range) | drop partial boundary periods |

Supported conversions:
- **Aggregation (higher → lower):** Daily/BDaily/Weekly → Monthly/Quarterly/
  HalfYearly/Yearly; YP → coarser YP; Daily ↔ BDaily.
- **Disaggregation (lower → higher):** Yearly→Quarterly→Monthly; Monthly→
  Weekly/Daily/BDaily; YP/Weekly → Weekly/Daily/BDaily.

### 2.2 MATLAB design

A single top-level `tse.fconvert` free function with method dispatch on the
target/source frequency pair, plus private helpers. No new classes.

```
+tse/
├── fconvert.m                       ← public entry; dispatches by freq pair
└── private/
    ├── fconvert_mit.m               ← MIT/MITRange → target buckets
    ├── fconvert_yp_to_yp.m          ← YP↔YP (month-fraction math)
    ├── fconvert_calendar.m          ← Daily/BDaily/Weekly ↔ {YP, calendar}
    ├── fconvert_aggregate.m         ← bucket reduce (mean/sum/min/max/point)
    ├── fconvert_disaggregate.m      ← const/even/linear expansion
    └── fconvert_buckets.m           ← shared "which target period(s) does
                                        each source period fall in" mapping
```

Design notes:
- **Target frequency is passed as a `tse.Frequency` object or int code**, e.g.
  `tse.fconvert(tse.Quarterly(), t)` (Julia passes the *type*; MATLAB has no
  type-as-value, so we accept an instance or an int code, consistent with how
  `tse.MIT` already accepts both).
- **`method` and `ref` are name–value pairs** (char/string), mirroring our
  existing `pct(..., 'islog', tf)` convention:
  `tse.fconvert(tse.Monthly(), t, 'method', 'mean', 'ref', 'end')`.
- **The function-first form** `fconvert(f, F_to, t)` becomes
  `tse.fconvert(F_to, t, 'method', @myfun)` — accept a function handle as a
  `method` value, applied per bucket. Cleaner than overloading arg order in
  MATLAB.
- **Two-layer architecture, exactly like Julia:**
  1. *Index layer* (`fconvert_mit`/`fconvert_buckets`): compute, purely from
     dates, the mapping between source positions and target periods. For
     calendar↔YP this reuses `mitToDate` + the `dateTo*Value` helpers; for
     YP↔YP it's integer month arithmetic.
  2. *Data layer* (`fconvert_aggregate`/`fconvert_disaggregate`): apply the
     reduction/expansion over the numeric `.values` using the index map
     (vectorised with `accumarray` for aggregation, `repelem`/`interp1` for
     disaggregation).
- **Aggregation is `accumarray`-friendly:** map each source row to a target
  bucket index, then `accumarray(bucketIdx, values, [], @mean)` etc. `:point`
  selects the source row at the `ref` boundary of each bucket. This keeps the
  hot path vectorised.
- **Disaggregation:** `:const` = `repelem`; `:even` = `repelem(v ./ counts)`;
  `:linear` = `interp1` on bucket reference points (Daily/BDaily/Monthly
  targets only, matching Julia's restriction).

### 2.3 Holidays / BDaily

`skip_holidays`/`holidays_map`/`bias` are the genuinely fiddly part and the
least-used. **Recommendation: ship `fconvert` without holiday support first**
(error clearly if `skip_holidays`/`holidays_map` are passed), then add it as a
follow-on once the core conversions are solid. The original `PLAN.md` already
deferred "business-daily holiday calendars" as a non-goal, so this is
consistent.

### 2.4 Phasing

- **A1 — Index layer.** `fconvert` for `MIT` and `MITRange` across all
  supported pairs; `trim`/`ref` semantics; the bucket-mapping helper.
  Foundation for everything else.
- **A2 — Aggregation (higher→lower).** `:mean`/`:sum`/`:min`/`:max`/`:point`
  plus function-handle methods, NaN handling (`skip_all_nans` for the common
  case). Covers the most common direction.
- **A3 — Disaggregation (lower→higher).** `:const`/`:even`/`:linear`.
- **A4 — BDaily/holidays.** `bias`, `skip_holidays`, `holidays_map`. Optional /
  later.

### 2.5 Tests

Port `test/test_fconvert*.jl` and the `test_22.jl` regression case into
`tests/TestFconvertMIT.m`, `TestFconvertAgg.m`, `TestFconvertDisagg.m`.
Anchor numeric expectations against Julia output for a handful of known
series (quarterly↔monthly↔yearly; daily→monthly mean/sum/end).

### 2.6 Risks

- **Boundary/`ref` edge cases** (partial first/last periods, `trim`) are where
  Julia parity is easy to miss — invest in tests there.
- **Calendar arithmetic correctness** for Weekly/BDaily mappings; mitigated by
  reusing already-tested `dateTo*Value` helpers.
- **Performance** is a non-issue if we keep aggregation on `accumarray` and
  avoid per-period object construction.

---

## 3. Feature B — `plotrecipes` (plotting)

### 3.1 Julia surface

`src/plotrecipes.jl` uses **RecipesBase**/**Plots.jl** — a declarative recipe
system. Three recipes: `one_tseries` (single), `many_tseries` (multiple
TSeries), `many_mvtseries` (multiple MVTSeries with variable selection and
one subplot per variable). Core helpers:

- `mit_offset(loc)` → within-period x-offset for `:left` (0.0), `:middle`
  (0.5/N), `:right` (1.0/N).
- `mit_formatter(...)` → turns a numeric x value back into an MIT label, with a
  `⁺` marker when the x doesn't land exactly on a period.
- Attributes: `mit_loc`, `trange`, `label`, `vars`, `layout`.
- Daily/Weekly are converted to real dates for the axis.

### 3.2 MATLAB design

MATLAB has **no recipe system**; the idiomatic equivalent is overloaded
`plot` methods that build x/y data and configure a custom tick formatter.
This also supersedes the placeholder `plot()` promised in `PLAN.md` §13.7.

```
+tse/
├── @TSeries/plot.m      (or a `plot` method in TSeries.m)
├── @MVTSeries/plot.m
└── private/
    └── mit_axis.m       ← shared: build x-coords + tick labels/formatter
```

Behaviour:
- **`plot(t)`** on a `TSeries`: x = numeric coordinate per period (use
  `toFloat(mit)` we already have — `year + (p-1)/N` for YP — and a `mit_loc`
  offset; for Daily/Weekly/BDaily, build a `datetime` x-axis via `mitToDate`).
  y = `t.values`. Then set `xticks`/`xticklabels` from MIT labels, or use a
  `datetime` ruler for calendar frequencies (MATLAB formats those natively).
- **`plot(x)`** on an `MVTSeries`: one line per column (legend = colnames), or
  one subplot per `vars` selection via `tiledlayout`. Support `'vars'`,
  `'trange'`, `'mit_loc'` name–value args mirroring Julia.
- **Pass-through** of standard `plot` line-spec / name–value options to the
  built-in (`plot(t, 'LineWidth', 2, ...)`).
- **`mit_loc`** (`'left'|'middle'|'right'`) and **`trange`** (an `MITRange`
  subset) map 1:1 to the Julia attributes.
- The `⁺` non-aligned-tick marker is a nice-to-have; we can match it in the
  tick formatter or drop it (document the difference).

Return the axis/line handles so users can compose further, MATLAB-style.

### 3.3 Phasing

- **B1 — `TSeries.plot`** with YP and calendar x-axes, `mit_loc`, `trange`,
  option pass-through.
- **B2 — `MVTSeries.plot`** with multi-line, `vars`, and subplot (`tiledlayout`)
  layout.

### 3.4 Tests

Plotting is visual; tests are smoke/structural only (no pixel assertions):
construct a figure with `'Visible','off'`, then assert on the returned line
objects' `XData`/`YData`, tick labels, and number of axes/subplots. Put these
in `tests/TestPlot.m`. Mark clearly that these don't validate appearance.

### 3.5 Risks

- **Low overall.** Main fidelity gap is the recipe-attribute surface vs. our
  name–value surface; document the mapping.
- **Tick-label density** for long daily series — rely on MATLAB's `datetime`
  ruler rather than hand-placing ticks where possible.

---

## 4. Feature C — `x13` (X‑13ARIMA‑SEATS)

This is the big one. It is a **wrapper around an external program**, not a
numeric algorithm we reimplement.

### 4.1 Julia surface

`src/x13/` — five files, ~20 spec section types, ~250–300 keyword options:

- `X13.jl` — module/entry; exports `deseasonalize`/`deseasonalize!`,
  `cleanup`, result-workspace types. Imports **`X13as_jll`** for the binary.
- `x13spec.jl` — ~20 spec sections (`series`, `arima`, `automdl`, `x11`,
  `seats`, `transform`, `regression`, `estimate`, `forecast`, `outlier`,
  `check`, `force`, `history`, `identify`, `metadata`, `pickmdl`,
  `slidingspans`, `spectrum`, `x11regression`) + builder functions
  (`series()`, `x11()`, …) and the `X13spec` container; `newspec()`.
- `x13write.jl` — serialises the spec to a `.spc` file and shells out to the
  binary.
- `x13result.jl` — parses output tables into a (lazy) result workspace.
- `x13consts.jl` — keyword/option constants.

Workflow: `newspec(series) → x11()/seats()/arima()/… → run → result
workspace`; `deseasonalize` wraps the common case.

### 4.2 The hard dependency: the X‑13 binary

Julia gets the binary for free via `X13as_jll` (an artifact). **MATLAB has no
equivalent.** This is the single biggest decision in this whole plan. Options:

1. **User-supplied binary + configurable path (recommended baseline).**
   The user installs X‑13ARIMA‑SEATS (it's public‑domain, distributed by the
   US Census Bureau for Windows/Linux/macOS). We locate it via, in order: an
   explicit path argument, a `tse.x13.setbinary(path)` setting, an env var
   (e.g. `X13PATH`), then `PATH`. Clear error with install instructions if not
   found.
2. **Download helper (recommended companion).** `tse.x13.install()` downloads
   the correct Census build into a per-user cache dir (with checksum), so
   first-time setup is one call. (Network access required; respects the
   environment's network policy.)
3. **Bundle binaries in-repo.** Possible (public domain) but bloats the repo
   with per-platform executables and complicates updates. **Not recommended.**

**Recommendation: (1) + (2).** Invoke via `system()` in a temp working dir,
read back the output files, then clean up (`cleanup`).

### 4.3 MATLAB design

A dedicated subpackage `+tse/+x13/` keeps the large surface isolated:

```
+tse/+x13/
├── newspec.m            ← create an X13spec (struct-backed)
├── series.m  x11.m  seats.m  arima.m  automdl.m  transform.m
├── regression.m  estimate.m  forecast.m  outlier.m  check.m
├── force.m  history.m  identify.m  metadata.m  pickmdl.m
├── slidingspans.m  spectrum.m  x11regression.m
├── run.m                ← write spec, invoke binary, parse result
├── deseasonalize.m      ← convenience wrapper
├── setbinary.m / findbinary.m / install.m / cleanup.m
└── private/
    ├── writespec.m      ← X13spec → .spc text (port of x13write.jl)
    ├── parseresult.m    ← output tables → result struct (port of x13result.jl)
    ├── x13consts.m      ← option/keyword constants
    └── runbinary.m      ← system() invocation + temp-dir management
```

Representation choices:
- **Specs as structs, not classes.** Each section builder (`tse.x13.x11(...)`)
  takes name–value pairs and returns a struct; `newspec`/assembly stores them
  in an `X13spec` struct (field per section). This mirrors Julia's
  keyword-constructor feel without 20 classdef files, and matches our
  free-function style. (`!`-mutating Julia variants collapse to plain
  reassignment in MATLAB.)
- **Results as a struct (optionally lazy).** Parse the produced tables
  (`d10` seasonal factors, `d11` seasonally adjusted, `d12` trend, `d13`
  irregular, plus diagnostics) into TSeries fields. Lazy-loading
  (`X13ResultWorkspace`) is an optimisation we can defer; eager parse of the
  requested `save=` tables is fine for the MVP.

### 4.4 Phasing — ship an MVP, then broaden

The full ~250–300 options are not worth porting up front. Stage it:

- **C1 — Infrastructure + smallest useful path.** Binary location/invocation
  (`findbinary`/`setbinary`/`runbinary`, temp-dir mgmt, `cleanup`), `newspec`,
  `series`, and **one** adjustment path (`x11`) end-to-end: write `.spc`, run,
  parse the core SA tables (`d10`/`d11`/`d12`/`d13`) into TSeries. Plus
  `deseasonalize` for the 80% case. **This delivers usable seasonal adjustment.**
- **C2 — Modelling breadth.** `transform`, `arima`, `automdl`, `regression`,
  `outlier`, `forecast`, `estimate`, `seats`. Covers essentially all routine
  SA work.
- **C3 — Diagnostics & long tail.** `check`, `history`, `identify`,
  `slidingspans`, `spectrum`, `force`, `pickmdl`, `metadata`,
  `x11regression`; richer result parsing; lazy result workspace; full option
  coverage and validation against `x13consts`.

### 4.5 Tests

X13 tests require the binary, so they must be **conditionally skipped** when no
binary is present (`assumeFail`/`assumeTrue` in `matlab.unittest`). Port
`test_x13*.jl` into `tests/TestX13Spec.m` (spec→`.spc` text, no binary needed —
pure string comparison, runs everywhere) and `tests/TestX13Run.m` (end-to-end,
skipped without a binary). The spec-writer tests are the high-value,
always-runnable ones.

### 4.6 Risks

- **Binary distribution/availability** is the dominant risk (§4.2). The
  conditional-skip test strategy and the `install` helper mitigate it.
- **Scope creep:** ~20 sections × many options. The MVP-first phasing is the
  control here — resist porting C3 until C1/C2 are proven.
- **Output-format drift** between X‑13 versions; pin/document a known-good
  Census build and parse defensively.
- **Cross-platform `system()` quoting** and temp-dir handling; centralise in
  `runbinary.m`.

---

## 5. Cross-cutting concerns

- **Naming/namespacing.** `fconvert` and `plot` live at the package top level
  (`tse.fconvert`, plus `plot` methods); `x13` gets its own subpackage
  `+tse/+x13/` because of its size.
- **Frequency-as-value.** Everywhere Julia passes a `Frequency` *type*, we
  accept a frequency instance or int code, consistent with existing `tse.MIT`.
- **Error IDs.** Reuse the existing hierarchy (`tseries:noMatch`,
  `tseries:mixedFreq`, `tseries:bounds`, `tseries:dimMismatch`) and add
  `tseries:x13` for binary/spec failures.
- **Docs.** Update `README.md` and `+tse/Contents.m`; mark the original
  `PLAN.md` non-goals (lines ~29–33, §13.7) as superseded by this document.
- **Benchmarks.** Add `fconvert` scenarios (e.g. daily→monthly mean,
  quarterly→monthly const) to `benchmarks/run_benchmarks.m` once A2/A3 land.

---

## 6. Open decisions to confirm before starting

1. **`fconvert` holiday support** — defer to phase A4 (recommended) or require
   it in the first cut? Original plan deferred holiday calendars.
2. **`x13` binary strategy** — user-supplied path + optional `install()`
   downloader (recommended), vs. bundling binaries in-repo.
3. **`x13` scope target** — commit to the MVP (C1) first and reassess, vs.
   plan straight through to full coverage (C3).
4. **Plotting fidelity** — match the Julia `⁺` non-aligned tick marker and
   exact attribute names, or adopt MATLAB-idiomatic name–value args and a
   `datetime` ruler (recommended) and document the differences.
5. **Result laziness for `x13`** — eager parse of requested tables (recommended
   for MVP) vs. porting the lazy `X13ResultWorkspace`.

---

*End of extension plan.*
