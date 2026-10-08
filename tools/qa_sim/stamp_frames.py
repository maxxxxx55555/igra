# -*- coding: utf-8 -*-
"""Copies the frames a runner just wrote under their AF3 names: <state>_<label>_<hash>_<UTC>.png (rc16).

usage: python tools/qa_sim/stamp_frames.py <src-dir> <dest-dir> <hash> [--label after] [--since-minutes 30] [--ext png] [--only NAME,NAME] [--demo]
The final-frames runner (scripts/tools/_final_frames_runner.gd) writes NN_name.png with no hash and no time. The UTC stamp is the file's own modification
time, so a frame that was not written by the run just made (older than --since-minutes) is skipped and cannot be passed off as fresh; the copy keeps the
bytes. tools/qa_sim/af3_frame_check.py --dir <dest-dir> then holds the names, the times and the hash against the code tree.
"""
import pathlib
import re
import shutil
import sys
import tempfile
import time


def stamp(src, dest, code_hash, label="after", since_minutes=30.0, ext="png", only=None):
    dest.mkdir(parents=True, exist_ok=True)
    now = time.time()
    written = []
    for f in sorted(src.glob("*." + ext)):
        if now - f.stat().st_mtime > since_minutes * 60 or (only and f.stem not in only):
            continue
        utc = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime(f.stat().st_mtime))
        target = dest / ("%s_%s_%s_%s.%s" % (f.stem, label, code_hash, utc, ext))
        shutil.copy2(f, target)
        written.append(target.name)
    return written


def demo():
    """A fresh frame is copied under a name that parses; a frame older than the window is skipped."""
    import os
    with tempfile.TemporaryDirectory() as tmp:
        src, dest = pathlib.Path(tmp) / "src", pathlib.Path(tmp) / "dest"
        src.mkdir()
        (src / "01_menu.png").write_bytes(b"a")
        (src / "02_old.png").write_bytes(b"b")
        old = time.time() - 3 * 3600
        os.utime(src / "02_old.png", (old, old))
        names = stamp(src, dest, "abc1234")
    ok = len(names) == 1 and re.fullmatch(r"01_menu_after_abc1234_\d{8}T\d{6}Z\.png", names[0]) is not None
    print("stamp_frames demo: %s" % ("1 fresh frame copied, 1 old frame skipped" if ok else "WRONG %s" % names))
    return 0 if ok else 1


def main(argv):
    if "--demo" in argv:
        return demo()
    src, dest, code_hash = pathlib.Path(argv[0]), pathlib.Path(argv[1]), argv[2]
    label = argv[argv.index("--label") + 1] if "--label" in argv else "after"
    minutes = float(argv[argv.index("--since-minutes") + 1]) if "--since-minutes" in argv else 30.0
    ext = argv[argv.index("--ext") + 1] if "--ext" in argv else "png"
    only = argv[argv.index("--only") + 1].split(",") if "--only" in argv else None
    names = stamp(src, dest, code_hash, label, minutes, ext, only)
    print("\n".join(names))
    print("stamp_frames: %d frame(s) copied to %s" % (len(names), dest))
    return 0 if names else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
