# -*- coding: utf-8 -*-
"""The integrity manifest (docs/SECURITY_HARDENING.md): the SHA-256 of the text of every content and data JSON that decides the game's rules.

usage: python tools/gen_integrity_manifest.py [--check | --demo]
No argument writes data/integrity_manifest.json. --check exits 1 when the manifest is not what the files say (a static gate: tools/check.sh), --demo is the
self-test. The hash is of the text with CRLF turned into LF, so a checkout with other line ends gives the same value as the game computes at run time
(scripts/security/integrity_scan.gd). data/i18n is left out (the strings change with every translation pass and decide no rule) and so is the manifest itself.
"""
import hashlib
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "data" / "integrity_manifest.json"
SCAN = ("content", "data")
SKIP_PREFIXES = ("data/i18n/",)


def digest(text):
    return hashlib.sha256(text.replace("\r\n", "\n").encode("utf-8")).hexdigest()


def collect(root=ROOT):
    files = {}
    for top in SCAN:
        for path in sorted((root / top).rglob("*.json")):
            rel = path.relative_to(root).as_posix()
            if rel.startswith(SKIP_PREFIXES) or path == root / "data" / "integrity_manifest.json":
                continue
            files["res://" + rel] = digest(path.read_text(encoding="utf-8"))
    return files


def render(files):
    return json.dumps({"version": 1, "normalization": "CRLF to LF", "files": files}, indent=1, sort_keys=True) + "\n"


def demo():
    assert digest("a\r\nb") == digest("a\nb")
    assert digest("a") != digest("b")
    assert render({"res://x.json": "1"}).endswith("}\n")
    print("gen_integrity_manifest demo OK (line ends do not change a hash, a change of text does)")


def main():
    if "--demo" in sys.argv:
        demo()
        return 0
    files = collect()
    if "--check" in sys.argv:
        have = MANIFEST.read_text(encoding="utf-8").replace("\r\n", "\n") if MANIFEST.exists() else ""
        ok = have == render(files)
        print("integrity manifest: %d file(s), %s" % (len(files), "matches" if ok else "STALE: run python tools/gen_integrity_manifest.py"))
        return 0 if ok else 1
    MANIFEST.write_text(render(files), encoding="utf-8", newline="\n")
    print("integrity manifest: %d file(s) written to %s" % (len(files), MANIFEST.relative_to(ROOT).as_posix()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
