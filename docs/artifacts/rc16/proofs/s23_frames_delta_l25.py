# CORRECTION_LOG 252: which frames the lighting fix reached. Every frame of the sets re-shot by the fix chain against the same frame at a4acbb5 (read from the commit named by the second argument, where they are committed): the mean luminance of each and the mean absolute difference of the pixels.
# usage: python s23_frames_delta_l25.py <new hash> <commit that holds the old frames>   (the old frames were committed after their own head, in dc34dff: read them from 0752c9b)
import io
import pathlib
import re
import statistics
import subprocess
import sys

import numpy as np
from PIL import Image

ROOT = pathlib.Path("C:/Users/Maxsim/Desktop/TLS_Build/THE_LAST_STREETLIGHT")
NEW, REF = sys.argv[1], sys.argv[2]
OLD = "a4acbb5"


def git(*args):
    return subprocess.run(["git", *args], cwd=ROOT, capture_output=True).stdout


def old_names(folder):
    return git("ls-tree", "-r", "--name-only", REF, folder).decode("utf-8").splitlines()


def lum_of(img):
    a = np.asarray(img.convert("RGB"), dtype=float) / 255.0
    return a, float((a @ np.array([0.2126, 0.7152, 0.0722])).mean())


def compare(label, folder, pattern_old, pattern_new, key):
    olds = {key(n.rsplit("/", 1)[-1]): n for n in old_names(folder) if re.search(pattern_old, n)}
    rows = []
    for p in sorted((ROOT / folder).glob("*")):
        m = re.search(pattern_new, p.name)
        if not m or key(p.name) not in olds:
            continue
        a_old, l_old = lum_of(Image.open(io.BytesIO(git("show", REF + ":" + olds[key(p.name)]))))
        a_new, l_new = lum_of(Image.open(p))
        if a_old.shape != a_new.shape:
            continue
        rows.append((key(p.name), l_old, l_new, float(np.abs(a_old - a_new).mean())))
    print("== %s: %d frames compared" % (label, len(rows)))
    for r in rows:
        print("  %-34s luminance %.3f -> %.3f (%+.3f), mean absolute pixel difference %.4f" % (r[0], r[1], r[2], r[2] - r[1], r[3]))
    moved = [r for r in rows if abs(r[2] - r[1]) >= 0.01]
    print("  frames whose mean luminance moved by 0.01 or more: %d of %d%s" % (len(moved), len(rows), (": " + ", ".join(r[0] for r in moved)) if moved and len(moved) <= 30 else ""))
    print("  median mean absolute pixel difference: %.4f" % (statistics.median(r[3] for r in rows) if rows else 0.0))


compare("release frames (docs/stills/ultimate)", "docs/stills/ultimate", r"_after_%s_" % OLD, r"_after_%s_" % NEW, lambda n: n.split("_after_")[0])
compare("polish states (docs/stills/polish)", "docs/stills/polish", r"_after_%s_" % OLD, r"_after_%s_" % NEW, lambda n: n.split("_after_")[0])
compare("density, the dressing shown (docs/stills/density)", "docs/stills/density", r"_after_%s_" % OLD, r"_after_%s_" % NEW, lambda n: n.split("_after_")[0])
