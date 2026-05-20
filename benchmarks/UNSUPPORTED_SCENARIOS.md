# Unsupported Benchmark Scenarios

This document lists all scenarios from
[`TimeSeriesEconPy/benchmarks/compare/scenarios.py`](https://github.com/Nic2020/TimeSeriesEconPy/tree/main/benchmarks/compare)
that are **not implemented** in `benchmarks/run_benchmarks.m`, together with
the reason for each gap.

---

## 1. `fconvert` scenarios — out of scope

`fconvert` (frequency conversion) is explicitly **out of scope** for this
MATLAB port (see `PLAN.md §1 Non-goals`).  All scenarios that depend on it
are therefore `n/a`:

| Scenario | Description |
|---|---|
| `fconvert_qq_to_yy_mean` | `fconvert(Yearly, t, method='mean')` |
| `fconvert_qq_to_yy_sum` | `fconvert(Yearly, t, method='sum')` |
| `fconvert_yy_to_qq_const` | `fconvert(Quarterly, t, method='const')` (higher-freq) |
| `fconvert_yy_to_qq_linear` | `fconvert(Quarterly, t, method='linear')` (higher-freq) |
| `fconvert_yy_to_qq_even` | `fconvert(Quarterly, t, method='even')` (higher-freq) |
| `fconvert_mm_to_qq_mean` | `fconvert(Quarterly, monthly_t, method='mean')` |
| `fconvert_qq_to_yy_mean_numpy` | kernel-direct `aggregate_groups_numpy` (mean) |
| `fconvert_qq_to_yy_sum_numpy` | kernel-direct `aggregate_groups_numpy` (sum) |
| `fconvert_mm_to_qq_mean_numpy` | kernel-direct `aggregate_groups_numpy` (monthly→quarterly) |
| `fconvert_qq_to_yy_mean_cython` | Cython kernel (mean) |
| `fconvert_qq_to_yy_sum_cython` | Cython kernel (sum) |
| `fconvert_mm_to_qq_mean_cython` | Cython kernel (monthly→quarterly) |

**Path to coverage:** implement `fconvert.m` for the aggregate (lower-freq)
and broadcast (higher-freq) directions.  The MATLAB equivalent of
`aggregate_groups_numpy` would be a vectorised `accumarray` call.

---

## 2. Mixed-frequency pipeline scenarios — depend on `fconvert`

Both scenarios are the paper-headline rows that expose the friction
DataFrame-based pipelines encounter with multi-frequency data.  They require
`fconvert` internally.

| Scenario | Description |
|---|---|
| `mixed_freq_qq_minus_mm_mean` | `qq_gdp - fconvert(Q, mm_cpi, mean)` — single-conversion mixed-freq op |
| `mixed_freq_pipeline_three_freq` | `Y + Q + M → quarterly` via two `fconvert` calls — three-frequency pipeline |

**Path to coverage:** same as §1 above.

---

## 3. `Workspace` scenarios — out of scope

`Workspace` (a dictionary-like container mapping names to TSeries) is
**out of scope** for this MATLAB port.

| Scenario | Description |
|---|---|
| `workspace_merge_5_series` | `Workspace.merge` — 5+5 series |
| `workspace_filter_5_series` | `Workspace.filter` — keep 5 of 10 series |
| `workspace_to_mvts_copyto_5cols` | `copyto(MVTSeries, Workspace)` — in-place materialiser |
| `compare_workspaces_equal_5_keys` | `compare(w1, w2)` — 5×TSeries, all equal |
| `compare_workspaces_differ_5_keys` | `compare(w1, w2)` — 5×TSeries, one differing |

**Path to coverage:** implement a `Workspace` class (a thin wrapper around a
MATLAB `struct` or `containers.Map`) plus `compare_ts` on workspaces.
Note: scalar TSeries comparison already exists as `tseries.compare_ts`.

---

## 4. X-13ARIMA-SEATS scenario — out of scope

X-13 seasonal adjustment is **out of scope** for this port (see `PLAN.md §1
Non-goals`).

| Scenario | Description |
|---|---|
| `deseasonalize_quarterly_50y` | `deseasonalize(t)` — 200-quarter series via the bundled `x13as` binary |

**Path to coverage:** implement an `x13.m` wrapper that shells out to the
`x13as` binary (the same Fortran binary the Python and Julia wrappers use).

---

## 5. Python/NumPy/Cython kernel-direct scenarios — no direct analogue

These scenarios time Python-specific layers (interpreted for-loop,
raw NumPy array operations, or compiled Cython extensions) that have no
meaningful counterpart in MATLAB.  MATLAB's JIT already inlines arithmetic
to native code; there is no "interpreter loop overhead" to isolate, and no
Cython equivalent.

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

**Rationale:** In the Python paper, these rows quantify the gap between
interpreted dispatch and C-speed kernels.  In MATLAB that gap does not
exist at the public-API level (MATLAB's own JIT handles it), so isolating
"kernel direct" vs "API" is not a meaningful comparison axis here.

---

## 6. `lookup` vectorised-indexing scenario — function not yet implemented

| Scenario | Description |
|---|---|
| `indexing_lookup_100_api` | `lookup(t, mit_keys)` — public vectorised API that gathers 100 MIT values in one call |

The scalar `t(mit)` path (per-element loop) is covered by
`indexing_mit_lookup_100` in `run_benchmarks.m`.  A vectorised batch-gather
using `t(mitrange)` or `t(logical_mask)` already works; the specific
`lookup(t, list_of_MITs)` free function does not yet exist.

**Path to coverage:** implement a `tseries.lookup(t, keys)` free function
that converts a cell array (or MIT array) of keys to integer offsets and
returns `t.values(offsets)` in a single vectorised call.

---

## Summary

| Category | Count | Status |
|---|---|---|
| `fconvert` and mixed-freq | 14 | Out of scope (PLAN.md §1) |
| `Workspace` | 5 | Out of scope (PLAN.md §1) |
| X-13 | 1 | Out of scope (PLAN.md §1) |
| Python/NumPy/Cython kernel-direct | 13 | No direct analogue in MATLAB |
| `lookup` vectorised API | 1 | Function not yet implemented |
| **Total unsupported** | **34** | — |
| **Implemented in `run_benchmarks.m`** | **32** | — |
