# DataEcon (.daec) interop: design and verification note

How TimeSeriesEcon.m and the `bankofcanada/DataEcon` MATLAB branch talk to
each other, why the conversion is unusually cheap, and what to watch when
running the tests for the first time.

This is the implementation record. The earlier
[`DATAECON_COMPARISON.md`](DATAECON_COMPARISON.md) is the analysis that
preceded it (should we *build on* DataEcon? — no; treat it as a
serialization target). This note documents the serialization bridge we
actually built.

---

## 1. What was built

Support for TimeSeriesEcon.m in DataEcon, mirroring DataEcon's existing
IRIS interop, split across both repositories exactly as the IRIS support
is (DataEcon owns the reader/writer; `+tse/` owns the convenience package).

### DataEcon side (`matlab/`)

| Location | Addition |
| --- | --- |
| `DAEC.daec_from_tse_date` | `tse.MIT` -> `DEDate` (mirrors `daec_from_iris_date`) |
| `DAEC.tse_date` | `DEDate` -> `tse.MIT` (mirrors `iris_date`) |
| `DAEC.make_tse_series` | axes + data -> `tse.TSeries` / `tse.MVTSeries` (mirrors `make_iris_series`) |
| `DEFile.write` | dispatch `tse.TSeries` / `tse.MVTSeries` -> `store_tseseries` / `store_tsemvseries` |
| `DEFile` + `DAEC.readdb` | `read_to_tse` flag (parallels `read_to_iris`) |
| `matlab/tests/test_tse_dates.m` | date-layer identity + optional libdaec calendar cross-check |
| `matlab/tests/test_tse.m` | file round-trip across every frequency + MVTSeries + default-read regression |

### TSE side (`+tse/+daec/`)

Symmetric with `+tse/+iris/`:

| File | Role |
| --- | --- |
| `isavailable` / `startup` | gate on DataEcon classes being on the path; load libdaec |
| `to_date` / `from_date` | `tse.MIT` <-> `DEDate` |
| `to_range` / `from_range` | `tse.MITRange` <-> range `DEAxis` |
| `to_series` / `from_series` | `tse.TSeries` / `tse.MVTSeries` <-> `DESeries` |
| `to_db` / `from_db` | struct of tse.* <-> struct of `DESeries` (in-memory, field by field) |
| `read` / `write` | `.daec` file <-> struct of tse.* series |
| `tests/TestDaecInterop.m` | 18 round-trip / guard tests (auto-discovered by `runAllTests`) |

---

## 2. The key insight: the conversion is the identity

The IRIS bridge is real work — IRIS has its own frequency codes and date
encoding, so it needs `dat2ypf`, `to_iris` / `from_iris` tables, and ISO-week
juggling. **The DataEcon bridge needs none of that**, because DataEcon *is*
the C backend for TimeSeriesEcon.jl, and this MATLAB port was built to match
it bit-for-bit.

- **Frequency codes are identical.** `+tse/private/freq2int.m` emits exactly
  DataEcon's `frequency_t` enum:

  | Frequency | tse code | DataEcon enum |
  | --- | --- | --- |
  | Unit | 11 | `freq_unit` |
  | Daily | 12 | `freq_daily` |
  | BDaily | 13 | `freq_bdaily` |
  | Weekly(ep) | 16 + ep | `freq_weekly_*` (17..23) |
  | Monthly | 32 | `freq_monthly` |
  | Quarterly(ep) | 64 + ep | `freq_quarterly_*` (65..67) |
  | HalfYearly(ep) | 128 + ep | `freq_halfyearly_*` (129..134) |
  | Yearly(ep) | 256 + ep | `freq_yearly_*` (257..268) |

- **The integer `value` (epoch) is identical.** DataEcon's `src/libdaec/dates.c`
  states its external rata die is `0001-01-01 => 1`, *"the same as Julia's
  standard library Dates.Date"*; `+tse/private/dateToDailyValue.m` uses the
  same epoch (`days since 0000-12-31`). YP frequencies use `value = N*y + p - 1`
  on both sides.

So the whole conversion collapses to:

```
tse.MIT(m.frequency, m.value)  <->  DEDate(m.frequency, m.value)
```

No frequency table, no libdaec round-trip for dates, and the date layer works
even when the native library is not loaded. End-of-period variants survive
because the end period is *in* the frequency integer (e.g. `Quarterly(1)` = 65),
and DataEcon stores that integer verbatim — its enum *aliases* (e.g.
`freq_quarterly_jan` = `freq_quarterly_apr` = 65) never lose information on a
round trip.

---

## 3. Source-level verification of the encoding

Because MATLAB + libdaec could not be run in the environment where this was
written, the encoding was verified by reading both sources rather than by
execution:

- **Frequency table** — `freq2int.m` vs `daecenums.m`: match (table above).
- **Daily epoch** — `dates.c` `EPOCH_ZERO_DAY` comment (`0001-01-01 => 1`) vs
  `dateToDailyValue.m` (`days since 0000-12-31`, so `0001-01-01` = 1): match.
- **Weekly representative day** — DataEcon `_rata_die_from_septem` returns the
  *end-of-week* day (Monday + 6 - O); tse `mitToDate` (weekly, `ref='end'`)
  returns `epoch + val*7 - (7 - endDay)`, also the end-of-week day: structurally
  aligned.
- **YP value** — `de_pack_year_period_date` `_encode_ppy` vs
  `tse.MIT.yp2value` / `mit2yp`: both `N*y + p - 1`, 1-based period: match.

The one assumption that structural reading can *not* fully close is the exact
weekly / bdaily epoch offset (a constant could differ despite the same
end-of-week convention). That is what the libdaec cross-check in
`test_tse_dates.m` exists to confirm at runtime — see §5.

---

## 4. Known limitations and deliberate choices

1. **`to_series` and the DESeries singleton-dimension quirk.** The DataEcon
   `DESeries` constructor counts only dimensions of length > 1, so a length-1
   TSeries or a single-column MVTSeries trips its dimension check. This affects
   only the convenience helper `tse.daec.to_series` (which builds a `DESeries`).
   The **file path does not go through `DESeries`** — `store_tsemvseries` and
   `make_tse_series` build DataEcon axes directly — so `read` / `write` are
   unaffected. Left as-is because it is a pre-existing DataEcon behavior.

2. **Typed values widen through the file.** DataEcon's element types map
   `int8..int32 -> int64` (signed) and unsigned/logical -> `uint64`. A `double`
   series round-trips exactly; an integer/logical series comes back widened.
   The tests therefore assert value equality on `double` series only.

3. **`to_db` / `from_db` are non-recursive**, matching the IRIS versions:
   only top-level struct fields are converted; nested sub-databases pass
   through untouched *at that layer*. Nesting is instead handled by the file
   layer — `write` / `read` recurse through DataEcon catalogs — so a nested
   `.daec` still round-trips into nested tse structs.

4. **No `check_conflicts` analogue.** IRIS needs it because it defines bare
   date helpers (`qq`, `mm`, `yy`, ...) that shadow tse's. DataEcon defines no
   such top-level names, so there is nothing to check.

5. **A bare `tse.MIT` scalar is not writable to `.daec`.** `DEFile.write`
   only special-cases series; a lone MIT falls through to the scalar path,
   which `prepare_scalar` does not recognise. This matches IRIS (a bare IRIS
   date is not writable either) and is out of parity scope. Wrap dates in a
   series if they need to be persisted.

---

## 5. Test inventory and recommended first run

| Suite | Covers | libdaec? |
| --- | --- | --- |
| `DataEcon/matlab/tests/test_tse_dates.m` | MIT<->DEDate identity + round-trip per freq; optional calendar cross-check | date checks: no; cross-check: yes |
| `DataEcon/matlab/tests/test_tse.m` | file round-trip, all frequencies + MVTSeries + end-period alias + default-read regression | yes |
| `TimeSeriesEcon.m/tests/TestDaecInterop.m` | dates, end periods, ranges, series, in-memory db, guards; plus one file round-trip | only `file_db_roundtrip` |

Run in dependency order:

1. **`test_tse_dates.m`** with libdaec loaded. Its calendar cross-check is the
   assertion that pins the **weekly / bdaily epoch** — the highest-risk item in
   the whole integration (see §3). If weekly comes back off by a constant, the
   fix is isolated to the date mapping.
2. **`runAllTests`** in TimeSeriesEcon.m. Everything except `file_db_roundtrip`
   needs only the DataEcon classes on the path; that one skips cleanly unless
   libdaec is loaded.
3. **`test_tse.m`** with libdaec. The full file matrix — watch the MVTSeries
   value orientation (column-major `values(:)` on write, reshaped on read) and
   the weekly rows.

To make the classes and library available in a session:

```matlab
addpath('/path/to/TimeSeriesEcon.m');
tse.daec.startup('/path/to/DataEcon/matlab');   % addpath + DAEC.load()
```

---

## 6. Reference commits

Branch `claude/timeseriesescon-dataecon-integration-os9g2s` on both repos.

| Step | DataEcon | TimeSeriesEcon.m |
| --- | --- | --- |
| 1 — date layer | `560f99e` | `ae643ca` |
| 2 — series read/write | `0a2da61` | `be3ad26` |
| 3 — file / db wrappers | (complete after step 2) | `6253052` |
| 4 — test breadth | `6d9e0ff` | `ef60aa6` |
