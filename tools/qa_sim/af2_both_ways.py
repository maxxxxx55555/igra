# -*- coding: utf-8 -*-
"""AF2 both-ways run (rc16): the checks of the pass must FAIL on the code before the fixes and PASS on the code after them.

usage: python tools/qa_sim/af2_both_ways.py --base <rev> [--only rc16] [--demo]
       python tools/qa_sim/af2_both_ways.py --analyze [--write]   (re-judges the two saved runs, from .qa_logs/proofs or the committed docs/artifacts/rc16/proofs;
                                                                    read-only unless --write rewrites docs/artifacts/rc16/af2_both_ways.txt)
Runs `CLOSEOUT_ONLY=<only> tools/qa_sim/closeout_check 300` twice, each through tools/qa_sim/proof_run:
  pre   every runtime file that differs between <rev> and HEAD is put back to its <rev> content (a file added since <rev> is moved aside, a
        file deleted since is restored); the checks files and the runner stay, so the new checks meet the old game
  post  the tree is put back to HEAD and the same run repeats
A check id BITES when it is not "ok" before and "ok" after; it is VACUOUS when it is "ok" in both runs; it is BROKEN when it is not "ok"
after. Raw logs: .qa_logs/proofs/af2_pre.out and af2_post.out (copied to docs/artifacts/rc16/proofs/); the verdict table is printed and
saved as docs/artifacts/rc16/af2_both_ways.txt. Exit 1 when any id is VACUOUS or BROKEN, or when no id was seen.
A runtime file is one the game ships (tools/qa_sim/af3_frame_check.py is_runtime); the tree must have no modified tracked file.
"""
import os
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "qa_sim"))
import af3_frame_check  # noqa: E402

LINE = re.compile(r"^\[closeout\] (ok  |FAIL) +(\S+)")
CHECK_ID = re.compile(r"[A-Z][A-Z0-9.]*")  # a closeout line starts with its check id; "the player spawned" is the set-up line, not the check of a fix
ASIDE = ".af2aside"


def git(*args, check=True):
    r = subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if check and r.returncode != 0:
        raise SystemExit("git %s failed: %s" % (" ".join(args), r.stderr.strip()))
    return r.stdout


def parse(log_text):
    """id -> 'ok' | 'FAIL'; an id is ok only when every line that starts with it is ok."""
    seen = {}
    for line in log_text.splitlines():
        m = LINE.match(line)
        if m and CHECK_ID.fullmatch(m.group(2)):
            status = "ok" if m.group(1).startswith("ok") else "FAIL"
            seen[m.group(2)] = "FAIL" if seen.get(m.group(2)) == "FAIL" or status == "FAIL" else "ok"
    return seen


def judge(pre, post, ids):
    rows, bad = [], 0
    for i in ids:
        a, b = pre.get(i, "missing"), post.get(i, "missing")
        if b != "ok":
            verdict = "BROKEN"
        elif a == "ok":
            verdict = "VACUOUS"
        else:
            verdict = "BITES"
        bad += verdict != "BITES"
        rows.append("%-12s pre=%-8s post=%-8s %s" % (i, a, b, verdict))
    return rows, bad


def log_text(run_id):
    """The full engine log a run attached (every ok and FAIL line). The proof's own .out holds only the FAIL and DONE lines the wrapper prints."""
    for proofs in (ROOT / ".qa_logs" / "proofs", ROOT / "docs" / "artifacts" / "rc16" / "proofs"):
        attach = proofs / (run_id + ".attach.closeout_check.log")
        if attach.exists() or (proofs / (run_id + ".out")).exists():
            return (attach if attach.exists() else proofs / (run_id + ".out")).read_text(encoding="utf-8", errors="replace")
    raise SystemExit("no saved run %s in .qa_logs/proofs or docs/artifacts/rc16/proofs" % run_id)


def run_closeout(run_id, only):
    env = dict(os.environ, CLOSEOUT_ONLY=only)
    subprocess.run(["bash", "tools/qa_sim/proof_run", "--launch", "--attach", ".qa_logs/closeout_check.log", run_id, "--",
                    "bash", "tools/qa_sim/closeout_check", "300"], cwd=ROOT, env=env)
    return log_text(run_id)


def report(base, only, pre_text, post_text, write=True):
    pre, post = parse(pre_text), parse(post_text)
    ids = sorted(set(pre) | set(post))
    rows, bad = judge(pre, post, ids)
    done = [ln for ln in post_text.splitlines() if ln.startswith("[closeout] DONE")]
    out = ["AF2 both ways: base %s, HEAD %s, group %s" % (base, git("rev-parse", "--short", "HEAD").strip(), only)] + rows
    out.append("post run: %s" % (done[-1] if done else "no DONE line"))
    out.append("AF2 verdict=%s ids=%d bad=%d" % ("PASS" if bad == 0 and ids else "FAIL", len(ids), bad))
    text = "\n".join(out)
    print(text)
    if write:
        (ROOT / "docs" / "artifacts" / "rc16" / "af2_both_ways.txt").write_text(text + "\n", encoding="utf-8", newline="\n")
    return 0 if bad == 0 and ids else 1


def demo():
    sample = "[closeout] ok   the player spawned\n[closeout] ok   PERF1 a\n[closeout] FAIL PERF1 b\n[closeout] ok   PERF2 c\n[closeout] ok   X9 d\nnoise\n"
    seen = parse(sample)
    assert seen == {"PERF1": "FAIL", "PERF2": "ok", "X9": "ok"}, seen
    rows, bad = judge({"A": "FAIL", "B": "ok", "C": "ok"}, {"A": "ok", "B": "ok", "C": "FAIL"}, ["A", "B", "C", "D"])
    assert [r.split()[-1] for r in rows] == ["BITES", "VACUOUS", "BROKEN", "BROKEN"] and bad == 3, rows
    import tempfile
    proofs = ROOT / ".qa_logs" / "proofs"
    proofs.mkdir(parents=True, exist_ok=True)
    stem = "af2_demo_%d" % os.getpid()
    (proofs / (stem + ".out")).write_text("[closeout] DONE checks=1 fails=0\n", encoding="utf-8")
    assert parse(log_text(stem)) == {}, "without an attached log the filtered .out has no id"
    (proofs / (stem + ".attach.closeout_check.log")).write_text("[closeout] ok   PERF1 a\n[closeout] DONE checks=1 fails=0\n", encoding="utf-8")
    assert parse(log_text(stem)) == {"PERF1": "ok"}, "the attached full log is the one that is read"
    for f in proofs.glob(stem + "*"):
        f.unlink()
    committed = ROOT / "docs" / "artifacts" / "rc16" / "proofs" / (stem + ".attach.closeout_check.log")
    committed.write_text("[closeout] ok   PERF2 c\n[closeout] DONE checks=1 fails=0\n", encoding="utf-8")
    assert parse(log_text(stem)) == {"PERF2": "ok"}, "a fresh clone has no .qa_logs: the committed copy is read"
    committed.unlink()
    del tempfile
    print("af2_both_ways demo OK (id parsing, bites / vacuous / broken, the attached log is read, also from the committed proofs)")


def main():
    args = sys.argv[1:]
    if "--demo" in args:
        demo()
        return 0
    base = args[args.index("--base") + 1] if "--base" in args else "e4bb4df"
    only = args[args.index("--only") + 1] if "--only" in args else "rc16"
    if "--analyze" in args:
        return report(base, only, log_text("af2_pre"), log_text("af2_post"), write="--write" in args)
    dirty = [x for x in git("status", "--porcelain").splitlines() if not x.startswith("??")]
    if dirty:
        raise SystemExit("the tree has modified tracked files, commit or stash first: %s" % dirty[:3])
    status = [x.split("\t") for x in git("diff", "--name-status", base, "HEAD").splitlines()]
    changed = [(s[0][0], s[-1]) for s in status if af3_frame_check.is_runtime(s[-1])]
    modified = [p for k, p in changed if k in "MD"]
    added = [p for k, p in changed if k == "A"]
    print("runtime files changed since %s: %d modified or deleted, %d added" % (base, len(modified), len(added)))
    moved = []
    try:
        for p in modified:
            git("checkout", base, "--", p)
        for p in added:
            src = ROOT / p
            if src.exists():
                src.rename(str(src) + ASIDE)
                moved.append(src)
        pre_text = run_closeout("af2_pre", only)
    finally:
        for p in modified:
            git("checkout", "HEAD", "--", p, check=False)
        for src in moved:
            pathlib.Path(str(src) + ASIDE).rename(src)
    post_text = run_closeout("af2_post", only)
    return report(base, only, pre_text, post_text)


if __name__ == "__main__":
    sys.exit(main())
