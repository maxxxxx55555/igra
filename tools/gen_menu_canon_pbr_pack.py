#!/usr/bin/env python3
"""Deterministic menu-canon photographic-grit PBR & UI texture generator for Last Streetlight."""

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
    "seed": 47221,
    "size": 512,
    "clamp_min": 19,
    "clamp_max": 240,
    "max_seam_delta": 7.0,
    "max_mean_sat_pct": 38.0,
    "palette": {
        "mist_teal": (20, 33, 38),
        "gutter_shadow": (20, 25, 27),
        "asphalt_base": (34, 37, 38),
        "asphalt_grit": (62, 62, 58),
        "plaster_dark": (36, 39, 38),
        "plaster_mid": (74, 71, 63),
        "plaster_damp": (24, 31, 33),
        "stone_under": (52, 46, 41),
        "cast_iron": (38, 34, 30),
        "rust_brown": (78, 52, 36),
        "panel_iron": (15, 19, 20),
        "panel_bevel": (30, 35, 36),
        "bronze_dim": (90, 74, 42),
    },
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
    harmonics: int = 7,
    persistence: float = 0.54,
) -> np.ndarray:
    """Strictly toroidal 2D Fourier fBm -> mathematically guaranteed seamless wrap."""
    coords = np.linspace(0.0, 2.0 * math.pi, size, endpoint=False, dtype=np.float32)
    yy, xx = np.meshgrid(coords, coords, indexing="ij")
    acc = np.zeros((size, size), dtype=np.float32)
    amp = 1.0
    norm = 0.0
    for o in range(octaves):
        fmax = base_freq * (2 ** o)
        for _ in range(harmonics):
            kx = int(rng.integers(-fmax, fmax + 1))
            ky = int(rng.integers(-fmax, fmax + 1))
            if kx == 0 and ky == 0:
                kx = fmax
            ph = float(rng.uniform(0.0, 2.0 * math.pi))
            acc += amp * np.cos(kx * xx + ky * yy + ph)
            norm += amp
        amp *= persistence
    acc /= max(norm, 1e-6)
    lo = float(acc.min())
    hi = float(acc.max())
    return (acc - lo) / max(hi - lo, 1e-6)


def periodic_height_to_normal(height: np.ndarray, strength: float = 3.2) -> np.ndarray:
    """Periodic Sobel normal map (tangent-space OpenGL)."""
    dx = (
        (np.roll(height, -1, axis=1) - np.roll(height, 1, axis=1)) * 2.0
        + (np.roll(np.roll(height, -1, axis=1), -1, axis=0) - np.roll(np.roll(height, 1, axis=1), -1, axis=0))
        + (np.roll(np.roll(height, -1, axis=1), 1, axis=0) - np.roll(np.roll(height, 1, axis=1), 1, axis=0))
    ) * (0.25 * strength)
    dy = (
        (np.roll(height, -1, axis=0) - np.roll(height, 1, axis=0)) * 2.0
        + (np.roll(np.roll(height, -1, axis=0), -1, axis=1) - np.roll(np.roll(height, 1, axis=0), -1, axis=1))
        + (np.roll(np.roll(height, -1, axis=0), 1, axis=1) - np.roll(np.roll(height, 1, axis=0), 1, axis=1))
    ) * (0.25 * strength)
    nx, ny, nz = -dx, -dy, np.ones_like(height, dtype=np.float32)
    inv = 1.0 / np.sqrt(np.maximum(nx * nx + ny * ny + nz * nz, 1e-8))
    rgb = np.stack([(nx * inv) * 0.5 + 0.5, (ny * inv) * 0.5 + 0.5, (nz * inv) * 0.5 + 0.5], axis=-1)
    return np.clip(np.round(rgb * 255.0), 0, 255).astype(np.uint8)


def clamp_u8(arr: np.ndarray) -> np.ndarray:
    return np.clip(np.round(arr), STYLE_LOCK["clamp_min"], STYLE_LOCK["clamp_max"]).astype(np.uint8)


def seam_delta(arr: np.ndarray) -> float:
    f = arr.astype(np.float32)
    return max(float(np.mean(np.abs(f[:, 0] - f[:, -1]))), float(np.mean(np.abs(f[0, :] - f[-1, :]))))


def mean_sat_pct(rgb: np.ndarray) -> float:
    f = rgb.astype(np.float32) / 255.0
    cmax = np.max(f, axis=-1)
    cmin = np.min(f, axis=-1)
    sat = np.where(cmax > 1e-5, (cmax - cmin) / np.maximum(cmax, 1e-5), 0.0)
    return float(np.mean(sat) * 100.0)


def save_map(
    out_dir: Path,
    fname: str,
    arr: np.ndarray,
    mode: str,
    check_seam: bool,
    is_color: bool,
) -> dict[str, Any]:
    p = out_dir / fname
    Image.fromarray(arr, mode=mode).save(p, optimize=True)
    return {
        "file": fname,
        "mode": mode,
        "size": [int(arr.shape[1]), int(arr.shape[0])],
        "seam_delta": round(seam_delta(arr), 3) if check_seam else 0.0,
        "mean_sat_pct": round(mean_sat_pct(arr), 2) if is_color else 0.0,
        "sha256": sha256_file(p),
    }


def gen_menu_wet_asphalt(out_dir: Path, rng: np.random.Generator, size: int) -> list[dict[str, Any]]:
    """Cracked wet nocturnal asphalt with deep puddle basins matching menu reference."""
    coords = np.linspace(0.0, 2.0 * math.pi, size, endpoint=False, dtype=np.float32)
    _, xx = np.meshgrid(coords, coords, indexing="ij")
    rut = 0.5 - 0.5 * np.cos(xx * 2.0)

    macro = periodic_fbm(size, rng, octaves=4, base_freq=2)
    mid = periodic_fbm(size, rng, octaves=4, base_freq=7)
    pebble = periodic_fbm(size, rng, octaves=3, base_freq=22)
    cr_field = np.abs(periodic_fbm(size, rng, octaves=4, base_freq=3) - 0.5) * 2.0
    cracks = np.clip(1.0 - cr_field * 15.0, 0.0, 1.0) ** 2.2

    puddle_raw = np.clip((0.46 - macro * 0.78 - rut * 0.22) * 6.0, 0.0, 1.0)
    puddle = puddle_raw * puddle_raw * (3.0 - 2.0 * puddle_raw)
    damp_rim = np.clip((0.58 - macro * 0.78 - rut * 0.22) * 3.8, 0.0, 1.0)

    dry_h = np.clip(0.38 * macro + 0.32 * mid + 0.30 * pebble - 0.40 * cracks, 0.0, 1.0)
    height = dry_h * (1.0 - 0.94 * puddle) + 0.44 * (0.94 * puddle)

    pal = STYLE_LOCK["palette"]
    c_base = np.array(pal["asphalt_base"], dtype=np.float32)
    c_grit = np.array(pal["asphalt_grit"], dtype=np.float32)
    c_dark = np.array(pal["gutter_shadow"], dtype=np.float32)

    albedo = c_base * (1.0 - pebble[..., None]) + c_grit * pebble[..., None]
    albedo = albedo * (0.86 + 0.24 * mid[..., None])
    albedo = albedo * (1.0 - 0.52 * cracks[..., None]) + c_dark * (0.52 * cracks[..., None])
    albedo = albedo * (1.0 - 0.24 * damp_rim[..., None] - 0.26 * puddle[..., None])

    rough = (0.86 + 0.08 * pebble) * (1.0 - 0.36 * damp_rim)
    rough = rough * (1.0 - puddle) + 0.10 * puddle
    rough = np.clip(rough, 0.10, 0.95)

    return [
        save_map(out_dir, "menu_asphalt_albedo.png", clamp_u8(albedo), "RGB", True, True),
        save_map(out_dir, "menu_asphalt_normal.png", periodic_height_to_normal(height, 3.6), "RGB", True, False),
        save_map(out_dir, "menu_asphalt_roughness.png", np.clip(np.round(rough * 255.0), 0, 255).astype(np.uint8), "L", True, False),
        save_map(out_dir, "menu_asphalt_puddle_mask.png", np.clip(np.round(puddle * 255.0), 0, 255).astype(np.uint8), "L", True, False),
    ]


def gen_menu_peeling_facade(out_dir: Path, rng: np.random.Generator, size: int) -> list[dict[str, Any]]:
    """Weathered European peeling plaster over dark damp stone/brick matching menu facade."""
    yy, xx = np.mgrid[0:size, 0:size]
    rows, cols = 16, 8
    rh, cw = size // rows, size // cols

    ys = (yy + rh // 2) % size
    r_idx = (ys // rh) % rows
    h_joint = ((ys % rh) < 3).astype(np.float32)

    col_off = np.where((r_idx % 2) == 0, cw // 4, (3 * cw) // 4)
    xs = (xx + col_off) % size
    c_idx = (xs // cw) % cols
    v_joint = ((xs % cw) < 3).astype(np.float32)
    mortar = np.maximum(h_joint, v_joint)

    stone_tone = ((r_idx * 41 + c_idx * 83 + 11) % 23).astype(np.float32) / 22.0
    macro = periodic_fbm(size, rng, octaves=4, base_freq=2)
    micro = periodic_fbm(size, rng, octaves=5, base_freq=6)
    drip_n = periodic_fbm(size, rng, octaves=4, base_freq=4)

    v_wave = 0.5 - 0.5 * np.cos(2.0 * math.pi * (yy.astype(np.float32) / float(size)) * 2.0)
    damp_streaks = np.clip((drip_n * 1.25 - 0.35) * (0.45 + 0.55 * v_wave), 0.0, 0.78)

    plaster = np.clip((macro - 0.34) * 5.0, 0.0, 1.0)
    plaster = plaster * plaster * (3.0 - 2.0 * plaster)
    peel_edge = np.clip(4.0 * plaster * (1.0 - plaster), 0.0, 1.0)

    stone_h = np.clip((1.0 - mortar) * (0.50 + 0.14 * stone_tone + 0.22 * micro) + mortar * 0.14, 0.0, 1.0)
    plaster_h = np.clip(0.84 + 0.14 * micro - 0.08 * peel_edge, 0.0, 1.0)
    height = stone_h * (1.0 - plaster) + plaster_h * plaster

    pal = STYLE_LOCK["palette"]
    p_dark = np.array(pal["plaster_dark"], dtype=np.float32)
    p_mid = np.array(pal["plaster_mid"], dtype=np.float32)
    p_damp = np.array(pal["plaster_damp"], dtype=np.float32)
    s_base = np.array(pal["stone_under"], dtype=np.float32)

    stone_rgb = s_base * (0.76 + 0.36 * stone_tone[..., None]) * (1.0 - 0.45 * mortar[..., None])
    plaster_rgb = p_dark * (1.0 - micro[..., None]) + p_mid * micro[..., None]
    albedo = stone_rgb * (1.0 - plaster[..., None]) + plaster_rgb * plaster[..., None]
    albedo = albedo * (1.0 - 0.25 * peel_edge[..., None])
    albedo = albedo * (1.0 - damp_streaks[..., None]) + p_damp * damp_streaks[..., None]

    rough = np.clip(0.86 + 0.10 * micro + 0.06 * mortar - 0.12 * damp_streaks, 0.72, 0.98)

    return [
        save_map(out_dir, "menu_facade_albedo.png", clamp_u8(albedo), "RGB", True, True),
        save_map(out_dir, "menu_facade_normal.png", periodic_height_to_normal(height, 3.4), "RGB", True, False),
        save_map(out_dir, "menu_facade_roughness.png", np.clip(np.round(rough * 255.0), 0, 255).astype(np.uint8), "L", True, False),
    ]


def gen_menu_cast_iron_and_industrial(out_dir: Path, rng: np.random.Generator, size: int) -> list[dict[str, Any]]:
    """Corroded cast-iron metal for lamp poles, railings, and industrial districts."""
    coords = np.linspace(0.0, 2.0 * math.pi, size, endpoint=False, dtype=np.float32)
    _, xx = np.meshgrid(coords, coords, indexing="ij")
    ribs = 0.5 + 0.5 * np.sin(xx * 16.0)
    micro = periodic_fbm(size, rng, octaves=5, base_freq=5)
    rust_n = periodic_fbm(size, rng, octaves=4, base_freq=3)
    rust = np.clip((rust_n - 0.46) * 3.4, 0.0, 1.0)

    pal = STYLE_LOCK["palette"]
    iron = np.array(pal["cast_iron"], dtype=np.float32)
    rust_c = np.array(pal["rust_brown"], dtype=np.float32)

    height = np.clip(0.68 * ribs + 0.32 * micro, 0.0, 1.0)
    albedo = (iron * (0.78 + 0.32 * ribs[..., None])) * (1.0 - rust[..., None]) + rust_c * rust[..., None]
    rough = np.clip(0.56 + 0.36 * rust + 0.08 * micro, 0.55, 0.96)

    return [
        save_map(out_dir, "menu_iron_albedo.png", clamp_u8(albedo), "RGB", True, True),
        save_map(out_dir, "menu_iron_normal.png", periodic_height_to_normal(height, 3.6), "RGB", True, False),
        save_map(out_dir, "menu_iron_roughness.png", np.clip(np.round(rough * 255.0), 0, 255).astype(np.uint8), "L", True, False),
    ]


def gen_menu_ui_panel_9slice(out_dir: Path, rng: np.random.Generator, size: int = 128, chamfer: int = 8) -> dict[str, Any]:
    """Weathered wet-iron chamfered 9-slice UI panel matching menu atmosphere."""
    yy, xx = np.mgrid[0:size, 0:size]
    d_edges = np.minimum.reduce([
        xx, size - 1 - xx, yy, size - 1 - yy,
        xx + yy - chamfer,
        (size - 1 - xx) + yy - chamfer,
        xx + (size - 1 - yy) - chamfer,
        (size - 1 - xx) + (size - 1 - yy) - chamfer,
    ])
    inside = d_edges >= 0
    rim = d_edges == 0
    bevel = d_edges == 1

    pal = STYLE_LOCK["palette"]
    base = np.array(pal["panel_iron"], dtype=np.float32)
    bev = np.array(pal["panel_bevel"], dtype=np.float32)
    edge = np.array(pal["bronze_dim"], dtype=np.float32)

    patina = periodic_fbm(size, rng, octaves=3, base_freq=2)
    grain = rng.normal(0.0, 2.4, size=(size, size)).astype(np.float32)
    rgb = base + (patina[..., None] - 0.5) * 10.0 + grain[..., None]
    rgb[bevel] = bev
    rgb[rim] = edge

    alpha = np.where(inside, 232, 0).astype(np.uint8)
    alpha[rim] = 255
    rgba = np.dstack([clamp_u8(rgb), alpha])
    return save_map(out_dir, "menu_ui_panel_9slice.png", rgba, "RGBA", False, False)


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate menu-canon PBR & UI pack for Last Streetlight.")
    parser.add_argument("--out-dir", type=Path, default=Path("assets/textures/menu_canon_pbr"))
    args = parser.parse_args()

    out_dir = args.out_dir.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    rng = np.random.default_rng(STYLE_LOCK["seed"])
    size = int(STYLE_LOCK["size"])

    records: list[dict[str, Any]] = []
    records.extend(gen_menu_wet_asphalt(out_dir, rng, size))
    records.extend(gen_menu_peeling_facade(out_dir, rng, size))
    records.extend(gen_menu_cast_iron_and_industrial(out_dir, rng, size))
    records.append(gen_menu_ui_panel_9slice(out_dir, rng, size=128, chamfer=8))

    errors: list[str] = []
    for r in records:
        if r["seam_delta"] > STYLE_LOCK["max_seam_delta"]:
            errors.append(f"{r['file']}: seam_delta={r['seam_delta']} > {STYLE_LOCK['max_seam_delta']}")
        if r["mean_sat_pct"] > STYLE_LOCK["max_mean_sat_pct"]:
            errors.append(f"{r['file']}: mean_sat_pct={r['mean_sat_pct']} > {STYLE_LOCK['max_mean_sat_pct']}")

    manifest_path = out_dir / "manifest_menu_canon.json"
    tmp = manifest_path.with_suffix(".json.tmp")
    tmp.write_text(json.dumps({"style_lock": STYLE_LOCK, "assets": records, "errors": errors}, indent=2) + "\n", encoding="utf-8", newline="\n")
    os.replace(tmp, manifest_path)

    print(json.dumps({"generated": len(records), "errors": len(errors), "manifest": str(manifest_path)}, indent=2))
    if errors:
        for err in errors:
            print(f"FAIL: {err}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
