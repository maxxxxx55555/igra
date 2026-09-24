#!/usr/bin/env python3
"""C6 regression gate: no hardcoded, player-visible words assigned to a
Control's text in GDScript. The i18n truth gate checks the locale files; this
checks the code that fills labels, so a new `label.text = "Settings"` fails
here instead of shipping one untranslated word in 12 locales.

Flags `<x>.text = "<literal>"` (and `+=`) where the literal contains a run of
2+ letters (any script). Numbers, symbols and emoji pass. Literals that are
key/tech tokens identical in every locale go in ALLOW with a reason.

Usage: python tools/qa_sim/hardcoded_text_gate.py [--demo]
Exit 0 clean, 1 on any hit.
"""
import re
import sys
from pathlib import Path

ASSIGN = re.compile(r'\.text\s*\+?=\s*"((?:[^"\\]|\\.)*)"')
WORD = re.compile(r"[^\W\d_]{2,}")
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
    bad = []
    for p in sorted((root / "scripts").rglob("*.gd")):
        if "tools" in p.relative_to(root).parts:
            continue  # dev-only probes, excluded from export
        for lit in scan_text(p.read_text(encoding="utf-8", errors="ignore")):
            bad.append(f"{p.relative_to(root).as_posix()}: \"{lit}\"")
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
    print("demo OK")


if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == "--demo":
        _demo()
        sys.exit(0)
    sys.exit(main())
