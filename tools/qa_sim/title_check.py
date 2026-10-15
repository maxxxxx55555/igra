# -*- coding: utf-8 -*-
"""The game's name is "Last Streetlight", never "The Last Streetlight" (owner, Session 23).

usage: python tools/qa_sim/title_check.py [--demo]
Scans what a player or a store reviewer can read (the locale files, the scenes, the scripts, project.godot, the export presets,
the store kit and the store documents) for the name written with a "The" in front of it in capitals: "The Last Streetlight",
"THE LAST STREETLIGHT", "TheLastStreetlight". A sentence of the story that says "the last streetlight" in lower case is the lamp,
not the name, and passes. The one path that must keep the old spelling (the desktop user:// folder the rename left behind,
docs/release_checklist.md) is named by ALLOWED_LINES. Exit 1 on a hit, one line per hit.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
TITLE = re.compile(r"the[ -]?last[ -]?streetlight", re.IGNORECASE)
SCAN_DIRS = ("data", "content", "scenes", "scripts", "localization", "store", "docs/store")
SCAN_FILES = ("project.godot", "export_presets.cfg", "docs/PRIVACY_POLICY.md", "docs/RELEASE_RUNBOOK.md", "docs/release_checklist.md", "RELEASE_CHECKLIST.md", "docs/RC_OWNER_CHECKLIST.md")
SCAN_SUFFIXES = (".json", ".tscn", ".tres", ".gd", ".godot", ".cfg", ".md", ".txt", ".xml")
ALLOWED_LINES = ("app_userdata",)


def hits(text):
    """Line numbers where the name carries a 'The' and any capital letter after its first one."""
    found = []
    for n, line in enumerate(text.splitlines(), 1):
        if any(a in line for a in ALLOWED_LINES):
            continue
        for m in TITLE.finditer(line):
            if m.group()[1:] != m.group()[1:].lower():
                found.append(n)
                break
    return found


def files():
    out = [ROOT / f for f in SCAN_FILES]
    for d in SCAN_DIRS:
        out += [p for p in (ROOT / d).rglob("*") if p.suffix in SCAN_SUFFIXES and p.is_file()]
    return sorted(set(p for p in out if p.is_file()))


def demo():
    assert hits('"x": "The Last Streetlight"') == [1]
    assert hits("THE LAST STREETLIGHT - 3 endings") == [1]
    assert hits('path="build/TheLastStreetlight.exe"') == [1]
    assert hits("Last Streetlight") == [] and hits("LAST STREETLIGHT") == []
    assert hits("The last streetlight. While it burns, the city lives.") == []
    assert hits("THE_LAST_STREETLIGHT/assets") == []
    assert hits("...\\app_userdata\\The Last Streetlight") == []
    assert hits("ok\nThe Last Streetlight\nok") == [2]
    print("title_check demo OK (the name with a capital 'The' is found with its line; the bare name, the lamp in a sentence, the folder name and the old user:// path pass)")


def main():
    if "--demo" in sys.argv:
        demo()
        return 0
    found = 0
    scanned = files()
    for p in scanned:
        for n in hits(p.read_text(encoding="utf-8", errors="replace")):
            print("%s:%d" % (p.relative_to(ROOT).as_posix(), n))
            found += 1
    print("title_check: %d hit(s) in %d file(s)" % (found, len(scanned)))
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main())
