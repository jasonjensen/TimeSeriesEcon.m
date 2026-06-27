# Dynare interop

If your workflow runs models in Dynare but you would rather keep most of your
data-handling code in TimeSeriesEcon.m, the `tse.dynare` subpackage is the
bridge: it converts data between `tse.TSeries` / `tse.MVTSeries` and Dynare's
`dseries`, and between `tse.MIT` / `tse.MITRange` and Dynare's `dates`.

The whole subpackage checks for Dynare only at call time -- nothing in `+tse/`
depends on Dynare being installed.

## Quick start

```matlab
tse.dynare.startup('/opt/dynare/matlab');     % addpath + conflict report

t  = tse.dynare.from_dseries(model_ds);       % dseries -> tse.TSeries / MVTSeries
ds = tse.dynare.to_dseries(t);                % tse.* series -> dseries

d  = tse.dynare.from_db(model_db);            % struct of dseries -> struct of tse.*
db = tse.dynare.to_db(d);                     % the other way

m  = tse.dynare.from_date(dates('2020Q1'));   % 1-element dates -> tse.MIT
dd = tse.dynare.to_date(tse.qq(2020,1));      % tse.MIT -> 1-element dates
```

`tse.dynare.isavailable()` is the cached probe;
`tse.dynare.check_conflicts()` lists any bare names defined by both libraries.

## Typical Dynare workflow

The most common pattern: hold all your data as `tse.TSeries` / `tse.MVTSeries`,
hand Dynare a `dseries` exactly when you call it, and convert the result back
on return.

```matlab
function out = run_my_model(inputs)
    % inputs is a struct of tse.* series
    ds_in  = tse.dynare.to_db(inputs);
    ds_out = my_dynare_model(ds_in);          % returns a struct of dseries
    out    = tse.dynare.from_db(ds_out);
end
```

Inside `my_dynare_model` you stay entirely in Dynare's idiom -- write `.mod`
files, call `dseries` methods, build `dates` objects with whatever syntax you
prefer. The conversion at the two boundaries is the only place tse and Dynare
need to know about each other.

## Frequency support

| tse class               | Dynare code  | Round-trippable |
|-------------------------|-------------:|-----------------|
| `tse.Yearly(12)`        | 1            | yes (calendar year only) |
| `tse.HalfYearly(6)`     | 2            | yes              |
| `tse.Quarterly(3)`      | 4            | yes              |
| `tse.Monthly`           | 12           | yes              |
| `tse.Weekly(7)`         | 52           | yes (ISO weeks)  |
| `tse.Daily`             | 365          | yes              |
| `tse.BDaily`            | -            | no -- Dynare has no business-day frequency.  `to_dseries` errors with a clear message; convert to Daily first via `tse.fconvert`. |
| `tse.Unit`              | -            | no -- Dynare requires a real frequency. |

Calendar-yearly frequencies round-trip cleanly. `tse.Yearly` carries an
`endPeriod` (default 12 = calendar year); Dynare has no end-month concept, so
`to_date` warns once if a yearly MIT carries any other `endPeriod`. Convert
fiscal years to calendar years first if you need a clean round-trip.

## Namespace conflicts

Compared to IRIS, the Dynare surface area is small. The only top-level Dynare
names that could conflict are the two classes:

- `dates` -- a class. No tse counterpart. Could theoretically be shadowed by
  another library's `dates` function (e.g. an older Financial Toolbox
  helper), so `tse.dynare.check_conflicts()` looks for it.
- `dseries` -- a class. No tse or MATLAB counterpart.

All tse helpers are namespaced (`tse.qq`, `tse.TSeries`, …), so they never
collide with Dynare. Method names that exist in both (`lag`, `lead`, `mean`,
`std`, `diff`, …) dispatch on the receiver class and resolve correctly.

## See also

- [`docs/design/iris_interop.md`](iris_interop.md) -- the sibling page for
  IRIS, with longer discussion of bare-name shadowing (mostly irrelevant for
  Dynare but useful when both are loaded).
- [`IRIS_INTEROP_PLAN.md`](../../IRIS_INTEROP_PLAN.md) -- the design plan that
  inspired this subpackage; the same shape applies here.
