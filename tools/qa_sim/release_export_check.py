#!/usr/bin/env python3
"""SECURITY_PATCH_SPEC C-08: static release-export config gate.

Checks the TRACKED export_presets.cfg for the two things that are always
wrong regardless of dev stage (a committed PCK encryption key, or debug
keystore credentials sitting in a preset meant to sign a real release
build) and treats a still-unconfigured release keystore as an expected
pre-release state (informational, not a failure) - this project hasn't
cut a signed release build yet, so a hard-fail here would misrepresent
"not done yet" as "broken".

With --aab <file> it also reads an exported bundle (Session 19): every packed file must be the game's. A file of the tools,
tests, docs or store art, a text file of the project root (opencode.json carried an API key into the v8.0.0 bundle), or an
API key pattern in a packed text file is a FAIL.

Run: python tools/qa_sim/release_export_check.py [--aab build/tls.aab] [--demo]
"""
import pathlib
import re
import sys
import tempfile
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
PACKS = ("assetPackInstallTime/assets/", "base/assets/")
NOT_GAME_DIRS = ("tools/", "scripts/tools/", "scenes/tools/", "scripts/security/", "_QUARANTINE/", "tests/", "docs/", ".claude/", ".signing/",
                 ".qa_logs/", "build/", "store/press/", "store/screens_spec/", "store/screenshots/", "store/trailer/")
NOT_GAME_FILES = ("opencode.json", "missing_keys.json", "scripts/stress_test.gd", "scenes/world/test_zone.tscn", "store/feature-graphic.png",
                  "store/icon-512.png")
NOT_GAME_SUFFIXES = (".md", ".py", ".sh", ".ps1", ".env", ".jks", ".keystore")
TEXT_SUFFIXES = (".json", ".cfg", ".txt", ".csv", ".tres", ".tscn", ".gd")
API_KEY = re.compile(rb"sk-[A-Za-z0-9_-]{16,}|\"apiKey\"")


def not_game(src):
    return src.startswith(NOT_GAME_DIRS) or src in NOT_GAME_FILES or src.endswith(NOT_GAME_SUFFIXES)


def aab_findings(path):
    """The packed files of a bundle that are not the game's, with the reason. An imported image ships with its .import, which names it."""
    found = []
    with zipfile.ZipFile(path) as z:
        for name in z.namelist():
            pack = next((p for p in PACKS if name.startswith(p)), None)
            if pack is None:
                continue
            rel = name[len(pack):]
            # a script ships as .gdc and .gd.remap, an imported file as its .import
            src = re.sub(r"\.gdc$", ".gd", re.sub(r"\.(remap|import)$", "", rel))
            if not_game(src):
                found.append(rel)
            elif rel.endswith(TEXT_SUFFIXES) and API_KEY.search(z.read(name)):
                found.append("%s (an API key pattern)" % rel)
    return found


def demo():
    with tempfile.TemporaryDirectory() as tmp:
        aab = pathlib.Path(tmp) / "t.aab"
        with zipfile.ZipFile(aab, "w") as z:
            for rel, body in (("opencode.json", b"{}"), ("tests/x.gdc", b""), ("scripts/ok.gdc", b""), ("store/trailer/a.png.import", b""),
                              ("data/i18n/en.json", b'{"k": "sk-abcdefghijklmnopqrstu"}'), ("data/items.json", b'{"name": "battery"}')):
                z.writestr(PACKS[0] + rel, body)
        got = aab_findings(aab)
    assert got == ["opencode.json", "tests/x.gdc", "store/trailer/a.png.import", "data/i18n/en.json (an API key pattern)"], got
    print("release_export_check demo OK (a root text file, test code, a store image and a key pattern are found; game files pass)")


def main() -> int:
    if "--demo" in sys.argv:
        demo()
        return 0
    cfg_path = ROOT / "export_presets.cfg"
    if not cfg_path.exists():
        print("export_presets.cfg not found - nothing to check")
        return 0
    text = cfg_path.read_text(encoding="utf-8")

    fails = []
    warns = []

    m = re.search(r'^encryption_key\s*=\s*"([^"]*)"', text, re.MULTILINE)
    if m and m.group(1).strip():
        fails.append("encryption_key= is committed to export_presets.cfg - "
                      "a PCK encryption key checked into git protects nothing")

    debug_fields = {
        "keystore/debug": re.search(r'^keystore/debug\s*=\s*"([^"]*)"', text, re.MULTILINE),
        "keystore/debug_user": re.search(r'^keystore/debug_user\s*=\s*"([^"]*)"', text, re.MULTILINE),
        "keystore/debug_password": re.search(r'^keystore/debug_password\s*=\s*"([^"]*)"', text, re.MULTILINE),
    }
    for name, match in debug_fields.items():
        if match and match.group(1).strip():
            fails.append("%s is non-empty in the tracked preset (%r) - "
                          "debug signing material must not be committed (D-04)"
                          % (name, match.group(1)))

    for name in ["keystore/release", "keystore/release_user", "keystore/release_password"]:
        match = re.search(r'^%s\s*=\s*"([^"]*)"' % re.escape(name), text, re.MULTILINE)
        if not match or not match.group(1).strip():
            warns.append("%s is empty - expected pre-release state (no signed "
                          "release build cut yet), not a failure" % name)

    for w in warns:
        print("NOTE: " + w)
    for f in fails:
        print("FAIL: " + f)

    if "--aab" in sys.argv:
        aab = pathlib.Path(sys.argv[sys.argv.index("--aab") + 1])
        found = aab_findings(aab)
        for rel in found:
            print("FAIL: %s packs a file that is not the game: %s" % (aab.name, rel))
        print("%s: %d packed file(s) that are not the game" % (aab, len(found)))
        fails.extend(found)
    else:
        print("\nNo bundle read (--aab <file> checks the packed files of an exported bundle).")

    ok = not fails
    print("\nPASS" if ok else "\nFAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
