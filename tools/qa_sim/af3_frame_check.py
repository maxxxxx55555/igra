# -*- coding: utf-8 -*-
"""AF3 fresh-frame gate (rc16): a frame is evidence only when it was captured from the code it is cited for, after that code existed.

usage: python tools/qa_sim/af3_frame_check.py [--dir DIR]... [--baseline REV] [--since YYYYMMDDTHHMMSSZ] [--demo]
Frame name: <state>_<label>_<hash>_<UTC>.png or .jpg   (UTC = YYYYMMDDTHHMMSSZ, written by scripts/tools/_rc16_probe_runner.gd or tools/qa_sim/stamp_frames.py)
Rules; every violation prints "FAIL <file>: <reason>" and the exit code is 1:
  F0 a directory with no .png or .jpg frame fails (a wrong directory or extension cannot pass with frames=0)
  F1 the name parses
  F2 the hash resolves to a commit of this repository
  F3 the capture time is not before that commit's committer time (a frame cannot show code that did not exist yet)
  F4 label "after": no runtime path differs between the hash and HEAD (the frame shows the code that ships); label "before": the hash is the
     declared baseline (--baseline, default e4bb4df)
  F5 a frame git has not committed yet (untracked or modified): its modification time is within 15 minutes of the capture time in its name, so a
     renamed old frame is caught when it is added. A committed frame is judged by the commit that added it, which cannot be older than the capture
     time: a clone or a pull sets every modification time to the checkout time, and the mtime rule failed 8 of 8 polish frames on any fresh copy
  F6 a valid PNG or JPEG of at least 400 x 200 pixels, not byte-identical to another frame of the set
  F7 with --since: the capture time is not before the start of the pass
Runtime paths are everything the game ships: scripts/ (not scripts/tools/), scenes/ (not scenes/tools/), assets/, data/, addons/,
android/, localization/, project.godot, export_presets.cfg, default_bus_layout.tres.
"""
import calendar
import hashlib
import pathlib
import re
import struct
import subprocess
import sys
import time

ROOT = pathlib.Path(__file__).resolve().parents[2]
NAME = re.compile(r"^(?P<state>[\w-]+?)_(?P<label>before|after)_(?P<hash>[0-9a-f]{7,40})_(?P<utc>\d{8}T\d{6}Z)\.(?:png|jpg)$")
RUNTIME_PREFIXES = ("scripts/", "scenes/", "assets/", "data/", "addons/", "android/", "localization/")
RUNTIME_FILES = ("project.godot", "export_presets.cfg", "default_bus_layout.tres")
NOT_RUNTIME = ("scripts/tools/", "scenes/tools/")
MTIME_SLACK_S = 15 * 60


def git(*args):
    return subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace")


def is_runtime(path):
    if path.startswith(NOT_RUNTIME):
        return False
    return path.startswith(RUNTIME_PREFIXES) or path in RUNTIME_FILES


def utc_to_epoch(stamp):
    return calendar.timegm(time.strptime(stamp, "%Y%m%dT%H%M%SZ"))


def time_fault(path, taken, committed=None):
    """F5: "" when the file's own time agrees with the capture time in its name, else the reason. committed=None asks git whether the file is clean."""
    if committed is None:
        committed = git("ls-files", "--error-unmatch", "--", str(path)).returncode == 0 and not git("status", "--porcelain", "--", str(path)).stdout.strip()
    if not committed:
        gap = abs(int(path.stat().st_mtime) - taken)
        return "file time and the name's capture time differ by %d s" % gap if gap > MTIME_SLACK_S else ""
    added = git("log", "--diff-filter=A", "--format=%ct", "--", str(path)).stdout.split()
    return "committed %d s before the capture time in its name" % (taken - int(added[-1])) if added and int(added[-1]) < taken else ""


def image_size(path):
    """(width, height) from the header of a PNG or a JPEG, None when the file is neither."""
    data = path.read_bytes()
    if len(data) >= 24 and data[:8] == b"\x89PNG\r\n\x1a\n" and data[12:16] == b"IHDR":
        return struct.unpack(">II", data[16:24])
    i = 2
    while data[:2] == b"\xff\xd8" and i + 9 <= len(data) and data[i] == 0xFF:
        if 0xC0 <= data[i + 1] <= 0xCF and data[i + 1] not in (0xC4, 0xC8, 0xCC):
            height, width = struct.unpack(">HH", data[i + 5:i + 9])
            return width, height
        i += 2 + struct.unpack(">H", data[i + 2:i + 4])[0]
    return None


def check(directories, baseline, since):
    fails, seen, total = [], {}, 0
    for d in directories:
        frames = sorted([*pathlib.Path(d).glob("*.png"), *pathlib.Path(d).glob("*.jpg")])
        if not frames:
            fails.append("%s: F0 no .png or .jpg frame in this directory" % d)
        for p in frames:
            total += 1
            rel = p.name
            m = NAME.match(p.name)
            if not m:
                fails.append("%s: F1 name is not <state>_<before|after>_<hash>_<UTC>.png or .jpg" % rel)
                continue
            rev = git("rev-parse", "--verify", m["hash"] + "^{commit}")
            if rev.returncode != 0:
                fails.append("%s: F2 hash %s is not a commit" % (rel, m["hash"]))
                continue
            full = rev.stdout.strip()
            ctime = int(git("show", "-s", "--format=%ct", full).stdout.strip())
            taken = utc_to_epoch(m["utc"])
            if taken < ctime:
                fails.append("%s: F3 captured %s, %d s before commit %s existed" % (rel, m["utc"], ctime - taken, m["hash"]))
            if m["label"] == "after":
                changed = [x for x in git("diff", "--name-only", full, "HEAD").stdout.splitlines() if is_runtime(x)]
                if changed:
                    fails.append("%s: F4 %d runtime path(s) differ between %s and HEAD, first: %s" % (rel, len(changed), m["hash"], changed[0]))
            else:
                base = git("rev-parse", "--verify", baseline + "^{commit}").stdout.strip()
                if not base or not (full == base or full.startswith(base) or base.startswith(full)):
                    fails.append("%s: F4 a before frame must come from the baseline %s, not %s" % (rel, baseline, m["hash"]))
            fault = time_fault(p, taken)
            if fault:
                fails.append("%s: F5 %s" % (rel, fault))
            size = image_size(p)
            if size is None or size[0] < 400 or size[1] < 200:
                fails.append("%s: F6 not a PNG or JPEG of at least 400 x 200 (%s)" % (rel, size))
            digest = hashlib.sha256(p.read_bytes()).hexdigest()
            if digest in seen:
                fails.append("%s: F6 byte-identical to %s" % (rel, seen[digest]))
            seen[digest] = rel
            if since and m["utc"] < since:
                fails.append("%s: F7 captured %s, before the pass started %s" % (rel, m["utc"], since))
    return total, fails


def demo():
    assert NAME.match("04_combat_hit_after_a1b2c3d_20261003T014512Z.png")
    assert not NAME.match("04_combat_hit_final_a1b2c3d_20261003T014512Z.png")
    assert not NAME.match("04_combat_hit_after_a1b2c3d_2026-10-03.png")
    assert is_runtime("scripts/player/player_3d.gd") and is_runtime("project.godot") and is_runtime("assets/shaders/a.gdshader")
    assert not is_runtime("scripts/tools/_x.gd") and not is_runtime("docs/PROOFS.md") and not is_runtime("tools/check.sh")
    assert utc_to_epoch("19700101T000010Z") == 10
    tmp = pathlib.Path(__import__("tempfile").mkdtemp())
    good = tmp / "a.png"
    good.write_bytes(b"\x89PNG\r\n\x1a\n" + struct.pack(">I", 13) + b"IHDR" + struct.pack(">II", 960, 527) + b"\x08\x02\x00\x00\x00")
    assert image_size(good) == (960, 527)
    jpeg = tmp / "c.jpg"
    jpeg.write_bytes(b"\xff\xd8\xff\xe0" + struct.pack(">H", 4) + b"\x00\x00" + b"\xff\xc0" + struct.pack(">H", 11) + b"\x08" + struct.pack(">HH", 703, 1280) + b"\x03")
    assert image_size(jpeg) == (1280, 703) and NAME.match("A01_menu_after_bca7d33_20261007T235629Z.jpg")
    bad = tmp / "b.png"
    bad.write_bytes(b"not a png at all, just text")
    assert image_size(bad) is None
    assert check([tmp / "no_frames"], "e4bb4df", "")[1][0].count("F0") == 1
    this = pathlib.Path(__file__)
    assert time_fault(this, 4102444800, True) != "" and time_fault(this, 0, True) == ""
    assert time_fault(good, int(good.stat().st_mtime), False) == "" and "differ" in time_fault(good, int(good.stat().st_mtime) - 4000, False)
    print("af3_frame_check demo OK (name grammar, runtime path classes, PNG and JPEG header, empty directory, F5 for a committed and an uncommitted frame)")


def main():
    args = sys.argv[1:]
    if "--demo" in args:
        demo()
        return 0
    dirs, baseline, since = [], "e4bb4df", ""
    i = 0
    while i < len(args):
        if args[i] == "--dir":
            dirs.append(args[i + 1])
            i += 2
        elif args[i] == "--baseline":
            baseline = args[i + 1]
            i += 2
        elif args[i] == "--since":
            since = args[i + 1]
            i += 2
        else:
            i += 1
    total, fails = check(dirs or [ROOT / "docs" / "stills" / d for d in ("polish", "rc16_playthrough", "rc16_final")], baseline, since)
    for f in fails:
        print("FAIL", f)
    print("af3 frames=%d fail=%d" % (total, len(fails)))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
