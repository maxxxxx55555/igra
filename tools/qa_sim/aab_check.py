# -*- coding: utf-8 -*-
"""AAB facts (Session 21): what docs/RELEASE_ARTIFACTS.md states about a built bundle, read from the file itself.

usage: python tools/qa_sim/aab_check.py <bundle.aab> --bundletool <official.jar> [--secrets] [--against <older.aab>] [--demo]
One line per fact, exit 1 when one is wrong:
  size, sha256, entries   the file
  jar      `jarsigner -verify` prints "jar verified."
  signer   the signing certificate's SHA-256 (`keytool -printcert -jarfile`, no password needed) is the one docs/RELEASE_ARTIFACTS.md records
  label    the app label "Last Streetlight" occurs in base/resources.pb, the resource table that holds the app_name string (the manifest only points at it)
  adsdk    no dex entry names Lcom/applovin/ (the ad SDK is not in a build without a key)
  integrity  every file of data/integrity_manifest.json is in the asset pack and hashes as the guard's scan hashes it (the text with CRLF turned into LF, SHA-256): what the scan reads on a phone
  refs     every file that the shipped scripts, scenes and resources name (a literal path, or a format-string pattern, or an autoload) and the export filter does not leave out is in the asset pack as the
           export makes it: tools/qa_sim/export_refs_check.py --bundle, the same reading as its static run against the filter
  secrets  (with --secrets, the keystore variables set in the environment by `. .signing/release.env`) the keystore path and password occur in
           no entry outside META-INF; only counts are printed, never the values
  --against  the entries of another bundle that are gone, new or changed (name and CRC; the signature files and the pack index change on every export)
A packed file that is not the game is the other check: tools/qa_sim/release_export_check.py --aab.
"""
import argparse
import configparser
import hashlib
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile
import xml.etree.ElementTree as ET

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import export_refs_check as refs  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parents[2]
ARTIFACTS = ROOT / "docs" / "RELEASE_ARTIFACTS.md"
LABEL = b"Last Streetlight"
APPLOVIN = b"Lcom/applovin/"
CHUNK = 1 << 22


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


def integrity(z, names):
    """The manifest's files that the bundle lacks or holds with other bytes, and the number the manifest lists."""
    files = json.loads(z.read(refs.PACK + "data/integrity_manifest.json").decode("utf-8")).get("files", {})
    wrong = []
    for path, want in sorted(files.items()):
        entry = refs.PACK + path[len("res://"):]
        if entry not in names or hashlib.sha256(z.read(entry).decode("utf-8").replace("\r\n", "\n").encode("utf-8")).hexdigest() != want:
            wrong.append("  integrity %s: missing or with other bytes" % path)
    return len(files), wrong


def fingerprint(text):
    m = re.search(r"SHA-?256:\s*([0-9A-Fa-f:]{95})", text)
    return m.group(1).replace(":", "").lower() if m else ""


def recorded_signer(text):
    keys = re.findall(r"SHA-256 fingerprint `([0-9A-Fa-f]{64})`", text)
    return keys[-1].lower() if keys else ""


def release_identity(root=ROOT):
    config = configparser.ConfigParser(interpolation=None)
    config.read(root / "export_presets.cfg", encoding="utf-8")
    sections = [s for s in config.sections() if config[s].get("name") == '"Android"']
    if len(sections) != 1:
        raise ValueError("Exactly one Android export preset is required")
    options = config[sections[0] + ".options"]
    return {"package": json.loads(options["package/unique_name"]),
            "versionCode": str(options.getint("version/code")),
            "versionName": json.loads(options["version/name"])}


def manifest_identity(xml):
    root = ET.fromstring(xml)
    if root.tag != "manifest":
        raise ValueError("Expected a manifest root")
    ns = "{http://schemas.android.com/apk/res/android}"
    app = root.find("application")
    if app is None or app.get(ns + "debuggable", "false") != "false":
        raise ValueError("Missing application or debuggable release")
    return {"package": root.attrib["package"],
            "versionCode": root.attrib[ns + "versionCode"],
            "versionName": root.attrib[ns + "versionName"]}


def manifest_check(path, bundletool):
    if not bundletool or not pathlib.Path(bundletool).is_file():
        print("manifest MISSING bundletool: supply --bundletool <official.jar>")
        return 1
    rc, out = tool("java", "-jar", str(bundletool), "dump", "manifest",
                   "--bundle=" + str(path), "--module=base", stdout_only=True)
    if rc:
        print("manifest bundletool failed (rc %d)" % rc)
        return 1
    try:
        actual, expected = manifest_identity(out), release_identity()
    except (ET.ParseError, KeyError, ValueError, configparser.Error) as error:
        print("manifest unreadable: %s" % error)
        return 1
    for key in expected:
        print("manifest %s=%s expected=%s: %s" %
              (key, actual[key], expected[key], "ok" if actual[key] == expected[key] else "MISMATCH"))
    return int(actual != expected)


def tool(*cmd, stdout_only=False):
    exe = shutil.which(cmd[0])
    if exe is None:
        return -1, cmd[0] + " not found"
    r = subprocess.run([exe, *cmd[1:]], capture_output=True, text=True, encoding="utf-8", errors="replace")
    return r.returncode, r.stdout if stdout_only else r.stdout + r.stderr


LIST_MAX = 40  # entries named per class by --against


def compare(path, older):
    with zipfile.ZipFile(path) as a, zipfile.ZipFile(older) as b:
        new = {i.filename: i.CRC for i in a.infolist()}
        old = {i.filename: i.CRC for i in b.infolist()}
    gone = sorted(set(old) - set(new))
    added = sorted(set(new) - set(old))
    changed = sorted(n for n in set(new) & set(old) if new[n] != old[n])
    print("against %s: %d entries gone, %d new, %d with other bytes" % (older.name, len(gone), len(added), len(changed)))
    for label, names in (("gone", gone), ("new", added), ("changed", changed)):
        for n in names[:LIST_MAX]:
            print("  %-7s %s" % (label, n))
        if len(names) > LIST_MAX:
            print("  %-7s ... and %d more" % (label, len(names) - LIST_MAX))


def facts(path, secrets, bundletool):
    bad = manifest_check(path, bundletool)
    data = path.read_bytes()
    print("size    %d bytes" % len(data))
    print("sha256  %s" % hashlib.sha256(data).hexdigest())
    with zipfile.ZipFile(path) as z:
        names = z.namelist()
        print("entries %d" % len(names))
        label = count_entries(z, [n for n in ("base/resources.pb",) if n in names], LABEL)
        adsdk = count_entries(z, [n for n in names if n.endswith(".dex")], APPLOVIN)
        print("label   base/resources.pb %s %s: %s" % ("names" if label else "does not name", LABEL.decode(), "ok" if label else "MISSING"))
        print("adsdk   %d dex entries name %s: %s" % (adsdk, APPLOVIN.decode(), "ok" if adsdk == 0 else "FOUND"))
        total, wrong = integrity(z, set(names))
        print("integrity %d file(s) of the manifest, %d missing or with other bytes: %s" % (total, len(wrong), "ok" if not wrong else "MISMATCH"))
        lacking, _ = refs.violations(ROOT, refs.patterns("Android"), set(names))
        print("refs    %d file(s) or patterns named by the shipped files are not in the bundle: %s" % (len(lacking), "ok" if not lacking else "MISSING"))
        for line in wrong + ["  " + x for x in lacking]:
            print(line)
        bad += (label == 0) + (adsdk > 0) + bool(wrong) + bool(lacking)
        if secrets:
            wanted = [os.environ.get("GODOT_ANDROID_KEYSTORE_RELEASE_PATH", ""), os.environ.get("GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD", "")]
            wanted = [w.encode() for w in wanted if w]
            outside = [n for n in names if not n.startswith("META-INF/")]
            hits = [count_entries(z, outside, w) for w in wanted]
            print("secrets %d value(s) of the environment searched in %d entries: %d hits (path, password)" % (len(wanted), len(outside), sum(hits)))
            bad += (len(wanted) != 2) + (sum(hits) > 0)
    rc, out = tool("jarsigner", "-J-Duser.language=en", "-J-Duser.country=US", "-verify", str(path))
    verified = rc == 0 and "jar verified." in out
    print("jar     %s" % ("jar verified." if verified else "NOT VERIFIED (rc %d)" % rc))
    rc, out = tool("keytool", "-J-Duser.language=en", "-J-Duser.country=US", "-printcert", "-jarfile", str(path))
    fp = fingerprint(out)
    recorded = recorded_signer(ARTIFACTS.read_text(encoding="utf-8")) if ARTIFACTS.exists() else ""
    match = rc == 0 and bool(fp) and fp == recorded
    print("signer  %s: %s" % (fp[:16] + "..." if fp else "no certificate read", "signer_match=yes" if match else "signer_match=NO"))
    return bad + (not verified) + (not match)


def demo():
    with tempfile.TemporaryDirectory() as tmp:
        p = pathlib.Path(tmp) / "t.aab"
        with zipfile.ZipFile(p, "w") as z:
            z.writestr("base/dex/classes.dex", b"x" * 10 + APPLOVIN + b"y")
            z.writestr("base/resources.pb", b"..." + LABEL + b"...")
            z.writestr("base/other.bin", b"a" * (CHUNK - 3) + b"SECRET" + b"b" * 9)
        with zipfile.ZipFile(p) as z:
            assert count_entries(z, ["base/dex/classes.dex"], APPLOVIN) == 1
            assert count_entries(z, ["base/resources.pb"], LABEL) == 1 and count_entries(z, ["base/resources.pb"], b"nothing") == 0
            assert occurs(z, "base/other.bin", b"SECRET"), "a needle across a chunk boundary is found"
    good = hashlib.sha256(b'{"a": 1}' + b"\n").hexdigest()
    with tempfile.TemporaryDirectory() as tmp:
        p = pathlib.Path(tmp) / "m.aab"
        with zipfile.ZipFile(p, "w") as z:
            z.writestr(refs.PACK + "data/integrity_manifest.json", json.dumps({"files": {"res://a.json": good, "res://b.json": good}}))
            z.writestr(refs.PACK + "a.json", b'{"a": 1}' + b"\r\n")
        with zipfile.ZipFile(p) as z:
            total, wrong = integrity(z, set(z.namelist()))
        assert total == 2 and len(wrong) == 1 and "b.json" in wrong[0], wrong
    assert fingerprint("Certificate fingerprints:\n\t SHA256: " + ":".join(["AB"] * 32)) == "ab" * 32
    print("aab_check demo OK (dex scan, label, a needle across a chunk boundary, the manifest read from a pack with other line ends, fingerprint parse)")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("bundle", nargs="?", type=pathlib.Path)
    parser.add_argument("--bundletool", default=os.environ.get("BUNDLETOOL_JAR", ""))
    parser.add_argument("--against", type=pathlib.Path)
    parser.add_argument("--secrets", action="store_true")
    parser.add_argument("--demo", action="store_true")
    args = parser.parse_args()
    if args.demo:
        demo()
        return 0
    if args.bundle is None:
        parser.error("bundle is required")
    bad = facts(args.bundle, args.secrets, args.bundletool)
    if args.against:
        compare(args.bundle, args.against)
    print("aab_check: %s" % ("PASS" if bad == 0 else "FAIL (%d)" % bad))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
