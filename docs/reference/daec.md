# DataEcon files (daec)

The `tse.daec` subpackage reads and writes DataEcon `.daec` files: SQLite
databases written by the DataEcon library, the same format that
TimeSeriesEcon.jl's `DataEcon` module and the Python port's `tsecon.dataecon`
use. A file written in MATLAB can be read in Julia or Python, and the other way
round.

The DataEcon library (libdaec) ships inside the package for Windows, Linux and
macOS, so nothing else needs installing. `tse.daec.version()` reports the
version in use.

## Reading and writing a database

A database is a MATLAB `struct`. Fields that are structs become catalogs
(folders) in the file.

```matlab
import tse.*
db.gdp   = TSeries(qq(2020, 1), [100; 101.5; 102.1; 103.0]);
db.rates = MVTSeries(mm(2024, 1), ["short" "long"], rand(12, 2));
db.note  = "preliminary";
db.models.alpha = 0.25;            % a catalog with one scalar

tse.daec.writedb('data.daec', db);
r = tse.daec.readdb('data.daec');
r.models.alpha                      % 0.25
```

`writedb` appends to an existing file, as in Julia. Pass `'append', false` to
empty the file first. `writedb('data.daec', '/models', db)` writes into an
existing catalog, and `readdb('data.daec', '/models')` reads one catalog.

`tse.daec.read` and `tse.daec.write` are short forms of `readdb`, and of
`writedb` into an emptied file.

Fields come back in name order, because DataEcon lists a catalog's objects by
name. Fields that cannot be written or read are skipped with a warning.

## What is stored, and what comes back

| MATLAB value | Stored as | Read back as |
|--------------|-----------|--------------|
| number, logical, string or char scalar | scalar | the same class (strings come back as char) |
| `tse.MIT`, `tse.Duration` scalar | date / duration scalar | `tse.MIT`, `tse.Duration` |
| vector, matrix, array of up to 5 dimensions | plain array | the same class and shape |
| string array or cellstr | text array | string array |
| `tse.TSeries` | series on a date axis | `tse.TSeries` |
| `tse.MVTSeries` | date axis × names axis | `tse.MVTSeries` |
| `tse.MITRange` | range | `tse.MITRange` |
| `tse.daec.Array` | axes in any order | `tse.daec.Array` (or a series, if it is one) |
| struct | catalog | struct |

Numbers keep their width: an `int32` stays `int32` and a `single` stays
`single`. Julia's `Float16` values read as `single`, which holds each of them
exactly. Logical values are stored as 1-byte integers with Julia's `Bool`
marker, so they come back as logical in MATLAB and as `Bool` in Julia.

## Arrays with any axes

Every stored array has one axis per dimension. An axis is plain (a length), a
date range, or a list of names, and the axes can come in any order. A
`tse.TSeries` is a single date axis, and a `tse.MVTSeries` is a date axis
followed by a names axis. Other layouts, such as names by dates or a 3-d array
with a date axis, read as a `tse.daec.Array`:

```matlab
ax = [tse.daec.Axis(["a" "b"]), tse.daec.Axis(tse.qq(2020, 1), 4)];
x  = tse.daec.Array(ax, rand(2, 4));          % names by quarters
tse.daec.writedb('data.daec', struct('x', x));

a = tse.daec.Array(db.gdp);   % the axes of a series
s = a.toseries();             % and back
```

## Working with an open file

`tse.daec.opendaec` returns a `tse.daec.File` for finer control. It opens
read-only unless `'write', true` is given:

```matlab
de = tse.daec.opendaec('data.daec', 'write', true);
de.new_catalog('/models');
de.store_scalar('/models', 'n', int32(3));
de.store_tseries('/models/gdp', gdp);
de.set_attribute('/models/gdp', 'source', 'StatCan');
de.list_catalog()                    % prints the tree, returns the paths
x = de.load_tseries('/models/gdp');
de.close();
```

Objects are named by a full path, by a parent catalog and a name, or by the
numeric id that `store_*` and `find_*` return. The other options are
`'append'` (default `true`; `false` empties the file) and `'overwrite'`
(default `false`; `true` replaces an existing object of the same name).
`tse.daec.opendaecmem()` opens a file that lives only in memory.

The `File` methods follow TimeSeriesEcon.jl's names:

| Group | Methods |
|-------|---------|
| Files | `close`, `isopen`, `truncate`, `isempty` |
| Objects and catalogs | `find_object`, `find_fullpath`, `get_fullpath`, `delete_object`, `new_catalog`, `catalog_size`, `list_catalog` |
| Attributes | `get_attribute`, `set_attribute`, `get_all_attributes` |
| Values | `store_scalar` / `load_scalar`, `store_tseries` / `load_tseries`, `store_mvtseries` / `load_mvtseries`, `store_ndtseries` / `load_ndtseries`, `write_data` / `read_data`, `writedb` / `readdb` |

## Compatibility with Julia and Python

`tests/TestDaecFixtures.m` reads all 3,873 objects in the Julia-written test
files of the Python port and checks each one byte for byte against what is
stored. 3,459 read exactly as stored. The others are listed in
`tests/fixtures/daec/known_gaps.tsv` and fall into these known limitations:

- **Int128, UInt128 and ComplexF16 values** have no MATLAB type and are refused.
- **Empty arrays of dates or durations lose their frequency.** A `tse.MIT`
  array keeps a frequency in each element, so an empty one has none, and
  writing one back is an error. Arrays with at least one date are not
  affected, nor are series' date axes.
- **Julia type markers other than `Bool`** (`Rational`, `Symbol`, `Date`,
  `Complex{Int64}` and so on) are ignored, and the stored value is returned
  as is.
- **`Bool` markers on values wider than one byte** read as logical, as in
  Julia's own loader.
- **Unit dates near the Int64 limits** overflow range lengths.
- **Malformed data** that Julia never writes, or that the Python port also
  rejects (dates of the wrong width, invalid UTF-8, strings with embedded
  zeros, `Bool` markers on values other than 0 and 1), is refused rather than
  misread.

Arrays have at most 5 dimensions (DataEcon's limit). MATLAB drops trailing
singleton dimensions, so a stored 3×1×2×1×1 array reads as 3×1×2.

## DataEcon's own MATLAB classes

DataEcon's `matlab` branch has its own classes (`DEFile`, `DESeries`, `DEAxis`,
`DEDate`). That branch is feature-frozen and kept for existing users, such as
IRIS users. New code should use `tse.daec`. For code that still uses those
classes, `tse.daec` converts between them and tse types (with DataEcon's
`matlab/` folder on the path; see `tse.daec.startup`):

| Function | Converts |
|----------|----------|
| `to_date` / `from_date` | `tse.MIT` ↔ `DEDate` |
| `to_range` / `from_range` | `tse.MITRange` ↔ range `DEAxis` |
| `to_series` / `from_series` | `tse.TSeries`, `tse.MVTSeries` ↔ `DESeries` |
| `to_db` / `from_db` | struct of tse series ↔ struct of `DESeries` |
