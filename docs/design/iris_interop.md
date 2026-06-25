# IRIS interop

If you are migrating a codebase from the IRIS Toolbox to TimeSeriesEcon.m, you
will likely need to keep both libraries on the path for a while. The
`tse.iris` subpackage is the bridge: it converts data between the two
representations, and it surfaces the (small) set of bare-name conflicts.

The whole subpackage checks for IRIS only at call time -- nothing in `+tse/`
depends on IRIS being installed.

## Quick start

```matlab
% Put both libraries on the path, then:
tse.iris.startup('/path/to/IRIS_Tbx_20150318');   % addpath + irisstartup + check

t  = tse.iris.from_tseries(iris_ts);   % IRIS tseries  -> tse.TSeries / MVTSeries
ts = tse.iris.to_tseries(t);           % tse.* series   -> IRIS tseries

d  = tse.iris.from_db(iris_db);        % struct of IRIS tseries -> struct of tse.*
db = tse.iris.to_db(d);                % the other way

m  = tse.iris.from_date(qq(2020,1));   % IRIS date double -> tse.MIT
dt = tse.iris.to_date(tse.qq(2020,1)); % tse.MIT -> IRIS date double
```

`tse.iris.isavailable()` is the cached probe; `tse.iris.check_conflicts()`
lists any bare names defined by both libraries.

## Three usage patterns

### 1. An all-tse function called from an IRIS script

Convert at the boundary on entry; everything inside is regular `tse` code.

```matlab
function out = my_tse_function(iris_db)
    d   = tse.iris.from_db(iris_db);
    sa  = tse.fconvert(tse.Yearly(), d.gdp, 'method', 'mean');
    out = tse.iris.to_db(struct('gdp_y', sa));
end
```

### 2. An all-IRIS function called from a tse script

The mirror image: convert once on entry, once on exit. Do not `import tse.*`
in the wrapper -- it would shadow IRIS's bare date helpers (see below).

```matlab
function tout = my_iris_wrapper(tin)
    iris_ts = tse.iris.to_tseries(tin);
    iris_out = my_old_iris_function(iris_ts);
    tout = tse.iris.from_tseries(iris_out);
end
```

### 3. Mixed in-place

If you really must call both libraries in the same function, qualify every
bare date helper. Method calls (`shift(t, -1)`, `mean(t)`, `t + s`) dispatch
on the receiver class and never need qualification.

```matlab
tt = tse.TSeries(tse.qq(2020,1), (1:40)');   % tse.qq -- explicit
ii = tseries(qq(2020,1), (1:40)');           % IRIS qq -- the bare one
m  = mean(tt);   % dispatches to tse.TSeries.mean
n  = mean(ii);   % dispatches to IRIS tseries/mean
```

## Namespace conflicts: the catalog

Most apparent conflicts are not conflicts at all -- they are method names that
dispatch on the type of their first argument. `shift`, `diff`, `pct`, `apct`,
`mean`, `std`, `cov`, `corr`, `cumsum`, arithmetic operators -- all of these
resolve correctly because MATLAB sees whether the receiver is an IRIS
`tseries` or a `tse.TSeries`.

The remaining genuine collisions are the **bare date helpers** that IRIS
exposes at top level:

```
qq mm yy ww hh dd zz
```

These have no receiver to dispatch on, so MATLAB picks whichever resolves
first on the path. The normal arrangement -- IRIS loaded first via
`irisstartup` -- means the bare `qq(2020,1)` returns an IRIS date double.

`import tse.*` flips this for the rest of the function scope: the bare name
rebinds to `tse.qq`, which returns a `tse.MIT`. Mixing IRIS and a
`import tse.*` in the same function is the only really dangerous case, and
the rule is just *don't*. Use `import tse.TSeries` and `import tse.MVTSeries`
for the class names and qualify the date helpers explicitly.

The other tse vs IRIS surface-area names are all spelled differently:
`tse.fconvert` vs IRIS `convert`, `tse.overlay` vs IRIS `dboverlay`,
`tse.compare` vs IRIS `dbcompare`, `tse.TSeries` vs IRIS `tseries`. No
collisions.

## Frequency support

| tse class               | IRIS code  | Round-trippable |
|-------------------------|-----------:|-----------------|
| `tse.Yearly(12)`        | 1          | yes (calendar year only) |
| `tse.HalfYearly(6)`     | 2          | yes              |
| `tse.Quarterly(3)`      | 4          | yes              |
| `tse.Monthly`           | 12         | yes              |
| `tse.Weekly(7)`         | 52         | yes (ISO weeks)  |
| `tse.Daily`             | 365        | yes              |
| `tse.BDaily`            | -          | no -- IRIS 2015 has no business-day frequency.  `to_tseries` errors with a clear message; convert to Daily first via `tse.fconvert`. |
| `tse.Unit`              | 0          | yes (`zz` on the IRIS side) |

`tse.Yearly` carries an `endPeriod` (default 12 = calendar year); IRIS yearly
has no end-month concept, so `to_date` warns once if the MIT's end period is
anything other than 12. If you need a clean round-trip on a fiscal year,
convert to calendar year first.

## See also

- [`IRIS_INTEROP_PLAN.md`](../../IRIS_INTEROP_PLAN.md) -- the full design plan,
  including phase 2.5 on implicit acceptance of IRIS dates in `tse.TSeries`
  constructors and indexing.
- [`benchmarks/iris_benchmarks.m`](../../benchmarks/iris_benchmarks.m) -- the
  IRIS analogue of `benchmarks/run_benchmarks.m`, useful for side-by-side
  performance comparison during a migration.
