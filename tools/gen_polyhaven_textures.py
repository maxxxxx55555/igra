#!/usr/bin/env python3
"""The photo-scanned surfaces of the game (session 36): eight CC0 materials of Poly Haven (https://polyhaven.com/license, CC0 1.0: no attribution is required, the authors are named in docs/ASSET_LICENSES.md) take the place of the
procedural noise sets of tools/gen_pbr_textures.py, and two more scans (the asphalt_04 of the road, the concrete_wall_007 of the sidewalk) become the luminance texture of the street (assets/textures/environment/asphalt.png and concrete.png, read by assets/shaders/soviet_road.gdshader).
The sources are not in the tree: python tools/gen_polyhaven_textures.py <dir> reads <dir>/<set>/Diffuse.jpg, nor_gl.jpg and Rough.jpg (the 1k maps, and <dir>/street_asphalt/Diffuse.jpg for the road; the table SETS names the Poly Haven asset of each set and the URL pattern
https://api.polyhaven.com/files/<asset> lists them), grades the albedo into the palette of docs/STYLE_GUIDE.md (no texel under 16 or over 216, saturation 0.40 at most, the mean of the set held where the dark city wants it) and
writes assets/textures/pbr/<set>_albedo.png, _normal.png and _rough.png at --size px (a missing import sidecar is written as gen_pbr_textures.py does; an existing one stays). The same bytes come out of the same sources.

usage: python tools/gen_polyhaven_textures.py <dir> [--size 512] [--street-size 1024] [--out assets/textures/pbr] [--street assets/textures/environment]
The mean linear luminance of each street texture is printed: it is the `mean_lum` the street builder gives the road shader (scripts/world/street_builder.gd), which divides the texture by it.
"""
import argparse
import pathlib
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from gen_pbr_textures import HIGH, LOW, seam_ratio, to_png, write_import  # noqa: E402

# set name: (Poly Haven asset, target mean of the albedo in sRGB, saturation scale, the albedo is the luminance texture of the street)
SETS = {
    "wet_asphalt": ("asphalt_02", 0.20, 0.45, True),
    "cracked_concrete": ("concrete_layers_02", 0.38, 0.55, True),
    "panel_facade": ("concrete_wall_007", 0.44, 0.55, False),
    "rusted_metal": ("rust_coarse_01", 0.30, 0.90, False),
    "painted_brick": ("brick_4", 0.38, 0.60, False),
    "dead_grass": ("forrest_ground_01", 0.25, 0.60, False),
    "plywood": ("wood_planks_dirt", 0.32, 0.85, False),
    "ceramic_tile": ("worn_tile_floor", 0.48, 0.60, False),
}
# street texture: (the source folder, the Poly Haven asset, the mean of the sRGB luminance, the relative standard deviation the road shader gets around its tint)
STREET = {"asphalt": ("street_asphalt", "asphalt_04", 0.19, 0.22), "concrete": ("panel_facade", "concrete_wall_007", 0.37, 0.14)}
MAX_SATURATION = 0.40


def load(path, size, mode):
    img = Image.open(path).convert(mode)
    return img if img.width == size else img.resize((size, size), Image.LANCZOS)


def grade(img, mean_target, sat_scale):
    """Albedo into the palette: the saturation scaled and capped, the value scaled so the mean lands on the target, every texel inside LOW..HIGH."""
    hsv = np.asarray(img.convert("HSV"), dtype=float) / 255.0
    hsv[..., 1] = np.minimum(hsv[..., 1] * sat_scale, MAX_SATURATION)
    rgb = np.asarray(Image.fromarray(np.round(hsv * 255.0).astype(np.uint8), "HSV").convert("RGB"), dtype=float) / 255.0
    rgb = np.clip(rgb * (mean_target / max(float(rgb.mean()), 1e-6)), LOW, HIGH)
    return rgb


def srgb_to_linear(a):
    return np.where(a <= 0.04045, a / 12.92, ((a + 0.055) / 1.055) ** 2.4)


def street_texture(src, size, mean_target, spread):
    """The luminance of the scan as a grey image of the street: the shader reads only its luminance around the tint of the tile, so the mean is held and the spread around it set (a photograph of a clean slab is flatter than the tile
    wants, one of cracks harder)."""
    grey = np.asarray(load(src, size, "L"), dtype=float) / 255.0
    grey = grey / max(float(grey.mean()), 1e-6)
    grey = 1.0 + (grey - 1.0) * (spread / max(float(grey.std()), 1e-6))
    return np.clip(grey * mean_target, LOW, HIGH)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sources")
    ap.add_argument("--size", type=int, default=512)
    ap.add_argument("--street-size", type=int, default=1024)
    ap.add_argument("--out", default="assets/textures/pbr")
    ap.add_argument("--street", default="assets/textures/environment")
    args = ap.parse_args()
    src = pathlib.Path(args.sources)
    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    for name, (asset, mean_target, sat_scale, _) in SETS.items():
        folder = src / name
        albedo = to_png(grade(load(folder / "Diffuse.jpg", args.size, "RGB"), mean_target, sat_scale), "RGB")
        albedo.save(out / f"{name}_albedo.png", compress_level=9)
        load(folder / "nor_gl.jpg", args.size, "RGB").save(out / f"{name}_normal.png", compress_level=9)
        rough = np.clip(np.asarray(load(folder / "Rough.jpg", args.size, "L"), dtype=float) / 255.0, 0.15, 0.95)
        to_png(rough, "L").save(out / f"{name}_rough.png", compress_level=9)
        for kind in ("albedo", "normal", "rough"):
            if not (out / f"{name}_{kind}.png.import").exists():  # a sidecar Godot has imported keeps its uid; the next import rewrites its paths
                write_import(out / f"{name}_{kind}.png", kind == "normal")
        print("%-17s %-20s seam %.2f  albedo %3d..%3d mean %.3f  %d bytes" % (name, asset, seam_ratio(albedo), np.asarray(albedo).min(), np.asarray(albedo).max(), np.asarray(albedo).mean() / 255.0,
              sum((out / f"{name}_{k}.png").stat().st_size for k in ("albedo", "normal", "rough"))))
    street = pathlib.Path(args.street)
    for file_name, (folder, asset, mean_target, spread) in STREET.items():
        img = to_png(street_texture(src / folder / "Diffuse.jpg", args.street_size, mean_target, spread), "L")
        img.save(street / f"{file_name}.png", compress_level=9)
        linear = float(srgb_to_linear(np.asarray(img, dtype=float) / 255.0).mean())
        print("street %-9s %-18s %dx%d seam %.2f  mean_lum %.4f  %d bytes" % (file_name, asset, img.width, img.height, seam_ratio(img), linear, (street / f"{file_name}.png").stat().st_size))


if __name__ == "__main__":
    main()
