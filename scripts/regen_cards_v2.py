#!/usr/bin/env python3
"""
regen_cards_v2.py — deterministic color-grade pipeline for district card art.

Grades raw district photographs (1024x1536, 2:3 portrait) into the shipped
card visual language by building a per-channel color-grade LUT via
histogram matching against the district's reference keeper card, then
clamping and applying seeded film grain.

Spec: docs/CARD_ART_BRIEF.md (sections 2, 6). Replaces scripts/regen_cards.py
(that script is broken and unreferenced — do not restore it, see
docs/KNOWN_ISSUES.md).

Pipeline per raw image:
  1. dimension check (1024x1536 exact unless --allow-other-dims)
  2. histogram-matching color grade:
       for each channel, LUT[v] = the reference-card value whose CDF mass
       equals the source CDF mass at v (linear interpolation on the CDF)
     => a 3x256 "color-grade LUT" derived deterministically from the
     reference; the reference's 92% center region is used so the 4px
     accent border does not skew the target histogram
  3. clamp texels to [16, 240] (card family convention)
  4. deterministic film grain (seeded; --grain 0 disables)
  5. validation against the brief's acceptance thresholds; JSON report

Determinism: no randomness outside the fixed grain seed, no timestamps in
the PNG output. Identical inputs => byte-identical outputs.

Usage (repo root):
  .venv/bin/python scripts/regen_cards_v2.py --raw /handoff/district_park.png
  .venv/bin/python scripts/regen_cards_v2.py --raw-dir /handoff/raw/ \
      --report /handoff/grade_report.json --emit-512 /tmp/cards512

Dependencies: pillow, numpy (python3 -m venv .venv && .venv/bin/pip install
pillow numpy). Nothing else.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

try:
    import numpy as np
    from PIL import Image
except ImportError as exc:  # pragma: no cover
    sys.exit(
        f"regen_cards_v2.py needs pillow+numpy ({exc}). "
        "Create a venv: python3 -m venv .venv && .venv/bin/pip install pillow numpy"
    )

REPO_ROOT = Path(__file__).resolve().parent.parent

# Canonical district ids (data/districts/*.tres), keeper mapping per
# docs/CARD_ART_BRIEF.md section 6, and accent hexes from
# scripts/world/district_themes.gd via docs/VISUAL_AUDIO_SPEC.md section 1.
DISTRICTS: dict[str, str] = {
    # district -> keeper card (histogram reference for the new raw photos)
    "suburbs": "suburbs",
    "residential": "residential",
    "industrial": "industrial",
    "power_station": "power_station",
    "park": "suburbs",
    "school": "residential",
    "hospital": "residential",
    "gas_station": "residential",
    "police": "residential",
    "warehouses": "industrial",
    "substation": "power_station",
}

ACCENTS: dict[str, str] = {
    "suburbs": "#f4a35d",
    "residential": "#f4a35d",
    "park": "#f4e35d",
    "school": "#f4c95d",
    "hospital": "#5dc8f4",
    "gas_station": "#e85d3a",
    "police": "#5d5dc8",
    "warehouses": "#e85d3a",
    "industrial": "#e85d3a",
    "substation": "#f4f45d",
    "power_station": "#f4f45d",
}

# Hue-family bands in degrees (docs/CARD_ART_BRIEF.md section 2.5/6.1).
WARM_BAND = (25.0, 52.0)
COOL_BAND = (180.0, 235.0)
ACCENT_TOL = 14.0

# park is canonically green-based ("the city's one living thing left",
# sky #0a110a/#12180f, VISUAL_AUDIO_SPEC section 1) — its green-black base
# (hue ~90-150, sat up to ~40%) is allowed where the other ten districts
# ban green entirely.
EXTRA_HUE_BANDS: dict[str, tuple[tuple[float, float], ...]] = {
    "park": ((70.0, 160.0),),
}


def sat_thresholds(district: str) -> dict[str, float]:
    t = {"median_sat": T_MAX_MEDIAN_SAT, "p99_sat": T_MAX_P99_SAT,
         "share_sat40": T_MAX_SHARE_SAT40}
    if district == "park":
        t["median_sat"] = 0.35
        t["share_sat40"] = 0.30
    return t

MASTER_W, MASTER_H = 1024, 1536
CLAMP_MIN, CLAMP_MAX = 16, 240

# Acceptance thresholds (measured against the 4 keeper cards; brief 6.1).
T_MAX_MEDIAN_SAT = 0.28
T_MAX_P99_SAT = 0.55
T_MAX_SHARE_SAT40 = 0.12
T_MIN_HUE_FAM_SHARE = 0.85
T_MIN_AHASH_HAMMING = 8      # nearest cross-cluster keeper pair is 9
T_MIN_MAD_32 = 12.0          # intra-cluster max is 6.2; cross-cluster is 16.1
T_MIN_BAND_STD = 20.0


# --------------------------------------------------------------------------
# reference loading
# --------------------------------------------------------------------------

def reference_card_path(district: str, refs_dir: Path | None, overrides: dict[str, Path]) -> Path:
    if district in overrides:
        return overrides[district]
    keeper = DISTRICTS[district]
    p = (refs_dir or REPO_ROOT / "assets" / "textures" / "cards") / f"card_{keeper}_512.png"
    if not p.exists():
        sys.exit(f"reference card missing for {district}: {p} (pass --ref-card {district}=<path>)")
    return p


def load_reference(path: Path) -> np.ndarray:
    """Load a reference card and return its 92% center region (border excluded)."""
    im = Image.open(path).convert("RGB")
    arr = np.asarray(im, dtype=np.float64)
    h, w, _ = arr.shape
    m = int(0.04 * min(h, w))  # >= 4px accent border + margin
    return arr[m:h - m, m:w - m]


# --------------------------------------------------------------------------
# histogram matching -> color-grade LUT
# --------------------------------------------------------------------------

def cdf_lut(src: np.ndarray, ref: np.ndarray) -> np.ndarray:
    """
    Per-channel 256-entry LUT mapping the source histogram onto the reference
    histogram (classical histogram matching via CDF interpolation).
    Returns array of shape (3, 256), float64, values in [0, 255].
    """
    luts = np.zeros((3, 256), dtype=np.float64)
    for c in range(3):
        s, r = src[..., c], ref[..., c]
        s_hist = np.bincount(s.astype(np.uint8).ravel(), minlength=256).astype(np.float64)
        r_hist = np.bincount(r.astype(np.uint8).ravel(), minlength=256).astype(np.float64)
        s_cdf = s_hist.cumsum()
        r_cdf = r_hist.cumsum()
        s_cdf /= max(s_cdf[-1], 1.0)
        r_cdf /= max(r_cdf[-1], 1.0)
        # for each source value v: find the reference value t with r_cdf[t] = s_cdf[v]
        lut = np.interp(s_cdf, r_cdf, np.arange(256))
        luts[c] = lut
    return luts


def apply_lut(arr: np.ndarray, luts: np.ndarray) -> np.ndarray:
    out = np.empty_like(arr)
    for c in range(3):
        out[..., c] = luts[c][np.clip(arr[..., c], 0, 255).astype(np.uint8)]
    return out


def stable_seed(base: int, name: str) -> int:
    """Deterministic per-district seed (hash() is salted per-process: never use it)."""
    import zlib
    return (base * 1_000_003 + zlib.crc32(name.encode("utf-8"))) % (2**32)


def hsv_to_rgb(h, s, v):
    """h in degrees [0,360), s/v in [0,1]; returns float RGB in [0,1]."""
    h = (h % 360.0) / 60.0
    i = np.floor(h).astype(np.int64) % 6
    f = h - np.floor(h)
    p = v * (1.0 - s)
    q = v * (1.0 - s * f)
    t = v * (1.0 - s * (1.0 - f))
    # per-element sector lookup (np.take with axis=None ravels: wrong for 2D)
    i2 = i[..., None]
    r = np.take_along_axis(np.stack([v, q, p, p, t, v], axis=-1), i2, axis=-1)[..., 0]
    g = np.take_along_axis(np.stack([t, v, v, q, p, p], axis=-1), i2, axis=-1)[..., 0]
    b = np.take_along_axis(np.stack([p, p, t, v, v, q], axis=-1), i2, axis=-1)[..., 0]
    return r, g, b


def hue_family_projection(arr: np.ndarray, district: str):
    """
    Palette lock (hue axis): rotate out-of-band saturated hues toward the
    nearest allowed hue (band edge or district accent), capped at 60 degrees.

    Same class of operation as the [16, 240] luminance clamp, which pins the
    value axis; this pins the hue axis to the families allowed by the brief
    (warm brass, cool blue-grey, accent, park green base). The rotation cap
    means grossly off-family input (e.g. magenta ~300 degrees, >60 degrees
    from every allowed hue) stays out-of-band and still fails validation —
    the check remains a real gate, not a formality.
    """
    # rgb_to_hsv_arr normalizes by 255 internally — pass 0-255 values
    hue, sat = rgb_to_hsv_arr(arr)
    v = (arr / 255.0).max(axis=2)
    ar, ag, ab = (int(ACCENTS[district][i:i + 2], 16) for i in (1, 3, 5))
    ahue, asat = rgb_to_hsv_arr(np.array([[[ar, ag, ab]]], dtype=np.float64))
    ahue, asat = float(ahue[0, 0]), float(asat[0, 0])

    h = hue
    bands = [WARM_BAND, COOL_BAND] + list(EXTRA_HUE_BANDS.get(district, ()))

    def circ_dist(x, y):
        return np.minimum(np.abs(x - y), 360.0 - np.abs(x - y))

    in_band = np.zeros_like(h, dtype=bool)
    for lo, hi in bands:
        in_band |= (h >= lo) & (h <= hi)
    if asat > 0.05:
        in_band |= circ_dist(h, ahue) <= ACCENT_TOL
    sel = (sat >= 0.18) & (~in_band)
    if not sel.any():
        return arr

    # nearest allowed hue (band edges + accent) per pixel
    cands = [e for lo, hi in bands for e in (lo, hi)]
    if asat > 0.05:
        cands.append(ahue)
    best_d = np.full_like(h, np.inf)
    target = None
    for c in cands:
        dc = circ_dist(h, c)
        better = dc < best_d
        best_d = np.where(better, dc, best_d)
        target = c if target is None else np.where(better, c, target)

    rot = sel & (best_d <= 60.0)
    if not rot.any():
        return arr
    delta = np.where(rot, (target - h + 180.0) % 360.0 - 180.0, 0.0)
    h_new = np.where(rot, h + delta, h)
    r, g, b = hsv_to_rgb(h_new, sat, v)
    out = np.stack([r, g, b], axis=2) * 255.0
    return np.clip(out, 0.0, 255.0)


# Filmic saturation rolloff: generated art overshoots highlight saturation
# (STYLE_GUIDE 4.1 documents the same class of AI-overshoot correction for
# lit twins: rescale, then clamp, in that order). A soft-knee compression
# above ROLLOFF_KNEE pulls hot highlight saturation toward ROLLOFF_MAX,
# uniformly for every district — it never touches hue, only chroma amount.
ROLLOFF_KNEE = 0.30
ROLLOFF_MAX = 0.48


def saturation_rolloff(arr: np.ndarray) -> np.ndarray:
    """Compress saturation above ROLLOFF_KNEE toward ROLLOFF_MAX (hue-preserving)."""
    a = arr / 255.0
    mx = a.max(axis=2, keepdims=True)
    mn = a.min(axis=2, keepdims=True)
    d = mx - mn
    sat = np.where(mx > 1e-6, d / np.maximum(mx, 1e-6), 0.0)
    s = sat[..., 0]
    over = s > ROLLOFF_KNEE
    if not over.any():
        return arr
    span = ROLLOFF_MAX - ROLLOFF_KNEE
    s_new = s.copy()
    s_new[over] = ROLLOFF_KNEE + span * (1.0 - np.exp(-(s[over] - ROLLOFF_KNEE) / span))
    # rescale chroma around the neutral axis by the sat ratio (hue-preserving)
    ratio = np.ones_like(s)
    ratio[over] = s_new[over] / np.maximum(s[over], 1e-6)
    grey = mx * 0 + (0.2126 * a[..., 0:1] + 0.7152 * a[..., 1:2] + 0.0722 * a[..., 2:3])
    neutral = np.broadcast_to(grey, a.shape)
    out = neutral + (a - neutral) * ratio[..., None]
    return np.clip(out, 0.0, 1.0) * 255.0


def add_grain(arr: np.ndarray, amplitude: float, seed: int) -> np.ndarray:
    """Deterministic zero-mean luminance-coupled film grain."""
    if amplitude <= 0:
        return arr
    rng = np.random.default_rng(seed)
    h, w, _ = arr.shape
    g = rng.standard_normal((h, w, 1), dtype=np.float64)
    # grain amplitude scales slightly with local darkness (filmic)
    lum = 0.2126 * arr[..., 0] + 0.7152 * arr[..., 1] + 0.0722 * arr[..., 2]
    dark = np.clip((255.0 - lum) / 255.0, 0.0, 1.0)
    noise = g * (amplitude * 255.0) * (0.5 + 0.5 * dark)[..., None]
    return arr + noise


# --------------------------------------------------------------------------
# metrics
# --------------------------------------------------------------------------

def rgb_to_hsv_arr(arr: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    a = arr / 255.0
    mx = a.max(axis=2)
    mn = a.min(axis=2)
    d = mx - mn
    sat = np.where(mx > 0, d / np.maximum(mx, 1e-6), 0.0)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    hue = np.zeros_like(mx)
    m = d > 1e-6
    idx = m & (mx == r)
    hue[idx] = (60.0 * ((g[idx] - b[idx]) / d[idx]) + 360.0) % 360.0
    idx = m & (mx == g) & ~((mx == r))
    hue[idx] = (60.0 * ((b[idx] - r[idx]) / d[idx]) + 120.0) % 360.0
    idx = m & (mx == b) & ~((mx == r)) & ~((mx == g))
    hue[idx] = (60.0 * ((r[idx] - g[idx]) / d[idx]) + 240.0) % 360.0
    return hue, sat


def hue_family_share(hue: np.ndarray, sat: np.ndarray, accent_hex: str,
                     district: str = "") -> float:
    """Share of saturated pixels inside the allowed hue bands (brief 6.1)."""
    sel = sat >= 0.18
    if not sel.any():
        return 1.0
    h = hue[sel]
    ok = (
        ((h >= WARM_BAND[0]) & (h <= WARM_BAND[1]))
        | ((h >= COOL_BAND[0]) & (h <= COOL_BAND[1]))
    )
    for lo, hi in EXTRA_HUE_BANDS.get(district, ()):
        ok = ok | ((h >= lo) & (h <= hi))
    ar, ag, ab = (int(accent_hex[i:i + 2], 16) for i in (1, 3, 5))
    ahue, asat = rgb_to_hsv_arr(np.array([[[ar, ag, ab]]], dtype=np.float64))
    ahue, asat = float(ahue[0, 0]), float(asat[0, 0])
    if asat > 0.05:
        dh = np.minimum(np.abs(h - ahue), 360.0 - np.abs(h - ahue))
        ok = ok | (dh <= ACCENT_TOL)
    return float(ok.mean())


def ahash(arr: np.ndarray) -> np.ndarray:
    im = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8)).convert("L").resize((8, 8))
    a = np.asarray(im, dtype=np.float64)
    return a > a.mean()


def hamming(a: np.ndarray, b: np.ndarray) -> int:
    return int((a != b).sum())


def mad32(arr: np.ndarray) -> np.ndarray:
    im = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8)).convert("L").resize((32, 32))
    return np.asarray(im, dtype=np.float64)


def band_std(arr: np.ndarray) -> float:
    """Luminance std of the on-screen 230x84-aspect center band."""
    h, w, _ = arr.shape
    lum = 0.2126 * arr[..., 0] + 0.7152 * arr[..., 1] + 0.0722 * arr[..., 2]
    band_h = int(round(w * 84 / 230))
    band_h = min(band_h, h)
    y0 = (h - band_h) // 2
    return float(lum[y0:y0 + band_h, :].std())


# --------------------------------------------------------------------------
# per-district processing
# --------------------------------------------------------------------------

def process(district: str, raw_path: Path, out_dir: Path,
            grain: float, seed: int, refs_dir: Path | None,
            overrides: dict[str, Path], keepers: dict[str, Path],
            emit512_dir: Path | None) -> dict:
    raw = np.asarray(Image.open(raw_path).convert("RGB"), dtype=np.float64)
    results = {
        "district": district,
        "raw": str(raw_path),
        "checks": {},
    }

    h, w, _ = raw.shape
    results["input_dims"] = [w, h]

    # 1) reference + LUT
    ref_path = reference_card_path(district, refs_dir, overrides)
    results["reference"] = str(ref_path)
    ref_region = load_reference(ref_path)
    luts = cdf_lut(raw, ref_region)
    results["lut_endpoints"] = [
        [float(luts[c][0]), float(luts[c][128]), float(luts[c][255])] for c in range(3)
    ]

    # 2) grade
    graded = apply_lut(raw, luts)

    # 2b) saturation rolloff (AI-overshoot correction, uniform across districts)
    graded = saturation_rolloff(graded)

    # 2c) palette lock: project out-of-band hues into the allowed families
    graded = hue_family_projection(graded, district)

    # 3) clamp
    graded = np.clip(graded, CLAMP_MIN, CLAMP_MAX)

    # 4) grain
    final = add_grain(graded, grain, stable_seed(seed, district))
    final = np.clip(final, CLAMP_MIN, CLAMP_MAX).astype(np.uint8)

    out_path = out_dir / f"district_{district}.png"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(final, "RGB").save(out_path, "PNG")
    results["output"] = str(out_path)

    # 5) validation
    lum = 0.2126 * final[..., 0] + 0.7152 * final[..., 1] + 0.0722 * final[..., 2]
    hue, sat = rgb_to_hsv_arr(final.astype(np.float64))
    th = sat_thresholds(district)
    med_sat = float(np.median(sat))
    p99_sat = float(np.percentile(sat, 99))
    share40 = float(np.mean(sat > 0.40))
    fam = hue_family_share(hue, sat, ACCENTS[district], district)
    band = band_std(final.astype(np.float64))
    tmin = int(lum.min())
    tmax = int(lum.max())

    results["checks"]["dims_1024x1536"] = (w == MASTER_W and h == MASTER_H)
    results["checks"]["texel_range_16_240"] = (tmin >= CLAMP_MIN and tmax <= CLAMP_MAX)
    results["checks"][f"median_sat_le_{th['median_sat']}"] = med_sat <= th["median_sat"]
    results["checks"]["p99_sat_le_0.55"] = p99_sat <= th["p99_sat"]
    results["checks"][f"share_sat40_le_{th['share_sat40']}"] = share40 <= th["share_sat40"]
    results["checks"]["hue_family_share_ge_0.85"] = fam >= T_MIN_HUE_FAM_SHARE
    results["metrics"] = {
        "lum_min": tmin, "lum_max": tmax,
        "median_sat": round(med_sat, 4), "p99_sat": round(p99_sat, 4),
        "share_sat40": round(share40, 4), "hue_family_share": round(fam, 4),
        "display_band_std": round(band, 2),
    }

    # uniqueness vs the 4 keeper cards (and any already-graded outputs)
    uniq_ok = True
    uniq_detail = {}
    final_f = final.astype(np.float64)
    a = ahash(final_f)
    m32 = mad32(final_f)
    for keeper_district, kp in keepers.items():
        if not kp or not Path(kp).exists():
            continue
        k = np.asarray(Image.open(kp).convert("RGB"), dtype=np.float64)
        ham = hamming(a, ahash(k))
        mad = float(np.mean(np.abs(m32 - mad32(k))))
        uniq_detail[f"vs_{keeper_district}"] = {"hamming": ham, "mad32": round(mad, 2)}
        if ham < T_MIN_AHASH_HAMMING or mad < T_MIN_MAD_32:
            uniq_ok = False
    for other_district, op in results_by_district.items():
        if other_district == district:
            continue
        op_path = Path(op["output"])
        if op_path.exists():
            o = np.asarray(Image.open(op_path).convert("RGB"), dtype=np.float64)
            ham = hamming(a, ahash(o))
            mad = float(np.mean(np.abs(m32 - mad32(o))))
            uniq_detail[f"vs_{other_district}"] = {"hamming": ham, "mad32": round(mad, 2)}
            if ham < T_MIN_AHASH_HAMMING or mad < T_MIN_MAD_32:
                uniq_ok = False
    # also cross-check against already-graded cards on disk from previous runs
    # (districts graded in earlier PRs/batches must stay distinct too)
    for f in sorted(Path(out_dir).glob("district_*.png")):
        od = f.stem[len("district_"):]
        if od == district or od in uniq_detail:
            continue
        o = np.asarray(Image.open(f).convert("RGB"), dtype=np.float64)
        ham = hamming(a, ahash(o))
        mad = float(np.mean(np.abs(m32 - mad32(o))))
        uniq_detail[f"vs_{od}_ondisk"] = {"hamming": ham, "mad32": round(mad, 2)}
        if ham < T_MIN_AHASH_HAMMING or mad < T_MIN_MAD_32:
            uniq_ok = False
    results["checks"]["unique_vs_keepers"] = uniq_ok
    results["uniqueness"] = uniq_detail
    results["checks"]["display_band_std_ge_20"] = band >= T_MIN_BAND_STD

    # 6) optional in-game 512 twin
    if emit512_dir is not None:
        emit512_dir.mkdir(parents=True, exist_ok=True)
        side = min(h, w)
        y0, x0 = (h - side) // 2, (w - side) // 2
        twin = final[y0:y0 + side, x0:x0 + side]
        twin = Image.fromarray(twin, "RGB").resize((512, 512), Image.LANCZOS)
        tarr = np.asarray(twin, dtype=np.uint8).copy()
        ar, ag, ab = (int(ACCENTS[district][i:i + 2], 16) for i in (1, 3, 5))
        tarr[:4, :] = (ar, ag, ab)
        tarr[-4:, :] = (ar, ag, ab)
        tarr[:, :4] = (ar, ag, ab)
        tarr[:, -4:] = (ar, ag, ab)
        twin_path = emit512_dir / f"card_{district}_512.png"
        Image.fromarray(tarr, "RGB").save(twin_path, "PNG")
        results["twin512"] = str(twin_path)

    return results


# mutable per-run state (kept module-global on purpose: small, single-process)
results_by_district: dict[str, dict] = {}


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument("--raw", action="append", default=[], metavar="PATH",
                     help="raw image (may be repeated); district id parsed from "
                          "'district_<id>' or 'card_<id>' in the filename")
    src.add_argument("--raw-dir", metavar="DIR",
                     help="directory of raw images named district_<id>* or card_<id>*")
    ap.add_argument("--district", action="append", default=[], metavar="ID=PATH",
                    help="explicit district mapping (repeatable); overrides filename parsing")
    ap.add_argument("--out", default="content/cards", metavar="DIR",
                    help="output directory for graded masters (default: content/cards)")
    ap.add_argument("--ref-card", action="append", default=[], metavar="ID=PATH",
                    help="override the histogram reference for a district")
    ap.add_argument("--refs-dir", default=None, metavar="DIR",
                    help="directory holding card_<keeper>_512.png references "
                         "(default: assets/textures/cards/)")
    ap.add_argument("--grain", type=float, default=0.04,
                    help="grain amplitude 0..0.15 (default 0.04, matches shipped cards)")
    ap.add_argument("--seed", type=int, default=13, help="determinism seed (default 13)")
    ap.add_argument("--report", default=None, metavar="PATH", help="write JSON report here")
    ap.add_argument("--emit-512", default=None, metavar="DIR",
                    help="also write in-game 512x512 twins (center crop + accent border)")
    ap.add_argument("--allow-other-dims", action="store_true",
                    help="warn instead of failing when input is not 1024x1536")
    args = ap.parse_args(argv)

    # collect (district, path) pairs
    pairs: list[tuple[str, Path]] = []
    explicit: dict[str, Path] = {}
    for item in args.district:
        if "=" not in item:
            sys.exit(f"--district expects ID=PATH, got: {item}")
        d, p = item.split("=", 1)
        d = d.strip()
        if d not in DISTRICTS:
            sys.exit(f"unknown district id: {d}")
        explicit[d] = Path(p)

    raws: list[Path] = [Path(r) for r in args.raw]
    if args.raw_dir:
        rd = Path(args.raw_dir)
        if not rd.is_dir():
            sys.exit(f"--raw-dir not a directory: {rd}")
        raws += sorted(rd.iterdir())

    for p in raws:
        if not p.is_file():
            continue
        stem = p.stem
        d = None
        for token in ("district_", "card_"):
            if token in stem:
                d = stem.split(token, 1)[1]
                # strip a _raw suffix, then a trailing all-digit segment ("_1024", "_512")
                d = d.split("_raw")[0]
                if "_" in d and d.rsplit("_", 1)[1].isdigit():
                    d = d.rsplit("_", 1)[0]
                break
        if d is None or d not in DISTRICTS:
            print(f"  skip {p.name}: no district id in filename "
                  f"(expected 'district_<id>.png' or 'card_<id>.png')", file=sys.stderr)
            continue
        if d in explicit:
            print(f"  note: {p.name} and --district {d}=... both present; "
                  f"--district wins", file=sys.stderr)
        else:
            pairs.append((d, p))
    for d, p in explicit.items():
        if not p.is_file():
            sys.exit(f"--district target missing: {p}")
        pairs.append((d, p))

    if not pairs:
        sys.exit("no raw images found (use --raw PATH or --raw-dir DIR)")

    overrides: dict[str, Path] = {}
    for item in args.ref_card:
        if "=" not in item:
            sys.exit(f"--ref-card expects ID=PATH, got: {item}")
        d, p = item.split("=", 1)
        overrides[d.strip()] = Path(p)

    refs_dir = Path(args.refs_dir) if args.refs_dir else None
    out_dir = Path(args.out)

    # keeper reference cards (the 4 existing base photographs, via their keepers)
    keepers = {
        "suburbs": REPO_ROOT / "assets/textures/cards/card_suburbs_512.png",
        "residential": REPO_ROOT / "assets/textures/cards/card_residential_512.png",
        "industrial": REPO_ROOT / "assets/textures/cards/card_industrial_512.png",
        "power_station": REPO_ROOT / "assets/textures/cards/card_power_station_512.png",
    }
    if refs_dir is not None:
        keepers = {k: refs_dir / f"card_{k}_512.png" for k in keepers}

    print(f"regen_cards_v2: {len(pairs)} raw image(s) -> {out_dir}/")
    report = {"districts": {}, "failed": []}
    exit_code = 0

    for d, p in pairs:
        print(f"  {d}: {p.name}")
        res = process(d, p, out_dir, args.grain, args.seed, refs_dir, overrides,
                      keepers, Path(args.emit_512) if args.emit_512 else None)
        res["ok"] = all(res["checks"].values())
        if args.allow_other_dims:
            res["checks"]["dims_1024x1536"] = True
            res["ok"] = all(res["checks"].values())
        results_by_district[d] = res
        report["districts"][d] = res
        for name, passed in res["checks"].items():
            mark = "PASS" if passed else "FAIL"
            print(f"      {mark}  {name}")
        if not res["ok"]:
            report["failed"].append(d)
            exit_code = 1

    if args.report:
        rp = Path(args.report)
        rp.parent.mkdir(parents=True, exist_ok=True)
        rp.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
        print(f"  report -> {rp}")

    if exit_code:
        print(f"FAILED: {', '.join(report['failed'])}", file=sys.stderr)
    else:
        print("OK: all checks passed (deterministic; re-run reproduces byte-identical output)")
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
