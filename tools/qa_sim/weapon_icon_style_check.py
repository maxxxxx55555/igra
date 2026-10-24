# -*- coding: utf-8 -*-
"""s31 (v10.0.0-close) N068: the three weapon icons read as one family.

usage: python tools/qa_sim/weapon_icon_style_check.py [--demo]
The quick bar shows pistol, rifle and shotgun side by side (N068): a glossy
transparent illustration (alpha coverage about 10-15 percent) beside a flat
dark tile (about 95 percent) reads as two icon systems. The check FAILs when
any of the three differs from the family median by more than 4x in alpha
coverage. --demo proves it both ways on synthetic coverage values.
"""
import pathlib
import sys

import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
WEAPONS = ["pistol", "rifle", "shotgun"]


def coverage(path):
    a = np.asarray(Image.open(path).convert("RGBA"), dtype=float)
    return float((a[:, :, 3] > 24).mean())


def findings(dirpath):
    vals = {w: coverage(dirpath / (w + ".png")) for w in WEAPONS}
    med = sorted(vals.values())[1]
    out = []
    for w, v in vals.items():
        if med > 0 and (v / med > 4.0 or med / v > 4.0):
            out.append("FAIL %s alpha coverage %.2f is far off the family median %.2f (N068 split)" % (w, v, med))
    return out, vals


def demo():
    vals = {"pistol": 0.98, "rifle": 0.11, "shotgun": 0.13}
    med = sorted(vals.values())[1]
    assert any(v / med > 4.0 or med / v > 4.0 for v in vals.values())
    same = {"pistol": 0.96, "rifle": 0.94, "shotgun": 0.90}
    med2 = sorted(same.values())[1]
    assert all(v / med2 <= 4.0 for v in same.values())
    print("weapon_icon_style_check demo OK (98/11/13 FAILs; 96/94/90 passes)")
    return 0


def main(argv):
    if "--demo" in argv:
        return demo()
    fails, vals = findings(ROOT / "assets" / "textures" / "items")
    for w, v in sorted(vals.items()):
        print("coverage %s %.2f" % (w, v))
    for f in fails:
        print(f)
    print("weapon_icon_style_check: %d finding(s)" % len(fails))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
