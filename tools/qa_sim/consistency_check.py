# -*- coding: utf-8 -*-
"""CON1 (Session 23): how consistent the interface and the palette of the world are, read from the sources (docs/UI_CONSISTENCY.md, docs/VISUAL_CONSISTENCY.md).

usage: python tools/qa_sim/consistency_check.py [--check] [--demo]
Prints the tables of the two documents. --check fails (exit 1) when
  - a font file outside the canon set (GDD 11.3: Roboto Condensed, Bebas Neue, Share Tech Mono; Rajdhani is the base of the localization fallback chain; OpenDyslexic is the Dyslexia Font option) is named by a shipped script, scene or theme,
  - a UI icon is not the brass family (one colour, the brass token of docs/STYLE_GUIDE.md, a 64 x 64 box, strokes of 4, no byte order mark),
  - a font size in a UI scene or script is one the ladder below does not hold (a ratchet: a new size is a decision, then it is added here),
  - a margin or separation of a UI scene is odd,
  - a facade colour of the skyline palettes is over 25 % chroma, the spread of its largest and smallest channel on 0..1 (HSV saturation reads a very dark colour as vivid: the canon facade #0f151d is 0.48).
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
import retint_ui_chrome  # noqa: E402  (the table of the old token colours and the files that hold UI colours)
CANON_FONTS = {"RobotoCondensed-Regular.ttf", "BebasNeue-Regular.ttf", "ShareTechMono-Regular.ttf", "Rajdhani-Regular.ttf", "OpenDyslexic-Regular.ttf"}
BRASS = "#c9a24a"
SIZE_LADDER = {8, 9, 10, 11, 12, 13, 14, 15, 16, 18, 20, 22, 24, 28, 30, 32, 36, 44, 64}  # 15 and 30: the Mono and Huge steps of the type scale of docs/VISUAL_PASS.md W9 (theme_provider.gd)
MAX_FACADE_CHROMA = 0.25
PALETTE = {"0c1016", "141b24", "2a3340", "c9a24a", "8a7338", "b4452f", "aeb6bf", "d8d2c4", "5f8a4e", "4a9ab5",
           "060f13", "0f1314", "1c1e1d", "5a4a2a", "8a8a85", "d8d5cc", "c0392b"}  # the last seven: the owner canon of 2026-10-29


def shipped(globs):
    for pattern in globs:
        for p in sorted(ROOT.glob(pattern)):
            rel = p.relative_to(ROOT).as_posix()
            if not rel.startswith(("scripts/tools/", "scenes/tools/")):
                yield p, p.read_text(encoding="utf-8", errors="replace")


def fonts():
    found = {}
    for p, text in shipped(["scripts/**/*.gd", "scenes/**/*.tscn", "assets/ui/*.tres", "data/ui/*.tres"]):
        for name in re.findall(r"res://assets/fonts/([\w\-]+\.(?:ttf|otf))", text):
            found.setdefault(name, set()).add(p.name)
    return found


def icons():
    rows = []
    for p in sorted((ROOT / "assets/ui").glob("ui_*.svg")):
        raw = p.read_bytes()
        text = raw.decode("utf-8-sig", errors="replace")
        colours = {c.lower() for c in re.findall(r'(?:fill|stroke)="(#[0-9a-fA-F]{6})"', text)}
        rows.append((p.name, raw[:3] == b"\xef\xbb\xbf", re.search(r'viewBox="([^"]*)"', text).group(1) if re.search(r'viewBox="([^"]*)"', text) else "-", sorted(colours), sorted(set(re.findall(r'stroke-width="([\d.]+)"', text)))))
    return rows


def font_sizes():
    sizes = {}
    for p, text in shipped(["scripts/ui/**/*.gd", "scenes/ui/**/*.tscn"]):
        for n in re.findall(r"theme_override_font_sizes/font_size = (\d+)", text) + re.findall(r'add_theme_font_size_override\("[a-z_]+",\s*(\d+)\)', text):
            sizes.setdefault(int(n), set()).add(p.name)
    for n in re.findall(r"const FONT_SIZE_\w+: int = (\d+)", (ROOT / "scripts/ui/theme_provider.gd").read_text(encoding="utf-8")):
        sizes.setdefault(int(n), set()).add("theme_provider.gd")
    return sizes


def spacings():
    values = {}
    for p, text in shipped(["scenes/ui/**/*.tscn"]):
        for n in re.findall(r"theme_override_constants/(?:margin_\w+|h?v?_?separation) = (-?\d+)", text):
            values.setdefault(int(n), set()).add(p.name)
    return values


def ui_colours():
    counts = {}
    for p, text in shipped(["scripts/ui/*.gd", "scenes/ui/*.tscn"]):
        for m in re.finditer(r'Color\(\s*"#?([0-9a-fA-F]{6})"\s*\)|#([0-9a-fA-F]{6})\b', text):
            h = (m.group(1) or m.group(2)).lower()
            counts[h] = counts.get(h, 0) + 1
    return counts


def chroma(hex6):
    r, g, b = (int(hex6[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
    return max(r, g, b) - min(r, g, b)


def facades():
    text = (ROOT / "scripts/world/skyline.gd").read_text(encoding="utf-8")
    block = text[text.index("const PALETTES"):text.index("const WIN_BRASS")]
    rows = {}
    for district, body in re.findall(r'&"(\w+)":\s*\[\[(.*?)\],', block, re.S):
        rows[district] = [h.lower() for h in re.findall(r'Color\("#([0-9a-fA-F]{6})"\)', body)]
    return rows


def report():
    out, bad = [], []
    f = fonts()
    out += ["Fonts named by shipped sources", "", "| Font file | Used by |", "|---|---|"]
    for name, users in sorted(f.items()):
        out.append("| %s%s | %s |" % (name, "" if name in CANON_FONTS else " (off canon)", ", ".join(sorted(users)[:6])))
        if name not in CANON_FONTS:
            bad.append("font %s is not in the canon set" % name)
    out += ["", "UI icons (assets/ui)", "", "| Icon | BOM | viewBox | Colours | Stroke widths |", "|---|---|---|---|---|"]
    for name, bom, box, colours, widths in icons():
        out.append("| %s | %s | %s | %s | %s |" % (name, "yes" if bom else "no", box, " ".join(colours), " ".join(widths) or "-"))
        if bom or box != "0 0 64 64" or colours != [BRASS] or any(w != "4" for w in widths):
            bad.append("icon %s is not the brass family (BOM %s, viewBox %s, colours %s, strokes %s)" % (name, bom, box, colours, widths))
    s = font_sizes()
    out += ["", "Font sizes in UI scenes and scripts (px at the 960 x 540 base)", "", "| Size | Files |", "|---|---|"]
    for n in sorted(s):
        out.append("| %d | %d |" % (n, len(s[n])))
        if n not in SIZE_LADDER:
            bad.append("font size %d is not on the ladder" % n)
    out.append("")
    out.append("%d distinct sizes, %d of them under 12 px." % (len(s), sum(1 for n in s if n < 12)))
    sp = spacings()
    out += ["", "Margins and separations of UI scenes: %s (all even: %s)" % (", ".join(str(v) for v in sorted(sp)), all(v % 2 == 0 for v in sp))]
    bad += ["odd spacing %d" % v for v in sp if v % 2]
    c = ui_colours()
    on = sum(n for h, n in c.items() if h in PALETTE)
    out += ["", "Hex colours of UI scripts and scenes: %d literals, %d distinct, %d (%.0f %%) in the ten tokens of the palette; off the palette: %s" % (sum(c.values()), len(c), on, 100.0 * on / max(1, sum(c.values())), " ".join(sorted(h for h in c if h not in PALETTE)))]
    stale = ["%s:%d" % (p.relative_to(ROOT).as_posix(), n) for p, text in shipped(retint_ui_chrome.TEXT_GLOBS) for n, line in enumerate(text.splitlines(), 1) if retint_ui_chrome.retint_text(line) != line]
    bad += ["a colour of the old tokens at " + s for s in stale]
    fac = facades()
    out += ["", "Facade palettes of the skyline (chroma of each of the three colours, 0..1; the canon facade #0f151d is %.2f)" % chroma("0f151d"), "", "| District | Chroma |", "|---|---|"]
    for district, colours in sorted(fac.items()):
        sats = [chroma(h) for h in colours]
        out.append("| %s | %s |" % (district, " ".join("%.2f" % v for v in sats)))
        if any(v > MAX_FACADE_CHROMA for v in sats):
            bad.append("facade palette of %s is over %.0f %% chroma" % (district, 100 * MAX_FACADE_CHROMA))
    return "\n".join(out), bad


def demo():
    assert abs(chroma("ff0000") - 1.0) < 1e-9 and chroma("808080") == 0.0
    assert {int(n) for n in re.findall(r"theme_override_font_sizes/font_size = (\d+)", "theme_override_font_sizes/font_size = 22")} == {22}
    text, bad = report()
    assert "Fonts named" in text and isinstance(bad, list)
    assert retint_ui_chrome.retint_text('Color("#141b24")') != 'Color("#141b24")', "an old token colour is found"
    print("consistency_check demo: the chroma, the size reader and the report are in order")
    return 0


def main(argv):
    if "--demo" in argv:
        return demo()
    text, bad = report()
    print(text)
    for line in bad:
        print("FAIL", line)
    return 1 if ("--check" in argv and bad) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
