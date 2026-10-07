# -*- coding: utf-8 -*-
"""rc16 U0: static lint of the files that changed and nothing else (no mass reformat of a repository this size).

usage: python tools/lint_changed.py [--staged | --base REV] [--demo]
Files: every one changed since REV (default e4bb4df, the rc15 tag) in a commit, in the worktree or untracked; --staged: the index only.
Skipped trees: addons/ _QUARANTINE/ docs/ .claude/ android/ build/ (vendor code, evidence and generated files).
  .gd       gdparse (syntax, no engine needed) and gdlint with ./gdlintrc (the defect-class rules only: comparison with itself, duplicated
            load, expression not assigned, mixed tabs and spaces, trailing whitespace, unnecessary pass)
  .py       ruff E9,F (syntax errors and pyflakes correctness)
  shell     shellcheck -S warning on .sh files and on the extensionless bash wrappers of tools/ (read with the carriage returns stripped)
  workflow  actionlint on .github/workflows/*.yml
A tool that is not installed is reported as SKIPPED. Every finding prints "FAIL <file>: <tool>: <text>" and the exit code is 1.
gdparse (gdtoolkit 4.5.0) cannot read two constructs the engine accepts: a one-line `if` inside a lambda body and a string literal with raw
newlines. GDPARSE_KNOWN names each file that holds one and the text of the failing line: the file passes only while it fails on that line, so a
new syntax error in the same file is still caught (the engine compile gate stays the parse proof for these files). --demo proves the gate on a fixture.
"""
import os
import pathlib
import re
import shutil
import subprocess
import sys
import sysconfig
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
BASE = "e4bb4df"
SKIP_TREES = ("addons/", "_QUARANTINE/", "docs/", ".claude/", "android/", "build/")
GDPARSE_KNOWN = {
    "scripts/ui/character_screen.gd": "tween_callback(func(): if toast: toast.queue_free())",
    "scripts/ui/hud_3d.gd": "func() -> void: if _quick_wheel: _quick_wheel.open()",
    "scripts/ui/puzzle_cables.gd": "tween_callback(func(): if _toast: _toast.queue_free(); _toast = null)",
    "scripts/tools/_closeout_check_runner.gd": 'stand_in.source_code = "extends Node',
}


def run(cmd, stdin=None):
    """(exit code, output). stdin is bytes: text mode would turn \\n into \\r\\n on Windows and put the carriage returns back."""
    r = subprocess.run(cmd, input=stdin, capture_output=True, cwd=ROOT)
    return r.returncode, (r.stdout + r.stderr).decode("utf-8", errors="replace").strip()


def git(*args):
    return run(["git", *args])[1].splitlines()


def tool(name):
    """The command of an installed tool, or None. pip --user puts scripts in a directory that is not on PATH on Windows."""
    found = shutil.which(name)
    if found:
        return found
    scheme = "nt_user" if os.name == "nt" else "posix_user"
    for ext in ("", ".exe"):
        candidate = pathlib.Path(sysconfig.get_path("scripts", scheme)) / (name + ext)
        if candidate.is_file():
            return str(candidate)
    return None


def module(name):
    return [sys.executable, "-m", name] if run([sys.executable, "-m", name, "--version"])[0] == 0 else None


def changed(base, staged):
    if staged:
        files = git("diff", "--cached", "--name-only", "--diff-filter=ACMR")
    else:
        files = git("diff", "--name-only", "--diff-filter=ACMR", base, "HEAD") + git("diff", "--name-only", "--diff-filter=ACMR", "HEAD") + git("ls-files", "--others", "--exclude-standard")
    return sorted({f for f in files if f and not f.startswith(SKIP_TREES) and (ROOT / f).is_file()})


def kind(path):
    if path.endswith(".gd"):
        return "gd"
    if path.endswith(".py"):
        return "py"
    if path.startswith(".github/workflows/") and path.endswith((".yml", ".yaml")):
        return "workflow"
    if path.endswith(".sh"):
        return "sh"
    if path.startswith("tools/") and "." not in pathlib.Path(path).name:
        head = (ROOT / path).read_bytes()[:64]
        return "sh" if head.startswith(b"#!") and b"bash" in head else None
    return None


def spread(text, pattern, out, prefix):
    """Adds each line of a tool's output that matches pattern (path, rest) to the findings of its file."""
    for line in text.splitlines():
        m = re.match(pattern, line)
        if m and m.group(1).replace("\\", "/") in out:
            out[m.group(1).replace("\\", "/")].append("%s: %s" % (prefix, m.group(2)))


def check_gd(paths, known=GDPARSE_KNOWN):
    """{path: [findings]} or None. gdparse runs in process (one parse per file), gdlint once for all the files."""
    try:
        from gdtoolkit.parser import parser
    except ImportError:
        return None
    out = {p: [] for p in paths}
    for path in paths:
        source = (ROOT / path).read_text(encoding="utf-8", errors="replace")
        try:
            parser.parse(source, gather_metadata=False)
        except Exception as error:  # lark raises several exception types
            line = re.search(r"line (\d+)", str(error))
            lines = source.splitlines()
            failing = lines[int(line.group(1)) - 1] if line and int(line.group(1)) <= len(lines) else ""
            if not (path in known and known[path] in failing):
                out[path].append("gdparse: " + " ".join(str(error).split())[:160])
    lint = module("gdtoolkit.linter")
    if lint is not None and paths:
        spread(run(lint + list(paths))[1], r"^(.+?):(\d+: Error: .*)$", out, "gdlint")
    return out


def check_py(paths):
    cmd = module("ruff")
    if cmd is None:
        return None
    out = {p: [] for p in paths}
    spread(run(cmd + ["check", *paths, "--select", "E9,F", "--output-format", "concise", "--no-cache"])[1], r"^(.+?):(\d+:\d+: .*)$", out, "ruff")
    return out


def check_sh(paths):
    cmd = tool("shellcheck")
    if cmd is None:
        return None
    out = {}
    for path in paths:
        text = (ROOT / path).read_bytes().replace(b"\r", b"")
        code, found = run([cmd, "-s", "bash", "-f", "gcc", "-S", "warning", "-"], stdin=text)
        out[path] = []
        spread(found, r"^(-):(\d+:\d+: .*)$", {"-": out[path]}, "shellcheck") if code != 0 else None
    return out


def check_workflow(paths):
    cmd = tool("actionlint")
    if cmd is None:
        return None
    out = {}
    for path in paths:
        code, found = run([cmd, "-no-color", path])
        out[path] = ["actionlint: " + t for t in found.splitlines() if t.strip()] if code != 0 else []
    return out


CHECKS = {"gd": check_gd, "py": check_py, "sh": check_sh, "workflow": check_workflow}


def demo():
    """Each fault of a fixture is reported and the clean file is not."""
    fixtures = {
        "good.gd": "extends Node\n\nfunc ok() -> void:\n\tpass\n",
        "syntax.gd": "extends Node\nfunc broken(:\n",
        "space.gd": "extends Node\nvar a = 1 \n",
        "same.gd": "extends Node\nfunc f(x):\n\treturn x == x\n",
        "unused.py": "import os\n",
        "cd.sh": "#!/usr/bin/env bash\ncd somewhere\nls\n",
    }
    wanted = {"good.gd": 0, "syntax.gd": 1, "space.gd": 1, "same.gd": 1, "unused.py": 1, "cd.sh": 1}
    wrong = []
    with tempfile.TemporaryDirectory(dir=ROOT) as tmp:
        folder = pathlib.Path(tmp)
        for name, body in fixtures.items():
            (folder / name).write_text(body, encoding="utf-8", newline="\n")
        for name, want in wanted.items():
            rel = (folder / name).relative_to(ROOT).as_posix()
            result = CHECKS[kind(rel)]([rel])
            if result is None:
                print("DEMO SKIP %s: tool not installed" % name)
                continue
            found = result[rel]
            if bool(found) != bool(want):
                wrong.append((name, want, found))
    for name, want, found in wrong:
        print("DEMO FAIL %s: wanted %d finding(s), got %s" % (name, want, found))
    print("lint_changed demo: %d fixtures, %d wrong" % (len(wanted), len(wrong)))
    return 1 if wrong else 0


def main(argv):
    if "--demo" in argv:
        return demo()
    staged = "--staged" in argv
    base = argv[argv.index("--base") + 1] if "--base" in argv else BASE
    findings, skipped, checked = [], set(), {"gd": 0, "py": 0, "sh": 0, "workflow": 0}
    groups = {}
    for path in changed(base, staged):
        if kind(path):
            groups.setdefault(kind(path), []).append(path)
    for k, paths in groups.items():
        result = CHECKS[k](paths)
        if result is None:
            skipped.add(k)
            continue
        checked[k] += len(paths)
        findings += ["FAIL %s: %s" % (path, f) for path in paths for f in result.get(path, [])]
    print("\n".join(findings))
    print("lint_changed: %s, skipped tools for: %s, %d finding(s)" % (", ".join("%d %s" % (n, k) for k, n in checked.items()), ", ".join(sorted(skipped)) or "none", len(findings)))
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
