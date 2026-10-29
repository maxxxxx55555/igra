#!/usr/bin/env python3
"""The item icons of the game are flat vector drawings, which MEGA_PROMPT v7 forbids (docs/VISUAL_REMAINING.md, prohibition 1); sheet 3 of the owner's style sheets (docs/art/style_reference/) is the target: a semi-realistic PBR render of each item on a transparent ground.
This cuts the icons out of that sheet and proposes them as the replacement: each tile is cut by ICON_BOXES, its near-black ground (one colour, `#070b0e`) is keyed to alpha with the dark inside of the object kept, and the piece is fitted into a 128 px square with a margin.
A cut has the resolution of the sheet (about 95 px a tile): it holds at the sizes the game shows an icon (32 to 64 px) and it is the place to put a full-resolution render when the owner has one.
Nothing reaches assets/ until the owner approves the replacement itself (v7: icons are optional and need their own APPROVED).

usage: python tools/harvest_sheets.py [--demo]            writes the proposal to .qa_logs/proposals/icons/ and the board (old | new for every item) to .qa_logs/approvals/icons_board.png
       python tools/harvest_sheets.py --apply --approved-by "NAME DATE"   writes assets/textures/items/*.png and adds the row of the approvals journal
"""
import collections
import pathlib
import re
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parents[1]
SHEETS = ROOT / "docs" / "art" / "style_reference"
ICON_PX = 128
ICON_MARGIN = 6
GROUND = np.array([7.0, 11.0, 14.0])
# sheet 3: the tile of each icon (x0, y0, x1, y1), read off the sheet
ICON_BOXES = {
    "battery": (218, 78, 318, 180), "fuse": (328, 78, 428, 180), "cable_coil": (437, 78, 537, 180), "electric_cable": (546, 78, 668, 180), "portable_battery": (681, 78, 783, 180),
    "medkit": (819, 78, 922, 180), "bandage": (934, 78, 1036, 180), "painkillers": (1047, 78, 1150, 180),
    "key": (1178, 78, 1268, 180), "access_card": (1280, 78, 1383, 180), "document": (1395, 78, 1500, 180),
    "note": (218, 312, 318, 412), "diary": (328, 312, 428, 412), "power_plan": (440, 312, 540, 412), "photo": (557, 312, 660, 412), "radio_code": (671, 312, 773, 412), "usb_drive": (783, 312, 879, 412),
    "wrench": (924, 333, 1030, 437), "screwdriver": (1060, 333, 1164, 437), "pliers": (1203, 333, 1346, 437), "crowbar": (1361, 333, 1486, 437),
    "pistol": (18, 556, 137, 652), "shotgun": (149, 556, 273, 652), "smg": (287, 556, 405, 652), "rifle": (421, 556, 555, 652), "sniper_rifle": (573, 556, 717, 652),
    "ammo_9mm": (750, 556, 878, 652), "ammo_12gauge": (896, 556, 1030, 652), "ammo_556": (1048, 556, 1183, 652), "ammo_762": (1201, 556, 1346, 652), "ammo_308": (1362, 556, 1496, 652),
    "flashlight": (17, 788, 100, 876), "water_bottle": (112, 788, 197, 876), "canned_food": (203, 788, 285, 876), "energy_bar": (297, 788, 407, 876), "cigarettes": (418, 788, 505, 876),
    "cloth": (542, 788, 633, 876), "duct_tape": (645, 788, 737, 876), "metal_parts": (748, 788, 850, 876), "scrap": (860, 788, 958, 876), "chemicals": (966, 788, 1055, 876),
    "lighter": (1080, 788, 1173, 876), "rope": (1187, 788, 1285, 876), "backpack": (1298, 788, 1394, 876), "lockpick": (1409, 788, 1500, 876),
}
# the game's item id -> the icon of the sheet that stands for it
ICON_OF = {
    "battery": "battery", "battery_l2": "portable_battery", "enhanced_battery": "portable_battery", "fuse": "fuse", "cable": "cable_coil", "wiring": "electric_cable",
    "medkit": "medkit", "bandage": "bandage", "fabric": "cloth", "serum": "painkillers", "key": "key", "ancient_key": "key", "document": "document", "paper": "note", "photo": "photo",
    "audio_log": "usb_drive", "blueprint": "power_plan", "tool": "wrench", "wrench": "wrench", "lockpick": "lockpick", "repair_kit": "pliers",
    "pistol": "pistol", "shotgun": "shotgun", "rifle": "rifle", "ammo": "ammo_9mm", "flashlight": "flashlight", "water": "water_bottle", "bottle": "water_bottle", "can_food": "canned_food",
    "scrap": "scrap", "metal": "metal_parts", "gear": "metal_parts", "gas_canister": "chemicals", "backpack": "backpack", "backpack_l1": "backpack", "backpack_l2": "backpack",
}
ICON_OF.update({f: "power_plan" for f in (
    "blueprint_backpack_capacity", "blueprint_backpack_slots", "blueprint_battery_l2", "blueprint_enhanced_battery", "blueprint_flashlight_battery", "blueprint_flashlight_brightness",
    "blueprint_portable_workbench", "blueprint_strobe_flashlight", "blueprint_uv_flashlight")})


def strip_lines(alpha):
    """The border line of a neighbouring tile that the cut caught: a thin piece at the edge of the cut is not part of the object."""
    height, width = alpha.shape
    shown = alpha > 0.1
    seen = np.zeros((height, width), bool)
    for y0 in range(height):
        for x0 in range(width):
            if not shown[y0, x0] or seen[y0, x0]:
                continue
            piece, queue = [], collections.deque([(y0, x0)])
            seen[y0, x0] = True
            while queue:
                y, x = queue.popleft()
                piece.append((y, x))
                for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                    if 0 <= ny < height and 0 <= nx < width and shown[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        queue.append((ny, nx))
            ys, xs = zip(*piece)
            thin = min(max(xs) - min(xs), max(ys) - min(ys)) < 5
            at_edge = min(xs) < 6 or max(xs) > width - 7 or min(ys) < 6 or max(ys) > height - 7
            if thin and at_edge:
                for y, x in piece:
                    alpha[y, x] = 0.0
    return alpha


def key_ground(tile, ground=None, reach=14.0):
    """RGBA of an RGB tile: the pixels of the ground go transparent, an edge keeps a soft alpha, and what the ground does not reach (the dark inside of an object) stays opaque.
    The ground is the colour of the tile ground of sheet 3 unless the caller gives one (`ground="edge"` takes the median of the rim of the cut); `reach` is how far from it a pixel may be and still be ground."""
    rgb = np.asarray(tile.convert("RGB")).astype(float)
    if isinstance(ground, str):
        ring = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]])
        ground = np.median(ring, axis=0)
    ground = GROUND if ground is None else np.asarray(ground, float)
    dist = np.abs(rgb - ground).max(axis=2)
    height, width = dist.shape
    ground_mask = np.zeros((height, width), bool)
    queue = collections.deque()
    for x in range(width):
        queue += [(0, x), (height - 1, x)]
    for y in range(height):
        queue += [(y, 0), (y, width - 1)]
    while queue:
        y, x = queue.popleft()
        if 0 <= y < height and 0 <= x < width and not ground_mask[y, x] and dist[y, x] < reach:
            ground_mask[y, x] = True
            queue += [(y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)]
    near = np.asarray(Image.fromarray((ground_mask * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(5))) > 0
    soft = np.clip((dist - 6.0) / 26.0, 0.0, 1.0)
    alpha = np.where(near, soft, 1.0)
    alpha = np.where(ground_mask & (dist < 6.0), 0.0, alpha)
    alpha = strip_lines(alpha)
    safe = np.maximum(alpha, 1e-3)[..., None]
    colour = np.clip((rgb - ground * (1.0 - alpha[..., None])) / safe, 0, 255)
    return Image.fromarray(np.dstack([colour, alpha * 255]).astype(np.uint8), "RGBA")


def fit(piece, px=ICON_PX, margin=ICON_MARGIN):
    """The cut inside a transparent square: trimmed to what shows, scaled to fill the square less the margin, centred."""
    box = piece.getchannel("A").point(lambda a: 255 if a > 24 else 0).getbbox()
    if box is not None:
        piece = piece.crop(box)
    room = px - 2 * margin
    scale = min(room / piece.width, room / piece.height)
    piece = piece.resize((max(1, round(piece.width * scale)), max(1, round(piece.height * scale))), Image.LANCZOS)
    out = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    out.alpha_composite(piece, ((px - piece.width) // 2, (px - piece.height) // 2))
    return out


def cut_all():
    """{sheet icon name: its 128 px RGBA cut}."""
    sheet = Image.open(SHEETS / "sheet_3_item_icons.webp").convert("RGB")
    return {name: fit(key_ground(sheet.crop((x0 + 3, y0 + 3, x1 - 3, y1 - 3)))) for name, (x0, y0, x1, y1) in ICON_BOXES.items()}


def proposal():
    """Writes the proposal for every item id of ICON_OF and the board that compares it with what the game holds."""
    cut = cut_all()
    out_dir = ROOT / ".qa_logs" / "proposals" / "icons"
    out_dir.mkdir(parents=True, exist_ok=True)
    (ROOT / ".qa_logs" / "approvals").mkdir(parents=True, exist_ok=True)
    ids = sorted(ICON_OF)
    cols, cell_w, cell_h = 8, 190, 130
    sheet = Image.new("RGB", (cols * cell_w, ((len(ids) + cols - 1) // cols) * cell_h), (14, 22, 25))
    draw = ImageDraw.Draw(sheet)
    for i, item in enumerate(ids):
        icon = cut[ICON_OF[item]]
        icon.save(out_dir / (item + ".png"), compress_level=9)
        x, y = (i % cols) * cell_w, (i // cols) * cell_h
        old_path = ROOT / "assets" / "textures" / "items" / (item + ".png")
        if old_path.exists():
            old = Image.open(old_path).convert("RGBA").resize((72, 72), Image.LANCZOS)
            sheet.paste(old, (x + 6, y + 8), old)
        sheet.paste(icon.resize((96, 96), Image.LANCZOS), (x + 84, y + 4), icon.resize((96, 96), Image.LANCZOS))
        draw.text((x + 6, y + 110), item, fill=(190, 190, 180))
    sheet.save(ROOT / ".qa_logs" / "approvals" / "icons_board.png", compress_level=9)
    return len(ids)


def apply(who):
    if not re.search(r"\w+.*\d{4}-\d{2}-\d{2}", who):
        sys.exit('--approved-by wants a name and a date, e.g. "Maxsim 2026-10-30"')
    cut = cut_all()
    out_dir = ROOT / "assets" / "textures" / "items"
    for item, name in sorted(ICON_OF.items()):
        cut[name].save(out_dir / (item + ".png"), compress_level=9)
    journal = ROOT / "docs" / "VISUAL_REMAINING.md"
    text = journal.read_bytes().decode("utf-8")
    eol = "\r\n" if "\r\n" in text else "\n"
    row = "| B8 | the %d item icons that the sheet has a match for, cut out of sheet 3 (`tools/harvest_sheets.py`; side by side: `.qa_logs/approvals/icons_board.png`) | APPROVED by %s |" % (len(ICON_OF), who)
    journal.write_bytes((text.rstrip("\r\n") + eol + row + eol).encode("utf-8"))
    return len(ICON_OF)


def demo():
    tile = Image.new("RGB", (40, 40), (7, 11, 14))
    for y in range(10, 30):
        for x in range(10, 30):
            tile.putpixel((x, y), (200, 150, 60) if (x + y) % 7 else (9, 12, 15))
    keyed = key_ground(tile)
    assert keyed.getpixel((2, 2))[3] == 0, "the ground goes transparent"
    assert keyed.getpixel((20, 20))[3] == 255, "the object stays opaque"
    line = tile.copy()
    for y in range(40):
        line.putpixel((1, y), (120, 100, 60))
    assert key_ground(line).getpixel((1, 20))[3] == 0, "the border line of a neighbour tile is dropped"
    fitted = fit(keyed)
    assert fitted.size == (ICON_PX, ICON_PX) and fitted.getchannel("A").getbbox()[0] >= ICON_MARGIN - 1, "the cut sits inside the margin"
    sheet = Image.open(SHEETS / "sheet_3_item_icons.webp")
    assert all(0 <= x0 < x1 <= sheet.width and 0 <= y0 < y1 <= sheet.height for x0, y0, x1, y1 in ICON_BOXES.values()), "every tile lies on the sheet"
    assert set(ICON_OF.values()) <= set(ICON_BOXES), "every icon an item names is cut"
    print("harvest_sheets demo OK (the ground is keyed, the object kept, the cut fits its margin, every box lies on the sheet)")


def main():
    if "--demo" in sys.argv:
        demo()
    elif "--apply" in sys.argv:
        who = sys.argv[sys.argv.index("--approved-by") + 1] if "--approved-by" in sys.argv else ""
        print("wrote", apply(who), "item icon(s) to assets/textures/items")
    else:
        print("proposal for", proposal(), "item(s): .qa_logs/proposals/icons/, board .qa_logs/approvals/icons_board.png")


if __name__ == "__main__":
    main()
