# -*- coding: utf-8 -*-
"""Measured deltas of the density frames (Session 23, AF8): for each pair of frames of one view (the dressing hidden "before", shown "after", one run, one code hash) the mean luminance,
the mean saturation and the contrast, with the parts of the screen that the HUD still draws left out, and the share of the picture that the dressing changed.

usage: python tools/qa_sim/density_measure.py <hash> [--base <hash>] [--write docs/DENSITY_MEASURED.md] [--dir docs/stills/density] [--demo]
--base names the code of the baseline `before` frames (the pass's first shot); it adds the district spread table: how far apart the eleven districts look in one view.
Luminance is Rec. 709 on 0..1; saturation is the HSV S of the pixels brighter than 0.05; contrast is the standard deviation of the luminance; changed share is the part of the pixels
whose luminance differs by 0.05 or more. The mask is in MASKS (pixels of the 960 x 540 frame): the objectives panel, the caption, the toast, the bars at the top left.
"""
import glob
import pathlib
import re
import sys

import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
MASKS = [(795, 120, 960, 220), (0, 160, 290, 192), (390, 400, 570, 435), (0, 0, 150, 48)]
VIEWS = ["01_dark", "02_rest", "03_street", "04_block", "05_skyline"]
CHANGE = 0.05


def load(path):
    a = np.asarray(Image.open(path).convert("RGB"), dtype=float) / 255.0
    keep = np.ones(a.shape[:2], dtype=bool)
    for x0, y0, x1, y1 in MASKS:
        keep[y0:y1, x0:x1] = False
    return a, keep


def lum(a):
    return a @ np.array([0.2126, 0.7152, 0.0722])


def saturation(a):
    v = a.max(2)
    s = np.where(v > 0, (v - a.min(2)) / np.maximum(v, 1e-9), 0.0)
    return s, v


def metrics(a, keep):
    y = lum(a)
    s, v = saturation(a)
    lit = keep & (v > 0.05)
    return float(y[keep].mean()), float(s[lit].mean()) if lit.any() else 0.0, float(y[keep].std())


def pair_metrics(before_path, after_path):
    b, keep = load(before_path)
    a, _ = load(after_path)
    mb, ma = metrics(b, keep), metrics(a, keep)
    changed = float((np.abs(lum(a) - lum(b))[keep] >= CHANGE).mean())
    return mb, ma, changed


def find(directory, pattern, code):
    """The frames of one run: the `before` frames (dressing hidden) of the pass's head are kept in `hidden_<code>`, the rest in the folder itself."""
    return sorted(glob.glob(str(directory / pattern)) + glob.glob(str(directory / ("hidden_%s" % code) / pattern)))


def pairs(directory, code):
    out = {}
    for before in find(directory, "*_before_%s_*.jpg" % code, code):
        name = pathlib.Path(before).name
        m = re.match(r"(?P<district>[a-z_]+?)_(?P<view>\d\d_[a-z]+)_before_", name)
        after = glob.glob(str(directory / ("%s_%s_after_%s_*.jpg" % (m.group("district"), m.group("view"), code))))
        if after:
            out[(m.group("district"), m.group("view"))] = (before, sorted(after)[-1])
    return out


def table(found):
    rows = {k: pair_metrics(*v) for k, v in found.items()}
    lines = ["| District | View | Luminance before | after | Saturation before | after | Contrast before | after | Changed share |", "|---|---|---|---|---|---|---|---|---|"]
    for (district, view), (mb, ma, changed) in sorted(rows.items(), key=lambda kv: (kv[0][0], VIEWS.index(kv[0][1]))):
        lines.append("| %s | %s | %.4f | %.4f | %.3f | %.3f | %.4f | %.4f | %.1f %% |" % (district, view, mb[0], ma[0], mb[1], ma[1], mb[2], ma[2], 100.0 * changed))
    by_view = {}
    for (district, view), (mb, ma, changed) in rows.items():
        by_view.setdefault(view, []).append((mb, ma, changed))
    lines += ["", "| View | Pairs | Luminance delta | Saturation delta | Contrast delta | Changed share |", "|---|---|---|---|---|---|"]
    for view in VIEWS:
        if view in by_view:
            items = by_view[view]
            lines.append("| %s | %d | %+.4f | %+.4f | %+.4f | %.1f %% |" % (view, len(items), np.mean([i[1][0] - i[0][0] for i in items]), np.mean([i[1][1] - i[0][1] for i in items]),
                                                                           np.mean([i[1][2] - i[0][2] for i in items]), 100.0 * np.mean([i[2] for i in items])))
    return "\n".join(lines), rows


def thumb(path):
    a, keep = load(path)
    a[~keep] = 0.0
    return np.asarray(Image.fromarray((a * 255).astype(np.uint8)).resize((48, 27), Image.BOX), dtype=float) / 255.0


def spread(shots):
    """(mean, least) of the root-mean-square distance between the 48 x 27 thumbnails of every two districts' frames, with the pair that is least apart."""
    names = sorted(shots)
    small = {n: thumb(shots[n]) for n in names}
    dists = [(float(np.sqrt(((small[a] - small[b]) ** 2).mean())), a, b) for i, a in enumerate(names) for b in names[i + 1:]]
    return float(np.mean([d[0] for d in dists])), min(dists)


def spread_table(directory, code, base):
    lines = ["| View | Baseline (%s) mean | least apart | Dressing hidden mean | least apart | Dressing shown mean | least apart |" % base, "|---|---|---|---|---|---|---|"]
    for view in VIEWS:
        cells = []
        for label, hash_ in [("before", base), ("before", code), ("after", code)]:
            shots = {}
            for path in find(directory, "*_%s_%s_%s_*.jpg" % (view, label, hash_), hash_):
                shots[pathlib.Path(path).name.split("_%s_" % view)[0]] = path
            mean, (least, a, b) = spread(shots)
            cells += ["%.4f" % mean, "%.4f (%s, %s)" % (least, a, b)]
        lines.append("| %s | %s |" % (view, " | ".join(cells)))
    return "\n".join(lines)


def main(argv):
    if "--demo" in argv:
        a = np.zeros((540, 960, 3))
        b = a.copy()
        b[300:340, 100:300] = 0.5
        keep = np.ones((540, 960), dtype=bool)
        assert metrics(a, keep)[0] == 0.0 and abs(metrics(b, keep)[0] - 0.5 * 40 * 200 / (540 * 960)) < 1e-9
        assert abs(float((np.abs(lum(b) - lum(a)) >= CHANGE).mean()) - 40 * 200 / (540 * 960)) < 1e-9
        print("density_measure demo: a lit rectangle on black raises the luminance by its area share and changes exactly its pixels")
        return 0
    code = argv[0]
    directory = ROOT / (argv[argv.index("--dir") + 1] if "--dir" in argv else "docs/stills/density")
    found = pairs(directory, code)
    text, rows = table(found)
    if "--base" in argv:
        text += "\n\nDistrict spread: the root-mean-square distance (0..1) between the 48 x 27 thumbnails of two districts' frames of one view, the mean over the 55 pairs of districts and the pair that is least apart.\n\n" + spread_table(directory, code, argv[argv.index("--base") + 1])
    print(text)
    if "--write" in argv:
        body = ["# Measured deltas of the density frames (Session 23)", "",
                "Written by `python tools/qa_sim/density_measure.py %s%s --write docs/DENSITY_MEASURED.md` from the pairs of `docs/stills/density` (the same run and the same code: `before` has the district's dressing node hidden, `after` shows it)." % (code, " --base " + argv[argv.index("--base") + 1] if "--base" in argv else ""),
                "Luminance is Rec. 709 on 0..1, saturation the HSV S of the pixels brighter than 0.05, contrast the standard deviation of the luminance, over the frame without the parts the HUD still draws; changed share is the part of the pixels",
                "whose luminance differs by %.2f or more. %d pairs." % (CHANGE, len(rows)), "", text]
        pathlib.Path(argv[argv.index("--write") + 1]).write_text("\n".join(body) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
