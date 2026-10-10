"""Write the expected contents of .daec fixtures as JSON (ASCII, so that
MATLAB reads it the same way under any default encoding).

Usage:  python3 -I expect.py OUTDIR FILE.daec [FILE.daec ...]

Reads each file's SQLite tables directly (standard library only, no libdaec)
and writes OUTDIR/<stem>.json, which tests/TestDaecFixtures.m compares with
what tse.daec reads.  One entry per object other than catalogs:

    path, class, type        object row
    freq                     scalar frequency code (scalars only)
    eltype, elfreq           element type and frequency (arrays only)
    axes                     per axis: type, length, freq, first (the first
                             date code, as a string so that 64-bit values
                             survive JSON) and names
    hex                      stored value bytes, lowercase hex
    attrs                    the object's attributes

Database ids, timestamps and the DE_VERSION root attribute are not part of
the expectations.
"""
import json
import pathlib
import sqlite3
import sys


def axis(con, axis_id):
    ax_type, length, freq, data = con.execute(
        "select ax_type, length, frequency, data from axes where id = ?",
        (axis_id,)).fetchone()
    a = {"type": ax_type, "length": length, "freq": freq, "first": None, "names": None}
    if ax_type == 1:
        a["first"] = str(data)
    elif ax_type == 2:
        a["names"] = data.split("\n") if length > 0 else []
    return a


def objects(con):
    rows = con.execute(
        "select o.id, i.fullpath, o.class, o.type from objects o "
        "join objects_info i on i.id = o.id where o.class <> 0 order by o.id")
    for oid, path, cls, typ in rows.fetchall():
        e = {"path": path, "class": cls, "type": typ}
        if cls == 1:
            freq, value = con.execute(
                "select frequency, value from scalars where id = ?", (oid,)).fetchone()
            e["freq"] = freq
        else:
            if cls == 2:
                eltype, elfreq, ax, value = con.execute(
                    "select eltype, elfreq, axis_id, value from tseries where id = ?",
                    (oid,)).fetchone()
                ids = [ax]
            elif cls == 3:
                eltype, elfreq, a1, a2, value = con.execute(
                    "select eltype, elfreq, axis1_id, axis2_id, value from mvtseries "
                    "where id = ?", (oid,)).fetchone()
                ids = [a1, a2]
            else:
                eltype, elfreq, value = con.execute(
                    "select eltype, elfreq, value from ndtseries where id = ?",
                    (oid,)).fetchone()
                ids = [r[0] for r in con.execute(
                    "select axis_id from ndaxes where obj_id = ? order by axis_index",
                    (oid,))]
            e["eltype"] = eltype
            e["elfreq"] = elfreq
            e["axes"] = [axis(con, i) for i in ids]
        e["hex"] = (value or b"").hex()
        e["attrs"] = {n: v for n, v in con.execute(
            "select name, value from attributes where id = ? order by name", (oid,))}
        yield e


def main(outdir, files):
    out = pathlib.Path(outdir)
    out.mkdir(parents=True, exist_ok=True)
    for f in files:
        f = pathlib.Path(f)
        con = sqlite3.connect(f"file:{f.resolve()}?mode=ro", uri=True)
        doc = {"file": f.name, "objects": list(objects(con))}
        con.close()
        (out / (f.stem + ".json")).write_text(
            json.dumps(doc, ensure_ascii=True, indent=0) + "\n", encoding="utf-8")
        print(f"{f.name}: {len(doc['objects'])} objects")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2:])
