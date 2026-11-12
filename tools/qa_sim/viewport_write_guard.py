#!/usr/bin/env python3
"""Viewport-write guard (G-MSAA, RELEASE_GAP_FINAL §3).

`get_viewport()` is null while a node is not inside a tree, and two production call sites wrote a Viewport property
through the bare call: `world_env_setup.gd` (the MSAA tier, applied from SettingsManager's `settings_changed` signal)
and `dynamic_resolution.gd` (the 3D scale of a drop). The headless suite drove the first one on a detached instance
and the engine printed "Cannot call method 'set_msaa_3d' on a null value" mid-apply — a real script error, and the
tier's environment half never ran (`.qa_logs/gate_qa_headless_suite_scene.log:44`). Reads through the call
(`get_viewport().get_camera_3d()`) return null safely; only a property WRITE needs the guard.

Rule: in `scripts/` (the QA harnesses under `scripts/tools/` are excluded — they run only inside a live tree), a
property write on a bare `get_viewport()` is a failure unless the same line or one of the four lines above it proves
the viewport is not null (`if vp != null`, `if get_viewport() != null`).

Run: python tools/qa_sim/viewport_write_guard.py        (--demo: self-check on synthetic text)
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SCRIPTS = ROOT / "scripts"
EXEMPT_DIRS = ("tools",)
# `get_viewport().<property> = ...` — a write, not a method call (those end with a parenthesis).
WRITE = re.compile(r"get_viewport\(\)\s*\.\s*([A-Za-z_]\w*)\s*=(?!=)")
GUARD = re.compile(r"(?:if\s+)?(?:vp|get_viewport\(\))\s*(?:!=\s*null|==\s*null\s*:\s*$)")
WINDOW = 4


def guarded(lines: list, idx: int) -> bool:
    for line in lines[max(0, idx - WINDOW): idx + 1]:
        if GUARD.search(line):
            return True
    return False


def violations(text: str, name: str = "") -> list:
    lines = text.splitlines()
    out = []
    for i, line in enumerate(lines):
        code = line.split("##")[0]
        m = WRITE.search(code)
        if not m:
            continue
        if guarded(lines, i):
            continue
        out.append((name, i + 1, m.group(1), line.strip()))
    return out


def demo() -> int:
    bad = (
        "func _apply(tier: int) -> void:\n"
        "\tget_viewport().msaa_3d = MSAA_BY_TIER[tier]\n"
    )
    good = (
        "func _apply(tier: int) -> void:\n"
        "\tvar vp := get_viewport()\n"
        "\tif vp != null:\n"
        "\t\tvp.msaa_3d = MSAA_BY_TIER[tier]\n"
    )
    guard_line = (
        "func _apply(tier: int) -> void:\n"
        "\tif get_viewport() != null:\n"
        "\t\tget_viewport().msaa_3d = MSAA_BY_TIER[tier]\n"
    )
    read_only = "func _apply() -> void:\n\tvar cam := get_viewport().get_camera_3d()\n"
    assert len(violations(bad)) == 1, violations(bad)
    assert violations(good) == [], violations(good)
    assert violations(guard_line) == [], violations(guard_line)
    assert violations(read_only) == [], violations(read_only)
    print("viewport_write_guard demo ok (bare write bites, guarded write and a read pass)")
    return 0


def main() -> int:
    if "--demo" in sys.argv:
        return demo()
    bad = []
    for path in sorted(SCRIPTS.rglob("*.gd")):
        rel = path.relative_to(SCRIPTS)
        if rel.parts and rel.parts[0] in EXEMPT_DIRS:
            continue
        bad.extend(violations(path.read_text(encoding="utf-8", errors="replace"), str(rel)))
    for name, line, prop, src in bad:
        print(f"FAIL {name}:{line}: write to Viewport.{prop} through a bare get_viewport() - {src}")
    if bad:
        print(f"viewport_write_guard: {len(bad)} unguarded write(s)")
        return 1
    print("viewport_write_guard: every Viewport property write in scripts/ is null-guarded")
    return 0


if __name__ == "__main__":
    sys.exit(main())
