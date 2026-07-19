# FAME database interop: design and CHLI lessons

How `+tse/+fame/` reads and writes FAME databases from TimeSeriesEcon.m,
modelled on the Bank of Canada [FAME.jl](https://github.com/bankofcanada/FAME.jl)
package and built directly on the FAME CHLI (C Host Language Interface).

Unlike the IRIS and DataEcon bridges (which wrap MATLAB-level toolboxes),
FAME is reached through its C shared library, so this integration is mostly
a `loadlibrary`/`calllib` binding. Most of the effort — and most of this
note — is about getting that binding right against a library we could only
probe indirectly.

---

## 1. What was built

A `+tse/+fame/` subpackage, same shape as `+tse/+iris/` and `+tse/+daec/`:

| Area | Functions |
| --- | --- |
| Availability | `isavailable`, `startup` |
| Loader | `CHLI` (singleton; owns all `loadlibrary`/`calllib`) |
| Frequency / type mapping | `freq_to_fame`, `freq_from_fame`, `type_to_fame`, `type_from_fame` |
| Dates / ranges | `to_date`, `from_date`, `to_range`, `from_range` |
| Series | `read`, `write`, `read_object`, `write_object` |

`read(db)` with no name list enumerates the whole database.

### Type model

| FAME type | tse form | direction |
| --- | --- | --- |
| precision | `tse.TSeries` of `double` | read + write |
| numeric | `tse.TSeries` of `single` | read + write |
| boolean | `tse.TSeries` of `logical` | read + write |
| string | `string` array (no time axis) | read only |
| date | `tse.MIT` array (no time axis) | read only |

`tse.TSeries` accepts only numeric/logical values, so string- and
date-valued series have no `TSeries` form; they read back as bare arrays
(as FAME.jl also drops the time axis for strings). Low-level
`CHLI.write_strings` / `CHLI.write_dates` exist for writing them with an
explicit range. **MVTSeries has no FAME equivalent and is out of scope.**

---

## 2. Architecture: classic + modern, split as FAME.jl splits it

The FAME CHLI has two generations of entry points, with **two different
calling conventions**, and FAME.jl uses both. We follow the same split:

- **classic `cfm*`** — `void`, status reported through the **first**
  argument (`int *status`, 0 == `HSUCC`). Used for the database lifecycle
  and object creation: `cfmini`, `cfmopdb`, `cfmopwk`, `cfmpodb`, `cfmcldb`,
  `cfmnwob`, `cfmferr`. Wrapped by `CHLI.raw_call`.
- **modern `fame_*`** — the `int` **return value** is the status. Used for
  metadata, date⇄index conversion, series data, and enumeration:
  `fame_quick_info`, `fame_year_period_to_index`, `fame_index_to_year_period`,
  `fame_get_*` / `fame_write_*`, `fame_*_wildcard`. Wrapped by `CHLI.fame_call`.

`CHLI.load` points `loadlibrary` at the **real** `$FAME/hli/hli.h`, so the
signatures and the `fame_range` struct come from the vendor header;
`private/chli.h` is documentation only. Series ranges are passed as a
`libstruct('fame_range')` — `{ int32 r_freq; int64 r_start; int64 r_end; }`.

Two MATLAB mechanics that this binding depends on (both validated on a real
CHLI):
- `calllib` updates a passed `libpointer`'s `.Value` in place — so wrappers
  pass pointers and read `.Value` afterward rather than juggling return
  ordering.
- `char**` is marshalled via `libpointer('stringPtrPtr', cellstr)`.

---

## 3. Frequencies, dates, missing values

- **Frequencies** (`freq_to_fame`): daily=8, business=9, weekly Sun=16 /
  Mon..Sat=17..22, monthly=129, quarterly=160..162, semiannual=204..209,
  annual=192..203, case=232. End periods are carried through. FAME-only
  frequencies (tenday, biweekly, sub-daily, …) are rejected.
- **Dates.** A series' range is `(first_index, last_index)` from
  `fame_quick_info`. Endpoints convert through `fame_year_period_to_index` /
  `fame_index_to_year_period` using tse's `(year, period)` = `mit2yp`. This
  is self-consistent: `write` sends `mit2yp(m)`, `read` rebuilds
  `tse.MIT(F, y, p)`, and the two are inverses — including **weekly**, where
  tse's week numbering happens to match FAME's exactly (checked against the
  CHLI; `weekly_from_iso` is a *different* convention and is NOT used here).
- **Missing values.** FAME uses finite sentinel doubles/floats (`FPRCNC`,
  `FNUMNC`, and the NA/ND variants), not `NaN`. They are `extern` globals —
  **MATLAB's `loadlibrary` cannot read library globals** (Julia reads them
  via `cglobal`), so their exact bit patterns are recorded in
  `fame_constants`. Write maps `NaN → NC`; read maps any of NC/NA/ND → `NaN`
  by vectorized equality (finite ⇒ exact).

---

## 4. CHLI lessons (the debugging trail)

Every one of these cost a round-trip against a real FAME install; they are
the load-bearing, non-obvious facts of this binding.

1. **`loadlibrary` reads the vendor `hli.h`.** Our hand-written prototype
   header was abandoned once the real header was on `$FAME/hli`.
2. **`cfmnwob` observed for float series.** Creating a precision/numeric
   series with `observed = HOBUND` (undefined) fails with `HBOBSV` (27).
   FAME.jl uses `observed = summed` for floats, undefined for non-floats;
   we match that.
3. **`cfmrrng` / `cfmwrng` are header macros, not exported symbols.** The
   callable symbols are `cfmrrng_f` / `cfmwrng_f` (later dropped for the
   modern readers/writers).
4. **Hand-built classic ranges fail (`HBRNG`, 14).** The classic range
   array must be built by `cfmsrng`, not assembled by hand. This pushed the
   whole series layer onto the modern `fame_*` API, which is what FAME.jl
   uses anyway (and gives first/last **index** directly, no `cfmwhat` +
   `cfmsrng`).
5. **Two calling conventions** — classic status-first vs modern
   status-return — need two wrappers (`raw_call`, `fame_call`).
6. **Missing values are globals, unreadable from MATLAB** — hence the
   recorded bit patterns. They are finite, so equality comparison is exact.
7. **FAME names are case-insensitive**; enumeration returns them (often
   upper-cased), so `read` lower-cases before making struct field names.
8. **Enumeration** uses the `?` wildcard (matches any name) and stops when
   `fame_get_next_wildcard` returns `HNOOBJ` (13).
9. **A date-valued series stores its value frequency in the `type`
   field** (so `type` is a frequency code, e.g. 162, not `HDATE`). That is
   how `read_object` tells a date series from a normal one.
10. **`tse.TSeries` is numeric/logical only** — strings and dates are bare
    arrays.

`CHLI.status_name` maps the numeric status codes to their `H*` names so
future errors read e.g. `error 14 (HBRNG)` instead of a bare number.

---

## 5. Setup and tests

```matlab
addpath('/path/to/TimeSeriesEcon.m');
tse.fame.startup();            % loads libchli/chli from $FAME/hli via loadlibrary
```

`startup` picks the platform library name; the CHLI must be on the system
library path and `$FAME` set (the licensing/header location).

| Suite | Needs the CHLI? |
| --- | --- |
| `tests/TestFameMapping.m` | no (pure frequency/type mapping) |
| `tests/TestFameDates.m` | yes (date/range round-trips) |
| `tests/TestFameSeries.m` | yes (precision, numeric, missing, annual, enumeration, multi-frequency incl. weekly, boolean, string, date) |

`TestFameMapping` always runs; the CHLI-backed suites skip cleanly when the
library is not loaded.

---

## 6. Reference commits

Branch `claude/timeseriesecon-fame-integration`.

| Step | Commits |
| --- | --- |
| Frequency / type mapping | `20da2ec` |
| CHLI loader + dates | `548e53c`, `15c8cd1` |
| Series I/O (classic, then re-based on modern `fame_*`) | `54d817c`, `8e4cbe5`, `be4d5d4`, `513b81d`, `e80d812` |
| Missing values + enumeration | `37ce738`, `356fede`, `42ef159`, `92a7f74` |
| Boolean / string / date types, weekly | `6924915`, `f041703`, `eb5c582` |
