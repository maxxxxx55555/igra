# CORRECTION_LOG 252: the mean luminance (Rec. 709, 0..1) of the 40 English store frames of the fix chain against the pair frame of the same district and view of the same chain, with the stage each run shot the view at (the state lines of the two logs).
# The frames of a stage 0 view were shot under the dark ambient (0.030) in both runs, the stage 3 views under the full one (0.160).
# usage: python -I s23_store_luminance_l25.py <hash> <store log> <pair log> <pair frames dir> <store frames dir> [<store frames dir> ...]
import glob
import re
import statistics
import sys

import numpy as np
from PIL import Image

H, STORE_LOG, PAIR_LOG, PAIR_DIR, *STORE_DIRS = sys.argv[1:]
IDS = ["residential", "industrial", "warehouses", "hospital", "gas_station", "police", "park", "power_station"]
VIEWS = ["01_dark", "02_rest", "03_street", "04_block", "05_skyline"]
LINE = re.compile(r"\[density\] state district=(\S+) view=(\S+) weather=\d+ stage=(\d) ")


def stages(path):
    return {(m.group(1), m.group(2)): int(m.group(3)) for m in (LINE.search(x) for x in open(path, encoding="utf-8", errors="replace")) if m}


def lum(path):
    a = np.asarray(Image.open(path).convert("RGB"), dtype=float) / 255.0
    return float((a @ np.array([0.2126, 0.7152, 0.0722])).mean())


def one(patterns):
    hits = sorted(sum((glob.glob(p) for p in patterns), []))
    assert len(hits) == 1, (patterns, hits)
    return hits[0]


st_store, st_pair = stages(STORE_LOG), stages(PAIR_LOG)
rows = []
for d in IDS:
    for v in VIEWS:
        pair = lum(one(["%s/%s_%s_after_%s_*.jpg" % (PAIR_DIR, d, v, H)]))
        store = lum(one(["%s/%s_%s_en_%s_*.png" % (s, d, v, H) for s in STORE_DIRS]))
        rows.append((d, v, st_store[(d, v)], st_pair[(d, v)], store, pair))
        print("%-14s %-10s store stage %d, pair stage %d: store %.3f, pair %.3f, %3.0f %%" % (d, v, rows[-1][2], rows[-1][3], store, pair, 100 * store / pair))
for name, keep in (
    ("stage 3 in both runs", lambda r: r[2] == 3 and r[3] == 3),
    ("stage 0 in both runs", lambda r: r[2] == 0 and r[3] == 0),
    ("a different stage in the two runs (the parent of a later district is lit by then)", lambda r: r[2] != r[3]),
):
    sel = [r for r in rows if keep(r)]
    share = [r[4] / r[5] for r in sel]
    print("%s: %d frames; store frame as a share of the pair frame: %.0f %% to %.0f %% (median %.0f %%); mean luminance of the store frames %.3f to %.3f" % (name, len(sel), 100 * min(share), 100 * max(share), 100 * statistics.median(share), min(r[4] for r in sel), max(r[4] for r in sel)))
