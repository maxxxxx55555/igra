#!/usr/bin/env python3
"""The night sky of the game (assets/textures/sky/night_sky_panorama_4096x2048.png): the gradient of the old 2048 x 1024 panorama (dark zenith, a teal haze at the horizon) and a field of stars that are a pixel or two wide.
The old panorama had nine soft blobs and stars of 2 to 3 px at 2048 px for 360 degrees; the camera shows about 25 px a degree, so every star was a white dot of 10 px or more over the whole night view (the owner's v8 contract: remove the
persistent large white dots). Here the sky has twice the pixels, a star is 1 px (a few 2 px) with a Gaussian edge, most are dim, the brightest stops at 225 (no pure white), and nothing is a blob. Deterministic (seed 7).

usage: python tools/gen_night_sky.py [--demo]   (writes the panorama; --demo checks the numbers on a small one and writes nothing)
"""
import pathlib
import sys

import numpy as np
from PIL import Image

OUT = pathlib.Path(__file__).resolve().parents[1] / "assets" / "textures" / "sky" / "night_sky_panorama_4096x2048.png"
# row of the old 1024 px panorama -> the median colour of that row (the sky without its stars)
GRADIENT = [(0, (10, 14, 20)), (128, (8, 12, 17)), (256, (7, 11, 16)), (384, (7, 12, 16)), (512, (9, 16, 20)), (640, (12, 23, 28)),
            (768, (16, 32, 39)), (832, (19, 38, 45)), (896, (22, 43, 51)), (960, (24, 49, 58)), (1023, (27, 54, 64))]
TINTS = np.array([(1.0, 1.0, 1.0), (0.85, 0.92, 1.0), (1.0, 0.93, 0.82)])
PEAK_MAX = 225.0


def sky(width, height, stars, seed=7):
    rng = np.random.default_rng(seed)
    rows = np.linspace(0, 1023, height)
    grad = np.stack([np.interp(rows, [g[0] for g in GRADIENT], [g[1][c] for g in GRADIENT]) for c in range(3)], axis=1)
    img = np.repeat(grad[:, None, :], width, axis=1) + rng.normal(0.0, 0.7, (height, width, 1))  # a little noise keeps the dark gradient from banding
    ys = rng.uniform(0, 0.82 * height, stars)
    keep = rng.uniform(0, 1, stars) < 1.0 - ys / (0.82 * height) * 0.6  # thinner toward the haze
    xs = rng.uniform(0, width, stars)[keep]
    ys = ys[keep]
    peak = 35.0 + 190.0 * rng.uniform(0, 1, len(xs)) ** 4
    sigma = np.where(peak > 150.0, 0.95, 0.6)
    tint = TINTS[rng.integers(0, len(TINTS), len(xs))]
    for x, y, p, s, t in zip(xs, ys, peak, sigma, tint):
        x0, y0 = int(x), int(y)
        for dy in (-1, 0, 1, 2):
            for dx in (-1, 0, 1, 2):
                px, py = (x0 + dx) % width, y0 + dy
                if 0 <= py < height:
                    img[py, px] += p * np.exp(-((x0 + dx + 0.5 - x) ** 2 + (py + 0.5 - y) ** 2) / (2.0 * s * s)) * t
    return Image.fromarray(np.clip(img, 0, PEAK_MAX).astype(np.uint8), "RGB")


def demo():
    small = sky(512, 256, 400)
    a = np.asarray(small).astype(float)
    assert small.mode == "RGB" and small.size == (512, 256)
    assert a.max() <= PEAK_MAX, "no pure white"
    lum = a.mean(axis=2)
    window = np.lib.stride_tricks.sliding_window_view(lum, (15, 15)).mean(axis=(2, 3))
    assert window.max() < 70.0, "no blob: the mean of a 15 px window stays dark"
    assert (a.max(axis=2) > 120).sum() > 20, "there are stars"
    print("gen_night_sky demo OK (RGB, no pixel over %d, no blob, stars present)" % PEAK_MAX)


if __name__ == "__main__":
    if "--demo" in sys.argv:
        demo()
    else:
        sky(4096, 2048, 4500).save(OUT, compress_level=9)
        print("wrote", OUT)
