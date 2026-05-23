# Options

A small process-global store holds the package's settings, read and written with
`getoption` / `setoption`.

```matlab
v = tse.getoption(name)
tse.setoption(name, value)
```

| Option | Default | Role |
|--------|---------|------|
| `'bdaily_holidays_map'` | `[]` | a `TSeries{BDaily}` of logicals (`true` = working day). Populated by `set_holidays_map`; consulted by `fconvert` and `cleanedvalues` when called with `'skip_holidays', true`. |
| `'bdaily_creation_bias'` | `'strict'` | stored for parity with the Julia/Python ports. The `bday` constructor takes an explicit `'bias'` argument per call. |
| `'bdaily_skip_nans'` | `false` | default NaN-skipping flag for BDaily helpers. |
| `'x13path'` | `''` | path to an X-13 executable (x13 is not implemented in this port). |

## Holidays

| Function | Description |
|----------|-------------|
| `tse.set_holidays_map(country[, subdivision])` | load a bundled calendar into `bdaily_holidays_map` |
| `tse.set_holidays_map(tseries)` | install a hand-built `TSeries{BDaily}` logical map |
| `tse.get_holidays_options([country])` | list supported countries (or a country's subdivisions) |
| `tse.clear_holidays_map()` | reset `bdaily_holidays_map` to `[]` |

```matlab
import tse.*
set_holidays_map('CA', 'ON');
m = getoption('bdaily_holidays_map');     % a BDaily logical TSeries
isHoliday = ~logical(m(bday('2024-02-19')));
clear_holidays_map();
```

See [BDaily holidays](../tutorials/1_timeseriesecon.md#16-bdaily-holidays) for
the full workflow.

!!! info "Julia ↔ MATLAB"
    Julia's `setoption(:foo, value)` symbol argument becomes a plain string,
    `setoption('foo', value)`. The holidays calendar data is bundled (copied
    from the Julia upstream) rather than fetched at runtime.
