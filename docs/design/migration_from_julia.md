# Migration from Julia

A reader coming from
[`TimeSeriesEcon.jl`](https://github.com/bankofcanada/TimeSeriesEcon.jl) will
recognise every concept here. The table catalogues the *visible* differences —
the spellings, not the semantics. Assume `import tse.*` is in scope.

| Concept | Julia | MATLAB (`tse`) |
|---------|-------|----------------|
| Quarterly literal | `2020Q1` | `qq(2020, 1)` |
| Monthly literal | `2020M3` | `mm(2020, 3)` |
| Yearly literal | `2020Y` | `yy(2020)` |
| Half-yearly | `2020H1` | `MIT(HalfYearly(), 2020, 1)` |
| Variant end-month | `MIT{Quarterly{2}}(2020, 1)` | `MIT(Quarterly(2), 2020, 1)` |
| Daily / business / weekly | `d"2022-01-03"` / `bd"…"` / `weekly("…")` | `day('2022-01-03')` / `bday('…')` / `week('…')` |
| Inclusive range | `2020Q1:2021Q4` | `MITRange(qq(2020,1), qq(2021,4))` or `qq(2020,1):qq(2021,4)` |
| Step range | `2000M1:2:2000M8` | `MITRange(mm(2000,1), 2, mm(2000,8))` |
| Reversed range (backcast) | `10U:-1:1U` | `MITRange(MIT(Unit(),10), -1, MIT(Unit(),1))` |
| Frequency-of | `frequencyof(t)` | `frequencyof(t)` |
| Periods per year | `ppy(frequencyof(t))` | `ppy(t)` (accepts MIT or Frequency) |
| Whole-object vs element-wise | `x + y` vs `x .+ y` | `x + y` / `x .* y` (MATLAB's `.`-operators) |
| Dot-broadcast | `log.(x)` | `log(x)` (implicit expansion) |
| Last element | `x[end]` | `x(lastdate(x))` |
| First element | `x[begin]` | `x(firstdate(x))` |
| Shifts | `lag(x)` / `lag!(x)` | `lag(x)` / `x = lag(x)` |
| Difference | `diff(x)` | `diff(x)` (method; Julia sign convention) |
| Undiff with anchor | `undiff(dx, firstdate(x) => first(x))` | `undiff(dx, firstdate(x), x(firstdate(x)))` |
| Moving average | `moving(t, n)` | `moving_average(t, n)` (alias `moving`) |
| Macro recurrence | `@rec rng a[t] = …` | `a = rec(rng, a, @(s,t) …)` |
| `rangeof` with drop | `rangeof(t, drop=1)` | `rangeof(t, 'drop', 1)` |
| MVTSeries construct | `MVTSeries(2020Q1, (:a,:b), data)` | `MVTSeries(qq(2020,1), {'a','b'}, data)` |
| MVTSeries column | `x.a` / `x[:a]` | `x.a` / `x('a')` |
| MVTSeries columns iter | `columns(x)` | `columns(x)` (returns a struct) |
| Per-column / per-row mean | `mean(mvts; dims=1)` / `dims=2` | `mean(mv, 'dims', 1)` / `'dims', 2` |
| Workspace | `Workspace()` / `delete!(w, :x)` | a `struct`: `struct()` / `rmfield(w, 'x')` |
| `overlay` | `overlay(x1, x2)` / `overlay(rng, x1, x2)` | `overlay(x1, x2)` / `overlay(rng, x1, x2)` |
| `compare` / `@compare` | `@compare(v1, v2, atol=1e-5)` | `compare(v1, v2, 'atol', 1e-5)` |
| `reindex` | `reindex(t, 2021Q1 => 1U)` | `reindex(t, qq(2021,1), MIT(Unit(),1))` |
| Matrix product | `A * t` | `A * t` (returns a numeric vector) |
| Frequency conversion | `fconvert(Quarterly, t; method=:mean)` | `fconvert(Quarterly(), t, 'method', 'mean')` |
| Options | `setoption(:foo, v)` | `setoption('foo', v)` |
| Holidays | `set_holidays_map("CA", "ON")` | `set_holidays_map('CA', 'ON')` |

## Semantics that are identical

- MIT-intersection alignment on element-wise ops (`x + y`).
- Resize-on-assign when an out-of-range MIT key is written.
- Frequency-mismatch raises on arithmetic between mismatched-frequency series.
- `fconvert` method semantics (mean / sum / first / last / min / max / point /
  const / even / linear) and `ref` / `trim` behaviour.

## Semantics that differ

- **Value semantics everywhere.** `MIT`, `TSeries`, `MVTSeries` are MATLAB value
  classes, so assignment copies on write and in-place `!`-mutators have no
  separate spelling — reassign the result (`t = lag(t)`,
  `a = rec(rng, a, fn)`).
- **No `Workspace` type.** Use a `struct`; `overlay` / `compare` accept
  structs field-by-field, but `reindex` dispatches over MIT / MITRange / TSeries.
- **No `rec_linear` / no `@rec` macro.** Use the higher-order `rec`; for
  `a[t] = a[t-1] + c`, use `undiff`.
- **`diff` follows the Julia sign convention.** `diff(t)` is a method, so it
  overrides MATLAB's built-in `diff` only for `TSeries` / `MVTSeries`
  (`diff(x) = x - lag(x)`); on plain arrays MATLAB's built-in `diff` is
  unchanged.
- **Display.** `disp(t)` reproduces the *shape* of Julia's `show` (header, range,
  truncated rows) but not the exact spacing.
- **`x13` is not ported** — see [the x13 page](../reference/x13.md).
