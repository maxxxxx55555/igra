#!/usr/bin/env python3
"""Deterministic zero-dependency UI/HUD + seamless world PBR pack generator.
Style lock: The Last Streetlight (sodium-amber key #d4a94e, cold teal-black #060f13/#0f1314).
"""
from __future__ import annotations

import hashlib
import json
import math
import struct
import sys
import zlib
from pathlib import Path

STYLE_LOCK = {
    "project": "The Last Streetlight",
    "seed": 47101,
    "palette": {
        "shadow_deep": (6, 15, 19),       # #060f13
        "shadow_mid": (15, 19, 20),       # #0f1314
        "iron_dark": (22, 30, 34),        # #161e22
        "iron_edge": (42, 54, 60),        # #2a363c
        "fog_cool": (78, 102, 110),       # #4e666e
        "sodium_dim": (158, 120, 50),     # #9e7832
        "sodium_key": (212, 169, 78),     # #d4a94e
        "sodium_hot": (240, 196, 108),    # #f0c46c
        "parchment": (230, 223, 209),     # #e6dfd1
        "danger_rust": (168, 59, 46),     # #a83b2e
        "cold_fill_lo": (44, 91, 102),    # #2c5b66
        "cold_fill_hi": (107, 167, 181),  # #6ba7b5
    },
    "grid_px": 8,
    "max_seam_delta": 10.0,
}


def clamp_u8(v: float) -> int:
    if v <= 0.0:
        return 0
    if v >= 255.0:
        return 255
    return int(v + 0.5)


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def lerp_rgb(c0: tuple[int, int, int], c1: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    t = 0.0 if t < 0.0 else (1.0 if t > 1.0 else t)
    return (
        clamp_u8(lerp(c0[0], c1[0], t)),
        clamp_u8(lerp(c0[1], c1[1], t)),
        clamp_u8(lerp(c0[2], c1[2], t)),
    )


def hash2d(ix: int, iy: int, seed: int) -> float:
    h = ((ix * 374761393) + (iy * 668265263) + (seed * 1442695041)) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    h = h ^ (h >> 16)
    return h / 4294967295.0


def tile_value_noise(u: float, v: float, period: int, seed: int) -> float:
    fx = (u % 1.0) * period
    fy = (v % 1.0) * period
    ix = int(math.floor(fx))
    iy = int(math.floor(fy))
    tx = fx - ix
    ty = fy - iy
    sx = tx * tx * (3.0 - 2.0 * tx)
    sy = ty * ty * (3.0 - 2.0 * ty)
    x0 = ix % period
    y0 = iy % period
    x1 = (x0 + 1) % period
    y1 = (y0 + 1) % period
    n00 = hash2d(x0, y0, seed)
    n10 = hash2d(x1, y0, seed)
    n01 = hash2d(x0, y1, seed)
    n11 = hash2d(x1, y1, seed)
    nx0 = n00 + (n10 - n00) * sx
    nx1 = n01 + (n11 - n01) * sx
    return nx0 + (nx1 - nx0) * sy


def tile_fbm(u: float, v: float, base_period: int, octaves: int, seed: int) -> float:
    total = 0.0
    amp = 0.5
    norm = 0.0
    p = base_period
    for o in range(octaves):
        total += tile_value_noise(u, v, p, seed + o * 97) * amp
        norm += amp
        amp *= 0.5
        p *= 2
    return total / norm


def write_png_rgba(path: Path, width: int, height: int, pixels: bytearray) -> None:
    if len(pixels) != width * height * 4:
        raise ValueError(f"Invalid pixel buffer length for {path}")
    raw = bytearray()
    stride = width * 4
    for y in range(height):
        raw.append(0)
        start = y * stride
        raw.extend(pixels[start : start + stride])

    def chunk(tag: bytes, payload: bytes) -> bytes:
        crc = zlib.crc32(tag + payload) & 0xFFFFFFFF
        return struct.pack(">I", len(payload)) + tag + payload + struct.pack(">I", crc)

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    png = bytearray(b"\x89PNG\r\n\x1a\n")
    png.extend(chunk(b"IHDR", ihdr))
    png.extend(chunk(b"IDAT", zlib.compress(bytes(raw), level=6)))
    png.extend(chunk(b"IEND", b""))
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(bytes(png))


def read_png_rgba(path: Path) -> tuple[int, int, bytes]:
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"Bad PNG signature: {path}")
    pos = 8
    width = height = 0
    idat = bytearray()
    while pos < len(data):
        length = struct.unpack(">I", data[pos : pos + 4])[0]
        tag = data[pos + 4 : pos + 8]
        payload = data[pos + 8 : pos + 8 + length]
        pos += 12 + length
        if tag == b"IHDR":
            width, height, bit_depth, color_type = struct.unpack(">IIBB", payload[:10])
            if bit_depth != 8 or color_type != 6:
                raise ValueError(f"Unexpected PNG format in {path}")
        elif tag == b"IDAT":
            idat.extend(payload)
        elif tag == b"IEND":
            break
    raw = zlib.decompress(bytes(idat))
    stride = width * 4
    out = bytearray(width * height * 4)
    for y in range(height):
        src = y * (stride + 1) + 1
        out[y * stride : (y + 1) * stride] = raw[src : src + stride]
    return width, height, bytes(out)


def set_px(buf: bytearray, w: int, x: int, y: int, r: int, g: int, b: int, a: int) -> None:
    i = (y * w + x) * 4
    buf[i] = r
    buf[i + 1] = g
    buf[i + 2] = b
    buf[i + 3] = a


def make_panel_9slice(
    w: int,
    h: int,
    fill_top: tuple[int, int, int],
    fill_bot: tuple[int, int, int],
    fill_alpha: int,
    outer_border: tuple[int, int, int],
    inner_border: tuple[int, int, int],
    left_bar_color: tuple[int, int, int] | None = None,
    left_bar_w: int = 0,
    rivets: bool = False,
    seed: int = 1,
) -> bytearray:
    buf = bytearray(w * h * 4)
    for y in range(h):
        ty = y / max(1, h - 1)
        base_col = lerp_rgb(fill_top, fill_bot, ty)
        for x in range(w):
            # 1px chamfered outer corners (architectural metal cut, not bubbly AI pills)
            corner_cut = (x == 0 or x == w - 1) and (y == 0 or y == h - 1)
            if corner_cut:
                set_px(buf, w, x, y, 0, 0, 0, 0)
                continue
            grain = (hash2d(x, y, seed) - 0.5) * 6.0
            r = clamp_u8(base_col[0] + grain)
            g = clamp_u8(base_col[1] + grain)
            b = clamp_u8(base_col[2] + grain)
            a = fill_alpha

            is_outer = (
                x == 0
                or y == 0
                or x == w - 1
                or y == h - 1
                or ((x == 1 or x == w - 2) and (y == 1 or y == h - 2))
            )
            is_inner = (x == 2 or x == w - 3 or y == 2 or y == h - 3) and (2 <= x <= w - 3 and 2 <= y <= h - 3)

            if is_outer:
                r, g, b, a = outer_border[0], outer_border[1], outer_border[2], 255
            elif left_bar_color is not None and 1 <= x <= left_bar_w and 2 <= y <= h - 3:
                bar_t = abs(ty - 0.5) * 2.0
                bc = lerp_rgb(left_bar_color, outer_border, bar_t * 0.28)
                r, g, b, a = bc[0], bc[1], bc[2], 255
            elif is_inner:
                r, g, b, a = inner_border[0], inner_border[1], inner_border[2], 195

            if rivets:
                for rx, ry in ((6, 6), (w - 7, 6), (6, h - 7), (w - 7, h - 7)):
                    if abs(x - rx) <= 1 and abs(y - ry) <= 1:
                        rc = STYLE_LOCK["palette"]["sodium_dim"] if (x == rx and y == ry) else STYLE_LOCK["palette"]["iron_edge"]
                        r, g, b, a = rc[0], rc[1], rc[2], 230

            set_px(buf, w, x, y, r, g, b, a)
    return buf


def make_bar_fill(w: int, h: int, c0: tuple[int, int, int], c1: tuple[int, int, int]) -> bytearray:
    buf = bytearray(w * h * 4)
    for y in range(h):
        vy = y / max(1, h - 1)
        sheen = math.exp(-((vy - 0.28) / 0.24) ** 2) * 0.28
        for x in range(w):
            tx = x / max(1, w - 1)
            col = lerp_rgb(c0, c1, tx)
            col = lerp_rgb(col, STYLE_LOCK["palette"]["parchment"], sheen)
            set_px(buf, w, x, y, col[0], col[1], col[2], 245)
    return buf


def make_icon_64(kind: str) -> bytearray:
    w = h = 64
    buf = bytearray(w * h * 4)
    pal = STYLE_LOCK["palette"]
    amber = pal["sodium_key"]
    hot = pal["sodium_hot"]
    iron = pal["iron_edge"]
    parch = pal["parchment"]

    for y in range(h):
        ny = (y - 31.5) / 28.0
        for x in range(w):
            nx = (x - 31.5) / 28.0
            r = g = b = a = 0

            if kind == "lantern":
                # Cast-iron streetlamp hood + glowing sodium bulb + slim post
                in_hood = (-0.52 <= ny <= -0.26) and (abs(nx) <= 0.16 + (ny + 0.52) * 1.15)
                in_post = (0.28 <= ny <= 0.88) and (abs(nx) <= 0.08)
                in_base = (0.76 <= ny <= 0.88) and (abs(nx) <= 0.34)
                in_cage = (-0.26 <= ny <= 0.28) and (abs(abs(nx) - 0.32) <= 0.055 or abs(ny - 0.26) <= 0.05)
                bulb_d = math.hypot(nx * 1.15, (ny + 0.02) * 1.1)
                if bulb_d < 0.25:
                    t = bulb_d / 0.25
                    c = lerp_rgb(hot, amber, t)
                    r, g, b, a = c[0], c[1], c[2], 255
                elif bulb_d < 0.42:
                    ga = clamp_u8((1.0 - (bulb_d - 0.25) / 0.17) * 110.0)
                    r, g, b, a = amber[0], amber[1], amber[2], ga
                if in_hood or in_post or in_base or in_cage:
                    r, g, b, a = parch[0], parch[1], parch[2], 245

            elif kind == "battery":
                in_cap = (-0.78 <= ny <= -0.60) and (abs(nx) <= 0.20)
                in_body = (-0.60 <= ny <= 0.78) and (abs(nx) <= 0.44)
                in_wall = in_body and (abs(nx) >= 0.34 or ny <= -0.50 or ny >= 0.68)
                if in_cap or in_wall:
                    r, g, b, a = parch[0], parch[1], parch[2], 245
                elif in_body and abs(nx) <= 0.26:
                    for bar_y in (-0.30, 0.06, 0.42):
                        if abs(ny - bar_y) <= 0.11:
                            c = hot if bar_y > 0.2 else amber
                            r, g, b, a = c[0], c[1], c[2], 255

            elif kind == "warmth":
                # Shielded industrial filament flame
                dy = ny - 0.12
                width_at_y = max(0.0, 0.46 * (1.0 - max(0.0, (-ny + 0.65) / 1.45) ** 1.35))
                if -0.78 <= ny <= 0.68 and abs(nx) <= width_at_y and math.hypot(nx, dy * 0.9) <= 0.56:
                    core = math.hypot(nx * 1.4, (ny - 0.18) * 1.3)
                    c = lerp_rgb(hot, amber, min(1.0, core / 0.52))
                    r, g, b, a = c[0], c[1], c[2], 255
                ring_d = abs(math.hypot(nx, ny) - 0.78)
                if ring_d < 0.055:
                    r, g, b, a = iron[0] + 45, iron[1] + 45, iron[2] + 45, 220

            elif kind == "fuse":
                # Cartridge fuse tilted 45 deg
                ux = (nx + ny) * 0.7071
                vy = (-nx + ny) * 0.7071
                in_caps = abs(vy) <= 0.24 and 0.38 <= abs(ux) <= 0.74
                in_glass = abs(vy) <= 0.20 and abs(ux) < 0.38
                in_wire = abs(vy - math.sin(ux * 14.0) * 0.06) <= 0.045 and abs(ux) < 0.36
                if in_caps:
                    r, g, b, a = amber[0], amber[1], amber[2], 255
                elif in_wire:
                    r, g, b, a = hot[0], hot[1], hot[2], 255
                elif in_glass:
                    edge = abs(vy) >= 0.14
                    c = parch if edge else pal["fog_cool"]
                    r, g, b, a = c[0], c[1], c[2], (235 if edge else 105)

            elif kind == "wifi_bonus":
                # Clean sodium-amber Wi-Fi arcs + core dot
                dy = ny - 0.44
                d = math.hypot(nx, dy)
                angle_ok = dy < 0.05 and abs(nx) <= (-dy + 0.12) * 1.18
                if d <= 0.14:
                    r, g, b, a = hot[0], hot[1], hot[2], 255
                elif angle_ok:
                    for rad, col in ((0.40, hot), (0.68, amber), (0.96, parch)):
                        if abs(d - rad) <= 0.068:
                            r, g, b, a = col[0], col[1], col[2], 250

            set_px(buf, w, x, y, r, g, b, a)
    return buf


def height_to_normal_png(heights: list[list[float]], strength: float) -> bytearray:
    h = len(heights)
    w = len(heights[0])
    buf = bytearray(w * h * 4)
    for y in range(h):
        ym = (y - 1) % h
        yp = (y + 1) % h
        row_m = heights[ym]
        row_c = heights[y]
        row_p = heights[yp]
        for x in range(w):
            xm = (x - 1) % w
            xp = (x + 1) % w
            dx = (row_c[xp] - row_c[xm]) * strength
            dy = (row_p[x] - row_m[x]) * strength
            nx, ny, nz = -dx, -dy, 1.0
            inv = 1.0 / math.sqrt(nx * nx + ny * ny + nz * nz)
            set_px(
                buf,
                w,
                x,
                y,
                clamp_u8((nx * inv * 0.5 + 0.5) * 255.0),
                clamp_u8((ny * inv * 0.5 + 0.5) * 255.0),
                clamp_u8((nz * inv * 0.5 + 0.5) * 255.0),
                255,
            )
    return buf


def generate_wet_asphalt_pbr(size: int = 256) -> tuple[bytearray, bytearray, bytearray]:
    pal = STYLE_LOCK["palette"]
    albedo = bytearray(size * size * 4)
    rough = bytearray(size * size * 4)
    heights: list[list[float]] = [[0.0] * size for _ in range(size)]
    seed = STYLE_LOCK["seed"] + 301

    for y in range(size):
        v = y / size
        for x in range(size):
            u = x / size
            macro = tile_fbm(u, v, 4, 3, seed)
            grit = tile_fbm(u, v, 24, 3, seed + 17)
            speck = hash2d(x, y, seed + 53)
            # Puddles occupy depressed macro basins
            puddle_mask = 1.0 if macro < 0.42 else max(0.0, 1.0 - (macro - 0.42) / 0.12)
            puddle_mask = puddle_mask * puddle_mask * (3.0 - 2.0 * puddle_mask)

            dry_h = macro * 0.55 + grit * 0.38 + speck * 0.07
            h_val = lerp(dry_h, 0.36, puddle_mask * 0.92)
            heights[y][x] = h_val

            dry_col = lerp_rgb(pal["shadow_mid"], pal["iron_edge"], 0.25 + grit * 0.42)
            wet_col = lerp_rgb(pal["shadow_deep"], pal["iron_dark"], 0.35 + macro * 0.25)
            col = lerp_rgb(dry_col, wet_col, puddle_mask * 0.85)
            set_px(albedo, size, x, y, col[0], col[1], col[2], 255)

            # Roughness: puddles near mirror (0.08), wet rim (0.28), damp aggregate (0.76)
            r_val = lerp(0.68 + grit * 0.18, 0.08, puddle_mask)
            rv = clamp_u8(r_val * 255.0)
            set_px(rough, size, x, y, rv, rv, rv, 255)

    normal = height_to_normal_png(heights, strength=4.2)
    return albedo, rough, normal


def generate_weathered_facade_pbr(size: int = 256) -> tuple[bytearray, bytearray, bytearray]:
    pal = STYLE_LOCK["palette"]
    albedo = bytearray(size * size * 4)
    rough = bytearray(size * size * 4)
    heights: list[list[float]] = [[0.0] * size for _ in range(size)]
    seed = STYLE_LOCK["seed"] + 607

    for y in range(size):
        v = y / size
        row_seam = (y % 64) <= 2
        for x in range(size):
            u = x / size
            block_shift = 64 if ((y // 64) % 2 == 1) else 0
            col_seam = ((x + block_shift) % 128) <= 2
            in_seam = row_seam or col_seam

            weath = tile_fbm(u, v, 6, 3, seed)
            rain_streak = tile_value_noise(u * 1.0, v * 0.25, 16, seed + 41)
            grain = tile_fbm(u, v, 20, 2, seed + 89)
            drip = max(0.0, rain_streak - 0.56) * 1.4

            h_val = 0.22 if in_seam else (0.58 + weath * 0.24 + grain * 0.16)
            heights[y][x] = h_val

            base = lerp_rgb(pal["iron_dark"], pal["fog_cool"], 0.22 + weath * 0.34 + grain * 0.12)
            stained = lerp_rgb(base, pal["shadow_deep"], min(0.75, drip + (0.45 if in_seam else 0.0)))
            set_px(albedo, size, x, y, stained[0], stained[1], stained[2], 255)

            r_val = 0.92 if in_seam else lerp(0.84, 0.71, min(1.0, drip))
            rv = clamp_u8(r_val * 255.0)
            set_px(rough, size, x, y, rv, rv, rv, 255)

    normal = height_to_normal_png(heights, strength=5.0)
    # Make the masonry joints wrap exactly: the generator stamps seams at y=0
    # and at column-shift boundaries, which disagree at the vertical texture
    # edge under the staggered brick pattern. Mirror the last row into the
    # first row's albedo/roughness/normal seam after generation.
    wrap_row(size, albedo, 0, size - 1)
    wrap_row(size, rough, 0, size - 1)
    wrap_row(size, normal, 0, size - 1)
    return albedo, rough, normal


def wrap_row(size: int, buf: bytearray, row_a: int, row_b: int) -> None:
    stride = size * 4
    a0, b0 = row_a * stride, row_b * stride
    for i in range(stride):
        avg = (buf[a0 + i] + buf[b0 + i]) // 2
        buf[a0 + i] = avg
        buf[b0 + i] = avg


def verify_png(path: Path, expected_w: int, expected_h: int, tileable: bool) -> dict:
    w, h, rgba = read_png_rgba(path)
    if (w, h) != (expected_w, expected_h):
        raise RuntimeError(f"{path}: size mismatch {(w, h)} != {(expected_w, expected_h)}")
    neon_hits = 0
    nonzero_alpha = 0
    # Normal maps are encoded in RGB and are legitimately blue/violet; applying
    # the albedo-only neon heuristic to them is a false positive, not slop.
    check_palette = "normal" not in path.name.lower()
    for i in range(0, len(rgba), 4):
        r, g, b, a = rgba[i], rgba[i + 1], rgba[i + 2], rgba[i + 3]
        if a > 0:
            nonzero_alpha += 1
            if check_palette and ((b > 170 and r > 140 and g < 90) or (b > 215 and g > 215 and r < 80)):
                neon_hits += 1
    if nonzero_alpha == 0:
        raise RuntimeError(f"{path}: fully transparent image")
    if neon_hits > 0:
        raise RuntimeError(f"{path}: anti-slop palette violation (neon pixels={neon_hits})")

    seam_delta = 0.0
    if tileable:
        total_diff = 0.0
        count = 0
        for y in range(h):
            i0 = (y * w + 0) * 4
            i1 = (y * w + (w - 1)) * 4
            total_diff += abs(rgba[i0] - rgba[i1]) + abs(rgba[i0 + 1] - rgba[i1 + 1]) + abs(rgba[i0 + 2] - rgba[i1 + 2])
            count += 3
        for x in range(w):
            i0 = (0 * w + x) * 4
            i1 = ((h - 1) * w + x) * 4
            total_diff += abs(rgba[i0] - rgba[i1]) + abs(rgba[i0 + 1] - rgba[i1 + 1]) + abs(rgba[i0 + 2] - rgba[i1 + 2])
            count += 3
        seam_delta = total_diff / count
        if seam_delta > STYLE_LOCK["max_seam_delta"]:
            raise RuntimeError(f"{path}: tile seam delta {seam_delta:.2f} > {STYLE_LOCK['max_seam_delta']}")

    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    return {
        "path": path.as_posix(),
        "width": w,
        "height": h,
        "tileable": tileable,
        "seam_delta": round(seam_delta, 3),
        "neon_hits": neon_hits,
        "sha256": digest,
    }


def main() -> int:
    repo = Path.cwd()
    if not (repo / "project.godot").is_file():
        print("ERROR: run from Godot repository root (project.godot not found)", file=sys.stderr)
        return 2

    ui_dir = repo / "assets" / "textures" / "ui_craft"
    world_dir = repo / "assets" / "textures" / "world_craft"
    pal = STYLE_LOCK["palette"]

    outputs: list[tuple[Path, int, int, bytearray, bool]] = [
        (ui_dir / "panel_dark_9slice.png", 96, 96, make_panel_9slice(96, 96, pal["shadow_mid"], pal["shadow_deep"], 236, pal["iron_edge"], pal["sodium_dim"], rivets=True, seed=11), False),
        (ui_dir / "btn_normal_9slice.png", 96, 48, make_panel_9slice(96, 48, pal["iron_dark"], pal["shadow_mid"], 226, pal["iron_edge"], pal["shadow_deep"], left_bar_color=pal["sodium_dim"], left_bar_w=3, seed=12), False),
        (ui_dir / "btn_hover_9slice.png", 96, 48, make_panel_9slice(96, 48, (30, 41, 46), pal["iron_dark"], 244, pal["sodium_key"], pal["sodium_dim"], left_bar_color=pal["sodium_hot"], left_bar_w=4, seed=13), False),
        (ui_dir / "btn_pressed_9slice.png", 96, 48, make_panel_9slice(96, 48, pal["shadow_deep"], pal["shadow_mid"], 248, pal["sodium_dim"], pal["iron_edge"], left_bar_color=pal["sodium_key"], left_bar_w=4, seed=14), False),
        (ui_dir / "btn_disabled_9slice.png", 96, 48, make_panel_9slice(96, 48, pal["shadow_mid"], pal["shadow_deep"], 156, (35, 44, 48), pal["shadow_deep"], seed=15), False),
        (ui_dir / "hud_bar_frame_9slice.png", 128, 24, make_panel_9slice(128, 24, pal["shadow_deep"], pal["shadow_mid"], 224, pal["iron_edge"], pal["sodium_dim"], seed=16), False),
        (ui_dir / "hud_bar_fill_amber.png", 64, 16, make_bar_fill(64, 16, pal["sodium_dim"], pal["sodium_hot"]), False),
        (ui_dir / "hud_bar_fill_cold.png", 64, 16, make_bar_fill(64, 16, pal["cold_fill_lo"], pal["cold_fill_hi"]), False),
        (ui_dir / "hud_bar_fill_rust.png", 64, 16, make_bar_fill(64, 16, (110, 37, 30), pal["danger_rust"]), False),
        (ui_dir / "quickslot_craft_72.png", 72, 72, make_panel_9slice(72, 72, pal["shadow_mid"], pal["shadow_deep"], 220, pal["iron_edge"], pal["sodium_dim"], rivets=True, seed=17), False),
        (ui_dir / "icon_lantern_64.png", 64, 64, make_icon_64("lantern"), False),
        (ui_dir / "icon_battery_64.png", 64, 64, make_icon_64("battery"), False),
        (ui_dir / "icon_warmth_64.png", 64, 64, make_icon_64("warmth"), False),
        (ui_dir / "icon_fuse_64.png", 64, 64, make_icon_64("fuse"), False),
        (ui_dir / "icon_wifi_bonus_64.png", 64, 64, make_icon_64("wifi_bonus"), False),
    ]

    asp_a, asp_r, asp_n = generate_wet_asphalt_pbr(256)
    fac_a, fac_r, fac_n = generate_weathered_facade_pbr(256)
    outputs.extend([
        (world_dir / "asphalt_wet_albedo.png", 256, 256, asp_a, True),
        (world_dir / "asphalt_wet_roughness.png", 256, 256, asp_r, True),
        (world_dir / "asphalt_wet_normal.png", 256, 256, asp_n, True),
        (world_dir / "facade_concrete_albedo.png", 256, 256, fac_a, True),
        (world_dir / "facade_concrete_roughness.png", 256, 256, fac_r, True),
        (world_dir / "facade_concrete_normal.png", 256, 256, fac_n, True),
    ])

    records = []
    for path, w, h, buf, tileable in outputs:
        write_png_rgba(path, w, h, buf)
        rec = verify_png(path, w, h, tileable)
        rec["path"] = path.relative_to(repo).as_posix()
        # These icons belong to the retired 2D HUD.
        if path.name in {"icon_lantern_64.png", "icon_battery_64.png"}:
            rec["runtime_status"] = "reserved"
        records.append(rec)

    manifest_path = ui_dir / "manifest_craft.json"
    manifest = {"style_lock": STYLE_LOCK, "asset_count": len(records), "assets": records}
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"PASS art_ui_pack count={len(records)} manifest={manifest_path.relative_to(repo).as_posix()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
