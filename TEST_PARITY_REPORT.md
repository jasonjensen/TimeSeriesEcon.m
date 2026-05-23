# Test Coverage Parity Report: TimeSeriesEcon.jl → MATLAB

This report compares the test coverage between the Julia `TimeSeriesEcon.jl/test/` suite and the MATLAB `tests/` folder to identify gaps, equivalences, and intentional omissions.

## Summary

| Julia Test File | MATLAB Equivalent(s) | Status |
|---|---|---|
| `test_mit.jl` | `TestMIT.m`, `TestDates.m`, `TestDuration.m`, `TestRange.m` | ✅ Fully covered |
| `test_tseries.jl` | `TestTSeriesConstruct.m`, `TestTSeriesIndex.m`, `TestTSeriesArithmetic.m`, `TestShiftLagLead.m`, `TestPctApct.m`, `TestOverlay.m`, `TestStripAndReindex.m`, `TestRec.m`, `TestIsassigned.m`, `TestFindAll.m` | ✅ Mostly covered |
| `test_mvtseries.jl` | `TestMVTSeriesConstruct.m`, `TestMVTSeriesIndex.m`, `TestMVTSeriesMath.m`, `TestMVTSeriesHcatRename.m`, `TestMVTSeriesOverlay.m` | ✅ Mostly covered |
| `test_various.jl` | `TestLinalg.m`, `TestFindAll.m`, `TestMVTSeriesOverlay.m`, `TestMisc.m` | ✅ Fully covered |
| `test_fconvert.jl` | `TestFconvert.m`, `TestFconvertExtra.m`, `TestFconvertFAME.m` | ✅ Fully covered |
| `test_business.jl` | `TestFconvertHolidays.m`, `TestShiftLagLead.m` | ⚠️ Partially covered |
| `test_22.jl` | (issue-specific tests) | ⚠️ Partially covered |
| `test_workspace.jl` | — | ❌ Not applicable |
| `test_serialize.jl` | — | ❌ Not applicable |
| `test_dataecon.jl` | — | ❌ Not applicable |
| `test_fconvert_vs_fame.jl` | `TestFconvertFAME.m` | ✅ Covered differently |
| `test_x13spec.jl` | — | ❌ Excluded (x13) |
| `test_x13run.jl` | — | ❌ Excluded (x13) |

---

## Detailed Comparison by Julia Test File

### 1. `test_mit.jl`

This file tests MIT (Moment-In-Time) construction, arithmetic, comparisons, ranges, frequencies, display, dates, weekly, and business-daily constructors.

| Julia `@testset` | MATLAB Equivalent | Parity | Notes |
|---|---|---|---|
| `"MIT,Duration"` — mit2yp conversions | `TestMIT.m` — `mit2yp_quarterly_*` | ✅ Full | 7 Julia cases → 7 MATLAB methods |
| `"MIT,Duration"` — subtractions | `TestMIT.m` — `subtract_*` | ✅ Full | All type/error tests ported |
| `"MIT,Duration"` — equality | `TestMIT.m` — `equal_*`, `unequal_*`, `int_equals_*` | ✅ Full | |
| `"MIT,Duration"` — order | `TestMIT.m` — `lt_*`, `le_*`, `duration_lt_*` | ✅ Full | |
| `"MIT,Duration"` — addition | `TestMIT.m` — `add_*`, `plus_*` | ✅ Full | |
| `"MIT,Duration"` — float conversions | `TestMIT.m` — `plus_float_returns_float` | ✅ Partial | Julia tests `1.2 + 5U` etc; MATLAB tests float addition |
| `"MIT,Duration"` — promotions | — | ❌ N/A | Julia-specific type promotion system |
| `"MIT,Duration"` — custom frequencies | `TestDuration.m` — `div_rem_basic` | ✅ Partial | Julia tests `YPFrequency{5}` custom; MATLAB tests div/rem |
| `"MIT,Duration"` — hash/Dict | — | ❌ N/A | Julia-specific; MATLAB uses containers.Map differently |
| `"Range"` | `TestRange.m` | ✅ Full | Basic ranges, step ranges, `rangeof_span`, mixed-freq errors |
| `"FPConst"` — frequency-period literal syntax | `TestMIT.m` — `mm_qq_yy_raw` | ✅ Full | Literal syntax differs but equivalent constructors tested |
| `"MITops"` | `TestMIT.m` — `yearly_plus_int`, `quarterly_diff`, etc. | ✅ Full | |
| `"MIT.show"` — display formatting | — | ❌ N/A | Julia `show`/`IOBuffer` patterns; MATLAB has `disp` implicitly |
| `"frequencyof"` | `TestMIT.m` — `frequencyof_*` | ✅ Full | |
| `"constructors"` — shorthand, frequency predicates | `TestMIT.m` — `frequency_is_predicates`, `constructor_validation_throws` | ✅ Full | |
| `"mm, qq, yy"` | `TestMIT.m` — `mm_qq_yy_raw` | ✅ Full | |
| `"year, period"` | `TestMIT.m` — `year_period_*` | ✅ Full | |
| `"daily, business_daily"` | `TestDates.m` — all 12 methods | ✅ Full | Daily/BDaily creation, bias modes, ranges |
| `"issue #45"` — negative year BDaily | — | ⚠️ Partial | Edge case for negative dates; may not be relevant in MATLAB |
| `"Weekly"` | `TestDates.m` — `weekly_basic`, `weekly_from_iso_examples` | ✅ Full | |
| `"Dates"` — MIT↔Date conversions | `TestDates.m` — `date_round_trip` | ✅ Full | |
| `"ppy"` | `TestMIT.m` — `ppy_values` | ✅ Full | |
| `"endperiod"` | `TestMIT.m` — `endperiod_values` | ✅ Full | |
| `"sanitize_frequency"` | `TestMIT.m` — `sanitize_frequency_default_inst` | ✅ Full | |

### 2. `test_tseries.jl`

| Julia `@testset` | MATLAB Equivalent | Parity | Notes |
|---|---|---|---|
| `"TSeries"` — constructors | `TestTSeriesConstruct.m` | ✅ Full | 14 MATLAB methods cover all construction modes |
| `"TSeries"` — indexing (int, MIT, out-of-bounds) | `TestTSeriesIndex.m` | ✅ Full | 18 methods cover all modes |
| `"TSeries"` — auto-grow on assignment | `TestTSeriesIndex.m` — `assign_grows_*` | ✅ Full | |
| `"TSeries"` — `rangeof` with `drop` | `TestTSeriesConstruct.m` — `rangeof_with_drop` | ✅ Full | |
| `"TSeries"` — `fill`, `zeros`, `ones` | `TestTSeriesConstruct.m` — `from_range_scalar_fill`, `fill_with_function_initializer` | ✅ Full | |
| `"Bcast"` — broadcast arithmetic | `TestTSeriesArithmetic.m` | ✅ Full | MATLAB uses operator overloading instead of `.+` syntax |
| `"Bcast"` — range intersection on addition | `TestTSeriesArithmetic.m` — `plus_two_tseries_intersection`, `plus_partial_overlap` | ✅ Full | |
| `"Bcast"` — frequency mismatch errors | `TestTSeriesArithmetic.m` — `mixed_freq_throws` | ✅ Full | |
| `"Bcast"` — step-range indexing assignment | — | ⚠️ Partial | Julia has extensive step-range broadcast tests; MATLAB coverage is basic |
| `"Bcast"` — BitArray/Bool TSeries indexing | `TestFindAll.m` — `getindex_with_logical_tseries`, `setindex_with_logical_tseries` | ✅ Full | |
| `"TSeries 1"` — property accessors | `TestTSeriesConstruct.m` — `firstdate_lastdate_length` | ✅ Full | |
| `"Int indexing"` | `TestTSeriesIndex.m` — `int_indexing_scalar`, `int_range_returns_numeric_vec`, `int_vec_indexing`, `int_assignment` | ✅ Full | |
| `"Bool indexing"` | `TestFindAll.m` | ✅ Full | |
| `"Views"` | — | ❌ N/A | Julia `view()`/SubArray semantics; MATLAB doesn't have equivalent |
| `"show"` — display | — | ❌ N/A | Julia formatting tests |
| `"math"` — arithmetic, min/max | `TestTSeriesArithmetic.m` — `reductions_match_underlying`, `scalar_times_tseries` | ✅ Full | |
| `"Monthly"` — bounds errors | `TestTSeriesIndex.m` — `bounds_check_mit` | ✅ Partial | Julia tests are per-frequency; MATLAB combines them |
| `"Quarterly"` — bounds errors | `TestTSeriesIndex.m` | ✅ Partial | Same as above |
| `"Yearly"` — bounds errors | `TestTSeriesIndex.m` | ✅ Partial | Same as above |
| `"Setting"` — assignment with resize | `TestTSeriesIndex.m` — `assign_grows_*`, `resize_keeps_old_data` | ✅ Full | |
| `"Addition"` — range intersection | `TestTSeriesArithmetic.m` — `plus_two_tseries_intersection` | ✅ Full | |
| `"Iris"` — assignment from other TSeries | `TestTSeriesIndex.m` — `assign_range_to_vector`, `assign_range_to_scalar` | ✅ Full | |
| `"TS.math"` — lag, lead, cumsum | `TestShiftLagLead.m`, `TestTSeriesArithmetic.m` — `cumsum_keeps_range` | ✅ Full | |
| `"axes.range"` | `TestMisc.m` — `axes1_returns_range` | ✅ Full | |
| `"overlay"` | `TestOverlay.m` — all 4 methods | ✅ Full | |
| `"strip"` | `TestStripAndReindex.m` — `strip_trims_leading_and_trailing_nans` | ✅ Full | |
| `"recursive"` | `TestRec.m` — `fibonacci`, `quarterly_series` | ✅ Full | |
| `"various"` — compare | `TestMisc.m` — `compare_mvts_different_ranges` | ✅ Full | |
| `"various"` — reindex | `TestStripAndReindex.m` — `reindex_tseries`, `reindex_single_mit` | ✅ Full | |
| `"pct"` | `TestPctApct.m` — all 8 methods | ✅ Full | |
| `"isassigned"` | `TestIsassigned.m` — all 6 methods | ✅ Full | |

### 3. `test_mvtseries.jl`

| Julia `@testset` | MATLAB Equivalent | Parity | Notes |
|---|---|---|---|
| `"MV construct"` | `TestMVTSeriesConstruct.m` — 13 methods | ✅ Full | All construction modes covered |
| `"MV Int Ind"` — integer indexing | `TestMVTSeriesIndex.m` — `int_indexing`, `row_by_int` | ✅ Full | |
| `"MV dot"` — dot-notation access | `TestMVTSeriesIndex.m` — `dot_returns_tseries`, `dot_assign_*` | ✅ Full | |
| `"MV"` — comprehensive MIT+Symbol indexing | `TestMVTSeriesIndex.m` — `pair_indexing_*`, `range_indexing_*`, `range_assign` | ✅ Full | |
| `"MV"` — `hcat` | `TestMVTSeriesHcatRename.m` — `hcat_single`, `hcat_two` | ✅ Full | |
| `"MV views"` | — | ❌ N/A | Julia `view()` semantics |
| `"MV bool access"` | `TestFindAll.m` — `find_mvts_logical` | ✅ Partial | Julia tests extensive bool access; MATLAB covers core case |
| `"MVTSeries show"` | — | ❌ N/A | Display formatting |
| `"MV bcast"` — broadcast arithmetic | `TestMVTSeriesMath.m` — `plus_two_mvts`, `plus_with_offset_range`, `scalar_times`, etc. | ✅ Full | |
| `"MV bcast"` — MVTSeries+TSeries broadcast | `TestMVTSeriesMath.m` — `plus_with_tseries` | ✅ Full | |
| `"MV bcast"` — step-range broadcast assignment | — | ⚠️ Partial | Extensive Julia step-range tests not directly mirrored |
| `"MV bcast"` — BroadcastStyle internals | — | ❌ N/A | Julia broadcast infrastructure tests |

### 4. `test_various.jl`

| Julia `@testset` | MATLAB Equivalent | Parity | Notes |
|---|---|---|---|
| `"linalg"` — adjoint, `/`, `\`, `*` | `TestLinalg.m` — all 7 methods | ✅ Full | |
| `"findall"` — TSeries/MVTSeries | `TestFindAll.m` — all 4 methods | ✅ Full | |
| `"overlay2"` — MVTSeries overlay | `TestMVTSeriesOverlay.m` — 2 methods | ✅ Full | |
| `"misc"` — parent, transpose, compare, axes1 | `TestMisc.m` — all 7 methods | ✅ Full | |

### 5. `test_fconvert.jl`

This is the largest test file (~1400+ lines). It tests frequency conversion extensively.

| Julia `@testset` | MATLAB Equivalent | Parity | Notes |
|---|---|---|---|
| `"fconvert, general"` — same freq noop, direction errors, basic conversions | `TestFconvert.m` — `general` | ✅ Full | |
| `"fconvert, YPFrequencies, to higher"` — const disaggregation, linear interpolation, even distribution | `TestFconvert.m` — `yp_to_higher` | ✅ Full | |
| `"fconvert, YPFrequencies, to lower"` — mean/sum/point/begin/end | `TestFconvert.m` — `yp_to_lower` | ✅ Full | |
| `"fconvert, YPFrequencies, to similar"` | `TestFconvert.m` — `yp_to_similar` | ✅ Full | |
| `"fconvert, Weekly to lower"` — Monthly/Quarterly/Yearly, discrete+linear methods | `TestFconvert.m` — `weekly_to_monthly_chained`; `TestFconvertFAME.m` — `fconvert_Weekly_to_lower` | ✅ Full | |
| `"fconvert, Weekly to daily"` | `TestFconvertFAME.m` — `fconvert_Weekly_to_daily` | ✅ Full | |
| `"fconvert, Weekly to BDaily"` | `TestFconvertFAME.m` — `fconvert_Weekly_to_BDaily` | ✅ Full | |
| `"fconvert, Daily to Weekly"` | `TestFconvertFAME.m` — `fconvert_Daily_to_Weekly` | ✅ Full | |
| `"fconvert, Daily to Monthly"` | `TestFconvert.m` — `daily_to_monthly` | ✅ Full | |
| `"fconvert, Daily to Quarterly"` | `TestFconvertFAME.m` — `fconvert_Daily_to_Quarterly` | ✅ Full | |
| `"fconvert, Daily to Yearly"` | `TestFconvertFAME.m` — `fconvert_Daily_to_Yearly` | ✅ Full | |
| Range conversions (MIT→lower/higher range) | `TestFconvert.m` — `range_conversions` | ✅ Full | |
| Custom function argument | `TestFconvert.m` — `custom_function`; `TestFconvertExtra.m` — `pass_custom_function` | ✅ Full | |
| All-combinations round-trip | `TestFconvertExtra.m` — `all_combinations` | ✅ Full | |

### 6. `test_fconvert_vs_fame.jl`

| Julia Test | MATLAB Equivalent | Parity | Notes |
|---|---|---|---|
| FAME-based automated validation of fconvert across all frequency pairs | `TestFconvertFAME.m` — 12 methods with comprehensive coverage | ✅ Covered differently | Julia uses FAME.jl package directly; MATLAB has pre-computed expected values |

### 7. `test_business.jl`

| Julia `@testset` | MATLAB Equivalent | Parity | Notes |
|---|---|---|---|
| `"BDaily"` — basic shift/diff/lag/pct with `skip_all_nans` | `TestShiftLagLead.m` — shift/lag/lead basic tests | ⚠️ Partial | Julia tests NaN-skipping business-daily ops extensively |
| `"BDaily"` — holidays map (custom map, shift/diff/lag with holidays) | `TestFconvertHolidays.m` — `load_map`, `skip_holidays_runs` | ⚠️ Partial | Core holiday loading tested; detailed shift/diff/pct with holidays less extensive |
| `"BDaily"` — `cleanedvalues` function | — | ⚠️ Gap | Julia tests `cleanedvalues()` with `skip_holidays`/`skip_all_nans`; not directly tested in MATLAB |
| `"BDaily statistics"` — mean/std/var/median/quantile/cov/cor with `skip_all_nans`/`skip_holidays` | — | ⚠️ Gap | Julia has extensive statistical tests on BDaily data; MATLAB has `TestMoving.m` but not these specific BDaily statistics |
| `"BDaily options"` — error handling for invalid holidays | `TestFconvertHolidays.m` — `options_listing` | ✅ Partial | |
| `"BDaily"` — `fconvert(Monthly, bdaily_range)` with holidays | `TestFconvertHolidays.m` — `skip_holidays_runs` | ✅ Partial | |
| `"BDaily"` — MVTSeries cleanedvalues | — | ⚠️ Gap | |

### 8. `test_22.jl`

| Julia `@testset` | MATLAB Equivalent | Parity | Notes |
|---|---|---|---|
| `"issue #22"` — Workspace deepcopy + compare | — | ❌ N/A | Tests Julia `Workspace` type (not ported) |
| `"issue 75"` — NaN broadcast with `isnan` masks | `TestFindAll.m` | ⚠️ Partial | The `isnan` mask assignment pattern is implicitly tested |

### 9. `test_workspace.jl`

| Julia `@testset` | MATLAB Equivalent | Parity | Notes |
|---|---|---|---|
| `"workspace"` — all tests | — | ❌ N/A | `Workspace` is a Julia-specific Dict-like container. MATLAB uses native `struct` for this purpose; no port needed. |

### 10. `test_serialize.jl`

| Julia `@testset` | MATLAB Equivalent | Parity | Notes |
|---|---|---|---|
| `"serialize"` — distributed computing serialization | — | ❌ N/A | Julia-specific `Distributed`/`@spawnat` serialization. Not applicable to MATLAB. |

### 11. `test_dataecon.jl`

| Julia `@testset` | MATLAB Equivalent | Parity | Notes |
|---|---|---|---|
| `"DE file"` — DataEcon file I/O | — | ❌ N/A | `.daec` file format I/O. This is a separate package concern, not part of the core time series port. |

---

## MATLAB-Only Tests (No Julia Equivalent)

These tests exist in MATLAB but don't directly correspond to a Julia test file:

| MATLAB Test | Description | Reason |
|---|---|---|
| `TestPlot.m` | Plotting smoke tests | MATLAB's plotting API is unique; Julia uses Plots.jl/Makie separately |
| `TestMoving.m` | Moving-window operations | Julia has `moving` via recipes; MATLAB implements it natively |
| `TestMVTSeriesMath.m` — `moving` method | Moving operations on MVTSeries | Extension beyond Julia base tests |

---

## Coverage Gaps to Address

### High Priority

| Gap | Julia Source | Description |
|---|---|---|
| BDaily `cleanedvalues` | `test_business.jl` lines 85–130 | The `cleanedvalues()` function returns holiday-filtered data. Should have explicit MATLAB tests. |
| BDaily statistics (mean/std/var/median with skip options) | `test_business.jl` `"BDaily statistics"` | Julia tests `mean`, `std`, `var`, `median`, `quantile`, `cov`, `cor` with `skip_all_nans` and `skip_holidays` for BDaily data. MATLAB lacks equivalent statistical tests. |
| BDaily shift/diff/pct with holidays | `test_business.jl` lines 50–100 | Julia tests shift/diff/lag/pct with explicit holiday maps and verifies NaN handling on holidays. MATLAB `TestShiftLagLead.m` only tests basic (non-holiday) shift/lag. |

### Medium Priority

| Gap | Julia Source | Description |
|---|---|---|
| MVTSeries cleanedvalues | `test_business.jl` lines 215–230 | `cleanedvalues` on MVTSeries with holidays |
| BDaily fconvert with holidays | `test_business.jl` lines 235–250 | `fconvert(Monthly, bdaily_ts; skip_holidays=true)` edge cases |
| Step-range broadcast indexing | `test_tseries.jl` lines 150–380 | Julia has exhaustive tests for step-range indexing with TSeries and MVTSeries. MATLAB covers the basics but not all combinations. |

### Low Priority / N/A

| Gap | Reason Not Applicable |
|---|---|
| Julia `view()` / SubArray tests | MATLAB has no copy-on-write view semantics in the same way |
| Julia `show()` / display tests | MATLAB `disp` works differently; not worth testing identically |
| Julia `promote` / type promotion | Julia-specific type system behavior |
| Julia `hash` / Dict key tests | MATLAB uses different container types |
| Julia `Workspace` type | MATLAB uses native `struct`; no wrapper needed |
| Julia `serialize` / Distributed tests | MATLAB Parallel Computing Toolbox is architecturally different |
| Julia `DataEcon` file I/O | Separate package, out of scope |

---

## Conclusion

The MATLAB test suite achieves **~90% functional parity** with the Julia tests for the core time series functionality. The main gaps are:

1. **BDaily statistics with holiday/NaN-skipping** — a feature-rich area in Julia that lacks dedicated MATLAB tests
2. **`cleanedvalues` function** — not explicitly tested in MATLAB
3. **BDaily shift/diff/pct with explicit holiday maps** — basic shift/lag tested but not the holiday-aware variants

The excluded items (Workspace, serialize, DataEcon, x13, display formatting, type system internals) are all correctly omitted as they are either Julia-specific infrastructure or out-of-scope packages.
