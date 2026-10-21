#!/usr/bin/env python3
"""The PBR texture sets of the props and the street (WORKQUEUE D1): eight tileable sets, each an albedo (sRGB), a normal map (tangent space, green up, from the height by a Sobel filter of strength 2) and a roughness map.
Every set is made of band-passed noise filtered in the frequency domain, so it repeats by construction; the same seeds give the same bytes. The albedo is held inside the palette of docs/STYLE_GUIDE.md: nothing darker than #101010 or
lighter than #d8d8d8, no pure black or white texel, and no per-pixel grain (it murders compression: the detail is low-frequency blotches, grooves and joints).
The files go to assets/textures/pbr/<set>_albedo.png, _normal.png, _rough.png; scripts/world/pbr_sets.gd puts a set on a material by its name.

usage: python tools/gen_pbr_textures.py [--size 512] [--out assets/textures/pbr] [--sheet <file.png>]
  --sheet writes a contact sheet of every albedo tiled 2 x 2 (read it for seams); the seam ratios are always printed.
"""
import argparse
import pathlib

import numpy as np
from PIL import Image

SETS = ["wet_asphalt", "cracked_concrete", "panel_facade", "rusted_metal", "painted_brick", "dead_grass", "plywood", "ceramic_tile"]
LOW, HIGH = 16 / 255.0, 216 / 255.0
NORMAL_STRENGTH = 2.0


def band(seed, size, lo, hi, stretch=(1.0, 1.0)):
    """Periodic noise of the features between `lo` and `hi` cycles an image wide, in 0..1; `stretch` multiplies the frequency along (x, y): (4, 1) makes vertical streaks."""
    white = np.random.default_rng(seed).standard_normal((size, size))
    f = np.fft.fftfreq(size) * size
    fx, fy = np.meshgrid(f, f)
    r = np.sqrt((fx / stretch[0]) ** 2 + (fy / stretch[1]) ** 2)
    keep = np.exp(-((r / hi) ** 4)) * (1.0 - np.exp(-((r / max(lo, 0.5)) ** 2)))
    out = np.real(np.fft.ifft2(np.fft.fft2(white) * keep / np.maximum(r, 1.0) ** 0.7))
    return (out - out.min()) / (out.max() - out.min())


def smooth(x, a, b):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def grid(size, cells, width, offset_rows=False):
    """1 on the joints of a grid of `cells` x `cells` (the rows of a brick wall shifted half a cell when offset_rows), 0 inside."""
    y, x = np.mgrid[0:size, 0:size]
    step = size // cells
    if offset_rows:
        x = (x + (y // step % 2) * step // 2) % size
    half = width // 2  # a joint is centred on the edge of its cell, so one stands across the edge of the image and the texture tiles
    return (((x + half) % step < width) | ((y + half) % step < width)).astype(float)


def cell_values(seed, size, cells, offset_rows=False):
    """A random value for each cell of the grid, spread over its pixels."""
    values = np.random.default_rng(seed).random((cells, cells))
    y, x = np.mgrid[0:size, 0:size]
    step = size // cells
    if offset_rows:
        x = (x + (y // step % 2) * step // 2) % size
    return values[(y // step) % cells, (x // step) % cells]


def tint(base, amount):
    return np.array(base)[None, None, :] * amount[..., None]


def wet_asphalt(s):
    patch, mid = band(1, s, 1, 6), band(2, s, 6, 24)
    puddle = smooth(patch, 0.55, 0.72)
    flecks = smooth(band(3, s, 30, 70), 0.80, 0.92)
    alb = tint((0.105, 0.115, 0.135), 0.8 + 0.4 * mid) * (1.0 - 0.3 * puddle[..., None]) + flecks[..., None] * 0.05
    return alb, 0.6 * mid - 0.2 * puddle, 0.84 - 0.58 * puddle


def cracked_concrete(s):
    blot, mid = band(4, s, 1, 8), band(5, s, 8, 26)
    crack = smooth(1.0 - 2.0 * np.abs(band(6, s, 2, 12) - 0.5), 0.965, 0.995)
    alb = tint((0.30, 0.31, 0.32), 0.75 + 0.35 * blot + 0.15 * mid) * (1.0 - 0.6 * crack[..., None])
    return alb, 0.5 * mid + 0.2 * blot - 0.5 * crack, 0.9 - 0.1 * crack


def panel_facade(s):
    joints = grid(s, 4, 5)
    bevel = grid(s, 4, 9) - joints
    streak = band(7, s, 2, 18, stretch=(5.0, 1.0))
    stain = smooth(band(8, s, 1, 5), 0.5, 0.8)
    alb = tint((0.24, 0.27, 0.31), 0.8 + 0.3 * streak - 0.2 * stain) * (1.0 - 0.55 * joints[..., None]) * (1.0 - 0.1 * bevel[..., None])
    return alb, 0.5 - 0.5 * joints + 0.08 * streak - 0.05 * bevel, 0.92 - 0.1 * stain


def rusted_metal(s):
    rust = smooth(band(9, s, 2, 14), 0.45, 0.66)
    scratch = band(10, s, 8, 40, stretch=(1.0, 8.0))
    steel = tint((0.28, 0.30, 0.32), 0.85 + 0.25 * scratch)
    flake = tint((0.30, 0.21, 0.15), 0.7 + 0.5 * band(11, s, 6, 24))
    alb = steel * (1.0 - rust[..., None]) + flake * rust[..., None]
    return alb, 0.3 * scratch + 0.4 * rust * band(12, s, 6, 24), 0.45 + 0.47 * rust


def painted_brick(s):
    mortar = grid(s, 16, 3, offset_rows=True)
    peel = smooth(band(13, s, 1.5, 6), 0.6, 0.72)
    per_brick = cell_values(14, s, 16, offset_rows=True)
    brick = tint((0.28, 0.20, 0.17), 0.75 + 0.5 * per_brick)
    paint = tint((0.22, 0.27, 0.25), 0.85 + 0.25 * band(15, s, 2, 10))
    alb = (paint * (1.0 - peel[..., None]) + brick * peel[..., None]) * (1.0 - 0.45 * mortar[..., None])
    return alb, 0.55 - 0.5 * mortar - 0.1 * peel + 0.05 * per_brick, 0.88 + 0.05 * peel


def dead_grass(s):
    strand = band(16, s, 6, 40, stretch=(5.0, 1.0))
    blot = band(17, s, 1, 6)
    alb = tint((0.28, 0.26, 0.19), 0.65 + 0.5 * strand) * (0.85 + 0.3 * blot[..., None])
    return alb, strand, np.full((s, s), 0.96)


def plywood(s):
    y = np.arange(s)[:, None] * np.ones((1, s))
    rings = np.sin(2.0 * np.pi * (11.0 * y / s + 1.6 * band(18, s, 1, 4) + 0.12 * band(19, s, 8, 24)))
    grain = smooth(rings, 0.2, 0.95)
    alb = tint((0.33, 0.27, 0.21), 0.82 + 0.25 * band(20, s, 2, 9) - 0.22 * grain)
    return alb, 0.35 * grain + 0.1 * band(21, s, 6, 20), 0.8 - 0.08 * grain


def ceramic_tile(s):
    grout = grid(s, 8, 3)
    craze = smooth(1.0 - 2.0 * np.abs(band(22, s, 6, 20) - 0.5), 0.965, 0.995)
    dirt = band(23, s, 1, 6)
    alb = tint((0.56, 0.58, 0.56), 0.8 + 0.22 * dirt - 0.12 * cell_values(24, s, 8)) * (1.0 - 0.7 * craze[..., None] * (1.0 - grout[..., None])) * (1.0 - 0.6 * grout[..., None])
    return alb, 0.5 - 0.5 * grout - 0.05 * craze, 0.28 + 0.62 * grout + 0.1 * dirt


def normal_map(height):
    """Tangent space, green up (the OpenGL convention Godot reads): from the height by a Sobel filter that wraps, so the maps tile too."""
    h = height.astype(float)
    gx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 2.0 + np.roll(np.roll(h, -1, 0), -1, 1) - np.roll(np.roll(h, -1, 0), 1, 1) + np.roll(np.roll(h, 1, 0), -1, 1) - np.roll(np.roll(h, 1, 0), 1, 1)
    gy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 2.0 + np.roll(np.roll(h, -1, 1), -1, 0) - np.roll(np.roll(h, 1, 1), -1, 0) + np.roll(np.roll(h, -1, 1), 1, 0) - np.roll(np.roll(h, 1, 1), 1, 0)
    n = np.stack([-gx * NORMAL_STRENGTH, gy * NORMAL_STRENGTH, np.ones_like(h) * 4.0], axis=-1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return n * 0.5 + 0.5


def to_png(array, mode):
    return Image.fromarray(np.round(np.clip(array, 0.0, 1.0) * 255.0).astype(np.uint8), mode)


def write_import(png, normal=False):
    """The sidecar of a map, with the import options a material wants (docs: Godot 4 compress/mode 2 = VRAM compressed, mipmaps on for the 3D view); Godot adds the uid and the paths at the next import.
    A normal map is flagged as one and channel-packed; an albedo is sampled as sRGB and a roughness as linear by the material that uses it, not by the file."""
    png.with_name(png.name + ".import").write_text(
        '[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]\n\n'
        "compress/mode=2\ncompress/high_quality=true\ncompress/lossy_quality=0.7\ncompress/uastc_level=0\ncompress/rdo_quality_loss=0.0\ncompress/hdr_compression=1\n"
        f"compress/normal_map={1 if normal else 0}\ncompress/channel_pack={1 if normal else 0}\nmipmaps/generate=true\nmipmaps/limit=-1\nroughness/mode=0\nroughness/src_normal=\"\"\n"
        "process/channel_remap/red=0\nprocess/channel_remap/green=1\nprocess/channel_remap/blue=2\nprocess/channel_remap/alpha=3\nprocess/fix_alpha_border=true\nprocess/premult_alpha=false\n"
        "process/normal_map_invert_y=false\nprocess/hdr_as_srgb=false\nprocess/hdr_clamp_exposure=false\nprocess/size_limit=0\ndetect_3d/compress_to=1\n",
        encoding="utf-8", newline="\n")


def seam_ratio(img):
    """The mean step across the edge of the image over the mean step between two neighbours inside it: about 1 for a texture that tiles, a lot more for one that does not."""
    a = np.asarray(img.convert("L"), dtype=float)
    inside = (np.abs(np.diff(a, axis=0)).mean() + np.abs(np.diff(a, axis=1)).mean()) / 2.0
    edge = (np.abs(a[0] - a[-1]).mean() + np.abs(a[:, 0] - a[:, -1]).mean()) / 2.0
    return edge / max(inside, 1e-6)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--size", type=int, default=512)
    ap.add_argument("--out", default="assets/textures/pbr")
    ap.add_argument("--sheet", default="")
    args = ap.parse_args()
    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    tiles = []
    for name in SETS:
        albedo, height, rough = globals()[name](args.size)
        albedo = np.clip(albedo, LOW, HIGH)
        rough = np.clip(rough, 0.15, 0.95)
        img = to_png(albedo, "RGB")
        img.save(out / f"{name}_albedo.png", compress_level=9)
        to_png(normal_map(height), "RGB").save(out / f"{name}_normal.png", compress_level=9)
        to_png(rough, "L").save(out / f"{name}_rough.png", compress_level=9)
        for kind in ("albedo", "normal", "rough"):
            write_import(out / f"{name}_{kind}.png", kind == "normal")
        tiles.append(img)
        lo = np.asarray(img).min()
        hi = np.asarray(img).max()
        print("%-17s seam ratio %.2f  albedo texels %3d..%3d  %d bytes" % (name, seam_ratio(img), lo, hi, sum((out / f"{name}_{k}.png").stat().st_size for k in ("albedo", "normal", "rough"))))
    if args.sheet:
        cell = 256
        sheet = Image.new("RGB", (cell * 4, cell * 2), (24, 24, 24))
        for i, img in enumerate(tiles):
            two = Image.new("RGB", (img.width * 2, img.height * 2))
            for k in range(4):
                two.paste(img, ((k % 2) * img.width, (k // 2) * img.height))
            sheet.paste(two.resize((cell, cell), Image.LANCZOS), ((i % 4) * cell, (i // 4) * cell))
        pathlib.Path(args.sheet).parent.mkdir(parents=True, exist_ok=True)
        sheet.save(args.sheet)
        print("sheet", args.sheet)


if __name__ == "__main__":
    main()
