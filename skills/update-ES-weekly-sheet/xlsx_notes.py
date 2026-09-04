#!/usr/bin/env python3
"""Read Excel cell notes, and repair what officecli breaks when it writes them.

    python xlsx_notes.py read  <file.xlsx> [sheet]
    python xlsx_notes.py fix   <in.xlsx> <out.xlsx> [Sheet!A1 ...]   # blank cells + reorder

Stdlib only. Reading never needs officecli; the SharePoint connector strips notes.
"""
import re, sys, zipfile
from xml.etree import ElementTree as ET

M = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"
RDOC = "{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id"
L = lambda tag: tag.split("}")[-1]
col = lambda ref: re.match(r"[A-Z]+", ref).group()
row = lambda ref: int(re.search(r"\d+", ref).group())


def sheet_parts(z):
    """sheet name -> worksheet part path, in workbook order."""
    rels = {r.get("Id"): r.get("Target")
            for r in ET.fromstring(z.read("xl/_rels/workbook.xml.rels"))}
    wb = ET.fromstring(z.read("xl/workbook.xml"))
    return {s.get("name"): "xl/" + rels[s.get(RDOC)].lstrip("/")
            for s in wb.iter(M + "sheet")}


def cell_text(z, part):
    """cell ref -> displayed text, shared strings resolved."""
    ss = []
    if "xl/sharedStrings.xml" in z.namelist():
        ss = ["".join(t.text or "" for t in si.iter(M + "t"))
              for si in ET.fromstring(z.read("xl/sharedStrings.xml")).iter(M + "si")]
    out = {}
    for c in ET.fromstring(z.read(part)).iter(M + "c"):
        v = c.find(M + "v")
        if v is None or v.text is None:
            continue
        out[c.get("r")] = ss[int(v.text)] if c.get("t") == "s" else v.text
    return out


def read(path, only=None):
    z = zipfile.ZipFile(path)
    for name, part in sheet_parts(z).items():
        if only and name != only:
            continue
        rp = part.rsplit("/", 1)[0] + "/_rels/" + part.rsplit("/", 1)[-1] + ".rels"
        if rp not in z.namelist():
            continue
        tgt = next((r.get("Target") for r in ET.fromstring(z.read(rp))
                    if r.get("Type").endswith("/comments")), None)
        if not tgt:
            continue
        grid = cell_text(z, part)
        weeks = {col(r): grid[r] for r in grid if row(r) == 3}
        labels = {row(r): grid[r] for r in grid if col(r) == "A"}
        print(f"\n===== {name} =====")
        root = ET.fromstring(z.read("xl/" + tgt.replace("../", "")))
        for c in sorted(root.iter(M + "comment"),
                        key=lambda c: (col(c.get("ref")), row(c.get("ref")))):
            ref = c.get("ref")
            txt = "".join(t.text or "" for t in c.iter(M + "t")).strip()
            txt = re.sub(r"^[^:\n]{0,40}:\s*", "", txt)   # drop the "Name:" header
            print(f"\n[{ref}] week {weeks.get(col(ref), '?')} | "
                  f"{labels.get(row(ref), '?').strip()}")
            for line in (l.strip() for l in txt.splitlines()):
                if line:
                    print("   " + line)


def fix(src, dst, blanks=()):
    """Undo officecli's two xlsx sins, and blank cells it cannot blank cleanly.

    1. It emits <ignoredErrors> AFTER <legacyDrawing>; CT_Worksheet requires the
       reverse, and Excel offers to "repair" the file.
    2. Setting a cell to empty leaves a stray value, so blanking is done here.
    """
    by_sheet = {}
    for b in blanks:
        s, ref = b.split("!")
        by_sheet.setdefault(s, set()).add(ref)

    zin = zipfile.ZipFile(src)
    names = {v: k for k, v in sheet_parts(zin).items()}
    order = re.compile(r"(<x:legacyDrawing\b[^>]*/>)"
                       r"(<x:ignoredErrors\b.*?</x:ignoredErrors>)", re.S)
    with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as zout:
        for it in zin.infolist():
            data = zin.read(it.filename)
            if it.filename.startswith("xl/worksheets/sheet"):
                s = data.decode("utf8")
                for ref in by_sheet.get(names.get(it.filename, ""), ()):
                    pat = re.compile(r'<x:c r="%s"([^>]*?)>.*?</x:c>' % ref, re.S)
                    s, n = pat.subn(
                        lambda m: '<x:c r="%s"%s/>' % (ref, re.sub(r'\st="[^"]*"', "", m.group(1))), s)
                    print(f"blanked {ref}: {n}")
                s, n = order.subn(r"\2\1", s)
                if n:
                    print(f"reordered ignoredErrors in {it.filename}")
                data = s.encode("utf8")
            zout.writestr(it, data)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    if sys.argv[1] == "read":
        read(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else None)
    elif sys.argv[1] == "fix":
        fix(sys.argv[2], sys.argv[3], sys.argv[4:])
    else:
        sys.exit(__doc__)
