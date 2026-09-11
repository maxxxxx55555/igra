#!/usr/bin/env python
"""GOLD MASTER v4 — Arena mobile-art-pass recreate (Path B: her branch
carried no payload — arena/01a08c53-igra tip is an ancestor of main,
zero new commits).

Deterministic (no randomness), STYLE_GUIDE palette only, PIL only.
Two families:

  assets/textures/touch/*.png   — 9 touch-HUD glyphs (128/256/96px)
  assets/textures/onboard_v2/onboard_{05,06,07}_*_1024x576.png — 3 stills,
      same "flat silhouettes on bg-deep, one warm light source max" class
      as the shipped onboard_01..04 (STYLE_GUIDE "Loading art" row).

Run:  python tools/gen_mobile_art_pass.py           # write all 12 + report
      python tools/gen_mobile_art_pass.py --check    # verify only
"""
import sys, pathlib
from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parents[1]
TOUCH = ROOT / "assets" / "textures" / "touch"
ONBOARD = ROOT / "assets" / "textures" / "onboard_v2"

# STYLE_GUIDE §2 palette
BG_DEEP = (0x0c, 0x10, 0x16)
PANEL = (0x14, 0x1b, 0x24)
PANEL_EDGE = (0x2a, 0x33, 0x40)
BRASS = (0xc9, 0xa2, 0x4a)
BRASS_DIM = (0x8a, 0x73, 0x38)
EMBER = (0xb4, 0x45, 0x2f)
STEEL = (0xae, 0xb6, 0xbf)
BONE = (0xd8, 0xd2, 0xc4)

LO, HI = 12, 216      # RGB clamp range for opaque/semi-opaque pixels
MAX_ALPHA = 226        # touch controls stay semi-transparent over the world


def clamp_rgb(im: Image.Image) -> Image.Image:
    """Clamp RGB channels to [LO,HI]; leave alpha untouched (0 must stay
    0 for real transparency)."""
    r, g, b, a = im.convert("RGBA").split()
    lut = [min(HI, max(LO, v)) for v in range(256)]
    r, g, b = r.point(lut), g.point(lut), b.point(lut)
    return Image.merge("RGBA", (r, g, b, a))


def cap_alpha(im: Image.Image, cap: int) -> Image.Image:
    r, g, b, a = im.convert("RGBA").split()
    a = a.point(lambda v: min(v, cap))
    return Image.merge("RGBA", (r, g, b, a))


def new_canvas(size: int) -> Image.Image:
    return Image.new("RGBA", (size, size), (0, 0, 0, 0))


def save(im: Image.Image, path: pathlib.Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path, optimize=True)


# ── touch glyphs ─────────────────────────────────────────────────────
def gen_joy_base() -> Image.Image:
    im = new_canvas(256)
    d = ImageDraw.Draw(im)
    c, r = 128, 108
    d.ellipse((c - r, c - r, c + r, c + r), fill=PANEL + (140,), outline=BRASS_DIM + (200,), width=6)
    d.ellipse((c - r + 10, c - r + 10, c + r - 10, c + r - 10), outline=PANEL_EDGE + (120,), width=2)
    return cap_alpha(im, MAX_ALPHA)


def gen_joy_knob() -> Image.Image:
    im = new_canvas(256)
    d = ImageDraw.Draw(im)
    c, r = 128, 62
    d.ellipse((c - r, c - r, c + r, c + r), fill=BRASS + (210,), outline=BRASS_DIM + (230,), width=5)
    d.ellipse((c - r + 16, c - r + 16, c + r - 16, c + r - 16), outline=BONE + (90,), width=3)
    return cap_alpha(im, MAX_ALPHA)


def gen_interact() -> Image.Image:
    """Lantern-in-hand glyph: streetlight lantern body over a simple
    open-palm silhouette — reads as "interact with the world"."""
    im = new_canvas(128)
    d = ImageDraw.Draw(im)
    # hand: rounded trapezoid palm + short fingers, steel
    d.rounded_rectangle((34, 70, 94, 108), radius=10, fill=STEEL + (210,))
    for fx in (40, 54, 68, 82):
        d.rounded_rectangle((fx, 56, fx + 10, 76), radius=4, fill=STEEL + (200,))
    # lantern: brass ring loop + body + warm glow, floating just above the palm
    d.line((64, 40, 64, 52), fill=BRASS + (220,), width=4)
    d.rounded_rectangle((48, 14, 80, 46), radius=8, fill=BRASS + (225,), outline=BRASS_DIM + (240,), width=3)
    d.ellipse((56, 22, 72, 38), fill=BONE + (230,))
    return cap_alpha(im, MAX_ALPHA)


def gen_pause() -> Image.Image:
    im = new_canvas(128)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((40, 28, 56, 100), radius=6, fill=BONE + (225,))
    d.rounded_rectangle((72, 28, 88, 100), radius=6, fill=BONE + (225,))
    return cap_alpha(im, MAX_ALPHA)


def gen_back() -> Image.Image:
    im = new_canvas(128)
    d = ImageDraw.Draw(im)
    d.line((84, 24, 40, 64), fill=BONE + (225,), width=14, joint="curve")
    d.line((40, 64, 84, 104), fill=BONE + (225,), width=14, joint="curve")
    return cap_alpha(im, MAX_ALPHA)


def gen_help_controls() -> Image.Image:
    """D-pad-style four-arrow glyph — reads as "controls" at a glance."""
    im = new_canvas(96)
    d = ImageDraw.Draw(im)
    c = 48
    for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
        cx, cy = c + dx * 26, c + dy * 26
        d.rounded_rectangle((cx - 12, cy - 12, cx + 12, cy + 12), radius=4, fill=STEEL + (225,))
    d.rounded_rectangle((c - 12, c - 12, c + 12, c + 12), radius=4, fill=BRASS + (225,))
    return cap_alpha(im, MAX_ALPHA)


def gen_help_battery() -> Image.Image:
    im = new_canvas(96)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((16, 30, 76, 66), radius=6, outline=BONE + (230,), width=5)
    d.rectangle((76, 40, 84, 56), fill=BONE + (230,))
    d.rounded_rectangle((22, 36, 58, 60), radius=3, fill=BRASS + (225,))
    return cap_alpha(im, MAX_ALPHA)


def gen_help_puzzle() -> Image.Image:
    """Cable-box puzzle glyph: plug seating into a socket."""
    im = new_canvas(96)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((50, 30, 82, 66), radius=6, outline=BONE + (230,), width=5)
    d.rectangle((18, 42, 52, 54), fill=BRASS + (225,))
    for px in (24, 34):
        d.rectangle((px, 34, px + 4, 42), fill=BRASS + (225,))
    return cap_alpha(im, MAX_ALPHA)


def gen_help_stealth() -> Image.Image:
    """Eye-with-slash glyph — universal "hidden / not seen" read."""
    im = new_canvas(96)
    d = ImageDraw.Draw(im)
    d.arc((14, 30, 82, 66), start=200, end=340, fill=STEEL + (225,), width=6)
    d.arc((14, 30, 82, 66), start=20, end=160, fill=STEEL + (225,), width=6)
    d.ellipse((40, 40, 56, 56), fill=BRASS + (225,))
    d.line((16, 20, 80, 76), fill=EMBER + (225,), width=6)
    return cap_alpha(im, MAX_ALPHA)


TOUCH_SPEC = {
    "touch_joy_base_256.png": gen_joy_base,
    "touch_joy_knob_256.png": gen_joy_knob,
    "touch_interact_128.png": gen_interact,
    "touch_pause_128.png": gen_pause,
    "touch_back_128.png": gen_back,
    "help_controls_96.png": gen_help_controls,
    "help_battery_96.png": gen_help_battery,
    "help_puzzle_96.png": gen_help_puzzle,
    "help_stealth_96.png": gen_help_stealth,
}
TOUCH_SIZE = {"touch_joy_base_256.png": 256, "touch_joy_knob_256.png": 256,
              "touch_interact_128.png": 128, "touch_pause_128.png": 128,
              "touch_back_128.png": 128, "help_controls_96.png": 96,
              "help_battery_96.png": 96, "help_puzzle_96.png": 96,
              "help_stealth_96.png": 96}

# ── onboard stills (1024x576, opaque, "loading art" class) ─────────────
W, H = 1024, 576


def _base(im: Image.Image) -> ImageDraw.ImageDraw:
    d = ImageDraw.Draw(im, "RGBA")
    d.rectangle((0, 0, W, H), fill=BG_DEEP)
    return d


def _panel_silhouette(d: ImageDraw.ImageDraw, x: int, w: int, h: int) -> None:
    d.rectangle((x, H - h, x + w, H), fill=PANEL)
    d.rectangle((x, H - h, x + w, H - h + 4), fill=PANEL_EDGE)


def gen_onboard_05() -> Image.Image:
    """Light cone + battery — the flashlight tutorial beat."""
    im = Image.new("RGB", (W, H), BG_DEEP)
    d = _base(im)
    for x, w, h in ((60, 140, 220), (900 - 60, 150, 260)):
        _panel_silhouette(d, x if x < 500 else W - x - w, w, h)
    # single warm light source: a cone from top-left toward center
    d.polygon([(120, 90), (520, 300), (120, 420)], fill=(0xc9, 0xa2, 0x4a, 60))
    d.ellipse((90, 70, 150, 130), fill=BRASS)
    d.ellipse((105, 85, 135, 115), fill=BONE)
    # battery glyph, bottom-center, cool (no second light source)
    bx, by = W // 2 - 60, H - 150
    d.rounded_rectangle((bx, by, bx + 120, by + 70), radius=8, outline=STEEL, width=5)
    d.rectangle((bx + 120, by + 22, bx + 132, by + 48), fill=STEEL)
    d.rounded_rectangle((bx + 10, by + 10, bx + 70, by + 60), radius=4, fill=BRASS_DIM)
    return clamp_rgb(im).convert("RGB")


def gen_onboard_06() -> Image.Image:
    """Cable puzzle box — the substation minigame tutorial beat."""
    im = Image.new("RGB", (W, H), BG_DEEP)
    d = _base(im)
    _panel_silhouette(d, 40, 180, 200)
    _panel_silhouette(d, W - 220, 180, 260)
    # the box itself, centered, warm-lit (one light source: the box glow)
    bx, by, bw, bh = W // 2 - 160, H // 2 - 110, 320, 220
    d.rounded_rectangle((bx, by, bx + bw, by + bh), radius=14, outline=BONE, width=6, fill=PANEL)
    d.rectangle((bx, by, bx + bw, by + 18), fill=PANEL_EDGE)
    ports = [(bx + 40, by + 60), (bx + 40, by + 140), (bx + bw - 40, by + 60), (bx + bw - 40, by + 140)]
    for px, py in ports:
        d.ellipse((px - 16, py - 16, px + 16, py + 16), outline=BRASS_DIM, width=4)
    d.line([ports[0], ports[3]], fill=BRASS, width=8)
    d.line([ports[1], ports[2]], fill=BRASS, width=8)
    for px, py in ports:
        d.ellipse((px - 8, py - 8, px + 8, py + 8), fill=BRASS)
    return clamp_rgb(im).convert("RGB")


def gen_onboard_07() -> Image.Image:
    """Crouch vs hunter cone — the stealth tutorial beat."""
    im = Image.new("RGB", (W, H), BG_DEEP)
    d = _base(im)
    _panel_silhouette(d, 0, 260, 180)
    _panel_silhouette(d, W - 200, 200, 230)
    # hunter's vision cone (ember — the only "danger" chroma), from the right
    apex = (W - 140, H // 2 - 40)
    d.polygon([apex, (apex[0] - 520, apex[1] - 170), (apex[0] - 520, apex[1] + 90)],
              fill=(0xb4, 0x45, 0x2f, 55))
    d.ellipse((apex[0] - 14, apex[1] - 14, apex[0] + 14, apex[1] + 14), fill=EMBER)
    # crouching player silhouette, low profile, just outside the cone edge
    px0, py0 = 190, H - 120
    d.ellipse((px0 - 16, py0 - 66, px0 + 16, py0 - 34), fill=BONE)        # head
    d.rounded_rectangle((px0 - 28, py0 - 40, px0 + 28, py0), radius=10, fill=STEEL)  # crouched body
    return clamp_rgb(im).convert("RGB")


ONBOARD_SPEC = {
    "onboard_05_light_cone_1024x576.png": gen_onboard_05,
    "onboard_06_cable_box_1024x576.png": gen_onboard_06,
    "onboard_07_crouch_hunter_1024x576.png": gen_onboard_07,
}


def build() -> None:
    for name, fn in TOUCH_SPEC.items():
        save(fn(), TOUCH / name)
    for name, fn in ONBOARD_SPEC.items():
        save(fn(), ONBOARD / name)
    print(f"wrote {len(TOUCH_SPEC)} touch glyphs -> {TOUCH}")
    print(f"wrote {len(ONBOARD_SPEC)} onboard stills -> {ONBOARD}")


def check() -> int:
    fails = []
    for name, size in TOUCH_SIZE.items():
        p = TOUCH / name
        if not p.exists():
            fails.append(f"{name} missing"); continue
        im = Image.open(p)
        if im.size != (size, size):
            fails.append(f"{name} is {im.size}, want ({size},{size})")
        kb = p.stat().st_size / 1024.0
        if kb > 30:
            fails.append(f"{name} is {kb:.1f} KB, want <=30 KB")
        rgba = im.convert("RGBA")
        a = rgba.getchannel("A")
        if a.getextrema()[1] > MAX_ALPHA:
            fails.append(f"{name} alpha max {a.getextrema()[1]} > {MAX_ALPHA}")
        # only check RGB purity where alpha > 0 (opaque-ish content)
        opaque = Image.composite(rgba.convert("RGB"), Image.new("RGB", im.size, (LO, LO, LO)), a)
        ex = opaque.getextrema()
        if any(lo < LO or hi > HI for lo, hi in ex):
            fails.append(f"{name} RGB extrema {ex} outside [{LO},{HI}]")
    for name in ONBOARD_SPEC:
        p = ONBOARD / name
        if not p.exists():
            fails.append(f"{name} missing"); continue
        im = Image.open(p)
        if im.size != (W, H):
            fails.append(f"{name} is {im.size}, want ({W},{H})")
        ex = im.convert("RGB").getextrema()
        if any(lo < LO or hi > HI for lo, hi in ex):
            fails.append(f"{name} RGB extrema {ex} outside [{LO},{HI}]")
    for f in fails:
        print("  FAIL", f)
    print("mobile art pass check:", "GREEN" if not fails else f"{len(fails)} FAIL")
    return 0 if not fails else 1


if __name__ == "__main__":
    sys.exit(check() if "--check" in sys.argv else (build() or check()))
