#!/usr/bin/env python3
"""SECURITY_PATCH_SPEC C-08: static release-export config gate.

Checks the TRACKED export_presets.cfg for the two things that are always
wrong regardless of dev stage (a committed PCK encryption key, or debug
keystore credentials sitting in a preset meant to sign a real release
build) and treats a still-unconfigured release keystore as an expected
pre-release state (informational, not a failure) - this project hasn't
cut a signed release build yet, so a hard-fail here would misrepresent
"not done yet" as "broken".

NO-GODOT / NOT DONE: this only inspects export_presets.cfg text. It does
NOT inspect an actual exported APK/PCK/Web artifact for leaked tool/test
scenes - that needs a real `--export-release` run with export templates
and signing keys configured, which this environment doesn't have. Stated
honestly rather than guessed at.

Run: python tools/qa_sim/release_export_check.py
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]


def main() -> int:
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

    print("\nNOT covered here (needs a real --export-release run, not attempted "
          "in this environment): inspecting an actual exported APK/PCK/Web "
          "artifact for leaked .import/.uid/tool/test scenes.")

    ok = not fails
    print("\nPASS" if ok else "\nFAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
