#!/usr/bin/env python3
"""R0/P0 truth gate: measures real defects on windowed capture PNGs, the only
place the owner's actual GPU output is visible (headless uses a dummy driver
that never shows this). FAIL thresholds match the ponytail order-pass spec:
magenta% > 1, black% > 85, or no HUD pixels detected in the top-left HUD band.

Magenta/purple corruption is detected by hue (HSV), not a fixed RGB corner:
the observed artifact ranges from pale lavender speckle through hot magenta,
and a pure-RGB "R and B both high" test misses the paler end of that range.
Hue band 260-345 degrees (purple -> magenta -> pink) is empty in this game's
actual night palette (amber lights, blue-grey ambient, red/green/amber HUD
bars) - verified against docs/stills/r0_scale1.png, the confirmed-clean
reference frame, which scores 0.00% on this same test.

Usage: python tools/qa_sim/visual_truth_gate.py <png> [<png> ...]
Exit 0 if every frame passes, 1 otherwise.
"""
import sys
import numpy as np
from PIL import Image

MAGENTA_FAIL_PCT = 1.0
BLACK_FAIL_PCT = 85.0
HUE_LOW, HUE_HIGH = 260.0, 345.0  # degrees: purple through magenta to pink
MIN_SAT, MIN_VAL = 0.25, 0.12     # ignore near-grey / near-black noise
# HUD bars (health/stamina/battery/noise/ability) live in the top-left corner
# in every 3D gameplay capture - see docs/stills/*district*.png.
HUD_BOX = (0, 0, 360, 220)


def _rgb_to_hsv(arr: np.ndarray) -> np.ndarray:
    """arr: (H,W,3) float32 in 0..1 -> (H,W,3) HSV, H in degrees."""
    r, g, b = arr[..., 0], arr[..., 1], arr[..., 2]
    maxc = np.max(arr, axis=-1)
    minc = np.min(arr, axis=-1)
    v = maxc
    delta = maxc - minc
    s = np.where(maxc > 0, delta / np.where(maxc == 0, 1, maxc), 0.0)
    with np.errstate(divide="ignore", invalid="ignore"):
        rc = np.where(delta > 0, (maxc - r) / np.where(delta == 0, 1, delta), 0.0)
        gc = np.where(delta > 0, (maxc - g) / np.where(delta == 0, 1, delta), 0.0)
        bc = np.where(delta > 0, (maxc - b) / np.where(delta == 0, 1, delta), 0.0)
    h = np.zeros_like(v)
    is_r = (maxc == r) & (delta > 0)
    is_g = (maxc == g) & (delta > 0)
    is_b = (maxc == b) & (delta > 0)
    h[is_r] = (bc - gc)[is_r]
    h[is_g] = 2.0 + (rc - bc)[is_g]
    h[is_b] = 4.0 + (gc - rc)[is_b]
    h = (h / 6.0) % 1.0
    return np.stack([h * 360.0, s, v], axis=-1)


def measure(path: str) -> dict:
    img = Image.open(path).convert("RGB")
    arr = np.asarray(img).astype(np.float32) / 255.0
    total = arr.shape[0] * arr.shape[1]

    hsv = _rgb_to_hsv(arr)
    hue, sat, val = hsv[..., 0], hsv[..., 1], hsv[..., 2]
    magenta_mask = (hue >= HUE_LOW) & (hue <= HUE_HIGH) & (sat >= MIN_SAT) & (val >= MIN_VAL)
    magenta_pct = 100.0 * float(np.count_nonzero(magenta_mask)) / total

    black_mask = (arr[..., 0] < 8 / 255.0) & (arr[..., 1] < 8 / 255.0) & (arr[..., 2] < 8 / 255.0)
    black_pct = 100.0 * float(np.count_nonzero(black_mask)) / total

    hud_crop = np.asarray(img.crop(HUD_BOX))
    hud_present = bool(hud_crop.size) and hud_crop.reshape(-1, 3).std(axis=0).sum() > 5.0

    return {"path": path, "magenta_pct": magenta_pct, "black_pct": black_pct, "hud_present": hud_present}


def check(path: str) -> tuple[bool, dict]:
    m = measure(path)
    ok = (m["magenta_pct"] <= MAGENTA_FAIL_PCT and
          m["black_pct"] <= BLACK_FAIL_PCT and
          m["hud_present"])
    return ok, m


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: visual_truth_gate.py <png> [<png> ...]")
        return 1
    all_ok = True
    for path in argv[1:]:
        ok, m = check(path)
        all_ok &= ok
        status = "PASS" if ok else "FAIL"
        print("%s magenta=%.2f%% black=%.2f%% hud=%s %s" % (
            status, m["magenta_pct"], m["black_pct"], m["hud_present"], path))
    return 0 if all_ok else 1


def _demo() -> None:
    """ponytail self-check: synthetic frames, no fixtures needed."""
    import os
    magenta_img = Image.new("RGB", (10, 10), (200, 20, 200))
    clean_img = Image.new("RGB", (10, 10), (40, 60, 90))  # night blue-grey, not magenta
    black_img = Image.new("RGB", (10, 10), (0, 0, 0))
    magenta_img.save("_tmp_magenta_demo.png")
    clean_img.save("_tmp_clean_demo.png")
    black_img.save("_tmp_black_demo.png")
    ok_m, m = check("_tmp_magenta_demo.png")
    ok_c, c = check("_tmp_clean_demo.png")
    ok_b, b = check("_tmp_black_demo.png")
    assert not ok_m and m["magenta_pct"] > 90.0, m
    assert c["magenta_pct"] == 0.0, c
    assert not ok_b and b["black_pct"] > 90.0, b
    for f in ("_tmp_magenta_demo.png", "_tmp_clean_demo.png", "_tmp_black_demo.png"):
        os.remove(f)
    print("demo OK")


if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == "--demo":
        _demo()
        sys.exit(0)
    sys.exit(main(sys.argv))
