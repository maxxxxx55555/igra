# -*- coding: utf-8 -*-
"""AF2 for Session 26, one launch row: undo one fix or one handler of the pass per check and see that exactly that check fails.

usage: python tools/qa_sim/s26_mutations.py run [--tag s26]   applies each set, runs the s26 closeout group through proof_run --launch (one chain), restores the files byte for byte, judges
       python tools/qa_sim/s26_mutations.py judge LOG0 LOG1    re-judges the two saved runs (no engine)
       python tools/qa_sim/s26_mutations.py apply N | restore  only the two halves, for a chain that runs the group itself (the tree must be clean before `apply`)
       python tools/qa_sim/s26_mutations.py --demo
A mutation is a one-line change that puts back what a fix changed or switches off what a handler does. The run is judged against two sets: every check named by a mutation of the set
must FAIL, and every other check must be ok. Two sets, because two mutations of the same function hide each other: ACHRUN1 (the marks stay) and ACHRUN2 (the counters go) both live in
reset_run_marks and need their own run. Together with the green run of the same group on the unmutated tree (check.sh --all) that is the both-ways proof of AF2.
"""
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
BAK = pathlib.Path(tempfile.gettempdir()) / "tls_s26_mutations"
ACH = "scripts/systems/achievements_manager.gd"
MARKS = 'if String(key).begins_with("seen_") or String(key).begins_with("hurt_"):'
# (file, old text, new text, the check that must fail), one list per run
SETS = [
    [
        (ACH, '_check_unlock(&"ach_01", true)', "pass", "ACHSIG1"),
        (ACH, '_check_unlock(&"ach_02", true)', "pass", "ACHSIG2"),
        (ACH, '_check_unlock(&"ach_03", _all_districts_full())', "pass", "ACHSIG3"),
        (ACH, '_check_unlock(&"ach_05", 50)', '_check_unlock(&"ach_05", 51)', "ACHSIG4"),
        (ACH, '_check_unlock(&"ach_04", _all_docs_collected())', "pass", "ACHSIG5"),
        (ACH, '_check_unlock(&"ach_15", EndingsManager.get_ending() == &"dark")', '_check_unlock(&"ach_15", true)', "ACH15"),
        (ACH, MARKS, "if false:", "ACHRUN1"),
        ("scripts/systems/daily_challenge_manager.gd", 'if not (String(t.get("type", "")) in PER_RUN_TYPES and int(t.get("target", 0)) > DistrictManager.DISTRICTS.size()):', "if true:", "DAILY2"),
    ],
    [
        (ACH, MARKS, "if true:", "ACHRUN2"),
    ],
]
LINE = re.compile(r"^\[closeout\] (ok  |FAIL) +(\S+)")


def apply(index):
    BAK.mkdir(parents=True, exist_ok=True)
    for rel, old, new, _ in SETS[index]:
        path = ROOT / rel
        backup = BAK / rel.replace("/", "_")
        if not backup.exists():
            shutil.copy2(path, backup)
        raw = path.read_bytes().decode("utf-8")
        newline = "\r\n" if "\r\n" in raw else "\n"
        text = raw.replace("\r\n", "\n")
        assert text.count(old) == 1, (rel, old[:60], text.count(old))
        path.write_bytes(text.replace(old, new).replace("\n", newline).encode("utf-8"))


def restore():
    for rel in sorted({m[0] for s in SETS for m in s}):
        path = ROOT / rel
        backup = BAK / rel.replace("/", "_")
        if backup.exists():
            shutil.copy2(backup, path)
            assert path.read_bytes() == backup.read_bytes(), rel
    shutil.rmtree(BAK, ignore_errors=True)


def parse(text):
    seen = {}
    for line in text.splitlines():
        m = LINE.match(line)
        if m and re.fullmatch(r"[A-Z][A-Z0-9.]*", m.group(2)):
            seen[m.group(2)] = "FAIL" if (m.group(1) == "FAIL" or seen.get(m.group(2)) == "FAIL") else "ok"
    return seen


def judge(index, text):
    seen = parse(text)
    expected = {m[3] for m in SETS[index]}
    rows, bad = [], 0
    for check in sorted(expected):
        state = seen.get(check, "missing")
        verdict = "BITES" if state == "FAIL" else ("NOT RUN" if state == "missing" else "VACUOUS")
        bad += verdict != "BITES"
        rows.append("set %d %-8s mutated: %s -> %s" % (index, check, state, verdict))
    stray = sorted(c for c, s in seen.items() if s == "FAIL" and c not in expected)
    bad += len(stray)
    done = [ln for ln in text.splitlines() if ln.startswith("[closeout] DONE")]
    rows.append("set %d failed without a mutation: %s" % (index, ", ".join(stray) or "nothing"))
    rows.append("set %d run: %s" % (index, done[-1] if done else "no DONE line"))
    return rows, bad


def verdict(texts):
    rows, bad = [], 0
    for i, t in enumerate(texts):
        r, b = judge(i, t)
        rows += r
        bad += b
    rows.append("S26 MUTATIONS verdict=%s mutations=%d bad=%d" % ("PASS" if bad == 0 else "FAIL", sum(len(s) for s in SETS), bad))
    return rows, bad


def run(tag):
    dirty = [x for x in subprocess.run(["git", "status", "--porcelain"], cwd=ROOT, capture_output=True, text=True).stdout.splitlines() if not x.startswith("??")]
    if dirty:
        raise SystemExit("the tree has modified tracked files, commit first: %s" % dirty[:3])
    run_id = "%s_mutations" % tag
    steps = []
    for i in range(len(SETS)):
        steps.append("python tools/qa_sim/s26_mutations.py apply %d; bash tools/qa_sim/guarded_headless res://scenes/tools/compile_gate_scene.tscn 120; "
                     "CLOSEOUT_ONLY=s26 bash tools/qa_sim/closeout_check 400; cp .qa_logs/closeout_check.log .qa_logs/%s_set%d.log; python tools/qa_sim/s26_mutations.py restore" % (i, run_id, i))
    attach = []
    for i in range(len(SETS)):
        attach += ["--attach", ".qa_logs/%s_set%d.log" % (run_id, i)]
    try:
        subprocess.run(["bash", "tools/qa_sim/proof_run", "--launch"] + attach + [run_id, "--", "bash", "-c", "; ".join(steps)], cwd=ROOT)
    finally:
        restore()
    texts = [(ROOT / ".qa_logs" / "proofs" / ("%s.attach.%s_set%d.log" % (run_id, run_id, i))).read_text(encoding="utf-8", errors="replace") for i in range(len(SETS))]
    rows, bad = verdict(texts)
    out = "\n".join(rows)
    print(out)
    (ROOT / "docs" / "artifacts" / "rc16" / ("%s_mutations.txt" % tag)).write_text(out + "\n", encoding="utf-8", newline="\n")
    return 1 if bad else 0


def demo():
    for i, s in enumerate(SETS):
        sample = "\n".join(["[closeout] ok   %s x" % m[3] for m in s])
        rows, bad = judge(i, sample)
        assert bad == len(s), "a run in which every mutated check is still ok is vacuous"
        broken = sample.replace("[closeout] ok   %s x" % s[0][3], "[closeout] FAIL %s x" % s[0][3]) + "\n[closeout] FAIL STRAY y"
        rows, bad = judge(i, broken)
        assert bad == len(s) - 1 + 1 and any("STRAY" in r for r in rows)
        rows, bad = judge(i, sample.replace("[closeout] ok   %s x" % s[0][3], ""))
        assert bad == len(s) and any("NOT RUN" in r for r in rows), "a check that never ran is not a check that bites"
    ids = [m[3] for s in SETS for m in s]
    assert len(set(ids)) == len(ids), "one mutation per check"
    print("s26_mutations demo: a vacuous check, a biting check and a stray failure are told apart")
    return 0


if __name__ == "__main__":
    args = sys.argv[1:]
    if "--demo" in args:
        sys.exit(demo())
    if args and args[0] == "judge":
        rows, bad = verdict([pathlib.Path(p).read_text(encoding="utf-8", errors="replace") for p in args[1:]])
        print("\n".join(rows))
        sys.exit(1 if bad else 0)
    if args and args[0] == "apply":
        apply(int(args[1]))
        print("s26_mutations: apply %s done (%d mutations)" % (args[1], len(SETS[int(args[1])])))
        sys.exit(0)
    if args and args[0] == "restore":
        restore()
        print("s26_mutations: restore done")
        sys.exit(0)
    if args and args[0] == "run":
        sys.exit(run(args[args.index("--tag") + 1] if "--tag" in args else "s26"))
    sys.exit("usage: s26_mutations.py run [--tag s26] | apply N | restore | judge LOG0 LOG1 | --demo")
