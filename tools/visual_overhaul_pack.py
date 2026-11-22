#!/usr/bin/env python3
"""Deterministic high-craft PBR & UI texture generator for THE LAST STREETLIGHT."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import sys
from pathlib import Path
from typing import Any

try:
    import numpy as np
    from PIL import Image
except ImportError as exc:
    print(f"FAIL: missing dependency ({exc}). Install pillow and numpy.", file=sys.stderr)
    raise SystemExit(1)

STYLE_LOCK: dict[str, Any] = {
    "seed": 47101,
    "palette": {
        "bg_deep": (6, 15, 19),
        "panel": (15, 19, 20),
        "panel_inset": (28, 30, 29),
        "panel_edge": (90, 74, 42),
        "brass_hot": (212, 169, 78),
        "asphalt_dark": (24, 29, 33),
        "asphalt_mid": (42, 49, 54),
        "concrete_dark": (34, 41, 45),
        "concrete_light": (78, 86, 89),
        "grime": (22, 24, 23),
        "sodium_dust": (212, 169, 78),
    },
    "clamp_min": 19,
    "clamp_max": 240,
    "max_seam_delta": 10.0,
    "max_mean_saturation_pct": 40.0,
    "concrete_roughness_bounds": (0.72, 0.98),
    "asphalt_roughness_bounds": (0.20, 0.94),
}


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def periodic_fbm(
    size: int,
    rng: np.random.Generator,
    octaves: int = 5,
    base_freq: int = 2,
    components_per_octave: int = 6,
    persistence: float = 0.52,
) -> np.ndarray:
    """Strictly periodic 2D fBm over [0, 2*pi) -> mathematically seamless wrap."""
    coords = np.linspace(0.0, 2.0 * math.pi, size, endpoint=False, dtype=np.float32)
    yy, xx = np.meshgrid(coords, coords, indexing="ij")
    acc = np.zeros((size, size), dtype=np.float32)
    amp = 1.0
    amp_sum = 0.0

    for oct_idx in range(octaves):
        freq_scale = base_freq * (2 ** oct_idx)
        for _ in range(components_per_octave):
            kx = int(rng.integers(-freq_scale, freq_scale + 1))
            ky = int(rng.integers(-freq_scale, freq_scale + 1))
            if kx == 0 and ky == 0:
                kx = freq_scale
            phase = float(rng.uniform(0.0, 2.0 * math.pi))
            acc += amp * np.cos(kx * xx + ky * yy + phase)
            amp_sum += amp
        amp *= persistence

    acc /= max(amp_sum, 1e-6)
    lo = float(acc.min())
    hi = float(acc.max())
    if hi - lo < 1e-6:
        return np.full((size, size), 0.5, dtype=np.float32)
    return (acc - lo) / (hi - lo)


def height_to_normal_rgb(height: np.ndarray, strength: float = 2.4) -> np.ndarray:
    """Periodic central-difference Sobel normal map (OpenGL tangent space)."""
    dx = (
        np.roll(height, -1, axis=1)
        - np.roll(height, 1, axis=1)
        + 0.5 * (np.roll(np.roll(height, -1, axis=1), -1, axis=0) - np.roll(np.roll(height, 1, axis=1), -1, axis=0))
        + 0.5 * (np.roll(np.roll(height, -1, axis=1), 1, axis=0) - np.roll(np.roll(height, 1, axis=1), 1, axis=0))
    ) * strength
    dy = (
        np.roll(height, -1, axis=0)
        - np.roll(height, 1, axis=0)
        + 0.5 * (np.roll(np.roll(height, -1, axis=0), -1, axis=1) - np.roll(np.roll(height, 1, axis=0), -1, axis=1))
        + 0.5 * (np.roll(np.roll(height, -1, axis=0), 1, axis=1) - np.roll(np.roll(height, 1, axis=0), 1, axis=1))
    ) * strength
    nx = -dx
    ny = -dy
    nz = np.ones_like(height, dtype=np.float32)
    inv_len = 1.0 / np.sqrt(np.maximum(nx * nx + ny * ny + nz * nz, 1e-8))
    nx *= inv_len
    ny *= inv_len
    nz *= inv_len
    rgb = np.stack([(nx * 0.5 + 0.5), (ny * 0.5 + 0.5), (nz * 0.5 + 0.5)], axis=-1)
    return np.clip(np.round(rgb * 255.0), 0, 255).astype(np.uint8)


def clamp_rgb_array(arr: np.ndarray) -> np.ndarray:
    return np.clip(
        np.round(arr),
        STYLE_LOCK["clamp_min"],
        STYLE_LOCK["clamp_max"],
    ).astype(np.uint8)


def measure_seam_delta(arr: np.ndarray) -> float:
    f = arr.astype(np.float32)
    lr = float(np.mean(np.abs(f[:, 0] - f[:, -1])))
    tb = float(np.mean(np.abs(f[0, :] - f[-1, :])))
    return max(lr, tb)


def measure_mean_saturation_pct(rgb: np.ndarray) -> float:
    f = rgb.astype(np.float32) / 255.0
    cmax = np.max(f, axis=-1)
    cmin = np.min(f, axis=-1)
    sat = np.where(cmax > 1e-5, (cmax - cmin) / np.maximum(cmax, 1e-5), 0.0)
    return float(np.mean(sat) * 100.0)


def generate_wet_asphalt_set(out_dir: Path, rng: np.random.Generator, size: int = 512) -> list[dict[str, Any]]:
    macro = periodic_fbm(size, rng, octaves=4, base_freq=2)
    mid = periodic_fbm(size, rng, octaves=4, base_freq=6)
    grit = periodic_fbm(size, rng, octaves=3, base_freq=18)
    cracks_raw = np.abs(periodic_fbm(size, rng, octaves=4, base_freq=3) - 0.5) * 2.0
    cracks = np.clip(1.0 - cracks_raw * 11.0, 0.0, 1.0) ** 2.0

    # Puddle mask: low-lying depressions hold water
    puddle = np.clip((0.46 - macro) * 5.2, 0.0, 1.0)
    puddle = puddle * puddle * (3.0 - 2.0 * puddle)

    height = np.clip(0.55 * macro + 0.25 * mid + 0.20 * grit - 0.35 * cracks, 0.0, 1.0)
    # Flatten normals inside water puddles
    water_flat_height = height * (1.0 - 0.88 * puddle) + 0.42 * (0.88 * puddle)

    dark = np.array(STYLE_LOCK["palette"]["asphalt_dark"], dtype=np.float32)
    mid_c = np.array(STYLE_LOCK["palette"]["asphalt_mid"], dtype=np.float32)
    grime = np.array(STYLE_LOCK["palette"]["grime"], dtype=np.float32)

    t = np.clip(0.5 * mid + 0.5 * grit, 0.0, 1.0)[..., None]
    albedo = dark * (1.0 - t) + mid_c * t
    # Wet areas darken physically (reduced diffuse albedo)
    albedo = albedo * (1.0 - 0.28 * puddle[..., None])
    albedo = albedo * (1.0 - 0.42 * cracks[..., None]) + grime * (0.42 * cracks[..., None])
    albedo_u8 = clamp_rgb_array(albedo)

    normal_u8 = height_to_normal_rgb(water_flat_height, strength=3.0)

    r_min, r_max = STYLE_LOCK["asphalt_roughness_bounds"]
    dry_rough = 0.84 + 0.10 * grit - 0.06 * mid
    rough = dry_rough * (1.0 - puddle) + r_min * puddle
    rough = np.clip(rough, r_min, r_max)
    rough_u8 = np.clip(np.round(rough * 255.0), 0, 255).astype(np.uint8)
    puddle_u8 = np.clip(np.round(puddle * 255.0), 0, 255).astype(np.uint8)

    records: list[dict[str, Any]] = []
    specs = [
        ("asphalt_wet_albedo_v2.png", albedo_u8, "RGB", True, True),
        ("asphalt_wet_normal_v2.png", normal_u8, "RGB", True, False),
        ("asphalt_wet_roughness_v2.png", rough_u8, "L", True, False),
        ("asphalt_puddle_mask_v2.png", puddle_u8, "L", True, False),
    ]
    for fname, data, mode, check_seam, check_color in specs:
        p = out_dir / fname
        Image.fromarray(data, mode=mode).save(p, optimize=True)
        seam = measure_seam_delta(data) if check_seam else 0.0
        sat = measure_mean_saturation_pct(data) if check_color else 0.0
        records.append({
            "file": fname,
            "size": [size, size],
            "mode": mode,
            "seam_delta": round(seam, 3),
            "mean_saturation_pct": round(sat, 2),
            "sha256": sha256_file(p),
        })
    return records


def generate_weathered_facade_set(out_dir: Path, rng: np.random.Generator, size: int = 512) -> list[dict[str, Any]]:
    macro = periodic_fbm(size, rng, octaves=4, base_freq=2)
    micro = periodic_fbm(size, rng, octaves=4, base_freq=10)

    # Architectural panel seams (4 vertical x 2 horizontal panels, seamless).
    # FIX: offset the joint grid so no joint sits on the texture border; the
    # original `yy % (size//2) < 3` put a dark line on row 0 but not row 511,
    # which produced seam_delta 32.9 / 18.5 (> 10.0) and made the generator
    # exit 2. A half-panel offset keeps the wrap mathematically seamless.
    yy, xx = np.mgrid[0:size, 0:size]
    joint_y = size // 4
    joint_x = size // 8
    h_seam = (((yy + joint_y) % (size // 2)) < 3).astype(np.float32)
    v_seam = (((xx + joint_x) % (size // 4)) < 2).astype(np.float32)
    seams = np.maximum(h_seam, v_seam)

    # Vertical rain-streak grime dripping from horizontal panel joints.
    # FIX: triangular decay from each joint is periodic across the wrap; the
    # original one-sided decay was ~1.0 at row 0 and ~0.0 at row 511.
    drip_noise = periodic_fbm(size, rng, octaves=3, base_freq=12)
    phase_raw = ((yy - joint_y) % (size // 2)).astype(np.float32) / float(size // 2)
    drip_phase = 1.0 - np.abs(phase_raw * 2.0 - 1.0)
    rain_streaks = np.exp(-drip_phase * 5.5) * np.clip(drip_noise * 1.4 - 0.25, 0.0, 1.0)

    height = np.clip(0.65 * macro + 0.35 * micro - 0.45 * seams, 0.0, 1.0)

    c_dark = np.array(STYLE_LOCK["palette"]["concrete_dark"], dtype=np.float32)
    c_light = np.array(STYLE_LOCK["palette"]["concrete_light"], dtype=np.float32)
    grime = np.array(STYLE_LOCK["palette"]["grime"], dtype=np.float32)

    albedo = c_dark * (1.0 - height[..., None]) + c_light * height[..., None]
    stain = np.clip(0.55 * rain_streaks + 0.65 * seams, 0.0, 0.85)[..., None]
    albedo = albedo * (1.0 - stain) + grime * stain
    albedo_u8 = clamp_rgb_array(albedo)

    normal_u8 = height_to_normal_rgb(height, strength=2.6)

    r_min, r_max = STYLE_LOCK["concrete_roughness_bounds"]
    # Wet rain streaks slightly lower roughness within matte facade bounds [0.72, 0.98]
    rough = 0.86 + 0.10 * micro - 0.12 * rain_streaks + 0.08 * seams
    rough = np.clip(rough, r_min, r_max)
    rough_u8 = np.clip(np.round(rough * 255.0), 0, 255).astype(np.uint8)

    records: list[dict[str, Any]] = []
    specs = [
        ("facade_concrete_albedo_v2.png", albedo_u8, "RGB", True, True),
        ("facade_concrete_normal_v2.png", normal_u8, "RGB", True, False),
        ("facade_concrete_roughness_v2.png", rough_u8, "L", True, False),
    ]
    for fname, data, mode, check_seam, check_color in specs:
        p = out_dir / fname
        Image.fromarray(data, mode=mode).save(p, optimize=True)
        seam = measure_seam_delta(data) if check_seam else 0.0
        sat = measure_mean_saturation_pct(data) if check_color else 0.0
        records.append({
            "file": fname,
            "size": [size, size],
            "mode": mode,
            "seam_delta": round(seam, 3),
            "mean_saturation_pct": round(sat, 2),
            "sha256": sha256_file(p),
        })
    return records


def generate_soft_sodium_mote(out_dir: Path, size: int = 128) -> dict[str, Any]:
    """Zero-edge radial dust/volumetric glow sprite (strict alpha=0 at r>=0.86)."""
    coords = np.linspace(-1.0, 1.0, size, dtype=np.float32)
    yy, xx = np.meshgrid(coords, coords, indexing="ij")
    r = np.sqrt(xx * xx + yy * yy)
    gauss = np.exp(-5.2 * r * r)
    window = np.clip((0.86 - r) / 0.36, 0.0, 1.0)
    window = window * window * (3.0 - 2.0 * window)
    alpha = np.clip(gauss * window, 0.0, 1.0)

    rgb = np.zeros((size, size, 3), dtype=np.float32)
    base = np.array(STYLE_LOCK["palette"]["sodium_dust"], dtype=np.float32)
    rgb[:, :, :] = base
    rgba = np.dstack([
        clamp_rgb_array(rgb),
        np.clip(np.round(alpha * 255.0), 0, 255).astype(np.uint8),
    ])
    fname = "fx_sodium_mote_soft_128.png"
    p = out_dir / fname
    Image.fromarray(rgba, mode="RGBA").save(p, optimize=True)
    border_max = int(max(rgba[0, :, 3].max(), rgba[-1, :, 3].max(), rgba[:, 0, 3].max(), rgba[:, -1, 3].max()))
    if border_max != 0:
        raise RuntimeError(f"fx_sodium_mote_soft_128 border alpha must be 0, got {border_max}")
    return {
        "file": fname,
        "size": [size, size],
        "mode": "RGBA",
        "border_alpha_max": border_max,
        "sha256": sha256_file(p),
    }


def generate_chamfered_panel_9slice(out_dir: Path, rng: np.random.Generator, size: int = 128, chamfer: int = 8) -> dict[str, Any]:
    """Chamfered dark-iron UI panel with crisp 1px #5a4a2a brass rim and 8-12% subtle brushed grain."""
    yy, xx = np.mgrid[0:size, 0:size]
    # Signed Manhattan chamfer distance from corners
    d_tl = xx + yy - chamfer
    d_tr = (size - 1 - xx) + yy - chamfer
    d_bl = xx + (size - 1 - yy) - chamfer
    d_br = (size - 1 - xx) + (size - 1 - yy) - chamfer
    d_edges = np.minimum.reduce([xx, size - 1 - xx, yy, size - 1 - yy, d_tl, d_tr, d_bl, d_br])

    inside = d_edges >= 0
    border = (d_edges == 0)
    inner_bevel = (d_edges == 1)

    grain = rng.normal(0.0, 2.2, size=(size, size)).astype(np.float32)
    # Brushed horizontal metal micro-lines
    streak = rng.normal(0.0, 1.4, size=(size, 1)).astype(np.float32)

    panel_rgb = np.zeros((size, size, 3), dtype=np.float32)
    base = np.array(STYLE_LOCK["palette"]["panel"], dtype=np.float32)
    inset = np.array(STYLE_LOCK["palette"]["panel_inset"], dtype=np.float32)
    edge = np.array(STYLE_LOCK["palette"]["panel_edge"], dtype=np.float32)

    panel_rgb[:, :, :] = base + grain[..., None] + streak[..., None]
    panel_rgb[inner_bevel] = inset
    panel_rgb[border] = edge

    alpha = np.where(inside, 238, 0).astype(np.uint8)
    alpha[border] = 255
    rgba = np.dstack([clamp_rgb_array(panel_rgb), alpha])

    fname = "ui_panel_chamfer_9slice_v2.png"
    p = out_dir / fname
    Image.fromarray(rgba, mode="RGBA").save(p, optimize=True)
    return {
        "file": fname,
        "size": [size, size],
        "mode": "RGBA",
        "nine_slice_margin_px": 10,
        "chamfer_px": chamfer,
        "sha256": sha256_file(p),
    }


def verify_records(records: list[dict[str, Any]]) -> list[str]:
    errors: list[str] = []
    for rec in records:
        if rec.get("seam_delta", 0.0) > STYLE_LOCK["max_seam_delta"]:
            errors.append(f"{rec['file']}: seam_delta={rec['seam_delta']} > {STYLE_LOCK['max_seam_delta']}")
        if rec.get("mean_saturation_pct", 0.0) > STYLE_LOCK["max_mean_saturation_pct"]:
            errors.append(
                f"{rec['file']}: mean_saturation_pct={rec['mean_saturation_pct']} > {STYLE_LOCK['max_mean_saturation_pct']}"
            )
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate v2 high-craft PBR/FX/UI textures for igra.")
    parser.add_argument("--out-dir", type=Path, default=Path("assets/textures/visual_v2"), help="Output directory.")
    args = parser.parse_args()

    out_dir = args.out_dir.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    rng = np.random.default_rng(STYLE_LOCK["seed"])

    records: list[dict[str, Any]] = []
    records.extend(generate_wet_asphalt_set(out_dir, rng, size=512))
    records.extend(generate_weathered_facade_set(out_dir, rng, size=512))
    records.append(generate_soft_sodium_mote(out_dir, size=128))
    records.append(generate_chamfered_panel_9slice(out_dir, rng, size=128, chamfer=8))

    errors = verify_records(records)
    manifest = {
        "style_lock": STYLE_LOCK,
        "assets": records,
        "errors": errors,
    }
    manifest_path = out_dir / "manifest_visual_v2.json"
    tmp = manifest_path.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")
    os.replace(tmp, manifest_path)

    print(json.dumps({"generated": len(records), "errors": len(errors), "manifest": str(manifest_path)}, indent=2))
    if errors:
        for err in errors:
            print(f"FAIL: {err}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
