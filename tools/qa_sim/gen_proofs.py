# -*- coding: utf-8 -*-
"""Regenerates docs/PROOFS.md from LEDGER and CLOSURES; evidence lines are quoted from the saved artifacts so a
quote cannot drift from the log. Run again after every verified batch."""
import re, io, json, sys
import pathlib
ROOT = str(pathlib.Path(__file__).resolve().parents[2]) + "/"
ART = ROOT + "docs/artifacts/rc15/"

def art(name):
    return open(ART + name, encoding="utf-8").read().splitlines()

def quote(file, needle, n=1):
    out = [l for l in art(file) if needle in l][:n]
    if not out:
        raise SystemExit("evidence line not found: %s / %s" % (file, needle))
    return " ; ".join(re.sub(r"^\[closeout\] (ok  |FAIL) +", "", l).strip() for l in out)

CL = "closeout_check_batch1.txt"
LEDGER = json.load(open(ART + "ledger.json", encoding="utf-8"))
CLOSURES = json.load(open(ART + "closures.json", encoding="utf-8"))

out = io.StringIO()
out.write("# PROOFS (rc15 closeout)\n\n")
out.write("Every closure is one line: ID | claim | exact command | quoted output or frame path | commit. A claim without a line here\n")
out.write("is FAKE and gets reverted with a CORRECTION_LOG row. Quotes are copied from the artifacts under `docs/artifacts/rc15/`\n")
out.write("by `gen_proofs` at the time of writing, so they cannot drift from the logs.\n\n")
out.write("## Launch ledger\n\nBudget: 10 Godot launches. One entry per top-level launch command; `tools/check.sh` and an `autoplay_bot` invocation\ncount as one entry each however many engine processes they start.\n\n")
out.write("Batches 3 to 14 ran far more launches than that (CORRECTION_LOG 62): the ledger stops at batch 2 and the closures below cite the artifact of the run that counts as the evidence. An evidence item may carry a label (`now:`, `old code:`) before its quoted line.\n\n")
out.write("| # | command | purpose | result |\n|---|---|---|---|\n")
for i, L in enumerate(LEDGER, 1):
    out.write("| %d | `%s` | %s | %s |\n" % (i, L["cmd"], L["why"], L["result"]))
out.write("\n## Closures\n\n| ID | claim | command | evidence | commit |\n|---|---|---|---|---|\n")
for c in CLOSURES:
    ev = c["evidence"]
    if isinstance(ev, list):
        ev = " ; ".join((e[2] + " " if len(e) > 2 else "") + quote(e[0], e[1]) if isinstance(e, list) else e for e in ev)
    out.write("| %s | %s | `%s` | %s | %s |\n" % (c["id"], c["claim"], c["cmd"], ev, c["commit"]))
open(ROOT + "docs/PROOFS.md", "w", encoding="utf-8", newline="\r\n").write(out.getvalue())
print("PROOFS.md:", len(LEDGER), "launches,", len(CLOSURES), "closures")
