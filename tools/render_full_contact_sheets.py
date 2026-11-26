#!/usr/bin/env python3
"""Builds high-resolution labeled contact sheets for Mobile HUD, Map, All 11 Districts, and UI."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError as exc:
    print(f"FAIL: Pillow missing ({exc})", file=sys.stderr)
    raise SystemExit(1)

BG_COLOR = (10, 15, 18)
HEADER_BG = (15, 19, 20)
BORDER_COLOR = (90, 74, 42)
TEXT_COLOR = (230, 223, 209)
ACCENT_COLOR = (212, 169, 78)


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def build_sheet(
    items: list[tuple[str, Path]],
    out_path: Path,
    cols: int,
    tile_w: int = 640,
    tile_h: int = 360,
    title: str = "",
) -> dict[str, object]:
    if not items:
        return {"sheet": str(out_path), "count": 0, "status": "EMPTY"}

    pad = 16
    label_h = 30
    top_h = 46 if title else pad
    rows = math.ceil(len(items) / cols)
    sheet_w = pad + cols * (tile_w + pad)
    sheet_h = top_h + rows * (tile_h + label_h + pad) + pad

    canvas = Image.new("RGB", (sheet_w, sheet_h), BG_COLOR)
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.load_default()

    if title:
        draw.rectangle([0, 0, sheet_w, top_h - 6], fill=HEADER_BG)
        draw.line([0, top_h - 6, sheet_w, top_h - 6], fill=BORDER_COLOR, width=2)
        draw.text((pad, 14), title, fill=ACCENT_COLOR, font=font)

    for idx, (label, img_path) in enumerate(items):
        r = idx // cols
        c = idx % cols
        x = pad + c * (tile_w + pad)
        y = top_h + r * (tile_h + label_h + pad)

        with Image.open(img_path) as im:
            im_rgb = im.convert("RGB")
            im_rgb.thumbnail((tile_w, tile_h), Image.Resampling.LANCZOS)
            ox = x + (tile_w - im_rgb.width) // 2
            oy = y + (tile_h - im_rgb.height) // 2
            draw.rectangle([x - 1, y - 1, x + tile_w + 1, y + tile_h + label_h], outline=BORDER_COLOR, width=1)
            canvas.paste(im_rgb, (ox, oy))

        draw.rectangle([x, y + tile_h, x + tile_w, y + tile_h + label_h], fill=HEADER_BG)
        draw.text((x + 8, y + tile_h + 9), label[:72], fill=TEXT_COLOR, font=font)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out_path, optimize=True)
    return {
        "sheet": str(out_path),
        "count": len(items),
        "size": [sheet_w, sheet_h],
        "sha256": sha256_file(out_path),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Compile high-res visual review sheets.")
    parser.add_argument("--in-dir", type=Path, required=True, help="Directory with showcase PNGs.")
    parser.add_argument("--out-dir", type=Path, required=True, help="Output directory for sheets.")
    args = parser.parse_args()

    in_dir = args.in_dir.resolve()
    out_dir = args.out_dir.resolve()
    pngs = sorted(in_dir.glob("*.png"))
    if not pngs:
        print(f"FAIL: no PNG files in {in_dir}", file=sys.stderr)
        return 1

    mobile_map = [(p.stem, p) for p in pngs if p.stem.startswith(("mobile_", "map_"))]
    districts = [(p.stem, p) for p in pngs if p.stem.startswith("dist_")]
    ui_combat = [(p.stem, p) for p in pngs if p.stem.startswith(("ui_", "combat_", "boss_"))]

    results = [
        build_sheet(mobile_map, out_dir / "SHEET_1_MOBILE_HUD_AND_MAP.png", cols=2, tile_w=760, tile_h=400, title="SHEET 1: MOBILE TOUCH HUD (PHONE VIEW) + LIGHT-REVEALED MAP"),
        build_sheet(districts, out_dir / "SHEET_2_ALL_11_DISTRICTS.png", cols=3, tile_w=600, tile_h=338, title="SHEET 2: ALL 11 CITY DISTRICTS (CANON ACCENTS & LIGHTING)"),
        build_sheet(ui_combat, out_dir / "SHEET_3_UI_AND_COMBAT_POLISH.png", cols=2, tile_w=720, tile_h=405, title="SHEET 3: OVERHAULED MENUS, SKILL TREE, SHOP & COMBAT VIGNETTE"),
    ]
    print(json.dumps(results, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
