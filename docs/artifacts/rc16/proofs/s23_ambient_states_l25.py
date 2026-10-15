# CORRECTION_LOG 252: the ambient light that each view of the density pair run shot under, read from the run's own state lines, at the head before the lighting fix (launch 24, a4acbb5) and at the head with it (the fix chain, ledger row 120).
# The ambient energy of the stage is 0.030 at stage 0 (DARK) and 0.160 at stage 3 (FULL), scripts/world_env_setup.gd (AMBIENT_*), so a stage 0 view that reads 0.160 was shot under the light of the district left.
# usage: python -I s23_ambient_states.py <label>=<pair log> [<label>=<pair log> ...]
import collections
import re
import sys

LINE = re.compile(r"\[density\] state district=(\S+) view=(\S+) weather=\d+ stage=(\d) tier=\d ambient=([0-9.]+)")

for arg in sys.argv[1:]:
    label, path = arg.split("=", 1)
    rows = [LINE.search(line) for line in open(path, encoding="utf-8", errors="replace")]
    rows = [m.groups() for m in rows if m]
    by = collections.Counter((int(s), a) for _, _, s, a in rows)
    dark = [(d, v, a) for d, v, s, a in rows if s == "0"]
    wrong = [(d, v, a) for d, v, a in dark if a != "0.030"]
    first = rows[0][0] if rows else "-"
    print("== %s (%s)" % (label, path))
    print("  state lines: %d (%d districts)" % (len(rows), len({d for d, _, _, _ in rows})))
    print("  by (stage, ambient): " + ", ".join("stage %d ambient %s: %d" % (s, a, n) for (s, a), n in sorted(by.items())))
    print("  stage 0 views: %d; read ambient 0.030: %d; read another ambient: %d" % (len(dark), len(dark) - len(wrong), len(wrong)))
    for d, v, a in wrong:
        print("    %s %s ambient %s" % (d, v, a))
    print("  the first district of the run: %s" % first)
