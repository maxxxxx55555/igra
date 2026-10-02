# -*- coding: utf-8 -*-
"""AF3 fresh-frame gate (rc16): a frame is evidence only when it was captured from the code it is cited for, after that code existed.

usage: python tools/qa_sim/af3_frame_check.py [--dir DIR]... [--baseline REV] [--since YYYYMMDDTHHMMSSZ] [--demo]
Frame name: <state>_<label>_<hash>_<UTC>.png   (UTC = YYYYMMDDTHHMMSSZ, written by scripts/tools/_rc16_probe_runner.gd)
Rules; every violation prints "FAIL <file>: <reason>" and the exit code is 1:
  F1 the name parses
  F2 the hash resolves to a commit of this repository
  F3 the capture time is not before that commit's committer time (a frame cannot show code that did not exist yet)
  F4 label "after": no runtime path differs between the hash and HEAD (the frame shows the code that ships); label "before": the hash is the
     declared baseline (--baseline, default e4bb4df)
  F5 the file's modification time is within 15 minutes of the capture time in its name (a renamed old frame is caught)
  F6 a valid PNG of at least 400 x 200 pixels, not byte-identical to another frame of the set
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
NAME = re.compile(r"^(?P<state>[\w-]+?)_(?P<label>before|after)_(?P<hash>[0-9a-f]{7,40})_(?P<utc>\d{8}T\d{6}Z)\.png$")
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


def png_size(path):
    data = path.read_bytes()[:33]
    if len(data) < 24 or data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        return None
    return struct.unpack(">II", data[16:24])


def check(directories, baseline, since):
    fails, seen, total = [], {}, 0
    for d in directories:
        for p in sorted(pathlib.Path(d).glob("*.png")):
            total += 1
            rel = p.name
            m = NAME.match(p.name)
            if not m:
                fails.append("%s: F1 name is not <state>_<before|after>_<hash>_<UTC>.png" % rel)
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
            if abs(p.stat().st_mtime - taken) > MTIME_SLACK_S:
                fails.append("%s: F5 file time and the name's capture time differ by %d s" % (rel, abs(int(p.stat().st_mtime) - taken)))
            size = png_size(p)
            if size is None or size[0] < 400 or size[1] < 200:
                fails.append("%s: F6 not a PNG of at least 400 x 200 (%s)" % (rel, size))
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
    assert png_size(good) == (960, 527)
    bad = tmp / "b.png"
    bad.write_bytes(b"not a png at all, just text")
    assert png_size(bad) is None
    print("af3_frame_check demo OK (name grammar, runtime path classes, PNG header)")


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
    total, fails = check(dirs or [ROOT / "docs" / "stills" / "polish"], baseline, since)
    for f in fails:
        print("FAIL", f)
    print("af3 frames=%d fail=%d" % (total, len(fails)))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
