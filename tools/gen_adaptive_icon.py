#!/usr/bin/env python
"""Derive the Android adaptive-icon layers from store/icon-512.png.

Deterministic (no randomness): resize the shipped 512 master into the
inner 66% safe zone of a 1080x1080 transparent foreground, and pair it
with an opaque palette-colour background. Both layers get their per-
channel extrema clamped to the STYLE_GUIDE range so there is no pure
#000 / #fff texel (the 512 master itself still has them; these layers
do not).

Run:  python tools/gen_adaptive_icon.py           # write the two PNGs + README
      python tools/gen_adaptive_icon.py --check    # verify only
"""
import sys, pathlib
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[1]
SRC = ROOT / "store" / "icon-512.png"
OUT = ROOT / "store" / "icon-adaptive"
SIZE = 1080
SAFE = 0.66                     # inner fraction the logo must stay within
BG_RGB = (0x14, 0x1b, 0x24)     # STYLE_GUIDE "panel" #141b24, opaque
LO, HI = 16, 216               # clamp range ~ #101418 .. #d8d2c4


def clamp_img(im):
    lut = [min(HI, max(LO, v)) for v in range(256)]
    return im.point(lut * len(im.getbands()))


def build():
    OUT.mkdir(parents=True, exist_ok=True)
    src = Image.open(SRC).convert("RGB")
    inner = int(SIZE * SAFE)
    # Clamp AFTER resampling — LANCZOS ringing would otherwise push values
    # back outside [LO,HI].
    logo = clamp_img(src.resize((inner, inner), Image.LANCZOS))

    fg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    off = (SIZE - inner) // 2
    fg.paste(logo.convert("RGBA"), (off, off))
    fg.save(OUT / "foreground_1080x1080.png")

    bg = Image.new("RGBA", (SIZE, SIZE), BG_RGB + (255,))
    bg.save(OUT / "background_1080x1080.png")

    (OUT / "README.md").write_text(README, encoding="utf-8")
    print("wrote", OUT / "foreground_1080x1080.png", OUT / "background_1080x1080.png",
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

Two layers, both 1080x1080, derived deterministically from
`store/icon-512.png` by `tools/gen_adaptive_icon.py` (re-run it if the
512 master changes):

| File | Role | Notes |
|---|---|---|
| `foreground_1080x1080.png` | adaptive icon foreground | RGBA. The 512 crest scaled into the inner 66% safe zone, centred, on a fully transparent field. Per-channel values clamped to `[16,216]` (~`#101418`..`#d8d2c4`) so there is no pure `#000`/`#fff` texel. |
| `background_1080x1080.png` | adaptive icon background | RGBA, fully opaque. Flat STYLE_GUIDE "panel" `#141b24`. |

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
composites fg over bg and crops to the device mask shape (circle /
squircle / rounded square); the 66% safe zone keeps the crest fully
visible under every mask.

Play Console's own 512x512 store icon is a separate upload — use
`store/icon-512.png` there, unchanged.
"""


if __name__ == "__main__":
    sys.exit(check() if "--check" in sys.argv else (build() or check()))
