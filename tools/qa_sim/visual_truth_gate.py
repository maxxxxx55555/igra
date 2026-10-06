#!/usr/bin/env python3
"""R0/P0/R2/R3 truth gate: measures real defects on windowed capture PNGs, the
only place the owner's actual GPU output is visible (headless uses a dummy
driver that never shows this).

R2 hardening (docs/REDTEAM_CHALLENGE.md TG-SEE, arena finding): the original
version measured magenta over the WHOLE frame, so real corruption confined
to a smaller region could hide under a low percentage once averaged against
a large sky/floor area. Hardened per the arena's exact spec:
  - the ratios are measured on the WORLD band only (excludes the HUD strip
    top-left and the quickbar/ammo strip at the bottom).
  - a reference-color-flood check: share of the world band within a small
    RGB distance of the project's clear color. It is REPORTED on every run
    (trend data) but is NOT a blocking condition: every DARK-stage "street"
    frame this project has scores 60-90% of it, correctly (a dark district
    is mostly near-black sky and ambient).
  - prints REBACK_UNVERIFIED next to every verdict: this gate reads
    get_texture().get_image() (an in-engine readback), not an OS-level
    desktop screenshot - until a human reads the saved frame, a clean gate
    result is not proof of a clean on-screen frame, only of a clean readback.

R3 adjudication (rc15, measured on the committed and captured frames, the four
real corruption frames in docs/stills/evidence included). Two of the original
rules fired on canon:
  - the saturation-outlier rule (sat > 0.55 on a frame whose median sat < 0.2)
    flagged the lamps, lit windows and moonlit sidewalks of every dark street
    (0.5-0.7% of the world band, hue 20-80 and 200-260 degrees): replaced by
    VIVID, pixels of nearly full saturation AND brightness, a colour the palette
    never produces (canon <= 0.005% of the band, the four corruption frames
    0.29-3.37%). The one canon effect that reaches it is the death burst of
    scenes/vfx/vfx_blood.tscn (28 dark red particles, 0.55/0.06/0.06, the PEGI 16
    blood of docs/PRODUCTION_BIBLE.md section 6): a final combat frame caught it
    at its peak and measured 0.062%. The threshold sits between that and the
    lightest corruption frame (0.294%), at 0.13%: 2.1x over the canon peak, 2.3x
    under the corruption minimum.
  - the magenta hue band (260-345 degrees) counted the ember damage vignette
    over a night scene: ember #b4452f blended into the blue-black ambient lands
    on hue 290-340 at value 0.12-0.34 (6.1% of the band at the worst, a heavy
    damage frame of the play-through). The band now counts only pixels of value
    >= BRIGHT_MIN_VAL (0.35: the corruption frames have a median value of
    0.24-0.41 and a 90th percentile of 0.31-0.62, canon vignettes a 99th
    percentile <= 0.38) as MAGENTA, and the darker ones as a DIM wash with its
    own, area-based threshold (10%: canon max 6.1%, the dim corruption frame
    15.1%).
Thresholds therefore: magenta (bright, hue band) <= 0.5%, dim wash <= 10%, vivid
<= 0.13%, black <= 40%, HUD present. `--demo` runs the mutation self-test on
synthetic frames: every defect pattern must fail, every canon pattern must pass.

Usage: python tools/qa_sim/visual_truth_gate.py <png> [<png> ...]
       python tools/qa_sim/visual_truth_gate.py --demo
Exit 0 if every frame passes, 1 otherwise.
"""
import sys
import numpy as np
from PIL import Image

MAGENTA_FAIL_PCT = 0.5
DIM_FAIL_PCT = 10.0
VIVID_FAIL_PCT = 0.13
# SLOP_REPORT item (§2, under-tight): was 85.0, nearly vacuous - a half-black
# corrupted frame would still pass. Real committed evidence frames
# (docs/stills/evidence/r0_after_*.png) measure 7.6-9.8% black on confirmed-
# clean captures; 40.0 keeps a 4-5x margin over that while actually catching
# a frame gone substantially black.
BLACK_FAIL_PCT = 40.0
CLEAR_COLOR_FLOOD_PCT = 2.0
HUE_LOW, HUE_HIGH = 260.0, 345.0  # degrees: purple through magenta to pink
MIN_SAT, MIN_VAL = 0.25, 0.12     # ignore near-grey / near-black noise
BRIGHT_MIN_VAL = 0.35             # below this a magenta pixel is shade (the damage vignette), not corruption
VIVID_SAT, VIVID_VAL = 0.85, 0.50
CLEAR_COLOR = np.array([0.03, 0.03, 0.05])  # project.godot environment/defaults/default_clear_color
CLEAR_COLOR_DELTA = 0.12

# Bands as a fraction of frame height, per docs/REDTEAM_CHALLENGE.md TG-SEE:
# HUD chrome lives in the top strip, the world in the middle, quickbar/ammo
# at the bottom - see scenes/ui/hud_3d.tscn for the real layout this mirrors.
HUD_BAND = (0.0, 0.18)
WORLD_BAND = (0.30, 0.85)
QUICKBAR_BAND = (0.85, 1.0)
HUD_BOX = (0, 0, 360, 220)  # kept for the existing HUD-presence check


def _band(arr: np.ndarray, frac: tuple[float, float]) -> np.ndarray:
    h = arr.shape[0]
    y0, y1 = int(h * frac[0]), int(h * frac[1])
    return arr[y0:y1, :, :]


def measure(path: str) -> dict:
    img = Image.open(path).convert("RGB")
    arr = np.asarray(img).astype(np.float32) / 255.0
    world = _band(arr, WORLD_BAND)
    world_total = world.shape[0] * world.shape[1]

    # PIL's own HSV conversion (8-bit per channel: H,S,V all 0..255) instead
    # of a hand-rolled per-pixel converter - PIL is already imported for
    # image I/O, and ~1.4deg/step quantization is fine for an 85deg-wide
    # magenta band.
    hsv_full = np.asarray(img.convert("HSV"), dtype=np.float32)
    hsv_full = np.stack([hsv_full[..., 0] * 360.0 / 255.0, hsv_full[..., 1] / 255.0, hsv_full[..., 2] / 255.0], axis=-1)
    hsv = _band(hsv_full, WORLD_BAND)
    hue, sat, val = hsv[..., 0], hsv[..., 1], hsv[..., 2]
    in_band = (hue >= HUE_LOW) & (hue <= HUE_HIGH) & (sat >= MIN_SAT) & (val >= MIN_VAL)
    magenta_pct = 100.0 * float(np.count_nonzero(in_band & (val >= BRIGHT_MIN_VAL))) / world_total
    dim_pct = 100.0 * float(np.count_nonzero(in_band & (val < BRIGHT_MIN_VAL))) / world_total
    vivid_pct = 100.0 * float(np.count_nonzero((sat >= VIVID_SAT) & (val >= VIVID_VAL))) / world_total

    black_mask = (arr[..., 0] < 8 / 255.0) & (arr[..., 1] < 8 / 255.0) & (arr[..., 2] < 8 / 255.0)
    black_pct = 100.0 * float(np.count_nonzero(black_mask)) / (arr.shape[0] * arr.shape[1])

    clear_dist = np.linalg.norm(world - CLEAR_COLOR, axis=-1)
    clear_flood_pct = 100.0 * float(np.count_nonzero(clear_dist < CLEAR_COLOR_DELTA)) / world_total

    hud_crop = np.asarray(img.crop(HUD_BOX))
    hud_present = bool(hud_crop.size) and hud_crop.reshape(-1, 3).std(axis=0).sum() > 5.0

    return {
        "path": path, "magenta_pct": magenta_pct, "dim_pct": dim_pct, "vivid_pct": vivid_pct,
        "black_pct": black_pct, "clear_flood_pct": clear_flood_pct, "hud_present": hud_present,
    }


def check(path: str) -> tuple[bool, dict]:
    m = measure(path)
    ok = (m["magenta_pct"] <= MAGENTA_FAIL_PCT and
          m["dim_pct"] <= DIM_FAIL_PCT and
          m["vivid_pct"] <= VIVID_FAIL_PCT and
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
        print("%s magenta(world)=%.2f%% dim=%.2f%% vivid=%.3f%% black=%.2f%% clear-flood(world)=%.2f%% hud=%s REBACK_UNVERIFIED %s" % (
            status, m["magenta_pct"], m["dim_pct"], m["vivid_pct"], m["black_pct"], m["clear_flood_pct"], m["hud_present"], path))
    return 0 if all_ok else 1


def _frame(patch=None, base=(40, 60, 90), size=(100, 300)) -> Image.Image:
    """A 100x300 frame (the world band is rows 90-255): a flat base colour with one patch painted into the world band,
    patch = (x0, x1, y0, y1, colour) as fractions of the width and of the world band."""
    im = Image.new("RGB", size, base)
    px = im.load()
    h = size[1]
    y_world0, y_world1 = int(h * WORLD_BAND[0]), int(h * WORLD_BAND[1])
    if patch:
        x0, x1, f0, f1, colour = patch
        for x in range(int(size[0] * x0), int(size[0] * x1)):
            for y in range(int(y_world0 + (y_world1 - y_world0) * f0), int(y_world0 + (y_world1 - y_world0) * f1)):
                px[x, y] = colour
    return im


def _demo() -> None:
    """ponytail self-check: synthetic frames, no fixtures needed. Defect patterns must fail, canon patterns pass."""
    import os
    import random
    cases = []  # (name, image, must_pass)
    cases.append(("clean", _frame(), True))
    cases.append(("black", Image.new("RGB", (100, 300), (0, 0, 0)), False))
    half_black = _frame()
    for x in range(100):
        for y in range(150, 300):
            half_black.putpixel((x, y), (0, 0, 0))
    cases.append(("half_black_frame", half_black, False))  # 50% black, everything else clean: only the black rule can fail it
    cases.append(("bright_magenta_patch", _frame((0.0, 1.0, 0.0, 1.0, (200, 20, 200))), False))
    cases.append(("small_bright_magenta_patch", _frame((0.0, 0.1, 0.0, 1.0, (200, 20, 200))), False))  # 10% of the world band
    cases.append(("bright_purple_patch", _frame((0.0, 0.2, 0.0, 1.0, (150, 60, 200))), False))
    cases.append(("bright_pink_patch", _frame((0.0, 0.2, 0.0, 1.0, (230, 40, 140))), False))             # hue 330, the upper half of the band
    cases.append(("dim_magenta_wash_20pct", _frame((0.0, 0.2, 0.0, 1.0, (60, 25, 60))), False))
    cases.append(("dim_wash_vignette_5pct", _frame((0.0, 0.05, 0.0, 1.0, (60, 25, 45))), True))   # the damage vignette over a night scene
    cases.append(("ember_vignette_30pct", _frame((0.0, 0.3, 0.0, 1.0, (70, 28, 24))), True))      # ember hue 5 degrees, dark: not in the band
    cases.append(("brass_lamp_blob", _frame((0.4, 0.6, 0.3, 0.5, (201, 162, 74))), True))          # canon brass #c9a24a, 4% of the band
    cases.append(("lit_window_row", _frame((0.1, 0.9, 0.4, 0.45, (230, 200, 90))), True))          # saturated warm light, sat 0.61
    cases.append(("moonlit_sidewalk", _frame((0.0, 1.0, 0.7, 0.8, (170, 190, 235))), True))
    cases.append(("blood_burst_peak", _frame((0.0, 0.13, 0.5, 0.5061, (140, 15, 15))), True))          # 13 of 16500 px (0.079%) of the death burst's red 0.55/0.06/0.06, above the 0.062% measured peak
    noise = Image.new("RGB", (100, 300), (40, 60, 90))
    rng = random.Random(7)
    npx = noise.load()
    y_world0, y_world1 = int(300 * WORLD_BAND[0]), int(300 * WORLD_BAND[1])
    for _ in range(40):  # 40 of 16500 world pixels: vivid primaries scattered over the band
        npx[rng.randrange(100), rng.randrange(y_world0, y_world1)] = rng.choice([(255, 0, 0), (0, 255, 0), (0, 0, 255), (0, 255, 255), (255, 255, 0)])
    cases.append(("scattered_vivid_noise", noise, False))
    for name, im, must_pass in cases:
        im.save("_tmp_gate_demo.png")
        ok, m = check("_tmp_gate_demo.png")
        assert ok == must_pass, (name, ok, must_pass, {k: m[k] for k in ("magenta_pct", "dim_pct", "vivid_pct", "black_pct", "hud_present")})
    flood = Image.new("RGB", (100, 300), (8, 8, 13))  # near default_clear_color everywhere
    flood.save("_tmp_gate_demo.png")
    _, f = check("_tmp_gate_demo.png")  # clear-flood is reported, not blocking
    assert f["clear_flood_pct"] > 90.0, f
    os.remove("_tmp_gate_demo.png")
    print("demo OK (%d patterns)" % (len(cases) + 1))


if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == "--demo":
        _demo()
        sys.exit(0)
    sys.exit(main(sys.argv))
