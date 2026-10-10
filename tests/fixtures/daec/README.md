# Julia-written .daec fixtures

The `julia_*.daec` files are copied unchanged from the Python port,
[Nic2020/TimeSeriesEconPy](https://github.com/Nic2020/TimeSeriesEconPy)
(MIT licence), `tests/dataecon/fixtures` at commit
`f9419074331419fd2e0bcc897525a7643bf38d40` (fixtures last changed in
`f90c953b184e97a1ee82e74b9a5005bf54f4340f`).  They were written by
TimeSeriesEcon.jl with DataEcon_jll 0.4.0; that repository's
`tests/dataecon/fixtures/README.md` describes what each file holds and how it
was generated, and its `.toml` files record the provenance of each.

Each `julia_*.json` lists the raw storage of every object in the matching
file (object type, element type and frequency, axes, value bytes,
attributes).  It is generated from the SQLite tables alone, without libdaec:

```text
python3 -I tools/daec_fixtures/expect.py tests/fixtures/daec tests/fixtures/daec/*.daec
```

`tests/TestDaecFixtures.m` reads every object with `tse.daec` and checks that
it lays out to the same storage.  `known_gaps.tsv` lists the objects that do
not, which is the MATLAB side of gap G7 in `lore/GAPS.md`.

Many objects are deliberate controls: values Julia stores but that the Python
port refuses (out-of-window dates, foreign markers, malformed payloads).
