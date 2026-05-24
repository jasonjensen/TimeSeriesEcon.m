# Unsupported Benchmark Scenarios

This document lists all scenarios from
[`TimeSeriesEconPy/benchmarks/compare/scenarios.py`](https://github.com/Nic2020/TimeSeriesEconPy/tree/main/benchmarks/compare)
that are **not implemented** in `benchmarks/run_benchmarks.m`, together with
the reason for each gap.

---

## 1. `fconvert` scenarios — ✅ now implemented

`fconvert.m` is fully implemented.  All six public-API fconvert scenarios and
both mixed-frequency pipeline scenarios are registered in `run_benchmarks.m`.

The kernel-direct rows (`_numpy`, `_cython`) have no MATLAB analogue — see §4.

---

## 2. Mixed-frequency pipeline scenarios — ✅ now implemented

Both pipeline scenarios (`mixed_freq_qq_minus_mm_mean`,
`mixed_freq_pipeline_three_freq`) are registered in `run_benchmarks.m`.

---

## 3. `Workspace` scenarios — mostly implemented

MATLAB uses plain `struct` as the workspace equivalent.  The following
scenarios are now registered in `run_benchmarks.m`:

| Scenario | Implementation |
|---|---|
| `workspace_merge_5_series` | `tse.overlay(w1, w2)` on structs with disjoint fields |
| `workspace_filter_5_series` | field-copy loop into new struct |
| `compare_workspaces_equal_5_keys` | `tse.compare(w1, w2, 'quiet', true)` |
| `compare_workspaces_differ_5_keys` | `tse.compare(w1, w2, 'quiet', true)` |

The following scenario remains `n/a` — it depends on `copyto`, a Python-specific
in-place materialiser with no direct MATLAB equivalent:

| Scenario | Description |
|---|---|
| `workspace_to_mvts_copyto_5cols` | `copyto(MVTSeries, Workspace)` — in-place materialiser |

---

## 4. X-13ARIMA-SEATS scenario — implemented, but needs an external binary

X-13 seasonal adjustment is now ported in `+tse/+x13` (`tse.x13.deseasonalize`,
`tse.x13.run`, …).  The scenario is still **not registered** in
`run_benchmarks.m` because the MATLAB port does not bundle the `x13as`
executable — it must be installed separately and located via
`tse.setoption('x13path', ...)`.

| Scenario | Description |
|---|---|
| `deseasonalize_quarterly_50y` | `deseasonalize(t)` — 200-quarter series; requires an installed `x13as` binary |

---

## 5. Python/NumPy/Cython kernel-direct scenarios — no direct analogue

These scenarios time Python-specific layers that have no meaningful counterpart
in MATLAB.  MATLAB's JIT already inlines arithmetic to native code; there is
no "interpreter loop overhead" to isolate, and no Cython equivalent.

| Scenario | Reason |
|---|---|
| `rec_linear_ar2_100_pylist` | Pure-Python `list` AR(2) loop — Python-specific baseline |
| `rec_linear_ar2_100_numpy` | `rec_linear_numpy` kernel direct — NumPy-specific |
| `rec_linear_ar2_100_cython` | `rec_linear_cython` kernel direct — Cython-specific |
| `mean_quarterly_100_numpy` | `mean_numpy(values)` kernel direct |
| `mean_quarterly_100_cython` | `mean_cython(values)` kernel direct |
| `std_quarterly_100_numpy` | `std_numpy(values, 1)` kernel direct |
| `std_quarterly_100_cython` | `std_cython(values, 1)` kernel direct |
| `cor_two_tseries_numpy` | `cor_numpy(x, y)` kernel direct |
| `cor_two_tseries_cython` | `cor_cython(x, y)` kernel direct |
| `undiff_quarterly_numpy` | `cumsum_anchored_numpy` kernel direct |
| `undiff_quarterly_cython` | `cumsum_anchored_cython` kernel direct |
| `indexing_lookup_100_numpy` | `gather_numpy(values, ix)` kernel direct |
| `indexing_lookup_100_cython` | `gather_cython(values, ix)` kernel direct |
| `fconvert_qq_to_yy_mean_numpy` | kernel-direct `aggregate_groups_numpy` (mean) |
| `fconvert_qq_to_yy_sum_numpy` | kernel-direct `aggregate_groups_numpy` (sum) |
| `fconvert_mm_to_qq_mean_numpy` | kernel-direct `aggregate_groups_numpy` (monthly→quarterly) |
| `fconvert_qq_to_yy_mean_cython` | Cython kernel (mean) |
| `fconvert_qq_to_yy_sum_cython` | Cython kernel (sum) |
| `fconvert_mm_to_qq_mean_cython` | Cython kernel (monthly→quarterly) |

---

## 6. `lookup` vectorised-indexing scenario — ✅ now implemented

`tse.lookup` exists and `indexing_lookup_100_api` is registered in
`run_benchmarks.m`.

---

## Summary

| Category | Count | Status |
|---|---|---|
| `fconvert` public API (6) + mixed-freq (2) | 8 | ✅ Implemented |
| `Workspace` public scenarios | 4 | ✅ Implemented |
| `workspace_to_mvts_copyto_5cols` | 1 | n/a — no MATLAB `copyto` equivalent |
| X-13 | 1 | Out of scope |
| Python/NumPy/Cython kernel-direct | 20 | No direct analogue in MATLAB |
| `lookup` vectorised API | 1 | ✅ Implemented |
| **Total unsupported** | **22** | — |
| **Implemented in `run_benchmarks.m`** | **47** | — |
