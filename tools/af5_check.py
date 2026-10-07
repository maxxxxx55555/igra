# -*- coding: utf-8 -*-
"""AF5 citation gate (rc16): a doc line that cites `path:line` is only evidence while the code at HEAD still says what it claims.

usage: python tools/af5_check.py [--base REV] [--file DOC]... [--all] [--demo]
Scope: the doc lines added since REV (default e4bb4df, the rc15 tag; committed, uncommitted and untracked docs). docs/artifacts/ and
docs/stills/ are raw evidence and skipped; RUN_STATE.md counts from its newest "## Session" block only (older blocks are the history of
code that has moved on). --file checks every line of the named docs, --all every citation of every doc (informational: old docs hold stale lines).
A citation is `path:N`, `path:N-M` or `path:N,M-K` with a source extension; `res://` and a bare file name that is unique among tracked files resolve.
  C1 the file resolves to one tracked or existing file
  C2 every cited line exists (1 <= N <= M <= line count)
  C3 when a backticked claim stands right before the citation (`claim` (`path:N`), `claim` at `path:N`; a commit hash is no claim), a word of the
     claim (an identifier of 3 or more characters) occurs in the cited lines; a citation with no such claim is checked by C1 and C2 only
Every violation prints "FAIL <doc>:<doc line>: <citation>: <reason>" and the exit code is 1. --demo proves the gate on a fixture: the
good citations pass and each of the four faults is reported.
"""
import pathlib
import re
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
CITE = re.compile(r"(?P<path>(?:res://)?[\w./\\-]+\.(?:gd|tscn|tres|gdshader|py|sh|json|md|cfg|godot|ps1|yml)):(?P<spec>\d+(?:-\d+)?(?:,\d+(?:-\d+)?)*)")
SPAN = re.compile(r"`([^`]+)`")
WORD = re.compile(r"[A-Za-z_][A-Za-z0-9_]{2,}")
HASH = re.compile(r"[0-9a-f]{7,40}")
LINK = re.compile(r"^[\s`]*(?:\(|at|in|see|from|:|-|—|–)?[\s(`]*$")
SKIP = ("docs/artifacts/", "docs/stills/")
TRACKED = None


def git(*args):
    r = subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace")
    return r.stdout


def resolve(raw):
    global TRACKED
    path = raw.replace("res://", "").replace("\\", "/")
    if (ROOT / path).is_file():
        return path
    if "/" in path:
        return None
    if TRACKED is None:
        TRACKED = git("ls-files").split("\n")
    hits = [t for t in TRACKED if t.endswith("/" + path) or t == path]
    return hits[0] if len(hits) == 1 else None


def check_line(doc, number, text, root=None):
    """The FAIL messages of one doc line."""
    out = []
    spans = [(m.start(), m.end(), m.group(1)) for m in SPAN.finditer(text)]
    for m in CITE.finditer(text):
        label = m.group(0)
        path = resolve(m.group("path"))
        if path is None:
            out.append((doc, number, label, "C1 the file does not resolve to one file"))
            continue
        lines = (ROOT / path).read_text(encoding="utf-8", errors="replace").splitlines()
        ranges = [tuple(int(x) for x in (part.split("-") * 2)[:2]) for part in m.group("spec").split(",")]
        bad = [r for r in ranges if not 1 <= r[0] <= r[1] <= len(lines)]
        if bad:
            out.append((doc, number, label, "C2 line %d-%d is past the end (%d lines)" % (bad[0][0], bad[0][1], len(lines))))
            continue
        cited = " ".join(" ".join(lines[a - 1:b]) for a, b in ranges)
        claim = None
        for start, end, span in spans:
            if end <= m.start() and not CITE.search(span) and not HASH.fullmatch(span) and LINK.match(text[end:m.start()]):
                claim = span
        words = WORD.findall(claim) if claim else []
        if words and not any(w in cited for w in words):
            out.append((doc, number, label, "C3 none of %s occurs in the cited lines" % ", ".join(words[:4])))
    return out


def added_lines(base):
    """(doc, number, text) of every checked doc line added since base."""
    docs = [d for d in git("ls-files", "docs").split("\n") + git("ls-files", "--others", "--exclude-standard", "docs").split("\n") if d.endswith(".md") and not d.startswith(SKIP)]
    for doc in sorted(set(docs)):
        text = (ROOT / doc).read_text(encoding="utf-8", errors="replace").splitlines()
        tracked = bool(git("ls-files", doc).strip())
        added = set(range(1, len(text) + 1))
        if tracked:
            added = set()
            for h in re.finditer(r"^@@ -\S+ \+(\d+)(?:,(\d+))? @@", git("diff", "-U0", base, "--", doc), re.M):
                first, count = int(h.group(1)), int(h.group(2) or 1)
                added.update(range(first, first + count))
        if doc.endswith("RUN_STATE.md"):
            heads = [i for i, t in enumerate(text, 1) if t.startswith("## Session")]
            added = {n for n in added if heads and n >= heads[0] and n < (heads[1] if len(heads) > 1 else len(text) + 1)}
        for n in sorted(added):
            yield doc, n, text[n - 1]


def demo():
    """A fixture: two good citations pass, and a wrong file, a line past the end, a wrong line and a missing claim word are each reported."""
    with tempfile.TemporaryDirectory() as tmp:
        fixture = pathlib.Path(tmp) / "af5_demo_fixture.gd"
        fixture.write_text("\n".join(["extends Node", "signal hit(amount)", "var hp = 3", "func damage():", "\thp -= 1"]) + "\n", encoding="utf-8")
        rel = fixture.relative_to(tmp).as_posix()
        global ROOT
        saved = ROOT
        ROOT = pathlib.Path(tmp)
        try:
            cases = {
                "`signal hit` (`%s:2`)" % rel: 0,
                "damage lowers it, `hp` at `%s:5`" % rel: 0,
                "`hit` (`nowhere/none.gd:1`)": 1,
                "`hp` (`%s:99`)" % rel: 1,
                "`hit` (`%s:3`)" % rel: 1,
            }
            wrong = [(text, want, len(check_line("demo.md", 1, text))) for text, want in cases.items() if len(check_line("demo.md", 1, text)) != want]
        finally:
            ROOT = saved
    for text, want, got in wrong:
        print("DEMO FAIL expected %d finding(s), got %d: %s" % (want, got, text))
    print("af5_check demo: %d cases, %d wrong" % (len(cases), len(wrong)))
    return 1 if wrong else 0


def main(argv):
    if "--demo" in argv:
        return demo()
    base = argv[argv.index("--base") + 1] if "--base" in argv else "e4bb4df"
    files = [argv[i + 1] for i, a in enumerate(argv) if a == "--file"]
    if files:
        lines = [(f, n, t) for f in files for n, t in enumerate((ROOT / f).read_text(encoding="utf-8", errors="replace").splitlines(), 1)]
    elif "--all" in argv:
        lines = [(d, n, t) for d in git("ls-files", "docs").split("\n") if d.endswith(".md") and not d.startswith(SKIP) for n, t in enumerate((ROOT / d).read_text(encoding="utf-8", errors="replace").splitlines(), 1)]
    else:
        lines = list(added_lines(base))
    findings = [f for doc, n, text in lines for f in check_line(doc, n, text)]
    cites = sum(len(CITE.findall(t)) for _, _, t in lines)
    for doc, n, label, why in findings:
        print("FAIL %s:%d: %s: %s" % (doc, n, label, why))
    print("af5_check: %d citation(s) in %d doc line(s), %d finding(s)" % (cites, len(lines), len(findings)))
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
