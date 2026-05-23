# Workspaces (MATLAB structs)

The Julia and Python ports have a dedicated `Workspace` type — an ordered,
attribute-accessible container for heterogeneous values (ranges, scalars, series
of any frequency, nested workspaces). **MATLAB has no separate `Workspace` class
in this port; the idiomatic equivalent is the native `struct`.**

A `struct` already provides everything `Workspace` does:

| Workspace (Julia/Python) | MATLAB `struct` |
|--------------------------|-----------------|
| `w = Workspace()` | `w = struct()` |
| `w.x = value` | `w.x = value` |
| `w.x` (read) | `w.x` |
| `delete!(w, :x)` / `del w.x` | `w = rmfield(w, 'x')` |
| iterate members | `fieldnames(w)` |
| nested workspaces | nested structs |

```matlab
import tse.*
w = struct();
w.rng   = MITRange(qq(2020, 1), qq(2021, 4));
w.alpha = 0.1;
w.v     = TSeries(qq(2020, 1), rand(6, 1));
disp(w)

w = rmfield(w, 'alpha');
```

## Workspace-style operations

The package helpers that take "workspace-like" containers accept structs and
recurse field-by-field:

- [`overlay(w1, w2, ...)`](various.md#overlay) — first-valid-wins composition
  across matching fields.
- [`compare_ts(w1, w2, ...)`](various.md#compare) — recursive comparison under
  tolerance.

```matlab
w1 = struct('x', TSeries(qq(2020,1), [1;NaN;3]), 'a', 1);
w2 = struct('x', TSeries(qq(2020,1), [9;2;9]),   'b', 5);
overlay(w1, w2)                 % field-by-field overlay
compare_ts(w1, w1, 'nans', true)   % true
```

## Converting to / from MVTSeries

- **MVTSeries → struct:** `columns(mv)` returns a struct of `TSeries`.
- **struct → MVTSeries:** build an `MVTSeries` from the struct's same-frequency
  `TSeries` fields over their shared (or spanning) range.

!!! info "Julia ↔ MATLAB"
    Corresponds to *Workspaces*. The only difference from Julia/Python is that
    there is no `Workspace` type — use `struct`. `reindex` dispatches over MIT /
    MITRange / TSeries (not over structs); reindex individual fields if needed.
