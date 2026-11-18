# -*- coding: utf-8 -*-
"""Skill-tree canon gate: the tree must read as a translucent tactical overlay,
not the 96 % opaque black wall the owner flagged (2026-11-18).

Four properties are locked, each with a biting mutant in --demo:
  TREE1 the background alpha is low enough for the live street to show through;
  TREE2 a steel frame and an amber header rule exist and use ThemeProvider tokens;
  TREE3 an edge vignette is drawn with the project's own shader (no external art);
  TREE4 amber unlock paths are derived from SkillTreeManager's requires-field.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
UI = ROOT / "scripts" / "ui"
SCENE = ROOT / "scenes" / "ui" / "skill_tree_ui.tscn"


def sources():
    return {
        "chrome": (UI / "skill_tree_chrome.gd").read_text(encoding="utf-8"),
        "paths": (UI / "skill_paths.gd").read_text(encoding="utf-8"),
        "scene": SCENE.read_text(encoding="utf-8"),
    }


def findings(src=None):
    src = src or sources()
    out = []
    chrome, paths = src["chrome"], src["paths"]
    m = re.search(r"bg\.color\s*=\s*Color\(\s*ThemeProvider\.COLOR_BG_PANEL\s*,\s*([\d.]+)\s*\)", chrome)
    if not m or float(m.group(1)) > 0.85:
        out.append("TREE1 skill-tree background must be a translucent panel (<=0.85)")
    if not re.search(r'set_border_width_all\(1\)', chrome) or "ThemeProvider.COLOR_BORDER" not in chrome:
        out.append("TREE2 a 1px steel frame is required")
    if "ThemeProvider.COLOR_AMBER" not in chrome:
        out.append("TREE2 an amber header rule is required")
    if "shader_type canvas_item" not in chrome or "smoothstep" not in chrome:
        out.append("TREE3 an in-project edge-vignette shader is required")
    if "get(\"requires\"" not in paths or "draw_line" not in paths:
        out.append("TREE4 unlock paths must read requires and draw them")
    return out


def demo():
    base = sources()
    assert findings(base) == [], findings(base)
    # Derive the mutant from the source, not from a hardcoded alpha: changing
    # the real value must never silently make the self-check vacuous again.
    value = re.search(r"(bg\.color\s*=\s*Color\(\s*ThemeProvider\.COLOR_BG_PANEL\s*,\s*)([\d.]+)(\s*\))", base["chrome"])
    assert value is not None, "demo anchor missing: background alpha"
    opaque = value.group(1) + "0.96" + value.group(3)
    mutants = [
        ("TREE1", "chrome", base["chrome"].replace(value.group(0), opaque, 1)),
        ("TREE2", "chrome", base["chrome"].replace("ThemeProvider.COLOR_BORDER", "Color(1, 0, 1)")),
        ("TREE3", "chrome", base["chrome"].replace("shader_type canvas_item", "shader_type canvas_lying")),
        ("TREE4", "paths", base["paths"].replace("draw_line(a, b", "draw_circle(a, 1.0")),
    ]
    for label, key, text in mutants:
        patch = dict(base)
        patch[key] = text
        bad = findings(patch)
        if not any(x.startswith(label) for x in bad):
            print("FAIL demo mutant %s did not bite" % label)
            return 1
    print("skill_tree_canon_check demo: 4 mutants bite")
    return 0


def main():
    if "--demo" in sys.argv:
        return demo()
    bad = findings()
    for b in bad:
        print("FAIL", b)
    print("skill_tree_canon_check: %d finding(s)" % len(bad))
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
