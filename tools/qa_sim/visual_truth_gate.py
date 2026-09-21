#!/usr/bin/env python3
"""R0/P0/R2 truth gate: measures real defects on windowed capture PNGs, the
only place the owner's actual GPU output is visible (headless uses a dummy
driver that never shows this).

R2 hardening (docs/REDTEAM_CHALLENGE.md TG-SEE, arena finding): the original
version measured magenta over the WHOLE frame, so real corruption confined
to a smaller region could hide under a low percentage once averaged against
a large sky/floor area. Hardened per the arena's exact spec:
  - magenta ratio is measured on the WORLD band only (excludes the HUD strip
    top-left and the quickbar/ammo strip at the bottom), threshold tightened
    to 0.5% (was 1.0% over the whole frame).
  - a second detector catches colored-noise outliers that aren't hue-pure
    magenta: per-pixel saturation > 0.55 while the frame's own median
    saturation is < 0.2 (a mostly-drab night scene with scattered vivid
    dots), OR'd with the original hue-band test.
  - a reference-color-flood check: share of the world band within a small
    RGB distance of the project's clear color. The arena spec that proposed
    this said it only means something on a FULL-stage district capture, and
    testing it against this project's own committed evidence frames proved
    that caveat correct the hard way: every DARK-stage "street" scenario
    capture (R0/R1's evidence, all early-game unlit districts) scored
    88-90% clear-color flood despite being confirmed-clean frames, because
    a DARK district is legitimately mostly near-black sky and ambient. Per
    the same evidence, this metric is REPORTED on every run (trend data)
    but is NOT a blocking FAIL condition - blocking on it would fail every
    correct dark-district screenshot this project has, which is worse than
    not checking it at all. Revisit as blocking once frames carry stage
    metadata (district stage isn't recoverable from a bare PNG).
  - prints REBACK_UNVERIFIED next to every verdict: this gate reads
    get_texture().get_image() (an in-engine readback), not an OS-level
    desktop screenshot (confirmed unavailable in this environment, see
    docs/RUN_STATE.md's G0 finding) - until a human does a live eye-check
    against the saved PNG, a clean gate result is not proof of a clean
    on-screen frame, only of a clean readback of it.

Usage: python tools/qa_sim/visual_truth_gate.py <png> [<png> ...]
Exit 0 if every frame passes, 1 otherwise.
"""
import sys
import numpy as np
from PIL import Image

MAGENTA_FAIL_PCT = 0.5
BLACK_FAIL_PCT = 85.0
CLEAR_COLOR_FLOOD_PCT = 2.0
HUE_LOW, HUE_HIGH = 260.0, 345.0  # degrees: purple through magenta to pink
MIN_SAT, MIN_VAL = 0.25, 0.12     # ignore near-grey / near-black noise
OUTLIER_SAT_MIN = 0.55
OUTLIER_MEDIAN_SAT_MAX = 0.20
CLEAR_COLOR = np.array([0.03, 0.03, 0.05])  # project.godot environment/defaults/default_clear_color
CLEAR_COLOR_DELTA = 0.12

# Bands as a fraction of frame height, per docs/REDTEAM_CHALLENGE.md TG-SEE:
# HUD chrome lives in the top strip, the world in the middle, quickbar/ammo
# at the bottom - see scenes/ui/hud_3d.tscn for the real layout this mirrors.
HUD_BAND = (0.0, 0.18)
WORLD_BAND = (0.30, 0.85)
QUICKBAR_BAND = (0.85, 1.0)
HUD_BOX = (0, 0, 360, 220)  # kept for the existing HUD-presence check


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


def _band(arr: np.ndarray, frac: tuple[float, float]) -> np.ndarray:
    h = arr.shape[0]
    y0, y1 = int(h * frac[0]), int(h * frac[1])
    return arr[y0:y1, :, :]


def measure(path: str) -> dict:
    img = Image.open(path).convert("RGB")
    arr = np.asarray(img).astype(np.float32) / 255.0
    world = _band(arr, WORLD_BAND)
    world_total = world.shape[0] * world.shape[1]

    hsv = _rgb_to_hsv(world)
    hue, sat, val = hsv[..., 0], hsv[..., 1], hsv[..., 2]
    magenta_mask = (hue >= HUE_LOW) & (hue <= HUE_HIGH) & (sat >= MIN_SAT) & (val >= MIN_VAL)
    median_sat = float(np.median(sat))
    outlier_mask = (sat > OUTLIER_SAT_MIN) & (median_sat < OUTLIER_MEDIAN_SAT_MAX)
    combined_mask = magenta_mask | outlier_mask
    magenta_pct = 100.0 * float(np.count_nonzero(combined_mask)) / world_total

    black_mask = (arr[..., 0] < 8 / 255.0) & (arr[..., 1] < 8 / 255.0) & (arr[..., 2] < 8 / 255.0)
    black_pct = 100.0 * float(np.count_nonzero(black_mask)) / (arr.shape[0] * arr.shape[1])

    clear_dist = np.linalg.norm(world - CLEAR_COLOR, axis=-1)
    clear_flood_pct = 100.0 * float(np.count_nonzero(clear_dist < CLEAR_COLOR_DELTA)) / world_total

    hud_crop = np.asarray(img.crop(HUD_BOX))
    hud_present = bool(hud_crop.size) and hud_crop.reshape(-1, 3).std(axis=0).sum() > 5.0

    return {
        "path": path, "magenta_pct": magenta_pct, "black_pct": black_pct,
        "clear_flood_pct": clear_flood_pct, "hud_present": hud_present,
    }


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
        print("%s magenta(world)=%.2f%% black=%.2f%% clear-flood(world)=%.2f%% hud=%s REBACK_UNVERIFIED %s" % (
            status, m["magenta_pct"], m["black_pct"], m["clear_flood_pct"], m["hud_present"], path))
    return 0 if all_ok else 1


def _demo() -> None:
    """ponytail self-check: synthetic frames, no fixtures needed."""
    import os
    # 1x300 tall column so the world band (30-85%) samples distinct content
    # from the HUD/quickbar bands - a real screenshot's aspect, simplified.
    magenta_img = Image.new("RGB", (10, 300))
    for y in range(300):
        frac = y / 300.0
        magenta_img.putpixel((0, y), (200, 20, 200) if 0.30 <= frac < 0.85 else (40, 60, 90))
    for x in range(1, 10):
        for y in range(300):
            magenta_img.putpixel((x, y), magenta_img.getpixel((0, y)))
    clean_img = Image.new("RGB", (10, 300), (40, 60, 90))
    black_img = Image.new("RGB", (10, 300), (0, 0, 0))
    flood_img = Image.new("RGB", (10, 300), (8, 8, 13))  # near default_clear_color everywhere
    for name, im in [("_tmp_magenta_demo.png", magenta_img), ("_tmp_clean_demo.png", clean_img),
                      ("_tmp_black_demo.png", black_img), ("_tmp_flood_demo.png", flood_img)]:
        im.save(name)
    ok_m, m = check("_tmp_magenta_demo.png")
    ok_c, c = check("_tmp_clean_demo.png")
    ok_b, b = check("_tmp_black_demo.png")
    _, f = check("_tmp_flood_demo.png")  # clear-flood is reported, not blocking - see check()'s comment
    assert not ok_m and m["magenta_pct"] > 90.0, m
    assert c["magenta_pct"] == 0.0, c
    assert not ok_b and b["black_pct"] > 90.0, b
    assert f["clear_flood_pct"] > 90.0, f
    for fn in ("_tmp_magenta_demo.png", "_tmp_clean_demo.png", "_tmp_black_demo.png", "_tmp_flood_demo.png"):
        os.remove(fn)
    print("demo OK")


if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == "--demo":
        _demo()
        sys.exit(0)
    sys.exit(main(sys.argv))
