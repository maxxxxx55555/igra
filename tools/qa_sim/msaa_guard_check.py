#!/usr/bin/env python3
"""G-MSAA regression: a graphics-tier change must not touch msaa_3d on a null viewport.

Defect (2026-11-11, .qa_logs/gate_qa_headless_suite_scene.log line 44):
`SCRIPT ERROR: Invalid assignment of property or key 'msaa_3d' ... on a base
object of type 'null instance'` at scripts/world_env_setup.gd:197, reached from
QualityManager._process -> set_graphics_tier -> _on_settings_changed. The node
is not inside the tree yet, so get_viewport() is null.

The gate fails if any `.msaa_3d =` write is not dominated by a null guard on
the viewport. Accepted forms: a same-line `if get_viewport() != null:` and a
captured `var vp := get_viewport()` followed by `if vp != null:`.

`--demo` strips the guard (re-introducing the historical bare assignment) and
shows the gate FAILS on that mutant while the real file PASSES: a mutation that
bites. Unrelated files and unrelated lines are never scanned.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
TARGET = ROOT / "scripts" / "world_env_setup.gd"

WRITE = re.compile(r"\.msaa_3d\s*=")
SAME_LINE_GUARD = re.compile(r"\bif\s+\w+(?:\(\))?\s*!=\s*null\s*:")
CAPTURE = re.compile(r"var\s+(\w+)\s*:?=\s*get_viewport\(\)")
GUARD_ON = re.compile(r"\bif\s+(\w+)\s*!=\s*null\s*:")


def findings(text: str):
    out = []
    lines = text.splitlines()
    captured = set()
    writes = 0
    for i, line in enumerate(lines, 1):
        captured.update(CAPTURE.findall(line))
        if not WRITE.search(line):
            continue
        writes += 1
        same_line = bool(SAME_LINE_GUARD.search(line))
        earlier = any(
            m.group(1) in captured
            for prev in lines[:i]
            for m in GUARD_ON.finditer(prev)
        )
        if not (same_line or earlier):
            out.append("unguarded .msaa_3d assignment (G-MSAA) at line %d: %s"
                       % (i, line.strip()[-80:]))
    if not writes:
        out.append("no msaa_3d assignment found (the fix removed the tier write)")
    return out


def mutate(text: str) -> str:
    """Re-introduce the historical defect by stripping the same-line guard."""
    return SAME_LINE_GUARD.sub("", text)


def main(argv):
    real = TARGET.read_text(encoding="utf-8")
    real_bad = findings(real)
    if "--demo" in argv:
        mutant = mutate(real)
        mut_bad = findings(mutant)
        bites = (not real_bad) and bool(mut_bad) and mutant != real
        print("msaa_guard_check --demo: real=%s mutation=%s changed=%s -> %s"
              % ("PASS" if not real_bad else "FAIL",
                 "FAIL" if mut_bad else "PASS",
                 mutant != real,
                 "BITES" if bites else "VACUOUS"))
        return 0 if bites else 1
    for f in real_bad:
        print("FAIL %s" % f)
    print("msaa_guard_check: %d finding(s)" % len(real_bad))
    return 1 if real_bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
