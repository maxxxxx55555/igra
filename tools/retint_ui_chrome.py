#!/usr/bin/env python3
"""The chrome kit of the UI (the flat PNGs of assets/textures/ui and ui_v2) follows the owner canon of 2026-10-29 (docs/STYLE_GUIDE.md section 8): every pixel that holds one of the old token colours takes the new one, the alpha stays.
A texture with more than MAX_COLOURS colours (the gradient button kit of ui_v2, the weather thumbnails) is left alone, and so is a file that holds no old colour.

usage: python tools/retint_ui_chrome.py [--demo]   (without an argument it rewrites the files)
"""
import glob
import pathlib
import sys

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[1]
MAX_COLOURS = 8
MAP = {
    (0x14, 0x1B, 0x24): (0x0F, 0x13, 0x14),  # panel
    (0x12, 0x18, 0x20): (0x0B, 0x0F, 0x10),  # slot fill
    (0x12, 0x18, 0x1F): (0x0B, 0x0F, 0x10),  # disabled fill
    (0x1A, 0x22, 0x2C): (0x1C, 0x1E, 0x1D),  # hover fill
    (0x0D, 0x12, 0x19): (0x06, 0x0F, 0x13),  # pressed fill
    (0x0D, 0x12, 0x1A): (0x06, 0x0F, 0x13),  # bar frame
    (0x0C, 0x10, 0x16): (0x06, 0x0F, 0x13),  # bg-deep
    (0x2A, 0x33, 0x40): (0x5A, 0x4A, 0x2A),  # panel-edge: bronze
    (0x23, 0x2B, 0x36): (0x3A, 0x32, 0x23),  # disabled border
    (0x21, 0x28, 0x33): (0x3A, 0x32, 0x23),  # slot rim
    (0x44, 0x4D, 0x59): (0x6B, 0x5A, 0x33),  # panel highlight
    (0x4A, 0x52, 0x5C): (0x4A, 0x40, 0x30),  # disabled highlight
    (0x66, 0x6A, 0x6E): (0x6B, 0x5A, 0x33),  # bar highlight
}


def retint(img):
    """The image with the old colours replaced, or None when it holds none or has too many colours."""
    rgba = img.convert("RGBA")
    colours = {p[:3] for p in rgba.getdata() if p[3] > 0}
    if len(colours) > MAX_COLOURS or not colours & MAP.keys():
        return None
    rgba.putdata([(*MAP[p[:3]], p[3]) if p[:3] in MAP else p for p in rgba.getdata()])
    return rgba


def demo():
    img = Image.new("RGBA", (3, 1))
    img.putdata([(0x14, 0x1B, 0x24, 255), (0x2A, 0x33, 0x40, 200), (0, 0, 0, 0)])
    out = retint(img)
    assert list(out.getdata()) == [(0x0F, 0x13, 0x14, 255), (0x5A, 0x4A, 0x2A, 200), (0, 0, 0, 0)], list(out.getdata())
    assert retint(out) is None, "a second pass finds nothing to change"
    print("retint_ui_chrome demo OK (the colours move, the alpha stays, a second pass is empty)")


def main():
    if "--demo" in sys.argv:
        demo()
        return
    changed = 0
    for path in sorted(glob.glob(str(ROOT / "assets/textures/ui/*.png")) + glob.glob(str(ROOT / "assets/textures/ui_v2/*.png"))):
        out = retint(Image.open(path))
        if out is not None:
            out.save(path, compress_level=9)
            changed += 1
    print("retinted", changed, "file(s)")


if __name__ == "__main__":
    main()
