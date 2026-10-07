# -*- coding: utf-8 -*-
"""Measured numbers of the polish frames, so a read of a frame has a measurement beside it (rc16 S6).

usage: python tools/qa_sim/frame_stats.py [--dir docs/stills/polish] [--hash HASH] [--demo]
For every `<state>_before_<hash>_<UTC>.png` and `<state>_after_<hash>_<UTC>.png` of the folder (with --hash: only the after frames of that hash and
the before frames) one line: mean luma and its standard deviation on 0..255 (a flat or black capture has a deviation under 2), the circular mean hue in
degrees of the lit pixels (value above 0.6, saturation above 0.1), the share of such pixels, and the grain measure: the strongest bin of the 2D
spectrum of a flat 128 x 64 patch of the upper frame (rows 20 to 84, the sky) over the mean bin. White noise reads about 9; a tile repeated every 10 px
reads far more. Then, per state, the change from the before frame to the after frame.
"""
import colorsys
import math
import pathlib
import re
import sys

import numpy as np
from PIL import Image

NAME = re.compile(r"^(?P<state>[\w-]+?)_(?P<label>before|after)_(?P<hash>[0-9a-f]{7,40})_(?P<utc>\d{8}T\d{6}Z)\.png$")
PATCH_ROWS = (20, 84)
PATCH_COLS = (416, 544)


def stats(path):
    rgb = np.asarray(Image.open(path).convert("RGB")).astype(float)
    luma = rgb @ np.array([0.2126, 0.7152, 0.0722])
    hsv = np.array([colorsys.rgb_to_hsv(*(px / 255.0)) for px in rgb.reshape(-1, 3)[::7]])
    lit = hsv[(hsv[:, 2] > 0.6) & (hsv[:, 1] > 0.1)]
    hue = math.degrees(math.atan2(np.sin(np.radians(lit[:, 0] * 360)).mean(), np.cos(np.radians(lit[:, 0] * 360)).mean())) % 360 if len(lit) else float("nan")
    patch = luma[PATCH_ROWS[0]:PATCH_ROWS[1], PATCH_COLS[0]:PATCH_COLS[1]]
    spectrum = np.abs(np.fft.fft2(patch - patch.mean())) ** 2
    spectrum[0, 0] = 0
    half = spectrum[: spectrum.shape[0] // 2 + 1]
    grain = half.max() / half.mean() if half.mean() > 0 else float("nan")
    return {"mean": luma.mean(), "std": luma.std(), "hue": hue, "lit": len(lit) / (len(hsv) or 1), "grain": grain}


def demo():
    """A flat frame reads a deviation under 2, noise reads a high one and a repeated tile a far stronger grain bin than white noise."""
    import tempfile
    rng = np.random.default_rng(1)
    with tempfile.TemporaryDirectory() as tmp:
        flat = pathlib.Path(tmp) / "flat.png"
        noise = pathlib.Path(tmp) / "noise.png"
        tiled = pathlib.Path(tmp) / "tiled.png"
        Image.fromarray(np.full((540, 960, 3), 20, np.uint8)).save(flat)
        Image.fromarray(rng.integers(0, 255, (540, 960, 3), dtype=np.uint8)).save(noise)
        tile = rng.integers(0, 255, (10, 10, 1), dtype=np.uint8)
        Image.fromarray(np.tile(tile, (54, 96, 3))).save(tiled)
        a, b, c = stats(flat), stats(noise), stats(tiled)
    wrong = []
    if not a["std"] < 2.0:
        wrong.append("flat deviation %.2f" % a["std"])
    if not b["std"] > 50.0:
        wrong.append("noise deviation %.2f" % b["std"])
    if not c["grain"] > 3 * b["grain"]:
        wrong.append("tiled grain %.1f against noise %.1f" % (c["grain"], b["grain"]))
    for w in wrong:
        print("DEMO FAIL " + w)
    print("frame_stats demo: 3 fixtures, %d wrong" % len(wrong))
    return 1 if wrong else 0


def main(argv):
    if "--demo" in argv:
        return demo()
    folder = pathlib.Path(argv[argv.index("--dir") + 1]) if "--dir" in argv else pathlib.Path(__file__).resolve().parents[2] / "docs" / "stills" / "polish"
    only = argv[argv.index("--hash") + 1] if "--hash" in argv else None
    rows = {}
    for f in sorted(folder.glob("*.png")):
        m = NAME.match(f.name)
        if not m or (m["label"] == "after" and only and not m["hash"].startswith(only)):
            continue
        rows.setdefault(m["state"], {})[m["label"]] = (f.name, stats(f))
    print("%-22s %-6s %6s %6s %6s %6s %6s  %s" % ("state", "label", "luma", "std", "hue", "lit%", "grain", "file"))
    flat = 0
    for state, pair in sorted(rows.items()):
        for label in ("before", "after"):
            if label in pair:
                name, s = pair[label]
                flat += s["std"] < 2.0
                print("%-22s %-6s %6.1f %6.1f %6.0f %6.1f %6.1f  %s" % (state, label, s["mean"], s["std"], s["hue"], 100 * s["lit"], s["grain"], name))
        if len(pair) == 2:
            b, a = pair["before"][1], pair["after"][1]
            print("%-22s change luma %+.1f, hue %+.0f deg, grain %.1f -> %.1f" % ("", a["mean"] - b["mean"], ((a["hue"] - b["hue"] + 180) % 360) - 180, b["grain"], a["grain"]))
    print("frames with a deviation under 2: %d" % flat)
    return 1 if flat else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
