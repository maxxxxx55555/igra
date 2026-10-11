# -*- coding: utf-8 -*-
"""AAB facts (Session 21): what docs/RELEASE_ARTIFACTS.md states about a built bundle, read from the file itself.

usage: python tools/qa_sim/aab_check.py <bundle.aab> [--secrets] [--demo]
One line per fact, exit 1 when one is wrong:
  size, sha256, entries   the file
  jar      `jarsigner -verify` prints "jar verified."
  signer   the signing certificate's SHA-256 (`keytool -printcert -jarfile`, no password needed) is the one docs/RELEASE_ARTIFACTS.md records
  label    the app label "Last Streetlight" occurs in an entry of the manifest and resources
  adsdk    no dex entry names Lcom/applovin/ (the ad SDK is not in a build without a key)
  secrets  (with --secrets, the keystore variables set in the environment by `. .signing/release.env`) the keystore path and password occur in
           no entry outside META-INF; only counts are printed, never the values
A packed file that is not the game is the other check: tools/qa_sim/release_export_check.py --aab.
"""
import hashlib
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
ARTIFACTS = ROOT / "docs" / "RELEASE_ARTIFACTS.md"
LABEL = b"Last Streetlight"
APPLOVIN = b"Lcom/applovin/"
CHUNK = 1 << 22
SMALL = 5 << 20


def occurs(z, name, needle):
    """True when `needle` occurs in the entry, read in chunks that overlap by the needle's length."""
    tail = b""
    with z.open(name) as f:
        while True:
            block = f.read(CHUNK)
            if not block:
                return False
            if needle in tail + block:
                return True
            tail = block[-len(needle):]


def count_entries(z, names, needle):
    return sum(1 for n in names if occurs(z, n, needle))


def fingerprint(text):
    m = re.search(r"SHA-?256:\s*([0-9A-Fa-f:]{95})", text)
    return m.group(1).replace(":", "").lower() if m else ""


def tool(*cmd):
    exe = shutil.which(cmd[0])
    if exe is None:
        return -1, cmd[0] + " not found"
    r = subprocess.run([exe, *cmd[1:]], capture_output=True, text=True, encoding="utf-8", errors="replace")
    return r.returncode, r.stdout + r.stderr


def facts(path, secrets):
    bad = 0
    data = path.read_bytes()
    print("size    %d bytes" % len(data))
    print("sha256  %s" % hashlib.sha256(data).hexdigest())
    with zipfile.ZipFile(path) as z:
        names = z.namelist()
        print("entries %d" % len(names))
        small = [n for n in names if z.getinfo(n).file_size < SMALL and not n.startswith("META-INF/")]
        label = count_entries(z, small, LABEL)
        adsdk = count_entries(z, [n for n in names if n.endswith(".dex")], APPLOVIN)
        print("label   %d entries name %s: %s" % (label, LABEL.decode(), "ok" if label else "MISSING"))
        print("adsdk   %d dex entries name %s: %s" % (adsdk, APPLOVIN.decode(), "ok" if adsdk == 0 else "FOUND"))
        bad += (label == 0) + (adsdk > 0)
        if secrets:
            wanted = [os.environ.get("GODOT_ANDROID_KEYSTORE_RELEASE_PATH", ""), os.environ.get("GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD", "")]
            wanted = [w.encode() for w in wanted if w]
            outside = [n for n in names if not n.startswith("META-INF/")]
            hits = [count_entries(z, outside, w) for w in wanted]
            print("secrets %d value(s) of the environment searched in %d entries: %d hits (path, password)" % (len(wanted), len(outside), sum(hits)))
            bad += (not wanted) + (sum(hits) > 0)
    rc, out = tool("jarsigner", "-verify", str(path))
    verified = "jar verified." in out
    print("jar     %s" % ("jar verified." if verified else "NOT VERIFIED (rc %d)" % rc))
    rc, out = tool("keytool", "-printcert", "-jarfile", str(path))
    fp = fingerprint(out)
    recorded = re.sub(r"[^0-9a-f]", "", ARTIFACTS.read_text(encoding="utf-8").lower()) if ARTIFACTS.exists() else ""
    match = bool(fp) and fp in recorded
    print("signer  %s: %s" % (fp[:16] + "..." if fp else "no certificate read", "signer_match=yes" if match else "signer_match=NO"))
    return bad + (not verified) + (not match)


def demo():
    with tempfile.TemporaryDirectory() as tmp:
        p = pathlib.Path(tmp) / "t.aab"
        with zipfile.ZipFile(p, "w") as z:
            z.writestr("base/dex/classes.dex", b"x" * 10 + APPLOVIN + b"y")
            z.writestr("base/res/values.pb", b"..." + LABEL + b"...")
            z.writestr("base/other.bin", b"a" * (CHUNK - 3) + b"SECRET" + b"b" * 9)
        with zipfile.ZipFile(p) as z:
            assert count_entries(z, ["base/dex/classes.dex"], APPLOVIN) == 1
            assert count_entries(z, ["base/res/values.pb"], LABEL) == 1 and count_entries(z, ["base/res/values.pb"], b"nothing") == 0
            assert occurs(z, "base/other.bin", b"SECRET"), "a needle across a chunk boundary is found"
    assert fingerprint("Certificate fingerprints:\n\t SHA256: " + ":".join(["AB"] * 32)) == "ab" * 32
    print("aab_check demo OK (dex scan, label, a needle across a chunk boundary, fingerprint parse)")


def main():
    args = sys.argv[1:]
    if "--demo" in args:
        demo()
        return 0
    paths = [a for a in args if not a.startswith("--")]
    if not paths:
        raise SystemExit(__doc__)
    bad = facts(pathlib.Path(paths[0]), "--secrets" in args)
    print("aab_check: %s" % ("PASS" if bad == 0 else "FAIL (%d)" % bad))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
