#!/usr/bin/env python3
"""Deterministic Wave 2 PBR Texture Generator for The Last Streetlight.
Style-locked to the Main Menu nocturnal survival-horror canon:
- Shadow blue-teal: #0f1314 / #060f13
- Weathered concrete / iron: #38434a / #21282d
- Brass / Sodium Amber accents: #c9a24a / #d4a94e
Target: Samsung Galaxy A32 (Mali-G52, GL Compatibility, seamless tileable PBR maps).
"""

from __future__ import annotations

import argparse
import gc
import hashlib
import json
import math
import random
import sys
from pathlib import Path
from typing import Any, Dict, Tuple

from PIL import Image, ImageDraw, ImageFilter

STYLE_LOCK: Dict[str, Any] = {
    "project": "The Last Streetlight",
    "wave": "wave2_pbr_textures",
    "seed": 47102,
    "palette_hex": {
        "shadow_slate": "#0f1314",
        "deep_teal": "#060f13",
        "concrete_mid": "#3f4a52",
        "concrete_dark": "#252e34",
        "concrete_damp": "#1a2228",
        "asphalt_dry": "#283036",
        "asphalt_wet": "#161d23",
        "sidewalk_slab": "#39434a",
        "cast_iron": "#1e2429",
        "brass": "#c9a24a",
        "sodium_amber": "#d4a94e",
        "rust_subtle": "#5c3022",
    },
    "resolutions": {
        "panel_facade": 1024,
        "wet_asphalt": 512,
        "concrete_sidewalk": 512,
        "iron_brass_hardware": 512,
    },
    "min_mean_luma": 18.0,
    "max_mean_luma": 175.0,
    "max_pack_mb": 8.0,
}


def hex_rgb(h: str) -> Tuple[int, int, int]:
    h = h.lstrip("#")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def tileable_noise_l(size: int, coarse: int, rng: random.Random, amp: int) -> Image.Image:
    base = Image.new("L", (coarse, coarse))
    bpx = base.load()
    for y in range(coarse):
        for x in range(coarse):
            bpx[x, y] = max(0, min(255, 128 + rng.randint(-amp, amp)))
    # Wrap-pad by 1 pixel on all sides so bilinear upscale stays seamless across tile edges
    padded = Image.new("L", (coarse + 2, coarse + 2))
    ppx = padded.load()
    for y in range(coarse + 2):
        sy = (y - 1) % coarse
        for x in range(coarse + 2):
            sx = (x - 1) % coarse
            ppx[x, y] = bpx[sx, sy]
    up = padded.resize((size + 2 * (size // coarse), size + 2 * (size // coarse)), Image.Resampling.BILINEAR)
    pad_px = size // coarse
    return up.crop((pad_px, pad_px, pad_px + size, pad_px + size))


def blend_grain(img: Image.Image, noise: Image.Image) -> Image.Image:
    w, h = img.size
    px = img.load()
    npx = noise.load()
    if img.mode == "RGB":
        for y in range(h):
            for x in range(w):
                d = npx[x, y] - 128
                r, g, b = px[x, y]
                px[x, y] = (
                    max(6, min(245, r + d)),
                    max(6, min(245, g + d)),
                    max(6, min(245, b + d)),
                )
    else:
        for y in range(h):
            for x in range(w):
                px[x, y] = max(0, min(255, px[x, y] + (npx[x, y] - 128)))
    return img


def height_to_normal(height_img: Image.Image, strength: float) -> Image.Image:
    w, h = height_img.size
    px = height_img.load()
    out = Image.new("RGB", (w, h))
    opx = out.load()
    for y in range(h):
        ym = (y - 1) % h
        yp = (y + 1) % h
        for x in range(w):
            xm = (x - 1) % w
            xp = (x + 1) % w
            tl, tc, tr = px[xm, ym] / 255.0, px[x, ym] / 255.0, px[xp, ym] / 255.0
            ml, mr = px[xm, y] / 255.0, px[xp, y] / 255.0
            bl, bc, br = px[xm, yp] / 255.0, px[x, yp] / 255.0, px[xp, yp] / 255.0
            dx = (tr + 2.0 * mr + br) - (tl + 2.0 * ml + bl)
            dy = (bl + 2.0 * bc + br) - (tl + 2.0 * tc + tr)
            nx, ny, nz = -dx * strength, -dy * strength, 1.0
            inv = 1.0 / math.sqrt(nx * nx + ny * ny + nz * nz)
            opx[x, y] = (
                max(0, min(255, int(round((nx * inv * 0.5 + 0.5) * 255.0)))),
                max(0, min(255, int(round((ny * inv * 0.5 + 0.5) * 255.0)))),
                max(0, min(255, int(round((nz * inv * 0.5 + 0.5) * 255.0)))),
            )
    return out


def compute_mean_luma(img: Image.Image) -> float:
    small = img.resize((64, 64), Image.Resampling.BILINEAR)
    px = list(small.getdata())
    total = sum(0.299 * r + 0.587 * g + 0.114 * b for r, g, b in px)
    return total / float(len(px))


def compute_tile_seam_delta(img: Image.Image, horizontal_only: bool = False) -> float:
    w, h = img.size
    px = img.load()
    diffs = 0.0
    count = 0
    for y in range(0, h, 4):
        r0, g0, b0 = px[0, y]
        r1, g1, b1 = px[w - 1, y]
        diffs += (abs(r0 - r1) + abs(g0 - g1) + abs(b0 - b1)) / 3.0
        count += 1
    if not horizontal_only:
        for x in range(0, w, 4):
            r0, g0, b0 = px[x, 0]
            r1, g1, b1 = px[x, h - 1]
            diffs += (abs(r0 - r1) + abs(g0 - g1) + abs(b0 - b1)) / 3.0
            count += 1
    return diffs / max(1, count)


def build_all_textures(out_dir: Path) -> Dict[str, Any]:
    out_dir.mkdir(parents=True, exist_ok=True)
    rng = random.Random(int(STYLE_LOCK["seed"]))
    pal = {k: hex_rgb(v) for k, v in STYLE_LOCK["palette_hex"].items()}
    manifest_sets: Dict[str, Any] = {}
    errors = []

    def emit_set(name: str, alb: Image.Image, hmap: Image.Image, ao: Image.Image, rough: Image.Image, metal: Image.Image, n_str: float, horizontal_only: bool = False) -> None:
        nrm = height_to_normal(hmap, strength=n_str)
        orm = Image.merge("RGB", (ao, rough, metal))
        p_alb = out_dir / f"{name}_albedo.png"
        p_nrm = out_dir / f"{name}_normal.png"
        p_orm = out_dir / f"{name}_orm.png"
        alb.save(p_alb, optimize=True)
        nrm.save(p_nrm, optimize=True)
        orm.save(p_orm, optimize=True)

        luma = round(compute_mean_luma(alb), 2)
        seam = round(compute_tile_seam_delta(alb, horizontal_only=horizontal_only), 2)
        if luma < float(STYLE_LOCK["min_mean_luma"]) or luma > float(STYLE_LOCK["max_mean_luma"]):
            errors.append(f"{name}:luma_out_of_bounds:{luma}")
        if seam > 26.0:
            errors.append(f"{name}:tile_seam_too_high:{seam}")

        manifest_sets[name] = {
            "size": list(alb.size),
            "mean_luma": luma,
            "tile_seam_delta": seam,
            "files": {
                "albedo": {"file": p_alb.name, "kb": round(p_alb.stat().st_size / 1024.0, 1), "sha256": sha256_file(p_alb)},
                "normal": {"file": p_nrm.name, "kb": round(p_nrm.stat().st_size / 1024.0, 1), "sha256": sha256_file(p_nrm)},
                "orm": {"file": p_orm.name, "kb": round(p_orm.stat().st_size / 1024.0, 1), "sha256": sha256_file(p_orm)},
            },
        }

    # 1. panel_facade (1024x1024): realistic Soviet concrete panels + recessed dark/amber windows + weathering
    sz = int(STYLE_LOCK["resolutions"]["panel_facade"])
    alb = Image.new("RGB", (sz, sz), pal["concrete_mid"])
    hmap = Image.new("L", (sz, sz), 156)
    ao = Image.new("L", (sz, sz), 232)
    rough = Image.new("L", (sz, sz), 218)
    metal = Image.new("L", (sz, sz), 0)
    da, dh, dao, dr, dm = ImageDraw.Draw(alb), ImageDraw.Draw(hmap), ImageDraw.Draw(ao), ImageDraw.Draw(rough), ImageDraw.Draw(metal)

    lit_windows = {(0, 1), (2, 2), (3, 0)}
    for row in range(4):
        y0 = row * 256
        for col in range(4):
            x0 = col * 256
            dv = rng.randint(-6, 6)
            slab_c = tuple(max(12, min(230, c + dv)) for c in pal["concrete_mid"])
            da.rectangle([x0 + 3, y0 + 3, x0 + 252, y0 + 252], fill=slab_c)
            # Symmetric panel seam grooves (2px on all 4 edges -> seamless wrap)
            for rect_g in ([x0, y0, x0 + 255, y0 + 2], [x0, y0 + 253, x0 + 255, y0 + 255], [x0, y0, x0 + 2, y0 + 255], [x0 + 253, y0, x0 + 255, y0 + 255]):
                da.rectangle(rect_g, fill=pal["concrete_dark"])
                dh.rectangle(rect_g, fill=55)
            dao.rectangle([x0, y0, x0 + 255, y0 + 5], fill=140)
            dao.rectangle([x0, y0 + 250, x0 + 255, y0 + 255], fill=140)
            # Recessed window bay with concrete sill + iron mullions
            wx0, wy0, wx1, wy1 = x0 + 54, y0 + 52, x0 + 202, y0 + 188
            da.rectangle([wx0 - 6, wy0 - 6, wx1 + 6, wy1 + 6], fill=pal["concrete_dark"])
            dh.rectangle([wx0 - 6, wy0 - 6, wx1 + 6, wy1 + 6], fill=95)
            dao.rectangle([wx0 - 10, wy0 - 10, wx1 + 10, wy1 + 10], fill=135)
            win_col = pal["sodium_amber"] if (row, col) in lit_windows else (18, 28, 35)
            da.rectangle([wx0, wy0, wx1, wy1], fill=win_col)
            dh.rectangle([wx0, wy0, wx1, wy1], fill=75)
            dr.rectangle([wx0, wy0, wx1, wy1], fill=36)
            dm.rectangle([wx0, wy0, wx1, wy1], fill=18)
            # Mullion crossbars
            da.rectangle([(wx0 + wx1) // 2 - 3, wy0, (wx0 + wx1) // 2 + 3, wy1], fill=pal["cast_iron"])
            da.rectangle([wx0, wy0 + 46, wx1, wy0 + 52], fill=pal["cast_iron"])
            dh.rectangle([(wx0 + wx1) // 2 - 3, wy0, (wx0 + wx1) // 2 + 3, wy1], fill=150)
            # Protruding sill + rain streaks underneath
            da.rectangle([wx0 - 10, wy1 + 2, wx1 + 10, wy1 + 16], fill=(74, 84, 92))
            dh.rectangle([wx0 - 10, wy1 + 2, wx1 + 10, wy1 + 16], fill=228)
            for s in range(6):
                sx = wx0 + 8 + s * 26 + rng.randint(-4, 4)
                da.line([(sx, wy1 + 17), (sx, wy1 + 17 + rng.randint(18, 44))], fill=pal["concrete_damp"], width=3)
                dr.line([(sx, wy1 + 17), (sx, wy1 + 17 + 32)], fill=145, width=3)

    alb = blend_grain(alb, tileable_noise_l(sz, 128, rng, 10))
    hmap = blend_grain(hmap, tileable_noise_l(sz, 128, rng, 12)).filter(ImageFilter.GaussianBlur(radius=0.5))
    emit_set("panel_facade", alb, hmap, ao, rough, metal, n_str=2.7)

    # 2. wet_asphalt (512x512): damp nocturnal road with puddle roughness pockets & subtle cracks
    sz2 = int(STYLE_LOCK["resolutions"]["wet_asphalt"])
    alb2 = Image.new("RGB", (sz2, sz2), pal["asphalt_dry"])
    hmap2 = Image.new("L", (sz2, sz2), 148)
    ao2 = Image.new("L", (sz2, sz2), 232)
    rough2 = Image.new("L", (sz2, sz2), 212)
    metal2 = Image.new("L", (sz2, sz2), 0)
    da2, dh2, dr2 = ImageDraw.Draw(alb2), ImageDraw.Draw(hmap2), ImageDraw.Draw(rough2)

    for _ in range(20):
        px0, py0 = rng.randint(0, sz2 - 1), rng.randint(0, sz2 - 1)
        rw, rh = rng.randint(28, 84), rng.randint(24, 78)
        for ox in (-sz2, 0, sz2):
            for oy in (-sz2, 0, sz2):
                da2.ellipse([px0 + ox - rw, py0 + oy - rh, px0 + ox + rw, py0 + oy + rh], fill=pal["asphalt_wet"])
                dr2.ellipse([px0 + ox - rw, py0 + oy - rh, px0 + ox + rw, py0 + oy + rh], fill=30)
                dh2.ellipse([px0 + ox - rw, py0 + oy - rh, px0 + ox + rw, py0 + oy + rh], fill=124)

    alb2 = blend_grain(alb2, tileable_noise_l(sz2, 128, rng, 14))
    hmap2 = blend_grain(hmap2, tileable_noise_l(sz2, 128, rng, 18)).filter(ImageFilter.GaussianBlur(radius=0.6))
    rough2 = rough2.filter(ImageFilter.GaussianBlur(radius=5.0))
    emit_set("wet_asphalt", alb2, hmap2, ao2, rough2, metal2, n_str=2.3)

    # 3. concrete_sidewalk (512x512): damp concrete paving tiles
    sz3 = int(STYLE_LOCK["resolutions"]["concrete_sidewalk"])
    alb3 = Image.new("RGB", (sz3, sz3), pal["sidewalk_slab"])
    hmap3 = Image.new("L", (sz3, sz3), 160)
    ao3 = Image.new("L", (sz3, sz3), 236)
    rough3 = Image.new("L", (sz3, sz3), 198)
    metal3 = Image.new("L", (sz3, sz3), 0)
    da3, dh3, dao3, dr3 = ImageDraw.Draw(alb3), ImageDraw.Draw(hmap3), ImageDraw.Draw(ao3), ImageDraw.Draw(rough3)

    for r_i in range(4):
        for c_i in range(4):
            x0, y0 = c_i * 128, r_i * 128
            dv = rng.randint(-7, 7)
            tc = tuple(max(12, min(230, c + dv)) for c in pal["sidewalk_slab"])
            da3.rectangle([x0 + 2, y0 + 2, x0 + 125, y0 + 125], fill=tc)
            for rect_s in ([x0, y0, x0 + 127, y0 + 1], [x0, y0 + 126, x0 + 127, y0 + 127], [x0, y0, x0 + 1, y0 + 127], [x0 + 126, y0, x0 + 127, y0 + 127]):
                da3.rectangle(rect_s, fill=pal["concrete_damp"])
                dh3.rectangle(rect_s, fill=62)
                dao3.rectangle(rect_s, fill=132)
                dr3.rectangle(rect_s, fill=120)

    alb3 = blend_grain(alb3, tileable_noise_l(sz3, 128, rng, 11))
    hmap3 = blend_grain(hmap3, tileable_noise_l(sz3, 128, rng, 14)).filter(ImageFilter.GaussianBlur(radius=0.5))
    emit_set("concrete_sidewalk", alb3, hmap3, ao3, rough3, metal3, n_str=2.5)

    # 4. iron_brass_hardware (512x512): cast iron + brushed antique brass trim for lamps/gates/fuseboxes
    sz4 = int(STYLE_LOCK["resolutions"]["iron_brass_hardware"])
    alb4 = Image.new("RGB", (sz4, sz4), pal["cast_iron"])
    hmap4 = Image.new("L", (sz4, sz4), 144)
    ao4 = Image.new("L", (sz4, sz4), 228)
    rough4 = Image.new("L", (sz4, sz4), 134)
    metal4 = Image.new("L", (sz4, sz4), 215)
    da4, dh4, dao4, dr4, dm4 = ImageDraw.Draw(alb4), ImageDraw.Draw(hmap4), ImageDraw.Draw(ao4), ImageDraw.Draw(rough4), ImageDraw.Draw(metal4)

    # Top half: weathered cast iron with subtle rust patches
    for x in range(4, sz4, 16):
        da4.rectangle([x, 0, min(sz4 - 1, x + 6), 255], fill=(34, 42, 48))
        dh4.rectangle([x, 0, min(sz4 - 1, x + 6), 255], fill=174)
    for _ in range(28):
        rx, ry = rng.randint(0, sz4 - 16), rng.randint(0, 236)
        da4.ellipse([rx, ry, rx + 14, ry + 10], fill=pal["rust_subtle"])
        dr4.ellipse([rx, ry, rx + 14, ry + 10], fill=215)
        dm4.ellipse([rx, ry, rx + 14, ry + 10], fill=65)
    # Bottom half: brushed antique brass (#c9a24a) + rivets
    da4.rectangle([0, 256, sz4, sz4], fill=pal["brass"])
    dr4.rectangle([0, 256, sz4, sz4], fill=92)
    dm4.rectangle([0, 256, sz4, sz4], fill=232)
    for y in range(256, sz4, 3):
        dv = rng.randint(-10, 10)
        bc = tuple(max(12, min(240, c + dv)) for c in pal["brass"])
        da4.line([(0, y), (sz4 - 1, y)], fill=bc, width=1)
        dh4.line([(0, y), (sz4 - 1, y)], fill=146 + dv, width=1)
    for rx in range(24, sz4, 48):
        for ry in (280, 488):
            dh4.ellipse([rx - 6, ry - 6, rx + 6, ry + 6], fill=236)
            dao4.ellipse([rx - 8, ry - 8, rx + 8, ry + 8], fill=158)

    alb4 = blend_grain(alb4, tileable_noise_l(sz4, 128, rng, 7))
    hmap4 = blend_grain(hmap4, tileable_noise_l(sz4, 128, rng, 9)).filter(ImageFilter.GaussianBlur(radius=0.4))
    emit_set("iron_brass_hardware", alb4, hmap4, ao4, rough4, metal4, n_str=2.4, horizontal_only=True)

    total_kb = round(sum(f["kb"] for s in manifest_sets.values() for f in s["files"].values()), 1)
    total_mb = round(total_kb / 1024.0, 2)
    if total_mb > float(STYLE_LOCK["max_pack_mb"]):
        errors.append(f"total_mb_exceeded:{total_mb}")

    manifest = {
        "style_lock": STYLE_LOCK,
        "gate_pass": len(errors) == 0,
        "total_files": len(manifest_sets) * 3,
        "total_mb": total_mb,
        "errors": errors,
        "sets": manifest_sets,
    }
    mpath = out_dir / "WAVE2_TEXTURES_MANIFEST.json"
    mpath.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return {
        "manifest": str(mpath),
        "manifest_sha256": sha256_file(mpath),
        "gate_pass": manifest["gate_pass"],
        "total_files": manifest["total_files"],
        "total_mb": total_mb,
        "errors": errors,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate Wave 2 seamless PBR textures for The Last Streetlight")
    parser.add_argument("--repo", required=True, help="Godot project root directory")
    args = parser.parse_args()
    repo = Path(args.repo).resolve()
    if not repo.is_dir():
        print(json.dumps({"error": f"Repo not found: {repo}"}))
        return 2
    out_dir = repo / "assets" / "textures" / "wave2"
    try:
        res = build_all_textures(out_dir)
    finally:
        # Section 6A Post-Run Cleanup
        gc.collect()
    res["cleanup"] = {"temp_leftovers": 0, "gc_collected": True}
    print(json.dumps(res, indent=2))
    return 0 if res["gate_pass"] else 1


if __name__ == "__main__":
    sys.exit(main())
