# -*- coding: utf-8 -*-
"""PV1 (Session 23): the luminance, saturation and contrast of the game's frames beside those of reference frames the owner supplies (docs/AAA_BENCHMARK.md).

usage: python tools/qa_sim/benchmark_frames.py --ref DIR [--ours DIR] [--demo]
Every .png and .jpg of a directory is one frame, measured whole (no part of the picture is left out, a reference frame has none of this game's HUD masks): the mean
luminance (Rec. 709 on 0..1), the mean saturation of the pixels brighter than 0.05 (HSV S) and the contrast (the standard deviation of the luminance). Then the median of
each set and the difference (ours minus the reference). Default --ours is the density frames of the pass (the `after` set). The reference frames are the owner's
(from a game the owner owns, in a similar light): none is stored in this repository.
"""
import glob
import pathlib
import statistics
import sys

import numpy as np
from PIL import Image

from density_measure import metrics

ROOT = pathlib.Path(__file__).resolve().parents[2]


def measure(path):
    a = np.asarray(Image.open(path).convert("RGB"), dtype=float) / 255.0
    return metrics(a, np.ones(a.shape[:2], dtype=bool))


def frames(directory, pattern="*"):
    return sorted(p for ext in ("png", "jpg") for p in glob.glob(str(pathlib.Path(directory) / ("%s.%s" % (pattern, ext)))))


def table(name, files):
    rows = [measure(f) for f in files]
    lines = ["| %s | Luminance | Saturation | Contrast |" % name, "|---|---|---|---|"]
    lines += ["| %s | %.4f | %.3f | %.4f |" % (pathlib.Path(f).name[:48], *r) for f, r in zip(files, rows)]
    med = [statistics.median(r[k] for r in rows) for k in range(3)] if rows else [0.0, 0.0, 0.0]
    lines.append("| **median of %d** | %.4f | %.3f | %.4f |" % (len(rows), *med))
    return "\n".join(lines), med


def demo():
    import tempfile
    with tempfile.TemporaryDirectory() as d:
        Image.fromarray(np.zeros((40, 40, 3), dtype=np.uint8)).save(pathlib.Path(d) / "black.png")
        flat = np.zeros((40, 40, 3), dtype=np.uint8)
        flat[:20] = (255, 0, 0)
        Image.fromarray(flat).save(pathlib.Path(d) / "half.png")
        black, half = measure(pathlib.Path(d) / "black.png"), measure(pathlib.Path(d) / "half.png")
    assert black == (0.0, 0.0, 0.0)
    assert abs(half[0] - 0.5 * 0.2126) < 1e-6 and abs(half[1] - 1.0) < 1e-9 and half[2] > 0.0
    print("benchmark_frames demo: a black frame reads zero, a half-red frame reads its luminance and a full saturation")
    return 0


def main(argv):
    if "--demo" in argv:
        return demo()
    if "--ref" not in argv:
        sys.exit("benchmark_frames: --ref DIR is needed (the owner's reference frames)")
    ref = frames(argv[argv.index("--ref") + 1])
    ours = frames(argv[argv.index("--ours") + 1] if "--ours" in argv else ROOT / "docs/stills/density", "*_after_*" if "--ours" not in argv else "*")
    if not ref or not ours:
        sys.exit("benchmark_frames: no frame in %s" % ("the reference directory" if not ref else "this game's directory"))
    text_ref, m_ref = table("Reference", ref)
    text_our, m_our = table("This game", ours)
    print(text_ref + "\n\n" + text_our)
    print("\nDifference of the medians (this game minus the reference): luminance %+.4f, saturation %+.3f, contrast %+.4f" % tuple(o - r for o, r in zip(m_our, m_ref)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
