# FAME interop plan

A plan for reading and writing FAME databases from TimeSeriesEcon.m, so users
can pull series out of a `.db` into `tse.TSeries` / `tse.MVTSeries`, run their
analysis, and push results back.

The plan mirrors the IRIS and Dynare interop layouts (converters at the
boundary, no hard dependency), but the shape is different: FAME is a C-only
HLI (Host Language Interface) with a database on disk, not a MATLAB class.
The interop is therefore a **shared-library bridge** driven from MATLAB via
`loadlibrary` / `calllib`, using a committed prototype file so users never
need a C compiler.

The CRAN R `fame` header
([`fame.h`](https://github.com/cran/fame/blob/master/src/fame.h)) is a
purpose-built subset of the FAME HLI covering exactly the read/write/list
workflow we need. That is enough to build against without pulling the full
`hli.h`.

## Goals

- **Numeric and precision time-series read/write** across FAME's standard
  frequencies (annual, semi-annual, quarterly, monthly, all seven weekly
  variants, business, daily).
- **Faithful round-trip** for values, missing markers, frequency, start date,
  and description text.
- **Zero hard dependency** on FAME: nothing outside `+tse/+fame/` looks for
  it, and the subpackage checks at call time only.
- **Zero build step for users.** The `loadlibrary` prototype file is
  committed, so cloning the repo and having `libhli` on the loader path is
  all a user needs.

## Non-goals

- FAME **formula** objects (no read/write). The header exposes no formula
  entry points.
- FAME **STRING series** and **NAMELIST** objects — rare in macro work; can
  be added later using the `cfmgtsts` / `cfmlsts` calls that are in the
  header.
- **CASE / panel** frequencies — the R subset does not include them.
- **Server-side aggregation** (running FAME's own `CONVERT`): pull the raw
  series and use `tse.fconvert` instead.
- Bundling `libhli` — it is proprietary. Users must have FAME installed.

## Deployment story: `loadlibrary`, no per-user compile

The Matlab-facing bridge is `loadlibrary` / `calllib`, not MEX. That is a
deliberate choice for the "clone the repo and go" workflow: MEX ships a
platform-specific `.mex*` file per platform and needs a C compiler +
`$FAME` visible at the user's install time; `loadlibrary` needs neither.

`loadlibrary` does need a **prototype file** — a MATLAB-parseable
description of the C entry points. MATLAB can auto-generate one from
`fame.h` (that step needs a compiler) but the generated file is plain
MATLAB and gets committed to the repo. The user never sees the header
again.

Maintainer, once:

```matlab
loadlibrary('hli', fullfile(getenv('FAME'), 'hli', '64', 'fame.h'), ...
    'mfilename', '+tse/+fame/private/hli_proto', 'notempdir');
```

User, every time — no compiler, no `fame.h`, no `$FAME`:

```matlab
loadlibrary('hli', @tse.fame.private.hli_proto);
```

MATLAB picks the platform-specific library name automatically
(`libhli.so` / `libhli.dylib` / `fame.dll`).

Living with the two `loadlibrary` papercuts:

- `cfmrrng` / `cfmwrng` are `#define` macros in the header that forward to
  `cfmrrng_f` / `cfmwrng_f`; `calllib` binds against the real symbols so
  our wrapper always talks to the `_f` names.
- `cfmrrng`'s `void *valary` is `float*` or `double*` depending on whether
  the series is NUMERIC or PRECISION. We resolve that from the value type
  returned by `cfmwhat` and allocate the correct `libpointer` at the call
  site, so the prototype file itself stays untouched.

Location:

```
+tse/+fame/private/hli_proto.m           the committed prototype (checked in)
+tse/+fame/regenerate_proto.m            maintainer helper (calls loadlibrary
                                          with the generator flags)
```

## File layout

Same shape as `+tse/+iris/` and `+tse/+dynare/`:

```
+tse/+fame/
  Contents.m
  isavailable.m           libhli loadable (loads it lazily on first call)
  startup.m               explicit load + cfmini
  shutdown.m              cfmfin + unloadlibrary
  regenerate_proto.m      maintainer: regenerate hli_proto from $FAME/hli
  freq_to_fame.m          tse.Frequency -> FAME freq int
  freq_from_fame.m        FAME freq int -> tse.Frequency
  from_index.m            (freq, index)          -> tse.MIT
  to_index.m              tse.MIT                -> (freq, index)
  opendb.m                path + access mode     -> Database handle
  Database.m              classdef with delete() that calls cfmcldb
  list.m                  db + pattern           -> cellstr of series names
  read.m                  db + name              -> tse.TSeries or MVTSeries
  write.m                 db + name + tse.*      -> (nothing)
  del.m                   db + name              -> (delete object)
  rename.m                db + oldname + newname -> (rename object)
  info.m                  db + name              -> struct (from cfmwhat)
  check_conflicts.m       usual (mostly a no-op; nothing bare collides)
  private/
    hli_proto.m           committed loadlibrary prototype (checked in)
    fame_status.m         status int -> friendly error string via cfmferr
    fame_missing.m        FNUMNA/NC/ND / FPRCNA/NC/ND handling
    fame_freq_table.m     the hardcoded (Annual=9, Quarterly=17, …) table
```

## Bridge primitives

### `$FAME` environment variable

Only `regenerate_proto.m` (the maintainer helper) looks at `$FAME`, to
locate the header:

```matlab
famehome = getenv('FAME');
header   = fullfile(famehome, 'hli', '64', 'fame.h');   % or 'hli/fame.h'
```

Users don't need `$FAME` set, don't need the header, and don't need a
compiler.

**Runtime library path is the user's responsibility.** `startup.m` and
`isavailable.m` assume `libhli` is already reachable from the process —
via `LD_LIBRARY_PATH` on Linux / macOS, or `PATH` on Windows — the same
way FAME's own CLI expects it. We don't mutate the env from inside MATLAB
(MATLAB caches the loader state at startup, so `setenv` after the fact is
unreliable on some platforms). `isavailable` returns `false` with a hint
pointing at `LD_LIBRARY_PATH` if the loader can't find the DLL.

### Frequency mapping

FAME frequency codes we need (from the FAME HLI docs; only `HDAILY = 8` is in
the CRAN header):

| tse class               | FAME code | Notes |
|-------------------------|----------:|-------|
| `tse.Yearly(12)`        | 9         | Annual  |
| `tse.HalfYearly(6)`     | 15        | Semi-annual |
| `tse.Quarterly(3)`      | 17        | Quarterly |
| `tse.Monthly`           | 129       | Monthly |
| `tse.Weekly(1)…Weekly(7)`| 32…38    | Weekly Mon…Sun |
| `tse.Daily`             | 8         | Daily (in header as `HDAILY`) |
| `tse.BDaily`            | 13        | Business |

`freq_to_fame` picks by class + `endPeriod`; `freq_from_fame` inverts.

### Date ↔ FAME index

FAME encodes each date as an integer index within the given frequency. The
header exposes `cfmdatd(status, freq, indx, y, m, d)` (index → y/m/d) and
`cfmddat(status, freq, y, m, d, indx)` (y/m/d → index). We wrap:

- `from_index(freq, indx)`: call `cfmdatd`, then build the matching `tse.MIT`
  via `tse.day` / `tse.week` / `tse.MIT(F, y, p)` depending on the frequency
  class.
- `to_index(m)`: extract y/m/d/p from the MIT, call `cfmddat` in the
  matching frequency.

## Read / write operations

### `opendb(path, access)`

```matlab
db = tse.fame.opendb('mydata.db', 'read');    % or 'write', 'create'
```

Returns a `tse.fame.Database` value class holding the FAME `dbkey`
(returned by `cfmopdb`) plus the source path and access mode. The class's
`delete` method calls `cfmcldb` so the database closes when the handle goes
out of scope. `access` is a friendly name mapped internally to the numeric
mode FAME expects.

### `info(db, name)` — series metadata

Thin wrapper over `cfmwhat`. Returns a struct with fields:

```
class type freq basis observed first_index last_index n_obs
first_mit last_mit  description  documentation
```

`first_mit` / `last_mit` come from `from_index(freq, first_index/last_index)`
— those are the values users actually want. This lookup is what `read.m`
uses to decide the value-buffer type (NUMERIC → float32, PRECISION → double)
and to size the output.

### `read(db, name)`

1. `meta = info(db, name)`.
2. Reject `meta.class ~= HSERIE` with a clear message ("only SERIES objects
   are supported; use tse.fame.info for FORMULA / SCALAR").
3. Allocate a MATLAB buffer (`single` or `double`) sized to `meta.n_obs`.
4. Call `cfmrrng` with the whole `[first_index, last_index]` range and a
   missing-value translation table (`HTMIS`) that maps FAME's three missing
   markers (`FNUMNA/NC/ND` or `FPRCNA/NC/ND`) to `NaN`.
5. Cast to `double`, build `tse.TSeries(meta.first_mit, values)`, and
   attach `meta.description` as the series name.

Result: a `tse.TSeries` — always `double`, always `NaN` for missing,
regardless of FAME storage type.

### `write(db, name, t)`

1. Look up whether `name` already exists (`cfmwhat`); if not, `cfmnwob` to
   create it with class = HSERIE, type = HPRECN (double storage by default;
   optional NUMERIC via a `'type'` name-value), basis / observed defaulting
   to `HBSDAY` / `HOBAVG`, and frequency from `freq_to_fame(frequencyof(t))`.
2. Build FAME `[first_index, last_index]` from
   `to_index(firstdate(t))` and `to_index(lastdate(t))`.
3. Reverse-translate `NaN` → `FPRCNA` (or `FNUMNA` for NUMERIC).
4. Call `cfmwrng`.

If `t` is a `tse.MVTSeries`, iterate columns using `colnames` as the base of
each object name (`name.gdp`, `name.cpi`, …) — plain multi-column series
don't exist in FAME.

### `list(db, pattern)`

`cfminwc(db, pattern)` + repeated `cfmnxwc` until the wildcard is exhausted;
return a cellstr. Filter by object class = SERIES when asked (`'seriesOnly',
true`).

### `del(db, name)`, `rename(db, old, new)`

One-line wrappers over `cfmdlob` / `cfmrnob`.

## Missing-value handling

FAME has three missing kinds: **NA** (Not Available), **NC** (Not
Computable), **ND** (Not Defined). MATLAB has only `NaN`. On read the
translation table folds all three to `NaN`; on write `NaN` becomes `NA`
(the most benign kind). If a caller needs to distinguish the three, they can
use `'preserve_missing', true` on `read`, which fills the return with three
distinct sentinel values (also chosen from the FAME constants) and returns
them alongside.

## Namespace conflicts

Effectively none. Every FAME entry point is prefixed `cfm*` and reached
via `calllib('hli', 'cfm…', …)`; every helper is namespaced under
`tse.fame`. The only bare class name we introduce is `tse.fame.Database`,
which is already namespaced.

`check_conflicts.m` still ships for consistency with the other two interop
subpackages; it looks for `cfm*` and `tse.fame.*` shadowing but is expected
to find nothing.

## Test coverage

A `tests/TestFameInterop.m` that:

- **Skips itself cleanly** (`assumeFail`) unless `tse.fame.isavailable()`
  returns true. So CI without FAME stays green.
- Round-trips a quarterly `tse.TSeries` to a temp `.db` and back, checks
  values / start date / frequency.
- Repeats for monthly, annual, weekly (Mon-end), business, daily.
- Confirms `NaN` on both sides survives the round trip.
- Round-trips a small `tse.MVTSeries` (per-column names become series names,
  read back and reassembled).
- Checks the `del` and `rename` paths.
- Uses a temporary `.db` file that gets cleaned up in `TestClassTeardown`.

The suite runs against the user's own FAME install — we cannot ship a
sample `.db`.

## Phasing

Same commit-sized cadence as the IRIS plan:

1. **Probe + load.** `Contents.m`, `isavailable.m`, `startup.m`,
   `shutdown.m`, the committed `hli_proto.m`, `regenerate_proto.m`. Smoke
   path: init the HLI (`cfmini`), issue a trivial `cfmfame` command,
   shutdown (`cfmfin`), unload.
2. **Frequency + date primitives.** `freq_to_fame`, `freq_from_fame`,
   `from_index`, `to_index`. Direct `calllib` unit tests for the FAME
   constants that `cfmdatd`/`cfmddat` should agree on.
3. **Database handle + metadata.** `opendb`, `Database`, `info`, `list`,
   `del`, `rename`. Enough to open a `.db` and enumerate it.
4. **Read.** `read.m` covering NUMERIC and PRECISION SERIES for each
   supported frequency. Missing-value fold-in.
5. **Write.** `write.m` including auto-`cfmnwob` for new names and MVTSeries
   splitting into per-column objects.
6. **Docs.** `docs/design/fame_interop.md` (same shape as
   `iris_interop.md` / `dynare_interop.md`), added to `mkdocs.yml`. Update
   `README.md`'s "What's included" line to mention FAME with a note that the
   HLI binary is user-supplied.

Roughly one commit per phase. Total code is smaller than the IRIS port
because the surface is narrower — the whole interop should fit in maybe
15 MATLAB files plus one ~200-line C shim.
