# Migration from Python

For readers coming from the sister package
[TimeSeriesEconPy](https://nic2020.github.io/TimeSeriesEconPy/) (`tsecon`). The
two ports share the same Julia ancestor, so the concepts line up one-to-one;
only the spellings differ. Assume `import tse.*` is in scope in MATLAB and
`from tsecon import *` in Python.

| Concept | Python (`tsecon`) | MATLAB (`tse`) |
|---------|-------------------|----------------|
| Quarterly / Monthly / Yearly | `qq(2020,1)` / `mm(2020,3)` / `yy(2020)` | `qq(2020,1)` / `mm(2020,3)` / `yy(2020)` |
| Half-yearly | `MIT.from_yp(HalfYearly(), 2020, 1)` | `MIT(HalfYearly(), 2020, 1)` |
| Daily / business / weekly | `daily('…')` / `bdaily('…')` / `weekly('…')` | `day('…')` / `bday('…')` / `week('…')` |
| Inclusive range | `MITRange(qq(2020,1), qq(2021,4))` | `MITRange(qq(2020,1), qq(2021,4))` |
| Step range | `MITRange(mm(2000,1), mm(2000,8), step=2)` | `MITRange(mm(2000,1), 2, mm(2000,8))` |
| Reversed range | `MITRange(a, b, step=-1)` | `MITRange(a, -1, b)` |
| Construct TSeries | `TSeries(qq(2020,1), arr)` | `TSeries(qq(2020,1), col)` |
| Zeros / fill | `TSeries(rng, np.zeros)` | `TSeries(rng, @zeros)` |
| Index by date | `t[qq(2020,1)]` | `t(qq(2020,1))` |
| Index by range | `t[MITRange(a,b)]` | `t(MITRange(a,b))` |
| Last / first | `t[t.lastdate]` / `t[t.firstdate]` | `t(lastdate(t))` / `t(firstdate(t))` |
| Element-wise math | `np.log(x)`, `x + y` | `log(x)`, `x + y` |
| Shifts | `lag(x)`, `lead(x)`, `shift(x,-1)` | `lag(x)`, `lead(x)`, `shift(x,-1)` |
| Difference / undiff | `diff(x)` / `undiff(dx, anchor=(d,v))` | `diff(x)` / `undiff(dx, d, v)` |
| Moving average | `moving(t, n)` | `moving_average(t, n)` |
| Recurrence | `rec(rng, t, lambda t: …)` | `t = rec(rng, t, @(s,t) …)` |
| Linear recurrence | `rec_linear(t, coeffs, lags, rng)` | *not ported* — use `rec` or `undiff` |
| `rangeof` drop | `rangeof(t, drop=1)` | `rangeof(t, 'drop', 1)` |
| MVTSeries construct | `MVTSeries(qq(2020,1), ('a','b'), mat)` | `MVTSeries(qq(2020,1), {'a','b'}, mat)` |
| MVTSeries column | `mv['a']` / `mv.a` | `mv('a')` / `mv.a` |
| Columns iter | `mv.columns.items()` | `columns(mv)` (a struct) |
| Per-column / per-row mean | `mean(mv, axis=0)` / `axis=1` | `mean(mv, 'dims', 1)` / `'dims', 2` |
| Workspace | `Workspace(...)` / `del w.x` | a `struct`: `struct(...)` / `rmfield(w,'x')` |
| `overlay` | `overlay(x1, x2, rng=…)` | `overlay(x1, x2)` / `overlay(rng, x1, x2)` |
| `compare` | `compare(v1, v2, atol=1e-5)` → `CompareResult` | `compare(v1, v2, 'atol', 1e-5)` → logical |
| `reindex` | `reindex(t, (old, new))` | `reindex(t, old, new)` |
| Matrix product | `A @ t` | `A * t` |
| Frequency conversion | `fconvert(t, Quarterly(), method='mean')`* | `fconvert(Quarterly(), t, 'method', 'mean')` |
| Options | `setoption('foo', v)` | `setoption('foo', v)` |
| Holidays | `set_holidays_map('CA', 'ON')` | `set_holidays_map('CA', 'ON')` |

\* The Python and MATLAB ports both put the target frequency in the `fconvert`
call; check the Python signature order on your version.

## Things only one side has

| | Python (`tsecon`) | MATLAB (`tse`) |
|--|-------------------|----------------|
| Compiled fast paths | Cython kernels (`rec_linear`, lookup, stats, fconvert) | hand-tuned `subsref` / `lookup` for class-dispatch overhead |
| DataFrame interop | `to_pandas` / `to_polars` | — (use `t.values` + `rangeof`) |
| JSON I/O | yes | — |
| `option_scope` context manager | yes | — (call `setoption` / restore manually) |
| `CompareResult` object | yes | `compare` returns a logical (`'quiet', false` prints a diff) |
| Workspace type | `Workspace` class | native `struct` |
| Matrix product operator | `@` (element-wise stays `*`) | `*` (element-wise is `.*`) |

## Semantics that match

- MIT-intersection alignment on `+` / `-`; resize-on-assign; frequency-mismatch
  errors; the full `fconvert` method/`ref`/`trim` surface; the holidays
  `skip_holidays` / `skip_all_nans` knobs.
