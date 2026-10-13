# -*- coding: utf-8 -*-
"""K1.7 (Session 23): secret-shaped strings in the tracked text files (docs/CLEANUP_LEDGER.md, section 7).

usage: python tools/qa_sim/secret_scan.py [--demo]
Every tracked text file is read (the art, the audio and the evidence frames are not text and are left out) and tested against the shapes of the usual keys and tokens (a Google, an OpenAI-style,
an Anthropic, a GitHub, a Slack, an AWS key; a private key block; a JWT; a key, secret, token or password assigned a long literal, also a PowerShell $pass = "..."). A hit prints "FAIL <file>:<line>: <kind>" with
the file and the line and NEVER the value, and the exit code is 1. The two known false positives are listed in ALLOWED, each with its reason: a SHA-256 digest in the integrity manifest
and the fake key of the scanner's own test fixture in tools/qa_sim/release_export_check.py. The history is swept by hand when a pass asks for it (`git log --all -G`), not here.
"""
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
PATTERNS = {
    "google api key": re.compile(r"AIza[0-9A-Za-z_\-]{35}"),
    "openai style key": re.compile(r"\bsk-[A-Za-z0-9_\-]{20,}"),
    "anthropic key": re.compile(r"sk-ant-[A-Za-z0-9_\-]{20,}"),
    "github token": re.compile(r"\bgh[pousr]_[A-Za-z0-9]{30,}"),
    "slack token": re.compile(r"xox[baprs]-[A-Za-z0-9\-]{10,}"),
    "aws key id": re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    "private key block": re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----"),
    "jwt": re.compile(r"\beyJ[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}"),
    "assigned secret": re.compile(r"(?i)\b(api[_-]?key|secret|token|passwd|password|storepass|keypass|private[_-]?key)\b[\"']?\s*[:=]\s*[\"']([A-Za-z0-9_\-/+=]{16,})[\"']"),
    "assigned password variable": re.compile(r"(?i)\$(pass|password|pwd|secret|token|apikey)\s*=\s*[\"'][^\"'$]{6,}[\"']"),
    "long literal near a key word": re.compile(r"(?i)(key|secret|token)[^\n]{0,30}[\"']([A-Fa-f0-9]{32,}|[A-Za-z0-9+/]{40,}={0,2})[\"']"),
}
ALLOWED = {
    ("data/integrity_manifest.json", "long literal near a key word"): "a SHA-256 digest of a file whose name has the word secrets in it",
    ("tools/qa_sim/release_export_check.py", "openai style key"): "the fake key of this scanner's own fixture (data/i18n/en.json of a test bundle)",
}
SKIP_DIRS = ("docs/stills/", "assets/", "content/cards/", "store/trailer/", "store/screenshots/", ".godot/")
SKIP_EXT = {".png", ".jpg", ".jpeg", ".ogg", ".wav", ".mp3", ".ttf", ".res", ".ctex", ".webp", ".mp4", ".aab", ".jar", ".gz", ".zip", ".import", ".uid"}


def scan_text(text):
    """[(line number, kind)] of a text."""
    out = []
    for number, line in enumerate(text.splitlines(), 1):
        for kind, rx in PATTERNS.items():
            if rx.search(line):
                out.append((number, kind))
    return out


def tracked():
    out = subprocess.run(["git", "ls-files", "-z"], cwd=ROOT, capture_output=True).stdout.decode("utf-8", "replace").split("\0")
    return [p for p in out if p and not p.startswith(SKIP_DIRS) and pathlib.Path(p).suffix.lower() not in SKIP_EXT]


def demo():
    fake = "sk-" + "a" * 24
    assert scan_text('{"apiKey": "%s"}' % fake) == [(1, "openai style key")] or (1, "openai style key") in scan_text('{"apiKey": "%s"}' % fake)
    assert scan_text('x = "{env:OMNIROUTE_API_KEY}"') == []
    assert (1, "private key block") in scan_text("-----BEGIN " + "RSA PRIVATE KEY-----")  # split, so this file does not hold the shape it looks for
    assert scan_text("the key to the city") == []
    print("secret_scan demo: a key literal and a private key block are found, an environment reference and a plain sentence are not")
    return 0


def main(argv):
    if "--demo" in argv:
        return demo()
    bad, scanned = [], 0
    for p in tracked():
        try:
            text = (ROOT / p).read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        scanned += 1
        for number, kind in scan_text(text):
            if (p, kind) not in ALLOWED:
                bad.append("%s:%d: %s" % (p, number, kind))
    for line in bad:
        print("FAIL", line)
    print("secret_scan: %d tracked text file(s), %d allowed false positive(s), %d finding(s)" % (scanned, len(ALLOWED), len(bad)))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
