# -*- coding: utf-8 -*-
"""How much of a frame is burnt out (v10 F12, N001/N002 of the nitpick file): the share of pixels at luma 235 or more, the share of cream (R >= 225, G >= 215, B >= 150: the flat lit-road colour that docs/STYLE_GUIDE.md bans) and the mean and 99th percentile luma.

usage: python tools/qa_sim/frame_clip_stats.py <frame.png|.jpg|dir>... [--max-clip 0.02] [--only GLOB] [--demo]
A directory is read for its .png and .jpg frames. With --max-clip the exit code is 1 when a frame (those matching --only, default all) has a clipped share above the number. The HUD sits in the frame, so the shares are of the whole picture: a bright HUD counts like a bright road
(the HUD is dark glass and brass: its bright pixels are a fraction of a percent, measured on the frames of the final set).
"""
import fnmatch
import pathlib
import sys

import numpy as np
from PIL import Image


def stats(path):
    rgb = np.asarray(Image.open(path).convert("RGB"), dtype=np.float32)
    luma = 0.2126 * rgb[..., 0] + 0.7152 * rgb[..., 1] + 0.0722 * rgb[..., 2]
    cream = (rgb[..., 0] >= 225) & (rgb[..., 1] >= 215) & (rgb[..., 2] >= 150)
    return {"clip": float((luma >= 235).mean()), "cream": float(cream.mean()), "mean": float(luma.mean()), "p99": float(np.percentile(luma, 99))}


def frames(args):
    out = []
    for a in args:
        p = pathlib.Path(a)
        out += sorted(f for f in p.rglob("*") if f.suffix.lower() in (".png", ".jpg", ".jpeg")) if p.is_dir() else [p]
    return out


def main(argv):
    if "--demo" in argv:
        import tempfile
        with tempfile.TemporaryDirectory() as tmp:
            dark = pathlib.Path(tmp) / "dark.png"
            Image.fromarray(np.full((100, 100, 3), 40, np.uint8)).save(dark)
            burnt = np.full((100, 100, 3), 40, np.uint8)
            burnt[:10, :, :] = (250, 240, 200)
            hot = pathlib.Path(tmp) / "hot.png"
            Image.fromarray(burnt).save(hot)
            a, b = stats(dark), stats(hot)
            assert a["clip"] == 0.0 and a["cream"] == 0.0 and abs(b["clip"] - 0.10) < 1e-6 and abs(b["cream"] - 0.10) < 1e-6
        print("frame_clip_stats demo: a dark frame reads 0 % clipped and a frame with a tenth of it burnt out reads 10 % clipped and 10 % cream")
        return 0
    limit = float(argv[argv.index("--max-clip") + 1]) if "--max-clip" in argv else None
    only = argv[argv.index("--only") + 1] if "--only" in argv else "*"
    skip = {argv[i + 1] for i, a in enumerate(argv) if a in ("--max-clip", "--only")}
    paths = frames([a for a in argv if not a.startswith("--") and a not in skip])
    bad = 0
    for f in paths:
        s = stats(f)
        over = limit is not None and fnmatch.fnmatch(f.name, only) and s["clip"] > limit
        bad += 1 if over else 0
        print("%-70s clip %5.2f %%  cream %5.2f %%  mean %5.1f  p99 %5.1f%s" % (f.name[:70], 100 * s["clip"], 100 * s["cream"], s["mean"], s["p99"], "  OVER" if over else ""))
    print("frame_clip_stats: %d frame(s)%s" % (len(paths), (", %d over %.1f %% clipped" % (bad, 100 * limit)) if limit is not None else ""))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
