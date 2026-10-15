# -*- coding: utf-8 -*-
"""U0.3 (Session 24): the proofs audit. docs/PROOFS.md says "a claim without a row here is FAKE"; this holds the rows themselves.

usage: python tools/qa_sim/proofs_audit_sim.py [--demo]
For every closure of docs/artifacts/rc16/closures.json: the id is unique, its proof log exists and ends with its "# EXIT=" line, its attached log exists when it names one,
its commit resolves in this repository, and the row of docs/PROOFS.md is the row gen_proofs16.py builds from the log today (the same sha256 of the log with its line
ends read as LF, the same exit code, the same first line of each quote, the same frame stamps). Prints the PASS and FAIL counts; exit 1 on any FAIL.
"""
import json
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "qa_sim"))
import gen_proofs16  # noqa: E402


def commit_resolves(rev):
    return subprocess.run(["git", "cat-file", "-e", rev + "^{commit}"], cwd=ROOT, capture_output=True).returncode == 0


def judge(closures, logs, committed_rows, resolves):
    """FAIL lines for closures: logs maps proof name to its text (None when absent), committed_rows maps id to its PROOFS.md line."""
    fails, seen = [], set()
    for c in closures:
        i = c["id"]
        if i in seen:
            fails.append("%s: the id is not unique" % i)
        seen.add(i)
        text = logs.get(c["proof"])
        if text is None:
            fails.append("%s: the proof log %s is absent" % (i, c["proof"]))
        elif not re.search(r"^# EXIT=\d+$", text, re.M):
            fails.append("%s: %s has no # EXIT= line" % (i, c["proof"]))
        if not resolves(c["commit"]):
            fails.append("%s: the commit %s does not resolve" % (i, c["commit"]))
        if i not in committed_rows:
            fails.append("%s: no row in docs/PROOFS.md" % i)
    return fails


def main():
    if "--demo" in sys.argv:
        cs = [{"id": "A", "proof": "p1", "commit": "abc1234"}, {"id": "A", "proof": "p2", "commit": "bad"}, {"id": "B", "proof": "p3", "commit": "abc1234"}]
        got = judge(cs, {"p1": "x\n# EXIT=0\n", "p2": "no exit line"}, {"A": "row"}, lambda r: r == "abc1234")
        want = ["A: the id is not unique", "A: p2 has no # EXIT= line", "A: the commit bad does not resolve",
                "B: the proof log p3 is absent", "B: no row in docs/PROOFS.md"]
        assert got == want, got
        print("proofs_audit_sim demo OK (a repeated id, a log with no exit line, a commit that does not resolve, an absent log, a missing row)")
        return 0
    closures = json.loads(gen_proofs16.CLOSURES.read_text(encoding="utf-8"))
    logs = {}
    for c in closures:
        p = gen_proofs16.LOGS / (c["proof"] + ".out")
        logs[c["proof"]] = p.read_text(encoding="utf-8", errors="replace") if p.is_file() else None
    text = gen_proofs16.PROOFS.read_text(encoding="utf-8").replace("\r\n", "\n")
    section = text[text.index(gen_proofs16.BEGIN):text.index(gen_proofs16.END)]
    committed = {m.group(1): m.group(0) for m in re.finditer(r"^\| ([A-Za-z0-9._-]+) \|.*$", section, re.M)}
    cache = {}
    fails = judge(closures, logs, committed, lambda r: cache.setdefault(r, commit_resolves(r)))
    for c in closures:
        if c["id"] in committed and logs.get(c["proof"]) is not None:
            try:
                built = gen_proofs16.row(c)
            except SystemExit as e:
                fails.append("%s: %s" % (c["id"], e))
                continue
            if built != committed[c["id"]]:
                fails.append("%s: its row in docs/PROOFS.md is not the row of its log today (a log, a frame or a quote moved)" % c["id"])
    for f in fails:
        print("FAIL", f)
    bad = len({f.split(":")[0] for f in fails})
    print("proofs_audit_sim: %d closure(s), PASS %d, FAIL %d" % (len(closures), len(closures) - bad, bad))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
