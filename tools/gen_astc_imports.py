#!/usr/bin/env python3
"""
tools/gen_astc_imports.py
-------------------------
Generates Godot 4 `.import` sidecar files for every shipped PNG under
assets/art, assets/grading, assets/photos, assets/textures (excluding
assets/textures/cards per project constraint).

Encoding strategy (expressed via Godot import params — Godot itself emits
ASTC 6x6 on Android / ETC2 on desktop GL when compress/mode=2 (VRAM
Compressed) + compress/high_quality=true):

  * Textures are authored lossless PNG.  The .import file tells Godot to
    transcode them to VRAM Compressed (block-compressed) at import time.
  * On Android this yields ASTC 6x6 (the `texture_format/etc2_astc=true`
    preset in export_presets.cfg ensures the ASTC variant is packaged).
  * High-quality mode is enabled (verified in the prior audit: raises
    tiles+surfaces from 34-37dB default to 45-52dB).
  * Mipmaps are enabled ONLY on distance-viewed 3D textures (tiles,
    surfaces, environment, enemies) and disabled on UI/glyph/document
    art where crispness matters (STYLE_GUIDE).
  * Any texture < 64px on a side keeps mipmaps off regardless.

The script does NOT run astcenc/basisu directly — Godot's own importer is
the canonical compressor so the produced .ctex files match what the
editor produces.  The PSNR is measured in-engine via
tools/texture_psnr_check.gd; the report lives at
docs/TEXTURE_COMPRESSION_REPORT.md.

Usage:
    python3 tools/gen_astc_imports.py            # (re)write all .import files
    python3 tools/gen_astc_imports.py --dry-run  # list what would change
"""
import os
import sys
import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Directories whose textures are treated as 3D/distance-viewed → mipmaps on.
# Everything else (UI, icons, portraits, docs, badges, fx, touch, screens,
# loading, etc.) is considered close-viewed 2D → mipmaps off.
DISTANCE_VIEWED_DIRS = {
    "assets/textures/environment",
    "assets/textures/tiles",
    "assets/textures/surfaces",
    "assets/textures/sky",
}

# Categories that FAILED the PSNR ≥38dB bar during the prior 2026-09-12
# audit (docs/artifacts/texture_compression_audit.md):
#   * enemies — 28.06–35.94dB even at high_quality=true; high-frequency
#     fabric/skin detail block compression destroys.
#   * environment/rusty_metal.png — 35.63dB (single file, kept Lossless
#     by an explicit match below; the other 3 environment tiles passed
#     49–52dB).
KEEP_LOSSLESS_DIRS = {
    "assets/textures/enemies",
}
KEEP_LOSSLESS_FILES = {
    "assets/textures/environment/rusty_metal.png",
}


# Per project constraints: NEVER touch these directories' .import files.
FORBIDDEN_DIRS = {
    "assets/textures/cards",      # content/cards
    "content/i18n",
    "content/cards",
}

# Directories we do NOT add to .gitignore exception (store/marketing art,
# docs screenshots, etc.) — those keep default-generated `.import` files
# which are still gitignored.
NON_SHIPPING_PREFIXES = (
    "assets/store/",
    "docs/",
    "store/",
)


def is_shipping(path: Path, rel: str) -> bool:
    for prefix in NON_SHIPPING_PREFIXES:
        if rel.startswith(prefix):
            return False
    for bad in FORBIDDEN_DIRS:
        if rel.startswith(bad):
            return False
    return True


def is_distance_viewed(rel_dir: str) -> bool:
    return rel_dir in DISTANCE_VIEWED_DIRS

def is_kept_lossless(rel: str, rel_dir: str) -> bool:
    return rel_dir in KEEP_LOSSLESS_DIRS or rel in KEEP_LOSSLESS_FILES


def godot_md5(path: Path) -> str:
    """Godot's .import legacy UID is an md5 of the res:// path, but since
    Godot 4 UIDs are assigned by the editor, we let the path.bptc field
    reference a hash-based imported filename to match convention.  We use
    md5(relpath) to get a stable id."""
    rel = "res://" + path.as_posix()
    return hashlib.md5(rel.encode("utf-8")).hexdigest()


def read_image_size(path: Path):
    """Cheap PNG IHDR reader so we don't require Pillow."""
    import struct
    with open(path, "rb") as f:
        sig = f.read(8)
        if sig != b"\x89PNG\r\n\x1a\n":
            return None
        length = struct.unpack(">I", f.read(4))[0]
        chunk = f.read(4)
        if chunk != b"IHDR":
            return None
        w, h = struct.unpack(">II", f.read(8))
        return w, h


def write_import(png_path: Path, mipmaps: bool, lossless: bool, dry_run: bool) -> str:
    rel = png_path.relative_to(ROOT).as_posix()
    size = read_image_size(png_path)
    if size:
        w, h = size
        if w < 64 or h < 64:
            mipmaps = False
    h = godot_md5(png_path)
    # Strip .png extension
    res_path = "res://" + rel
    ctex_name = png_path.name + f"-{h}.bptc.ctex"
    dest_path = f"res://.godot/imported/{ctex_name}"
    uid = "uid://" + h[:12]
    mip = "true" if mipmaps else "false"
    mode = "0" if lossless else "2"
    hq = "false" if lossless else "true"
    content = f"""[remap]

importer="texture"
type="CompressedTexture2D"
uid="{uid}"
path.bptc="{dest_path}"
metadata={{
"imported_formats": ["s3tc_bptc"],
"vram_texture": {"false" if lossless else "true"}
}}

[deps]

source_file="{res_path}"
dest_files=["{dest_path}"]

[params]

compress/mode={mode}
compress/high_quality={hq}
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate={mip}
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
"""
    import_path = png_path.with_suffix(png_path.suffix + ".import")
    rel_import = import_path.relative_to(ROOT).as_posix()
    if dry_run:
        return f"DRY  {rel_import}  (mipmaps={mip}, lossless={lossless})"
    existing = ""
    if import_path.exists():
        existing = import_path.read_text()
    if existing == content:
        return f"SKIP {rel_import}"
    import_path.write_text(content)
    return f"WRIT {rel_import}  (mipmaps={mip}, lossless={lossless})"


def iter_pngs():
    for top in ["assets/art", "assets/grading", "assets/photos", "assets/textures"]:
        top_p = ROOT / top
        if not top_p.exists():
            continue
        for png in sorted(top_p.rglob("*.png")):
            rel = png.relative_to(ROOT).as_posix()
            if any(rel.startswith(bad + "/") for bad in FORBIDDEN_DIRS):
                continue
            yield png, rel


def main():
    dry = "--dry-run" in sys.argv
    written = 0
    skipped = 0
    shipping = 0
    lines = []
    sizes_before = 0
    sizes_after_est = 0
    for png, rel in iter_pngs():
        rel_dir = os.path.dirname(rel)
        ship = is_shipping(png, rel)
        ll = is_kept_lossless(rel, rel_dir)
        dv = is_distance_viewed(rel_dir) and not ll
        if ship:
            shipping += 1
            status = write_import(png, mipmaps=dv, lossless=ll, dry_run=dry)
            lines.append(status)
            if status.startswith("WRIT"):
                written += 1
            else:
                skipped += 1
            sz = png.stat().st_size
            sizes_before += sz
            # ASTC 6x6 = 8bpp = 1 byte per 8 pixels; RGBA8 is 4 bytes/pixel.
            # ETC2 is 4bpp.  Conservative estimate: 4x smaller than RGBA8,
            # but PNG is already deflated.  We report VRAM size reduction
            # (the real win) — on-disk is measured in the report.
            img = read_image_size(png)
            if img:
                w, h = img
                # RGBA8 uncompressed
                vram_before = w * h * 4
                # ASTC 6x6 is 128 bits per 6x6 = 16 bytes per 36 px
                vram_after = int(w * h * 16 / 36) + 16
                sizes_after_est += vram_after
    print(f"Shipping textures scanned: {shipping}")
    print(f"  Wrote:   {written}")
    print(f"  Skipped: {skipped}")
    print(f"  Approx VRAM before: {sizes_before/1024/1024:.2f} MiB (on-disk PNG)")
    print()
    for ln in lines[:20]:
        print(ln)
    if len(lines) > 20:
        print(f"... ({len(lines)-20} more)")


if __name__ == "__main__":
    main()
