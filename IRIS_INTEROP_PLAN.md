# IRIS interop plan

A staged plan for letting projects use **TimeSeriesEcon.m** and the **IRIS
Toolbox** (2015 vintage, `tseries` class) side by side during a migration.

The plan has two parts:

1. **Conversion utilities** — round-trip data between IRIS `tseries` / IRIS date
   doubles / IRIS struct-databases and `tse.TSeries` / `tse.MIT` /
   `tse.MVTSeries` / `struct`.
2. **Namespace conflicts** — what actually clashes, and how to keep mixed
   scripts unambiguous.

## Goals

- **Lossless round-trip** for every common frequency (Yearly, HalfYearly,
  Quarterly, Monthly, Weekly, Daily, BDaily).
- **Zero hard dependency** on IRIS: the interop subpackage lives in
  `+tse/+iris/`, only checks for IRIS at *call* time, and the rest of the
  package keeps working unchanged when IRIS is absent.
- **Predictable behaviour** when both packages are on the path: callers always
  know which library a `qq(2020,1)` resolves to.
- **Documented in one place** (`docs/design/iris_interop.md`) with a small
  migration cookbook.

## Non-goals

- Re-implementing IRIS model/estimation code in MATLAB — out of scope.
- Sub-quarterly-on-yearly endperiod quirks that IRIS itself does not model
  (IRIS yearly has no `endMonth`; we always assume calendar year, see below).
- A wrapper that lets unmodified IRIS code call `tse.TSeries` transparently.
  We provide explicit converters, not type-emulation.

---

## 1. Conversion utilities

### File layout

```
+tse/+iris/
  Contents.m              package overview
  from_tseries.m          IRIS tseries  -> tse.TSeries / tse.MVTSeries
  to_tseries.m            tse.TSeries / tse.MVTSeries -> IRIS tseries
  from_date.m             IRIS date double -> tse.MIT
  to_date.m               tse.MIT -> IRIS date double
  from_range.m            IRIS date vector -> tse.MITRange
  to_range.m              tse.MITRange -> IRIS date vector
  from_db.m               struct of IRIS tseries -> struct of tse.TSeries
  to_db.m                 struct of tse.TSeries -> struct of IRIS tseries
  freq_to_iris.m          tse.Frequency -> IRIS freq code (1, 2, 4, 12, ...)
  freq_from_iris.m        IRIS freq code -> tse.Frequency
  isavailable.m           true iff IRIS is on the path
  startup.m               optional: addpath + irisstartup helper
```

All conversion functions live under `tse.iris.*`. Nothing else in `+tse/` knows
or cares whether IRIS is installed.

### Date conversions

IRIS encodes a date as a single `double` (a year + period offset + a frequency
marker fraction). `tse.MIT` is a value class holding an integer frequency code
and an integer ordinal.

| `tse.iris.from_date(d)` | `tse.iris.to_date(m)` |
|---|---|
| Read IRIS `dat2ypf(d)` → `(year, period, freq)`. | Dispatch on `frequencyof(m)` to the matching IRIS constructor. |
| Map `freq` → tse class (`freq_from_iris`). | `mit2yp(m)` → `(y, p)`. |
| Build via `tse.MIT(F, y, p)` (or `tse.day`/`tse.bday` for calendar freqs). | `qq(y,p)` / `mm(y,p)` / `yy(y)` / `ww(y,p)` / `dd(y,m,d)`. |

`from_range` / `to_range` are thin wrappers over the per-date converters: an
IRIS range is just `first:last`, while `tse.MITRange` is `start:stop`.

### Series conversions

`from_tseries(ts)`

- Single column → `tse.TSeries(start, ts.Data)` where `start = from_date(get(ts,'start'))`.
- Multi column → `tse.MVTSeries(start, comments, ts.Data)` with `comments` from
  the `Comment` property (filled with `"col1"…"colN"` when blank).
- Preserve numeric type (IRIS allows non-`double` data).
- `NaN`s are passed through unchanged — that is how missing values look on both
  sides.

`to_tseries(t)`

- `tse.TSeries`     → `tseries(to_date(t.firstdate), t.values)`.
- `tse.MVTSeries`   → `tseries(to_date(t.firstdate), t.values, '', cellstr(t.colnames))`.
- Element type passes through.

### Database conversions

`from_db(d)` walks the input `struct`, converting each field that is an IRIS
`tseries` and copying everything else by reference. `to_db` is the inverse.
Both preserve field order and ignore non-series fields (matching what the IRIS
`dbfun` family does).

### Frequency mapping

| IRIS code | tse class                     | Notes                                                |
|----------:|-------------------------------|------------------------------------------------------|
| 1         | `tse.Yearly(12)`              | IRIS has no `endMonth`; we always pick calendar year |
| 2         | `tse.HalfYearly(6)`           | Calendar half-year                                   |
| 4         | `tse.Quarterly(3)`            | Calendar quarter                                     |
| 12        | `tse.Monthly()`               |                                                      |
| 52        | `tse.Weekly(7)`               | ISO-week convention on both sides                    |
| 365       | `tse.Daily()`                 |                                                      |
| (260)     | `tse.BDaily()`                | IRIS lacks a native BDaily; `to_tseries` errors with a clear message |
| 0         | `tse.Unit()`                  |                                                      |

`endMonth` / `endPeriod` mismatches (e.g. a `tse.Yearly(6)` fiscal year) are
reported with a warning at convert time. The user can `fconvert` to a calendar
year first if they need a clean round-trip.

### Edge cases

- **BDaily**: IRIS 2015 has no business-day frequency; `to_tseries` on a BDaily
  series errors with a "convert to Daily first" message. `from_tseries` never
  produces BDaily.
- **Weekly**: both sides nominally use ISO weeks; tests cover the
  end-of-year-53 edge case explicitly.
- **Empty series**: round-trip an empty `tseries` → length-0 `tse.TSeries` at
  the same start date.
- **Multi-column with duplicate / empty `Comment`**: fill with `col1…colN`,
  warn once.

### Performance

The converters are O(n) array copies plus the date-class plumbing. Two
optimisations worth doing if profiling demands:

1. Bulk-build `tse.MITRange` from the IRIS date vector in one call rather than
   per-element (the integer code arithmetic is monotone).
2. `to_db` / `from_db` reuse a single `tse.Frequency` instance across series of
   the same freq.

---

## 2. Namespace conflicts

### What actually clashes

MATLAB rules: package functions (`tse.qq`) and class methods (`TSeries.shift`)
never collide with unrelated top-level functions on the path. The only
collisions to worry about are **bare names** used by both libraries.

| Name(s)                                    | IRIS                  | tse                                | Real conflict? |
|--------------------------------------------|-----------------------|------------------------------------|----------------|
| `qq`, `mm`, `yy`, `ww`, `hh`, `dd`, `zz`   | top-level functions   | `tse.qq` etc. (namespaced)         | **Only under `import tse.*`** |
| `tseries`                                  | top-level class       | `tse.TSeries` (different case + ns)| No             |
| `convert`                                  | top-level function    | `tse.fconvert`                     | No             |
| `dboverlay`, `dbmerge`                     | top-level functions   | `tse.overlay`                      | No             |
| `dbcompare`                                | top-level function    | `tse.compare`                      | No             |
| `dbfun`, `dbquery`, `dbsave`, `dbload`     | top-level functions   | (none)                             | No             |
| `range`                                    | tseries method        | `tse.rangeof` + MITRange method    | Method dispatch resolves it |
| `shift`, `diff`, `pct`, `apct`, `cumsum`   | tseries methods       | TSeries/MVTSeries methods          | Method dispatch resolves it |
| `mean`, `std`, `var`, `min`, `max`, `cov`, `corr` | tseries methods + MATLAB | TSeries/MVTSeries methods   | Method dispatch resolves it |
| `movavg`, `movsum`                         | tseries methods       | `moving_average`, `moving_sum` methods | Different names, no conflict |

### Why method dispatch covers most of it

Calls of the form `shift(t, -1)` dispatch by the class of `t`. If `t` is an
IRIS `tseries`, MATLAB finds `@tseries/shift.m`. If `t` is a `tse.TSeries`, it
finds `tse.TSeries.shift`. **The bare verbs only resolve to a particular
library once you pick a receiver.** No collision.

The same is true for arithmetic operators (`+ - .* ./`), reductions, and any
other operation whose first argument is the series itself.

### The bare-helper problem

`qq(2020,1)` has no receiver to dispatch on. With both libraries on the path:

- **Default** (no `import`): MATLAB resolves `qq` against the path order →
  whichever package is **first on the path** wins. IRIS installs typically run
  `irisstartup` which does `addpath(genpath(IRIS))` first, so `qq` → IRIS.
- **`import tse.*`**: the bare name `qq` is rebound to `tse.qq` for the rest
  of the function scope, **shadowing IRIS**. A bare `qq(2020,1)` then returns
  a `tse.MIT`, not an IRIS date double.

This is the only sharp edge.

### Resolution strategy

We recommend three guard-rails, in order of strength:

1. **Prefer explicit prefixes in mixed code.** Always write `tse.qq(2020,1)`
   or `iris_qq = @qq; iris_qq(2020,1)` when both libraries are loaded.
   Document this in `docs/design/iris_interop.md` as the *one* rule users have
   to remember.
2. **Don't `import tse.*` in scripts that also call IRIS.** It silently
   shadows the IRIS date helpers. Use `import tse.TSeries` / `import tse.MVTSeries`
   for the class names only.
3. **Use the converters at the boundary.** Within a function, work in one
   library's types end-to-end. Convert with `tse.iris.from_db(d)` once on entry
   and `tse.iris.to_db(d)` once on exit. The bare-helper problem then never
   appears in the middle of the code.

### A conflict-checker

Add `tse.iris.check_conflicts()` (a few lines): it walks `path()`, looks for
the bare names above (`which qq -all`), and prints a warning per shadowed
name. Cheap, run once at session start. Output looks like:

```
qq:  /home/user/IRIS_Tbx_20150318/dates/qq.m   (shadows +tse/qq.m)
mm:  /home/user/IRIS_Tbx_20150318/dates/mm.m   (shadows +tse/mm.m)
yy:  /home/user/IRIS_Tbx_20150318/dates/yy.m   (shadows +tse/yy.m)
```

The warning is informational, not an error — the path order is correct for
IRIS-first mixed code.

### Documented usage patterns

The interop doc should show three concrete patterns:

- **All-tse function called from an IRIS script.** Caller does
  `t = tse.iris.from_tseries(ts);` then calls the tse function. tse internals
  use `tse.qq`/`tse.mm` explicitly.
- **All-IRIS function called from a tse script.** Caller does
  `ts = tse.iris.to_tseries(t);` then calls the IRIS function. No `import tse.*`.
- **Mixed in-place.** Always qualify date helpers (`tse.qq(...)` /
  `iris_qq = @qq; iris_qq(...)`). Method calls (`shift(t, -1)`,
  `mean(t)`, …) need no qualification because dispatch picks the right class.

---

## Test coverage

A new `tests/TestIrisInterop.m` that:

- **Skips itself cleanly** when IRIS is not on the path
  (`if ~tse.iris.isavailable, return; end`).
- Round-trips one series of each frequency in both directions and asserts
  value-for-value equality.
- Round-trips a 5-field struct database.
- Verifies `from_date`/`to_date` for the first and last period of each
  frequency, plus a few edge dates (Jan 1, Dec 31, week 53 of a 53-week year).
- Calls `tse.iris.check_conflicts()` and asserts it returns the expected list
  of shadowed names when IRIS is loaded.

Mark in the help text and in `TEST_PARITY_REPORT.md` that the suite *requires*
IRIS to actually run; without it the tests are silently skipped.

---

## Phasing

A reasonable rollout order, each phase commit-sized and independently useful:

1. **Bridge primitives** — `freq_to_iris`, `freq_from_iris`, `from_date`,
   `to_date`, `from_range`, `to_range`, `isavailable`. Tests for date round-trips.
2. **Series conversions** — `from_tseries`, `to_tseries`. Tests for one
   series per frequency, with the BDaily error path.
3. **Database conversions** — `from_db`, `to_db`. One round-trip test.
4. **Conflict tooling** — `check_conflicts`, `startup`. Documentation page
   `docs/design/iris_interop.md` covering the three usage patterns above.
5. **Optional**: a `+tse/+iris/+private/` helper that batches per-range
   conversions if profiling shows the per-element path is a hotspot.

Roughly one commit per phase; the whole thing should be a few hundred lines of
MATLAB plus the doc page.
