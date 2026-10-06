#!/usr/bin/env python3
"""Scene node-header gate (rc15, CORRECTION_LOG 76).

A `[node ...]` header carries name, type, parent, index, groups, owner, instance and a few more; a property
(anchors, offsets, colours) belongs on its own line below it. Five UI scenes (new_game_plus, skill_tree_ui,
skill_tree_tab, skill_button, lobby) had their anchors and offsets written inside the header: the engine ignores them,
so their roots were zero-size and the New Game+ panel hung from the middle of the screen (play-through frame
docs/stills/playthrough/V11_ngp_screen.jpg). Fails on any header with another attribute.

Run: python tools/qa_sim/tscn_header_check.py        (--demo: self-check on synthetic text)
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
STANDARD = {"name", "type", "parent", "index", "groups", "owner", "instance", "node_paths", "unique_id",
            "instance_placeholder", "unique_name_in_owner", "editable"}
HEADER = re.compile(r'^\[node ((?:[^\]"]|"[^"]*")*)\]\s*$')
ATTR = re.compile(r'(\w+)=("[^"]*"|\w+\([^)]*\)|[^\s\]]+)')


def stray(text: str) -> list:
    out = []
    for n, line in enumerate(text.splitlines(), 1):
        m = HEADER.match(line)
        if m:
            extra = sorted({k for k, _ in ATTR.findall(m.group(1))} - STANDARD)
            if extra:
                out.append((n, extra))
    return out


def demo() -> int:
    bad = '[node name="A" type="Control" layout_mode=1 anchors_preset=15 anchor_right=1.0]\n'
    good = '[node name="A" type="Control" parent="." groups=["x"]]\nlayout_mode = 1\nanchors_preset = 15\n'
    assert stray(bad) == [(1, ["anchor_right", "anchors_preset", "layout_mode"])], stray(bad)
    assert stray(good) == [], stray(good)
    print("tscn_header_check demo ok")
    return 0


def main() -> int:
    if "--demo" in sys.argv:
        return demo()
    fails = 0
    for path in sorted(ROOT.rglob("*.tscn")):
        rel = path.relative_to(ROOT).as_posix()
        if rel.startswith((".godot/", "_QUARANTINE/", "addons/")):
            continue
        for n, extra in stray(path.read_text(encoding="utf-8", errors="replace")):
            print("FAIL %s:%d header carries %s" % (rel, n, ", ".join(extra)))
            fails += 1
    print("tscn_header_check: %d stray header attribute line(s)" % fails)
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
