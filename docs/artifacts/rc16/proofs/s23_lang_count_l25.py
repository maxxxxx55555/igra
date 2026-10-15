# CORRECTION_LOG 258 (LANG-23): the lines of the scripts that hold Cyrillic, how many are comments, and in how many files, all of scripts/**/*.gd and without scripts/tools (the shipped scripts).
import pathlib
import re

ROOT = pathlib.Path("C:/Users/Maxsim/Desktop/TLS_Build/THE_LAST_STREETLIGHT")
CYR = re.compile("[\u0400-\u04FF]")
rows = {"all": [0, 0, set()], "shipped": [0, 0, set()]}
for path in sorted((ROOT / "scripts").rglob("*.gd")):
    rel = path.relative_to(ROOT).as_posix()
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if not CYR.search(line):
            continue
        for key in ("all",) + (() if rel.startswith("scripts/tools/") else ("shipped",)):
            rows[key][0] += 1
            rows[key][1] += line.lstrip().startswith("#")
            rows[key][2].add(rel)
for key, (lines, comments, files) in rows.items():
    print("%-8s %d lines with Cyrillic, %d of them start with #, in %d files" % (key, lines, comments, len(files)))
print("tracked .gd files in the repository: %d, under scripts/: %d" % (len(list(ROOT.rglob("*.gd"))), len(list((ROOT / "scripts").rglob("*.gd")))))
