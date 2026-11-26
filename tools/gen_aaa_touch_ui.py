#!/usr/bin/env python3
"""Deterministic AAA tactical touch-button plate & 15-icon generator for Last Streetlight."""

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
    from PIL import Image, ImageDraw
except ImportError as exc:
    print(f"FAIL: missing dependency ({exc}). Install pillow and numpy.", file=sys.stderr)
    raise SystemExit(1)

STYLE_LOCK: dict[str, Any] = {
    "seed": 47109,
    "size_px": 128,
    "supersample": 2,
    "palette": {
        "bg_idle": (15, 19, 20),       # #0f1314
        "bg_primary": (22, 30, 34),    # #161e22
        "bg_pressed": (58, 45, 22),    # warm sodium press
        "bevel_inner": (34, 42, 46),   # metallic inner rim
        "bronze_dim": (90, 74, 42),    # #5a4a2a
        "brass": (201, 162, 74),       # #c9a24a
        "sodium": (212, 169, 78),      # #d4a94e
        "bone": (230, 223, 209),       # #e6dfd1
    },
    "clamp_min": 19,
    "clamp_max": 240,
}


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def octagon_points(size: int, pad: float, chamfer: float) -> list[tuple[float, float]]:
    x0, y0 = pad, pad
    x1, y1 = size - 1 - pad, size - 1 - pad
    c = chamfer
    return [
        (x0 + c, y0), (x1 - c, y0),
        (x1, y0 + c), (x1, y1 - c),
        (x1 - c, y1), (x0 + c, y1),
        (x0, y1 - c), (x0, y0 + c),
    ]


def render_tactical_plate(
    rng: np.random.Generator,
    bg_rgb: tuple[int, int, int],
    rim_rgb: tuple[int, int, int],
    alpha_fill: int,
    rim_width: int,
    is_circle: bool = False,
    accent_bar: bool = False,
) -> Image.Image:
    s = STYLE_LOCK["size_px"] * STYLE_LOCK["supersample"]
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    pad = 8.0
    chamfer = 34.0
    if is_circle:
        bbox = [pad, pad, s - 1 - pad, s - 1 - pad]
        draw.ellipse(bbox, fill=(*bg_rgb, alpha_fill))
        inner_pad = pad + rim_width + 4.0
        draw.ellipse(
            [inner_pad, inner_pad, s - 1 - inner_pad, s - 1 - inner_pad],
            outline=(*STYLE_LOCK["palette"]["bevel_inner"], 145),
            width=2,
        )
        draw.ellipse(bbox, outline=(*rim_rgb, 245), width=rim_width)
    else:
        pts = octagon_points(s, pad, chamfer)
        draw.polygon(pts, fill=(*bg_rgb, alpha_fill))
        inner_pts = octagon_points(s, pad + rim_width + 4.0, max(12.0, chamfer - 4.0))
        draw.polygon(inner_pts, outline=(*STYLE_LOCK["palette"]["bevel_inner"], 140), width=2)
        draw.polygon(pts, outline=(*rim_rgb, 245), width=rim_width)
        for cx, cy in [
            (pad + chamfer, pad),
            (s - 1 - pad - chamfer, pad),
            (pad + chamfer, s - 1 - pad),
            (s - 1 - pad - chamfer, s - 1 - pad),
        ]:
            draw.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=(*rim_rgb, 220))
        if accent_bar:
            draw.rectangle(
                [pad + 2, pad + chamfer + 6, pad + 10, s - 1 - pad - chamfer - 6],
                fill=(*STYLE_LOCK["palette"]["sodium"], 250),
            )

    arr = np.array(img, dtype=np.float32)
    mask = arr[:, :, 3] > 20.0
    yy = np.linspace(-1.0, 1.0, s, dtype=np.float32)[:, None]
    grad = -yy * 10.0
    grain = rng.normal(0.0, 2.0, size=(s, s)).astype(np.float32)
    for ch in range(3):
        arr[:, :, ch] = np.where(
            mask,
            np.clip(arr[:, :, ch] + grad + grain, STYLE_LOCK["clamp_min"], STYLE_LOCK["clamp_max"]),
            arr[:, :, ch],
        )

    out = Image.fromarray(np.clip(np.round(arr), 0, 255).astype(np.uint8), mode="RGBA")
    return out.resize((STYLE_LOCK["size_px"], STYLE_LOCK["size_px"]), Image.Resampling.LANCZOS)


def render_icon(name: str) -> Image.Image:
    s = STYLE_LOCK["size_px"] * STYLE_LOCK["supersample"]
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    bone = (*STYLE_LOCK["palette"]["bone"], 255)
    brass = (*STYLE_LOCK["palette"]["brass"], 255)
    sodium = (*STYLE_LOCK["palette"]["sodium"], 255)
    c = s * 0.5
    w = 9

    if name == "attack":
        r = 56
        d.ellipse([c - r, c - r, c + r, c + r], outline=sodium, width=w)
        d.ellipse([c - 10, c - 10, c + 10, c + 10], fill=bone)
        for dx, dy in [(1, 0), (-1, 0), (0, 1), (0, -1)]:
            d.line([c + dx * 28, c + dy * 28, c + dx * 76, c + dy * 76], fill=bone, width=w)
    elif name == "interact":
        d.rounded_rectangle([c - 34, c - 46, c + 34, c + 48], radius=14, outline=sodium, width=w)
        d.line([c, c - 18, c, c + 24], fill=bone, width=w + 2)
        d.ellipse([c - 14, c - 30, c + 14, c - 2], fill=sodium)
    elif name == "melee":
        d.line([c - 48, c + 48, c + 36, c - 36], fill=bone, width=w + 3)
        d.polygon([(c + 18, c - 50), (c + 56, c - 56), (c + 44, c - 14)], fill=sodium)
        d.line([c - 32, c + 12, c - 12, c + 32], fill=brass, width=w)
    elif name == "jump":
        for dy in (-22, 16):
            d.line([(c - 44, c + dy + 22), (c, c + dy - 18), (c + 44, c + dy + 22)], fill=bone, width=w, joint="curve")
    elif name == "dodge":
        for dx in (-18, 22):
            d.line([(c + dx - 22, c - 36), (c + dx + 16, c), (c + dx - 22, c + 36)], fill=bone, width=w, joint="curve")
        d.line([c - 58, c, c - 24, c], fill=sodium, width=w)
    elif name == "reload":
        d.arc([c - 48, c - 48, c + 48, c + 48], start=35, end=315, fill=bone, width=w)
        d.polygon([(c + 30, c - 48), (c + 60, c - 30), (c + 26, c - 16)], fill=sodium)
    elif name == "sprint":
        for dx in (-26, 8):
            d.line([(c + dx, c - 34), (c + dx + 30, c), (c + dx, c + 34)], fill=sodium if dx > 0 else bone, width=w, joint="curve")
        d.line([c - 52, c + 48, c + 52, c + 48], fill=brass, width=6)
    elif name == "stealth":
        d.arc([c - 56, c - 28, c + 56, c + 44], start=195, end=345, fill=bone, width=w)
        d.arc([c - 56, c - 44, c + 56, c + 28], start=15, end=165, fill=bone, width=w)
        d.ellipse([c - 16, c - 16, c + 16, c + 16], outline=sodium, width=w)
    elif name == "flash":
        d.polygon([(c - 54, c - 14), (c - 6, c - 14), (c + 12, c - 28), (c + 12, c + 28), (c - 6, c + 14), (c - 54, c + 14)], outline=bone, width=w)
        for dy in (-30, 0, 30):
            d.line([c + 26, c + dy * 0.4, c + 58, c + dy], fill=sodium, width=w - 1)
    elif name == "uv":
        d.ellipse([c - 22, c - 22, c + 22, c + 22], outline=sodium, width=w)
        for r in (44, 62):
            d.arc([c - r, c - r, c + r, c + r], start=-45, end=45, fill=bone, width=w - 1)
            d.arc([c - r, c - r, c + r, c + r], start=135, end=225, fill=bone, width=w - 1)
    elif name == "strobe":
        for k in range(8):
            ang = k * math.pi / 4.0
            r0 = 18.0
            r1 = 58.0 if k % 2 == 0 else 42.0
            d.line([c + math.cos(ang) * r0, c + math.sin(ang) * r0, c + math.cos(ang) * r1, c + math.sin(ang) * r1], fill=sodium if k % 2 == 0 else bone, width=w)
    elif name == "wheel":
        d.ellipse([c - 50, c - 50, c + 50, c + 50], outline=bone, width=w)
        d.ellipse([c - 16, c - 16, c + 16, c + 16], outline=sodium, width=w)
        for ang in (0.0, math.pi * 0.5, math.pi, math.pi * 1.5):
            d.line([c + math.cos(ang) * 18, c + math.sin(ang) * 18, c + math.cos(ang) * 50, c + math.sin(ang) * 50], fill=brass, width=w - 1)
    elif name == "inventory":
        d.rounded_rectangle([c - 40, c - 30, c + 40, c + 52], radius=14, outline=bone, width=w)
        d.arc([c - 22, c - 54, c + 22, c - 10], start=180, end=360, fill=sodium, width=w)
        d.line([c - 38, c + 4, c + 38, c + 4], fill=brass, width=w - 1)
        d.rectangle([c - 10, c - 6, c + 10, c + 16], fill=sodium)
    elif name == "workbench":
        d.ellipse([c - 36, c - 36, c + 36, c + 36], outline=bone, width=w)
        d.ellipse([c - 14, c - 14, c + 14, c + 14], outline=sodium, width=w)
        for k in range(6):
            ang = k * math.pi / 3.0
            d.line([c + math.cos(ang) * 34, c + math.sin(ang) * 34, c + math.cos(ang) * 52, c + math.sin(ang) * 52], fill=brass, width=w + 2)
    elif name == "map":
        pts = [
            (c - 52, c - 34), (c - 18, c - 46), (c + 18, c - 34), (c + 52, c - 46),
            (c + 52, c + 34), (c + 18, c + 46), (c - 18, c + 34), (c - 52, c + 46),
        ]
        d.polygon(pts, outline=bone, width=w)
        d.line([c - 18, c - 44, c - 18, c + 34], fill=brass, width=6)
        d.line([c + 18, c - 34, c + 18, c + 44], fill=brass, width=6)
        d.ellipse([c - 6, c - 6, c + 6, c + 6], fill=sodium)
    else:
        raise ValueError(f"Unknown icon: {name}")

    return img.resize((STYLE_LOCK["size_px"], STYLE_LOCK["size_px"]), Image.Resampling.LANCZOS)


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate AAA unified touch UI plates and 15 icons.")
    parser.add_argument("--out-dir", type=Path, default=Path("assets/textures/ui_craft/touch_aaa"))
    args = parser.parse_args()

    out_dir = args.out_dir.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    rng = np.random.default_rng(STYLE_LOCK["seed"])
    p = STYLE_LOCK["palette"]

    plates = [
        ("plate_primary_normal.png", p["bg_primary"], p["brass"], 212, 5, True, False),
        ("plate_primary_pressed.png", p["bg_pressed"], p["sodium"], 238, 6, True, False),
        ("plate_interact_normal.png", p["bg_primary"], p["sodium"], 206, 4, False, True),
        ("plate_interact_pressed.png", p["bg_pressed"], p["sodium"], 238, 5, False, True),
        ("plate_arc_normal.png", p["bg_idle"], p["bronze_dim"], 172, 3, False, False),
        ("plate_arc_pressed.png", p["bg_pressed"], p["brass"], 228, 4, False, False),
        ("plate_dock_normal.png", p["bg_idle"], p["bronze_dim"], 156, 3, False, False),
        ("plate_dock_pressed.png", p["bg_pressed"], p["brass"], 224, 4, False, False),
    ]

    records: list[dict[str, Any]] = []
    for fname, bg, rim, alpha, rw, is_circ, acc in plates:
        im = render_tactical_plate(rng, bg, rim, alpha, rw, is_circle=is_circ, accent_bar=acc)
        fp = out_dir / fname
        im.save(fp, optimize=True)
        records.append({"file": fname, "kind": "plate", "size": list(im.size), "sha256": sha256_file(fp)})

    icons = [
        "attack", "interact", "melee", "jump", "dodge", "reload",
        "sprint", "stealth", "flash", "uv", "strobe", "wheel",
        "inventory", "workbench", "map",
    ]
    for icon_name in icons:
        im = render_icon(icon_name)
        fname = f"icon_touch_{icon_name}.png"
        fp = out_dir / fname
        im.save(fp, optimize=True)
        records.append({"file": fname, "kind": "icon", "size": list(im.size), "sha256": sha256_file(fp)})

    manifest_path = out_dir / "manifest_touch_aaa.json"
    tmp = manifest_path.with_suffix(".json.tmp")
    tmp.write_text(json.dumps({"style_lock": STYLE_LOCK, "assets": records}, indent=2) + "\n", encoding="utf-8", newline="\n")
    os.replace(tmp, manifest_path)
    print(json.dumps({"generated": len(records), "manifest": str(manifest_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
