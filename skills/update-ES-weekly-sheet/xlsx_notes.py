#!/usr/bin/env python3
"""Read the ES workbook's cells and notes from the synced file. Stdlib only.

    python xlsx_notes.py context <file.xlsx> <sheet> [YYYY-MM-DD]   # everything steps 1-5 need, one call
    python xlsx_notes.py read    <file.xlsx> [sheet]                # every note, every week

The SharePoint connector strips notes, so they are read from the local file.
Writing goes through es_write.ps1, never through this file.
"""
import calendar, datetime as dt, re, sys, zipfile
from xml.etree import ElementTree as ET

M = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"
RDOC = "{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id"
col = lambda ref: re.match(r"[A-Z]+", ref).group()
row = lambda ref: int(re.search(r"\d+", ref).group())


def cnum(c):
    n = 0
    for ch in c:
        n = n * 26 + ord(ch) - 64
    return n


def cname(n):
    s = ""
    while n:
        n, r = divmod(n - 1, 26)
        s = chr(65 + r) + s
    return s


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


def sheet_notes(z, part):
    """[(ref, [lines])] for one worksheet, "Name:" header dropped, sorted by column then row."""
    rp = part.rsplit("/", 1)[0] + "/_rels/" + part.rsplit("/", 1)[-1] + ".rels"
    if rp not in z.namelist():
        return []
    tgt = next((r.get("Target") for r in ET.fromstring(z.read(rp))
                if r.get("Type").endswith("/comments")), None)
    if not tgt:
        return []
    out = []
    for c in ET.fromstring(z.read("xl/" + tgt.replace("../", ""))).iter(M + "comment"):
        txt = "".join(t.text or "" for t in c.iter(M + "t")).strip()
        txt = re.sub(r"^[^:\n]{0,40}:\s*", "", txt)
        out.append((c.get("ref"), [l.strip() for l in txt.splitlines() if l.strip()]))
    return sorted(out, key=lambda n: (cnum(col(n[0])), row(n[0])))


def read(path, only=None):
    z = zipfile.ZipFile(path)
    for name, part in sheet_parts(z).items():
        if only and name != only:
            continue
        grid = cell_text(z, part)
        print(f"\n===== {name} =====")
        for ref, lines in sheet_notes(z, part):
            print(f"\n[{ref}] week {grid.get(col(ref) + '3', '?')} | "
                  f"{grid.get('A' + str(row(ref)), '?').strip()}")
            for line in lines:
                print("   " + line)


def context(path, sheet, day=None):
    """Tabs, target column, last week vs this week, last week's notes, known ticket wording."""
    z = zipfile.ZipFile(path)
    parts = sheet_parts(z)
    if sheet not in parts:
        sys.exit(f"no tab '{sheet}' - tabs are: {', '.join(parts)}")
    part = parts[sheet]
    g = cell_text(z, part)
    d = dt.date.fromisoformat(day) if day else dt.date.today()
    fri = d + dt.timedelta(days=4 - d.weekday())          # Friday of d's Mon-Sun week

    mon, tgt = None, None
    for n in range(2, cnum("AZ")):
        c = cname(n)
        mon = (g.get(c + "2") or "").strip() or mon        # month is only on a block's first week
        try:
            hit = mon == calendar.month_name[fri.month] and float(g.get(c + "3", "x")) == fri.day
        except ValueError:
            hit = False
        if hit:
            tgt = c
            break
    if not tgt:
        sys.exit(f"no column for Friday {fri} on '{sheet}'")
    prev = cname(cnum(tgt) - 1)

    print(f"tabs: {', '.join(parts)} | {sheet}!A4 = {g.get('A4')}")
    print(f"week ending {fri:%a %d %b %Y} -> column {tgt} (last week {prev})")
    print(f"{'':37}{prev:>6}{tgt:>6}")
    for r in (6, 7, 10, 11, 12, 13, 14, 15, 18):
        lab = (g.get(f"A{r}") or "").strip()[:35]
        fmt = lambda v: "" if v is None else f"{float(v):g}"
        print(f"{r:>2} {lab:35}{fmt(g.get(f'{prev}{r}')):>6}{fmt(g.get(f'{tgt}{r}')):>6}")
    print("   (row 6 and 15 are formulas; cached values are as of the last Excel save)")

    notes = sheet_notes(z, part)
    for c in (prev, tgt):
        mine = [(ref, lines) for ref, lines in notes if col(ref) == c]
        print(f"\nnotes in {c}:" + ("" if mine else " none"))
        for ref, lines in mine:
            print(f"  {ref} {(g.get('A' + str(row(ref))) or '').strip()}")
            for line in lines:
                print("     " + line)

    words = {}                                            # latest wording per ticket id, last 8 weeks
    for ref, lines in notes:
        if cnum(tgt) - 8 <= cnum(col(ref)) <= cnum(tgt):
            for line in lines:
                m = re.match(r"(\d{4,6})\b", line)
                if m:
                    words[m.group(1)] = line
    print("\nknown wording (latest per ticket, last 8 weeks):")
    for k in sorted(words):
        print("  " + words[k])


if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    if sys.argv[1] == "read":
        read(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else None)
    elif sys.argv[1] == "context" and len(sys.argv) > 3:
        context(sys.argv[2], sys.argv[3], sys.argv[4] if len(sys.argv) > 4 else None)
    else:
        sys.exit(__doc__)
