# -*- coding: utf-8 -*-
"""U0 (Session 24): the parallel work on origin, branch by branch, and what main already holds of it.

usage: python tools/qa_sim/branch_absorb_sim.py [--check docs/ABSORB_PLAN.md] [--demo]
For every remote branch but main (origin/*): its commits ahead of main and, for each file it changes against the merge base, how main relates to it:
SAME (same path, same blob), MOVED (the blob is at another path), DIVERGED (the path exists with another blob), MISSING (the path is absent), GONE (the
branch deletes it). Prints the table and the PASS or FAIL count. With --check FILE the plan must have a row `| `origin/<branch>` | ... |` with a
disposition word (absorbed, kept, skipped, deleted) for every branch on origin, and a row for a branch that is gone must say "deleted". No remote branch
(a shallow CI clone) is a PASS with 0 branches. A ref that is not under origin/ (a pull request's own ref) is not a branch, and a branch HEAD already
contains (a pull request's head, a branch main absorbed) needs no row. Exit 1 on any FAIL.
"""
import collections
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
DISPOSITIONS = ("absorbed", "kept", "skipped", "deleted")
ROW = re.compile(r"^\|\s*`(origin/[^`]+)`\s*\|(.*)$", re.M)


def git(*args):
    r = subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace")
    return r.stdout


def classify(change, branch_blob, head_blobs, by_blob):
    """The relation of one changed file to main: change is (path, status letter), branch_blob the blob on the branch."""
    path, status = change
    if status == "D":
        return "GONE"
    if head_blobs.get(path) == branch_blob:
        return "SAME"
    if branch_blob in by_blob:
        return "MOVED"
    return "DIVERGED" if path in head_blobs else "MISSING"


def branches():
    out = []
    for line in git("branch", "-r").splitlines():
        name = line.strip()
        if name.startswith("origin/") and "->" not in name and name != "origin/main":
            out.append(name)
    return out


def contained(ref):
    """True when HEAD already holds every commit of the ref."""
    return subprocess.run(["git", "merge-base", "--is-ancestor", ref, "HEAD"], cwd=ROOT, capture_output=True).returncode == 0


def tree(ref):
    """{path: blob id} of a commit."""
    out = {}
    for line in git("ls-tree", "-r", ref).splitlines():
        meta, path = line.split("\t", 1)
        out[path] = meta.split()[2]
    return out


def inventory():
    head = tree("origin/main")
    by_blob = set(head.values())
    rows = []
    for br in branches():
        base = git("merge-base", "origin/main", br).strip()
        ahead = int(git("rev-list", "--count", "origin/main.." + br).strip() or 0)
        blobs = tree(br)
        counts = collections.Counter()
        if base:
            for line in git("diff", "--name-status", "--no-renames", base, br).splitlines():
                status, path = line.split("\t", 1)
                counts[classify((path, status[0]), blobs.get(path, ""), head, by_blob)] += 1
        rows.append((br, ahead, counts))
    return rows


def judge(names, plan_text, merged=()):
    """FAIL lines: a branch on origin with no row or no disposition (a merged one needs none); a row for a branch that is gone that does not say deleted."""
    rows = {m.group(1): m.group(2).lower() for m in ROW.finditer(plan_text)}
    fails = []
    for n in names:
        if n in merged:
            continue
        if n not in rows:
            fails.append("%s: the plan has no row for it" % n)
        elif not any(d in rows[n] for d in DISPOSITIONS):
            fails.append("%s: its row has no disposition (%s)" % (n, "/".join(DISPOSITIONS)))
    for n, text in rows.items():
        if n not in names and "deleted" not in text:
            fails.append("%s: named by the plan, gone from origin, and the row does not say deleted" % n)
    return fails


def demo():
    head = {"a.md": "b1", "b.md": "b2"}
    by_blob = {"b1", "b2"}
    assert classify(("a.md", "M"), "b1", head, by_blob) == "SAME"
    assert classify(("c.md", "A"), "b2", head, by_blob) == "MOVED"
    assert classify(("a.md", "M"), "bX", head, by_blob) == "DIVERGED"
    assert classify(("z.md", "A"), "bY", head, by_blob) == "MISSING"
    assert classify(("a.md", "D"), "", head, by_blob) == "GONE"
    plan = "| `origin/arena/x` | 3 | skipped: superseded |\n| `origin/jules/y` | 3 | no word |\n| `origin/old` | deleted: rejected |\n| `origin/stale` | skipped |\n"
    got = judge(["origin/arena/x", "origin/jules/y", "origin/z", "origin/pr-head"], plan, merged={"origin/pr-head"})
    want = ["origin/jules/y: its row has no disposition (absorbed/kept/skipped/deleted)", "origin/z: the plan has no row for it",
            "origin/stale: named by the plan, gone from origin, and the row does not say deleted"]
    assert got == want, got
    print("branch_absorb_sim demo OK (five relations, a missing row, a row with no disposition, a gone branch, a merged branch with no row)")


def main():
    args = sys.argv[1:]
    if "--demo" in args:
        demo()
        return 0
    rows = inventory()
    print("%-50s %7s  %4s %5s %8s %7s %4s" % ("branch", "commits", "SAME", "MOVED", "DIVERGED", "MISSING", "GONE"))
    for br, ahead, c in rows:
        print("%-50s %7d  %4d %5d %8d %7d %4d" % (br, ahead, c["SAME"], c["MOVED"], c["DIVERGED"], c["MISSING"], c["GONE"]))
    fails = []
    if "--check" in args and rows:  # a clone with no remote branch but main has nothing to hold the plan against
        names = [r[0] for r in rows]
        fails = judge(names, pathlib.Path(args[args.index("--check") + 1]).read_text(encoding="utf-8"), {n for n in names if contained(n)})
    for f in fails:
        print("FAIL", f)
    print("branch_absorb_sim: %d branch(es) on origin, FAIL %d, PASS %d" % (len(rows), len(fails), max(len(rows) - len(fails), 0)))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
