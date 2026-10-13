# -*- coding: utf-8 -*-
"""Composition rules of the store frames (Session 23, S1; store/SCREENSHOT_RECIPES.md): what a frame must be before it is looked at.

usage: python tools/qa_sim/store_frames_check.py [--dir store/screenshots/recipes] [--demo]
A frame is a PNG of 960 x 540 pixels (exactly 16:9) in RGB (no alpha), not blank (the standard deviation of the luminance at least 0.04), neither black nor bright (the mean luminance between
0.06 and 0.40), and without a blown-out white patch (at most 0.3 % of the pixels at a luminance of 0.98 or more: docs/STYLE_GUIDE.md bans pure white). Every violation prints
"FAIL <file>: <rule>" and the exit code is 1; a directory without a frame fails too. Whether the picture is worth a store page is a reading, not a rule: the frames are looked at.
"""
import glob
import pathlib
import sys

import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
SIZE = (960, 540)
MIN_STD = 0.04
MEAN_BAND = (0.06, 0.40)
WHITE_LUMA = 0.98
MAX_WHITE_SHARE = 0.003


def faults(path):
    out = []
    raw = pathlib.Path(path).read_bytes()
    if raw[:8] != b"\x89PNG\r\n\x1a\n":
        return ["not a PNG"]
    colour_type = raw[25]
    if colour_type in (4, 6):
        out.append("has an alpha channel (PNG colour type %d)" % colour_type)
    im = Image.open(path)
    if im.size != SIZE:
        out.append("size %dx%d, not %dx%d" % (*im.size, *SIZE))
    a = np.asarray(im.convert("RGB"), dtype=float) / 255.0
    luma = a @ np.array([0.2126, 0.7152, 0.0722])
    if luma.std() < MIN_STD:
        out.append("blank: luminance deviation %.3f under %.2f" % (luma.std(), MIN_STD))
    if not MEAN_BAND[0] <= luma.mean() <= MEAN_BAND[1]:
        out.append("mean luminance %.3f outside %.2f..%.2f" % (luma.mean(), *MEAN_BAND))
    white = float((luma >= WHITE_LUMA).mean())
    if white > MAX_WHITE_SHARE:
        out.append("%.2f %% of the pixels are blown out to white (limit %.1f %%)" % (100.0 * white, 100.0 * MAX_WHITE_SHARE))
    return out


def demo():
    import tempfile
    with tempfile.TemporaryDirectory() as d:
        d = pathlib.Path(d)
        rng = np.random.default_rng(1)
        good = (rng.random((SIZE[1], SIZE[0], 3)) * 90 + 10).astype(np.uint8)
        Image.fromarray(good).save(d / "good.png")
        Image.fromarray(good).convert("RGBA").save(d / "alpha.png")
        Image.fromarray(good[:300, :500]).save(d / "small.png")
        Image.fromarray(np.zeros((SIZE[1], SIZE[0], 3), dtype=np.uint8)).save(d / "black.png")
        blown = good.copy()
        blown[:60, :120] = 255
        Image.fromarray(blown).save(d / "blown.png")
        assert faults(d / "good.png") == [], faults(d / "good.png")
        assert any("alpha" in f for f in faults(d / "alpha.png"))
        assert any("size" in f for f in faults(d / "small.png"))
        assert any("blank" in f for f in faults(d / "black.png"))
        assert any("blown out" in f for f in faults(d / "blown.png"))
    print("store_frames_check demo: a good frame passes; an alpha channel, a wrong size, a black frame and a white patch are each told apart")
    return 0


def main(argv):
    if "--demo" in argv:
        return demo()
    directory = ROOT / (argv[argv.index("--dir") + 1] if "--dir" in argv else "store/screenshots/recipes")
    files = sorted(glob.glob(str(directory / "*.png")))
    bad = 0
    if not files:
        print("FAIL %s: no PNG frame" % directory)
        return 1
    for f in files:
        for reason in faults(f):
            print("FAIL %s: %s" % (pathlib.Path(f).name, reason))
            bad += 1
    print("store_frames_check: %d frame(s), %d fault(s)" % (len(files), bad))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
