#!/usr/bin/env python
"""Derive the app icons from the menu art, the owner's reference look.

Deterministic (no randomness): the lamp, its cone and the puddle of
assets/ui/menu_city.png (Gemini art, docs/ASSET_LICENSES.md) fill the
opaque background layer of the Android adaptive icon; the foreground is
transparent. The 512 icons (the Play store upload, the legacy launcher
icon, the project and Windows icon) are the part every launcher mask
shows (the inner 66.7%). Values are clamped to the STYLE_GUIDE range so
there is no pure #000 / #fff texel.

Run:  python tools/gen_adaptive_icon.py           # write the icons + README
      python tools/gen_adaptive_icon.py --check    # verify only
"""
import sys, pathlib
import numpy as np
from PIL import Image, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "ui" / "menu_city.png"
OUT = ROOT / "store" / "icon-adaptive"
ICONS = (ROOT / "store" / "icon-512.png", ROOT / "assets" / "store" / "play_icon_512.png", ROOT / "assets" / "ui" / "icon.png")
SIZE = 1080
SAFE = 0.66                     # inner fraction the logo must stay within
VIS = 820                       # source pixels under the inner 66.7% every mask shows
CENTRE = (1320, 430)            # the lamp, its cone and the puddle in menu_city.png
GAMMA = 0.85                    # lifts the street so it still reads at 48 px
LO, HI = 16, 216               # clamp range ~ #101418 .. #d8d2c4


def build():
    OUT.mkdir(parents=True, exist_ok=True)
    full = VIS * 3 // 2
    src = np.asarray(Image.open(SRC).convert("RGB"))
    # The crop runs past the art's top edge: the repeated edge rows there are blurred (that band lies outside every mask).
    ext = np.pad(src, ((full, full), (full, full), (0, 0)), mode="edge")
    x0, y0 = CENTRE[0] - full // 2 + full, CENTRE[1] - full // 2 + full
    bg = Image.fromarray(ext[y0:y0 + full, x0:x0 + full]).resize((SIZE, SIZE), Image.LANCZOS)
    top = max(0, full // 2 - CENTRE[1]) * SIZE // full
    if top:
        bg.paste(bg.crop((0, 0, SIZE, top + 24)).filter(ImageFilter.GaussianBlur(16)).crop((0, 0, SIZE, top)), (0, 0))
    bg = bg.point([min(HI, max(LO, round(255 * (v / 255) ** GAMMA))) for v in range(256)] * 3)
    bg.convert("RGBA").save(OUT / "background_1080x1080.png", optimize=True)
    Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0)).save(OUT / "foreground_1080x1080.png")
    edge = SIZE // 6
    icon = bg.crop((edge, edge, SIZE - edge, SIZE - edge)).resize((512, 512), Image.LANCZOS).convert("RGBA")
    for p in ICONS:
        icon.save(p, optimize=True)  # 32-bit PNG: the Play store icon asks for it
    (OUT / "README.md").write_bytes(README.encode("utf-8"))
    print("wrote", OUT / "foreground_1080x1080.png", OUT / "background_1080x1080.png", *ICONS,
          OUT / "README.md", sep="\n  ")


def check():
    fails = []
    for name, need_alpha in [("foreground_1080x1080.png", True),
                             ("background_1080x1080.png", False)]:
        p = OUT / name
        if not p.exists():
            fails.append(f"{name} missing")
            continue
        im = Image.open(p)
        if im.size != (SIZE, SIZE):
            fails.append(f"{name} is {im.size}, want ({SIZE},{SIZE})")
        rgb = im.convert("RGB")
        ex = rgb.getextrema()
        for ch, (lo, hi) in zip("RGB", ex):
            if lo < LO or hi > HI:
                # transparent border pixels read as (0,0,0) in RGB — only
                # flag the foreground's *opaque* region and the whole bg.
                if name.startswith("background") or _opaque_extrema_bad(im):
                    fails.append(f"{name} {ch} extrema {(lo, hi)} outside [{LO},{HI}]")
                break
        if need_alpha and "A" not in im.getbands():
            fails.append(f"{name} has no alpha channel")
        if name.startswith("background"):
            a = im.convert("RGBA").getchannel("A").getextrema()
            if a != (255, 255):
                fails.append(f"{name} not fully opaque: alpha extrema {a}")
    # safe zone: foreground opaque content must sit inside the inner 66%
    fg = Image.open(OUT / "foreground_1080x1080.png").convert("RGBA")
    bbox = fg.getchannel("A").getbbox()
    margin = int(SIZE * (1 - SAFE) / 2)
    if bbox and (bbox[0] < margin - 1 or bbox[1] < margin - 1
                 or bbox[2] > SIZE - margin + 1 or bbox[3] > SIZE - margin + 1):
        fails.append(f"foreground content {bbox} spills the {SAFE:.0%} safe zone (margin {margin})")
    for p in ICONS:
        if Image.open(p).size != (512, 512):
            fails.append(f"{p.name} is not 512x512")
    for f in fails:
        print("  FAIL", f)
    print("adaptive icon check:", "GREEN" if not fails else f"{len(fails)} FAIL")
    return 0 if not fails else 1


def _opaque_extrema_bad(im):
    rgba = im.convert("RGBA")
    r, g, b, a = rgba.split()
    opaque = Image.composite(rgba.convert("RGB"),
                             Image.new("RGB", im.size, (LO, LO, LO)), a)
    ex = opaque.getextrema()
    return any(lo < LO or hi > HI for (lo, hi) in ex)


README = """# Android adaptive icon — export layers

Two layers, both 1080x1080, derived deterministically from the menu art
`assets/ui/menu_city.png` (Gemini, `docs/ASSET_LICENSES.md`) by
`tools/gen_adaptive_icon.py`, which also writes the three 512 icons
(`store/icon-512.png`, `assets/store/play_icon_512.png`,
`assets/ui/icon.png`) from the same picture:

| File | Role | Notes |
|---|---|---|
| `foreground_1080x1080.png` | adaptive icon foreground | RGBA, fully transparent: the picture is the background. |
| `background_1080x1080.png` | adaptive icon background | RGBA, fully opaque. The lamp, its light cone and the puddle of the menu art; the inner 66.7% that every mask shows holds the lamp head. Per-channel values clamped to `[16,216]` (~`#101418`..`#d8d2c4`) so there is no pure `#000`/`#fff` texel. |

## Wiring (Godot 4.7 Android export preset)

In `export_presets.cfg` under `[preset.0.options]` (the Android preset) —
already wired:

```
launcher_icons/adaptive_foreground_432x432="res://store/icon-adaptive/foreground_1080x1080.png"
launcher_icons/adaptive_background_432x432="res://store/icon-adaptive/background_1080x1080.png"
```

Godot downscales these to the 432 slot on export; supplying 1080 keeps
the source crisp. `launcher_icons/main_192x192` (the legacy square
launcher icon) stays on `res://assets/store/play_icon_512.png`. Android
crops the background to the device mask shape (circle / squircle /
rounded square).

Play Console's own 512x512 store icon is a separate upload — use
`store/icon-512.png` there, unchanged.
"""


if __name__ == "__main__":
    sys.exit(check() if "--check" in sys.argv else (build() or check()))
