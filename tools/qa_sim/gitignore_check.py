# -*- coding: utf-8 -*-
"""K1.6 (Session 23): the .gitignore holds every generated, exported and secret path, and lets the evidence through.

usage: python tools/qa_sim/gitignore_check.py [--demo]
`git check-ignore` is asked about a list of paths the repository must never track (the engine's import cache, the QA logs, the signing material, the bundles, scratch of an editor
or a patch) and a list it must track (the committed texture sidecars, the proof logs a proof_run attaches). A path on the first list that is not ignored, or on the second that is,
prints "FAIL <path>: <what>" and the exit code is 1. The check also fails when a tracked file is matched by an ignore rule that is not one of the declared exceptions (a file that
was committed before its rule, or in spite of it). --demo proves the judge on a stand-in.
"""
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
MUST_IGNORE = [
    ".godot/imported/a.ctex", ".qa_logs/run.log", ".signing/release.env", ".signing/tls-release.keystore", "build/tls.aab", "exports/tls.aab", "android/build/x.gradle",
    "release.env", "a.keystore", "a.jks", "a.p12", "a.pem", "a.key", "google-services.json", "local.properties", ".env", "x.patch", "x.orig", "x.rej", "x.tmp", "x.swp",
    "scripts/__pycache__/a.pyc", "_BACKUPS/a/b.gd", ".claude/worktrees/a/b.gd", ".claude/settings.local.json", "docs/stills/playthrough/V_t1.jpg", "tools/debug.keystore",
]
MUST_TRACK = [
    "docs/artifacts/rc16/proofs/s23_x.attach.closeout_check.log", "assets/textures/surfaces/a.png.import", "assets/art/a.png.import", "docs/stills/density/a_before_1234567_20260101T000000Z.jpg",
    "scripts/world/district_dressing.gd", "export_presets.cfg", "store/SCREENSHOT_RECIPES.md", "docs/CLEANUP_LEDGER.md",
]


def ignored(path):
    return subprocess.run(["git", "check-ignore", "-q", "--no-index", path], cwd=ROOT).returncode == 0


def judge(is_ignored):
    out = ["%s: not ignored, and it must never be tracked" % p for p in MUST_IGNORE if not is_ignored(p)]
    out += ["%s: ignored, and it must be tracked" % p for p in MUST_TRACK if is_ignored(p)]
    return out


def tracked_but_ignored():
    files = subprocess.run(["git", "ls-files", "-z", "-ci", "--exclude-standard"], cwd=ROOT, capture_output=True).stdout.decode("utf-8", "replace").split("\0")
    return [f for f in files if f]


def demo():
    assert judge(lambda p: True) == ["%s: ignored, and it must be tracked" % p for p in MUST_TRACK]
    assert judge(lambda p: False) == ["%s: not ignored, and it must never be tracked" % p for p in MUST_IGNORE]
    assert judge(lambda p: p in MUST_IGNORE) == []
    print("gitignore_check demo: a path that leaks, a path that is swallowed and a clean list are each told apart")
    return 0


def main(argv):
    if "--demo" in argv:
        return demo()
    bad = judge(ignored)
    bad += ["%s: tracked although a rule ignores it" % f for f in tracked_but_ignored()]
    for line in bad:
        print("FAIL", line)
    print("gitignore_check: %d path(s) that must be ignored, %d that must be tracked, %d fault(s)" % (len(MUST_IGNORE), len(MUST_TRACK), len(bad)))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
