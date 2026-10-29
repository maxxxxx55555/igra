#!/usr/bin/env python3
"""The UI follows the owner canon of 2026-10-29 (docs/STYLE_GUIDE.md section 8): what holds one of the old token colours takes the new one.
Chrome: every pixel of the flat PNGs of assets/textures/ui and ui_v2, the alpha stays. A texture with more than MAX_COLOURS colours (the gradient button kit of ui_v2, the weather thumbnails) is left alone, and so is a file that holds no old colour.
Text: every literal of the UI themes, scenes and scripts (TEXT_GLOBS), a #rrggbb, a Color("rrggbb") or a Color(r, g, b) of floats within a step of 255; the alpha and the line endings stay. tools/qa_sim/consistency_check.py fails on a literal this still finds.

usage: python tools/retint_ui_chrome.py [--demo]   (without an argument it rewrites the files)
"""
import glob
import pathlib
import re
import sys

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
TOKENS = {
    (0x0C, 0x10, 0x16): (0x06, 0x0F, 0x13),  # bg-deep
    (0x14, 0x1B, 0x24): (0x0F, 0x13, 0x14),  # panel
    (0x1B, 0x23, 0x2E): (0x1C, 0x1E, 0x1D),  # panel-hover
    (0x2A, 0x33, 0x40): (0x5A, 0x4A, 0x2A),  # panel-edge: bronze
    (0xD8, 0xD2, 0xC4): (0xD8, 0xD5, 0xCC),  # bone
    (0xAE, 0xB6, 0xBF): (0x8A, 0x8A, 0x85),  # steel
    (0xB4, 0x45, 0x2F): (0xC0, 0x39, 0x2B),  # ember
}
TEXT_GLOBS = ("assets/ui/*.tres", "data/ui/*.tres", "scenes/ui/*.tscn", "scenes/ui/*.gd", "scripts/ui/*.gd")
HEX = re.compile(r'(#|Color\(\s*")([0-9a-fA-F]{6})((?:[0-9a-fA-F]{2})?)\b')
FLOATS = re.compile(r"Color\((\s*)([0-9.]+)(\s*,\s*)([0-9.]+)(\s*,\s*)([0-9.]+)")


def retint(img):
    """The image with the old colours replaced, or None when it holds none or has too many colours."""
    rgba = img.convert("RGBA")
    colours = {p[:3] for p in rgba.getdata() if p[3] > 0}
    if len(colours) > MAX_COLOURS or not colours & MAP.keys():
        return None
    rgba.putdata([(*MAP[p[:3]], p[3]) if p[:3] in MAP else p for p in rgba.getdata()])
    return rgba


def retint_text(text):
    """The text with every old token colour replaced by its canon colour (the same text when it holds none)."""
    def hexed(m):
        new = TOKENS.get(tuple(int(m.group(2)[i:i + 2], 16) for i in (0, 2, 4)))
        return m.group(0) if new is None else m.group(1) + "%02x%02x%02x" % new + m.group(3)

    def floated(m):
        rgb = [float(m.group(i)) * 255 for i in (2, 4, 6)]
        new = next((n for o, n in TOKENS.items() if all(abs(c - v) <= 0.6 for c, v in zip(rgb, o))), None)
        if new is None:
            return m.group(0)
        return "Color(%s%.6g%s%.6g%s%.6g" % (m.group(1), new[0] / 255, m.group(3), new[1] / 255, m.group(5), new[2] / 255)

    return FLOATS.sub(floated, HEX.sub(hexed, text))


def demo():
    from PIL import Image
    img = Image.new("RGBA", (3, 1))
    img.putdata([(0x14, 0x1B, 0x24, 255), (0x2A, 0x33, 0x40, 200), (0, 0, 0, 0)])
    out = retint(img)
    assert list(out.getdata()) == [(0x0F, 0x13, 0x14, 255), (0x5A, 0x4A, 0x2A, 200), (0, 0, 0, 0)], list(out.getdata())
    assert retint(out) is None, "a second pass finds nothing to change"
    sample = 'a Color("#0C1016") b Color(0.0471, 0.0627, 0.0863, 0.92) c Color("b4452f") # bone #d8d2c4 d Color(0.5, 0.5, 0.5) e #c0392b'
    moved = retint_text(sample)
    assert moved == 'a Color("#060f13") b Color(0.0235294, 0.0588235, 0.0745098, 0.92) c Color("c0392b") # bone #d8d5cc d Color(0.5, 0.5, 0.5) e #c0392b', moved
    assert retint_text(moved) == moved, "a second pass finds nothing to change"
    print("retint_ui_chrome demo OK (the colours move, the alpha stays, a second pass is empty, in textures and in text)")


def main():
    if "--demo" in sys.argv:
        demo()
        return
    from PIL import Image
    changed = 0
    for path in sorted(glob.glob(str(ROOT / "assets/textures/ui/*.png")) + glob.glob(str(ROOT / "assets/textures/ui_v2/*.png"))):
        out = retint(Image.open(path))
        if out is not None:
            out.save(path, compress_level=9)
            changed += 1
    print("retinted", changed, "texture(s)")
    changed = 0
    for pattern in TEXT_GLOBS:
        for path in sorted(glob.glob(str(ROOT / pattern))):
            old = pathlib.Path(path).read_bytes().decode("utf-8")
            new = retint_text(old)
            if new != old:
                pathlib.Path(path).write_bytes(new.encode("utf-8"))
                changed += 1
    print("retinted", changed, "text file(s)")


if __name__ == "__main__":
    main()
