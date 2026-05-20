# Side-quest: DataEcon (matlab branch) vs. our TimeSeriesEcon.jl port

A comparative analysis of the time-series design used in
[`bankofcanada/DataEcon` matlab branch](https://github.com/bankofcanada/DataEcon/tree/matlab/matlab)
and the design we are currently building (a port of TimeSeriesEcon.jl).
The conclusion is recorded here for the record; the current plan continues
unchanged unless explicitly redirected.

---

## 1. What DataEcon's MATLAB branch actually has

The relevant files at `matlab/` of the `matlab` branch are:

| File          | Lines | Role                                                  |
| ------------- | ----: | ----------------------------------------------------- |
| `DAEC.m`      | 414   | Singleton wrapper around `libdaec`; pack/unpack/IRIS  |
| `DEDate.m`    | 153   | "moment in time", a handle class                      |
| `DEAxis.m`    |  65   | A generalized axis (plain / range / names)            |
| `DESeries.m`  | 259   | N-dimensional value container                         |
| `DEFile.m`    | 619   | Open/read/write `.daec` binary files                  |
| `private/daecenums.m` | 47 | Frequency, type, status, axis-type integer enums |
| `tests/*.m`   |       | Round-trip tests (write to `.daec`, read back)        |

The shape of the data model is:

```
DESeries
├── axis : DEAxis[]      (1, 2, 3, ... axes)
│   └── each axis is one of:
│       • axis_plain  — integer-indexed (start, length)
│       • axis_range  — frequency-bearing date range
│       • axis_names  — labelled (cellstr)
└── value : numeric | logical | DEDate    (flat array, matched to axes)
```

So a 1-D TSeries is a `DESeries` whose single axis is `axis_range`.
A 2-D MVTSeries is a `DESeries` with `axis_range × axis_names`. The same
class supports arbitrary tensors.

Key design choices:

1. **Everything is a `handle` class** (`classdef DESeries < handle`,
   `DEDate < handle`, `DEAxis < handle`, `DEFile < handle`). Reference
   semantics; `b = a` makes `b` and `a` aliases.
2. **Frequency is a flat integer enum** loaded from
   `private/daecenums.m`: `freq_yearly_dec=268`, `freq_quarterly_mar=67`,
   `freq_weekly_sun=23`, etc. End-period variations of the same family
   share the same integer when they coincide (e.g.
   `freq_quarterly_mar=67` and `freq_quarterly_jun=67` are aliases).
3. **No date arithmetic in MATLAB.** Pack/unpack go through `libdaec`
   (`de_pack_calendar_date`, `de_unpack_year_period_date`) via
   `libpointer`/`calllib`. The MATLAB layer is a thin shim.
4. **No operator overloading** on `DESeries`/`DEDate`. There is no
   `plus`, `times`, `eq`, `colon`, `subsref`/`subsasgn` for date-based
   access. `disp` is the only override.
5. **No growth-on-assign.** Axis length is fixed at construction; the
   `value` array dimensions are validated against the axes in the
   constructor.
6. **`disp` formats via `array2table`** for 1-D and 2-D, with manual
   slicing for 3-D. Display style is MATLAB-table-y, not Julia-pretty.
7. **First-class IRIS interop.** `DAEC.daec_from_iris_date`,
   `DAEC.make_iris_series`, `DAEC.iris_date` — DataEcon can ingest and
   emit IRIS `tseries` and `Series` objects. The `_iris` test scripts
   round-trip through that path.

The intent of the design is clear from `DEFile.m` (619 lines, the
largest file): **DataEcon's MATLAB code exists to read and write the
binary `.daec` archive format.** Anything that helps a user *compute*
with a time series — alignment, indexing by date, arithmetic — is out
of scope and deliberately left to whatever toolbox already owns that
job (IRIS, in their case).

---

## 2. Side-by-side comparison with our planned design

| Aspect                | DataEcon matlab branch                          | Our TimeSeriesEcon.m plan                          |
| --------------------- | ----------------------------------------------- | -------------------------------------------------- |
| MIT analogue          | `DEDate` handle, `frequency:int + value:int64`  | `tseries.MIT` value class, `frequency: Frequency` + `value:int64` |
| Frequency type        | Single int from a flat enum                     | Class hierarchy with `endPeriod` property          |
| End-of-period variant | Enum aliases (`quarterly_mar=quarterly_jun=67`) | Distinct instances (`Quarterly(2)` ≠ `Quarterly(3)`) |
| Container (1-D)       | `DESeries` (handle) with 1 axis                 | `tseries.TSeries` (value)                          |
| Container (2-D)       | `DESeries` (handle) with 2 axes                 | `tseries.MVTSeries` (value, planned)               |
| N-D                   | `DESeries` with N axes                          | Not in our scope                                   |
| Date arithmetic       | Delegated to `libdaec` via libpointer           | Pure MATLAB integer math                           |
| Range type            | An axis with `ax_type==axis_range`              | `tseries.MITRange` first-class                     |
| `+ - * /`             | Not defined                                     | Overloaded with mixed-frequency guards             |
| `<, <=, ==, …`        | Not defined                                     | Overloaded                                         |
| `t(2020Q1)` indexing  | Not defined                                     | Overloaded `subsref`                               |
| `t[rng] = val` growth | Not supported (axis is fixed)                   | Supported, NaN-padded                              |
| Broadcasting          | Not defined                                     | Planned (Phase 3+)                                 |
| Display               | `array2table` (one-off `disp`)                  | Julia-style pretty print                           |
| Persistence (.daec)   | First-class                                     | Out of scope                                       |
| IRIS interop          | First-class                                     | Out of scope                                       |
| External dependency   | `libdaec.so/dll` (C library)                    | Pure MATLAB, no deps                               |
| MATLAB baseline       | Whatever supports `libpointer`/`arguments`      | R2019b+                                            |

---

## 3. Pros of building on DataEcon's approach

The arguments *for* anchoring our work on DataEcon's design:

1. **Already exists and ships at the Bank of Canada.** Adopting it would
   line up with internal practice; there is institutional code that uses
   `DEDate`, `DEAxis`, `DESeries`. Our port would land in a familiar
   namespace.
2. **The C library is the canonical source of truth for date math.**
   `libdaec` already implements `de_pack_calendar_date`,
   `de_unpack_year_period_date`, business-day shifts, ISO-week math, and
   so on, and it is the same library Julia's DataEcon.jl uses. Riding on
   it means the Julia and MATLAB MIT values are guaranteed to agree
   bit-for-bit.
3. **Persistence comes for free.** A user holding a `DESeries` can write
   it to a `.daec` file with one call (`de.write(struct)`). Julia
   programs can read the same file. Our plan deliberately punted on this
   — `.daec` interop is "out of scope" — but it is real value when users
   need to move data between ecosystems.
4. **Unified N-D container.** One class handles 1-D, 2-D, 3-D, and
   beyond. This matches the underlying storage model cleanly and avoids
   the maintenance burden of two near-duplicate code paths (TSeries and
   MVTSeries) that we are about to write.
5. **IRIS interop already implemented.** Many MATLAB-side users in
   macroeconomic forecasting use IRIS. DataEcon's `daec_from_iris_date`,
   `make_iris_series`, and the `iris_colnames_field` plumbing in
   `DEFile` are not trivial code to rewrite.
6. **Handle semantics may match user expectations for big arrays.**
   MATLAB programmers used to OO-style mutation may prefer
   `series.value(i) = …` mutating in place over our value-class
   "modify-and-rebind" model.
7. **Smaller surface area to maintain.** Without operator overloading,
   custom subsref/subsasgn, or broadcasting, the class is much shorter:
   ~260 lines for DESeries versus our ~430 lines for TSeries (and
   growing).

## 4. Cons of building on DataEcon's approach

The arguments *against*:

1. **Handle semantics break the TimeSeriesEcon.jl mental model.** Julia
   `TSeries` is a `mutable struct` used in a Julian way — `b = a` copies
   ownership of the binding, not the storage; `b[1U] = 5` *does not*
   silently mutate `a`. (Julia gets this via immutable `MIT`s, separate
   storage references, and broadcasting semantics.) Re-targeting onto a
   handle class is a *semantic* change, not just a syntactic one. Tests
   that work in Julia would behave differently in MATLAB, in ways that
   are hard to spot at the call site.
2. **The whole `TSeries` / `MVTSeries` API the user asked us to mirror
   is missing.** No `+`, no `-`, no `shift`/`lag`/`lead`, no `pct`, no
   `overlay`, no growth-on-assign, no MIT-keyed `subsref`. We would have
   to add all of it on top of `DESeries`. That is essentially the work
   we are already doing — we would just be writing it on a shakier
   substrate (a handle class with a more general axis model than we
   need).
3. **The flat frequency enum loses the type-level information we need.**
   In our code, `mixed_freq_error` triggers because
   `isa(F, 'tseries.Quarterly')` and `isa(G, 'tseries.Yearly')` are
   distinct classes. With DataEcon, `F == 67` vs `G == 268` — fine, but
   `Quarterly{2}` vs `Quarterly{3}` *are not* distinct in the DataEcon
   enum (they share integer codes through the alias table), so the
   semantics that Julia's `Quarterly{end_month}` parameter give you
   simply cannot be reproduced.
4. **`libdaec` is a hard dependency.** Users have to ship a native
   library (`libdaec.so`, `libdaec.dll`) and configure paths. For a
   user who just wants a TSeries in MATLAB, that is a heavy install
   cost. Pure-MATLAB ports work on a fresh machine instantly.
5. **The libpointer / calllib indirection is slow for hot scalar
   paths.** Every `mit2yp` becomes a C-call round-trip. Our pure-MATLAB
   path is a few integer operations. For inner-loop work (`@rec`-style
   recursive evaluation, broadcast over a 10-year monthly series),
   the difference is large.
6. **Display is table-y, not series-y.** `array2table` does not match
   the look TimeSeriesEcon users expect; ports of Julia tutorials and
   notebooks would render differently.
7. **No first-class `MITRange`.** Ranges are embedded inside `DEAxis`.
   Users wanting `2020Q1:2021Q4` as a free-standing value (to pass to
   `intersect`, `rangeof_span`, plotting, slicing) get nothing useful.
8. **Maintenance lives upstream.** Adding a frequency variant, fixing a
   bug, or changing the wire format means touching the C library, which
   is shared with the Julia ecosystem and any other binding. Iterating
   in MATLAB-land alone is constrained.
9. **The single-class N-D container is more than we need.** The user
   asked for TSeries and MVTSeries. Folding both into a "DESeries with
   N axes" generalizes prematurely. The bookkeeping for the axis-type
   union (plain / range / names) leaks into every method.
10. **It is a moving target.** The matlab branch is unmerged and
    pre-1.0 — the `0.4.0` version string in `daecenums.m` flags it. If
    we build on it, we adopt their release cadence and breakage risk.

---

## 5. How hard is it to switch *after* a full implementation?

Suppose we finish Phases 1–7 of the current plan and then decide to
move to (or merge with) the DataEcon design. What would that cost?

### 5.1 Pieces that swap cleanly

- **Frequency identifiers.** A mapping table from our class instances
  (`tseries.Quarterly(3)`) to DataEcon enum values
  (`freq_quarterly_mar=67`) is ~30 lines. Bidirectional.
- **Raw integer value.** Both representations store the same Julian-day
  / period-since-epoch integer. `MIT.value` and `DEDate.value` can be
  the same `int64`. The mapping for daily/bdaily/weekly may need a
  small offset adjustment for any difference in epoch convention.
- **TSeries → DESeries** (forward). `DESeries(DEAxis(DEDate(...),
  len), values)` is straight construction; one function file, perhaps
  60 lines.
- **MVTSeries → DESeries** (forward). Same shape, two-axis case;
  another 60 lines.
- **File I/O.** Adding `tseries.toDaec(file, struct)` is a tiny shim
  that walks a struct, converts our types to DESeries, and calls into
  the existing DataEcon writer. ~100 lines once converters exist.

So pure interop ("get my TSeries onto disk in `.daec` format") is
cheap. It is in the order of a few hundred lines and one extra
dependency (`libdaec.so`). **This is the path we recommend if file
interop becomes a requirement.**

### 5.2 Pieces that don't swap, they re-port

Wholesale replacement — i.e. *abandoning* our `tseries.TSeries` and
making `DESeries` the new home — is a different story. The cost shows
up in three places:

1. **Operator semantics.** Every overload — `plus`, `minus`, `mtimes`,
   `times`, `rdivide`, `power`, `eq`, `ne`, `lt`, `le`, `gt`, `ge`,
   `uminus`, `colon` on MIT, broadcasting alignment for TSeries vs
   MVTSeries, `+`/`-` on MITRange, mixed-frequency guards — must be
   re-added to `DESeries`/`DEDate`. Roughly **2000 lines** of code that
   we already wrote and tested will need to be rewritten against new
   property names (`series.value` not `series.values`, `series.axis(1)`
   not `series.firstdate`), against handle semantics (mutate-or-copy
   decisions everywhere), and against the N-D-friendly axis model. Most
   of the logic transfers — but every single function changes.

2. **Indexing.** Our `subsref`/`subsasgn` is the bulk of the
   complexity. Re-implementing it on a handle class is conceptually
   similar but practically painful, because every "grow the storage"
   step must now decide whether to mutate the receiver in place or
   spawn a new one. Composite paths (`x.a(2020Q1) = 5`) interact with
   `DESeries`'s axis model differently than with our flat
   `firstdate + values`. **Several days of work**, easily.

3. **Tests.** Every test we wrote (currently ~80 cases across
   TestMIT/TestDuration/TestRange/TestDates/TestTSeriesConstruct/
   TestTSeriesIndex, projected to ~250 by the end of Phase 5) names our
   types and methods. A migration touches every test file, because the
   class names change, the constructor signatures change, and the error
   IDs change. None of this is hard work, but it is broad. **Plan on a
   1-to-1 rewrite of the test suite.**

In addition there are some _semantic_ migrations that don't show up as
file diffs but bite at runtime:

- **Value vs handle.** Existing call sites of the form
  ```matlab
  q = t;
  q(2020Q1) = 5;
  ```
  silently change meaning. With our value class, `t` is unaffected;
  with a handle class, `t(2020Q1) == 5` afterwards. Hunting these down
  is detective work, not search-and-replace.
- **Growth-on-assign.** Code that today writes
  `t(qq(2030,1)) = 5;` and expects the series to grow needs an
  explicit `resize`-style call once we move to DataEcon's fixed-axis
  model. Or we have to re-add growth on top of DESeries, which means
  changing `DESeries` itself, which means forking it.
- **Error IDs.** Tests using `verifyError(@(), 'tseries:mixedFreq')`
  become `verifyError(@(), 'DESeries:DimensionMismatch')` or whatever
  the DataEcon equivalent ends up being.

### 5.3 Rough order-of-magnitude estimate

| Migration path                                      | Effort                                  |
| --------------------------------------------------- | --------------------------------------- |
| Add `.daec` file I/O while keeping our types        | ~1 week (mostly converters, one binding)|
| Adopt `DEDate`/`DESeries` *in addition* to ours     | ~2–3 weeks (parallel APIs + bridge)     |
| Replace ours with DESeries, port the API on top     | ~80–90% of the original implementation cost |
| Replace ours and drop the TimeSeriesEcon API        | Smaller, but then the user's request "port TimeSeriesEcon.jl" is no longer fulfilled |

The takeaway: **moving from our finished package to DataEcon's design is
a re-port, not a refactor.** The work scales with code volume, not with
some clever abstraction layer. The only inexpensive merge is the
*interop* one — keep our types, add converters.

---

## 6. Recommendation

Continue with the current plan (port of TimeSeriesEcon.jl) and treat
DataEcon's matlab branch as **a serialization target**, not a
foundation.

When (and if) `.daec` interop becomes a requirement, add a small
companion module — say `+tseries/+daec/` — containing:

- `+tseries/+daec/toDate.m` : `tseries.MIT → DEDate`
- `+tseries/+daec/fromDate.m` : `DEDate → tseries.MIT`
- `+tseries/+daec/toSeries.m` : `tseries.TSeries → DESeries`
- `+tseries/+daec/fromSeries.m` : `DESeries → tseries.TSeries`
- corresponding `toMV`/`fromMV` for MVTSeries
- `+tseries/+daec/write.m` / `read.m` thin wrappers

That keeps our value-class semantics, the operator overloads, and the
growth-on-assign behaviour intact, while making round-tripping through
the binary format a one-liner for users who need it. It also keeps
`libdaec` an *optional* dependency rather than a mandatory one.

The only scenario in which we should seriously revisit this decision is
if downstream institutional MATLAB code already speaks `DESeries`
natively and a wrapper layer ends up adding more friction than it
removes. In that case, the right move is probably the converse: build
the wrapper *the other direction* — extend `DESeries` with the
TimeSeriesEcon operators as a methods overlay, rather than rebasing our
class onto it.

---

*Reference commit examined: `bankofcanada/DataEcon` branch `matlab`,
files under `matlab/`.*
