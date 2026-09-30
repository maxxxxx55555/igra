#!/usr/bin/env python3
"""C6 regression gate: no hardcoded, player-visible words assigned to a
Control's text in GDScript. The i18n truth gate checks the locale files; this
checks the code that fills labels, so a new `label.text = "Settings"` fails
here instead of shipping one untranslated word in 12 locales.

Flags `<x>.text = "<literal>"` (and `+=`) where the literal contains a run of
2+ letters (any script). Numbers, symbols and emoji pass. Literals that are
key/tech tokens identical in every locale go in ALLOW with a reason.

Also: every `"<...>_key": "KEY"` literal in a GDScript data dict (tutorial
steps, recipe tables) must exist in data/i18n/en.json. The tutorial shipped
7 of 11 hint keys missing in every locale because such keys never pass
through a t()/tr() call the other checks look for.

And: a data resource's `display_name` is Russian in data/*.tres, so it may only
appear as the fallback argument of LocalizationManager.name_for(). The power
switch, the quick wheel and the shop showed Russian names in every locale.
name_for() only helps when the key exists, so every district, item, shop item
and monster resource must have its name key (monsters also a description key).
Every catalog document carries title_key/content_key that exist in en.json (33
legacy documents were Russian-only raw text in all 13 locales).

Usage: python tools/qa_sim/hardcoded_text_gate.py [--demo]
Exit 0 clean, 1 on any hit.
"""
import json
import re
import sys
from pathlib import Path

ASSIGN = re.compile(r'\.text\s*\+?=\s*"((?:[^"\\]|\\.)*)"')
WORD = re.compile(r"[^\W\d_]{2,}")
DATA_KEY = re.compile(r'"([a-z_]*_key)"\s*:\s*"([A-Za-z0-9_]+)"')


DISPLAY_NAME = re.compile(r"\.display_name\b")
# name_for() takes it as the fallback; an emptiness test and `fallback = ...` do not show it.
DISPLAY_NAME_SAFE = ("name_for(", "is_empty()", "fallback =", "@export")


# data folder -> key prefixes that name_for() looks up for each resource id.
NAME_KEYS = {
    "districts": ("DISTRICT_NAME_",),
    "items": ("ITEM_",),
    "shop": ("SHOP_ITEM_",),
    "monsters": ("MONSTER_", "MONSTER_DESC_"),
}
TRES_ID = re.compile(r'^id = &?"([^"]+)"', re.M)


def missing_name_keys(root: Path, known: set) -> list[str]:
    out = []
    for folder, prefixes in NAME_KEYS.items():
        for res in sorted((root / "data" / folder).glob("*.tres")):
            m = TRES_ID.search(res.read_text(encoding="utf-8"))
            for prefix in prefixes if m else ():
                key = prefix + m.group(1).upper()
                if key not in known:
                    out.append(f"{res.relative_to(root).as_posix()}: {key} not in en.json")
    return out


def missing_document_keys(root: Path, known: set) -> list[str]:
    out = []
    catalog = json.loads((root / "data/documents/documents_catalog.json").read_text(encoding="utf-8"))
    for entry in catalog:
        for field in ("title", "content"):
            key = entry.get(field + "_key")
            if key is None:
                out.append(f"documents_catalog {entry['doc_id']}: raw {field} text, use {field}_key")
            elif key not in known:
                out.append(f"documents_catalog {entry['doc_id']}: {key} not in en.json")
    return out


def missing_data_keys(text: str, known: set) -> list[str]:
    return [m.group(2) for m in DATA_KEY.finditer(text) if m.group(2) not in known]


def scan_display_names(text: str) -> list[str]:
    hits = []
    for line in text.splitlines():
        code = line.split("#", 1)[0]
        if DISPLAY_NAME.search(code) and not any(s in code for s in DISPLAY_NAME_SAFE):
            hits.append(code.strip())
    return hits


# Literal -> reason it is locale-independent.
ALLOW = {
    "[ESC]  /  [TAP]": "physical key / gesture names, same on every keyboard layout",
}


def scan_text(text: str) -> list[str]:
    hits = []
    for line in text.splitlines():
        code = line.split("#", 1)[0]
        for m in ASSIGN.finditer(code):
            lit = m.group(1)
            # Drop escape sequences first: "%s\nx%d" is not the word "nx".
            if WORD.search(re.sub(r"\\.", " ", lit)) and lit not in ALLOW:
                hits.append(lit)
    return hits


def main() -> int:
    root = Path(__file__).resolve().parents[2]
    known = set(json.loads((root / "data/i18n/en.json").read_text(encoding="utf-8")))
    bad = []
    for p in sorted((root / "scripts").rglob("*.gd")):
        if "tools" in p.relative_to(root).parts:
            continue  # dev-only probes, excluded from export
        text = p.read_text(encoding="utf-8", errors="ignore")
        for lit in scan_text(text):
            bad.append(f"{p.relative_to(root).as_posix()}: \"{lit}\"")
        for key in missing_data_keys(text, known):
            bad.append(f"{p.relative_to(root).as_posix()}: data key {key} not in en.json")
        for code in scan_display_names(text):
            bad.append(f"{p.relative_to(root).as_posix()}: display_name outside name_for(): {code}")
    bad += missing_name_keys(root, known)
    bad += missing_document_keys(root, known)
    for b in bad:
        print("HARDCODED", b)
    print("hardcoded_text_gate: %d hit(s)" % len(bad))
    return 1 if bad else 0


def _demo() -> None:
    assert scan_text('lbl.text = "Settings"') == ["Settings"]
    assert scan_text('lbl.text = "Настройки"') == ["Настройки"]
    assert scan_text('lbl.text = LocalizationManager.t("SETTINGS")') == []
    assert scan_text('lbl.text = "100"') == []
    assert scan_text('lbl.text = "-1"') == []
    assert scan_text('lbl.text = "[ESC]  /  [TAP]"') == []
    assert scan_text('# lbl.text = "Commented"') == []
    assert scan_text('btn.text = "[✓] " + btn.text') == []
    assert scan_text(r'lbl.text = "%s\nx%d"') == []  # escape + one letter is not a word
    assert scan_text(r'lbl.text = "Line\nTwo"') == [r"Line\nTwo"]
    assert missing_data_keys('{"text_key": "TUT_MOVE"}', {"TUT_MOVE"}) == []
    assert missing_data_keys('{"text_key": "TUT_GONE"}', {"TUT_MOVE"}) == ["TUT_GONE"]
    assert scan_display_names("lbl.text = item.display_name") == ["lbl.text = item.display_name"]
    assert scan_display_names('x = LocalizationManager.name_for("ITEM_", item.id, item.display_name)') == []
    assert scan_display_names("if d != null and not String(d.display_name).is_empty():") == []
    assert scan_display_names("@export var display_name: String") == []
    assert scan_display_names("# item.display_name is Russian") == []
    assert scan_display_names("draw_string(ThemeDB.fallback_font, p, String(item.display_name))") != []
    print("demo OK")


if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == "--demo":
        _demo()
        sys.exit(0)
    sys.exit(main())
