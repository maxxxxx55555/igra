#!/usr/bin/env python3
"""AF-MENU-STYLE: every UI chrome colour must be one of the main-menu palette tokens.

The owner asked for the whole interface to be dressed exactly like the game's
main screen (`scenes/ui/main_menu.tscn` + `scripts/ui/theme_provider.gd` +
`docs/STYLE_GUIDE.md` section 8, owner canon 2026-10-29). Theme drift used to
be invisible to every gate: eleven UI scenes shipped off-canon near-black
blue, pure yellow, warm brown and pure-red scrims while the menu used bg-deep
/ brass / panel. This gate reads the canon straight from ThemeProvider so a
token change and the check can never disagree.

Scope: UI chrome only — `scenes/ui/*.tscn` and `scripts/ui/*.gd`. Three files
are deliberately out of scope and are NOT exemptions for UI chrome:
  * scripts/ui/theme_provider.gd — the canon source itself;
  * scripts/ui/visual_style.gd — procedural WORLD art (tiles, silhouettes),
    governed by STYLE_GUIDE section 3, not by the UI chrome palette;
  * scripts/ui/asset_registry.gd — procedural placeholder textures for
    missing PNG art, also world art (STYLE_GUIDE section 3).

Functional greyscale `modulate` transforms (r == g == b, e.g. a 50 % dim on a
locked skill node or a fully transparent splash) are not colour tokens and are
allowed only on `modulate =` lines.

--demo mutates one canon colour into an off-canon purple and asserts the gate
FAILS on the mutant while the real tree PASSES — a mutation that bites.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
PROVIDER = ROOT / "scripts" / "ui" / "theme_provider.gd"
SCENES = sorted((ROOT / "scenes" / "ui").glob("*.tscn"))
SCRIPTS = sorted((ROOT / "scripts" / "ui").glob("*.gd"))
SKIP_SCRIPTS = {
    "theme_provider.gd",   # canon source
    "visual_style.gd",     # procedural world art
    "asset_registry.gd",   # procedural placeholder world art
}

# Heritage + accessibility tokens that are canon but not declared in ThemeProvider.
EXTRA = {
    "8a7338",  # heritage brass-dim, in consistency_check.py PALETTE
    "4a9ab5",  # info teal, in consistency_check.py PALETTE
    "5f8a4e",  # stamina, in consistency_check.py PALETTE
    "e8695a",  # lifted ember for small danger text on dark fills
    "1c1e1d",  # panel-hover
    "9e8645",  # brass-dim
    "e6cf6e",  # legacy subtitle yellow (kept for the A11Y three-colour option)
    "7fc4d9",  # legacy subtitle cyan (kept for the A11Y three-colour option)
}
TOL = 0.006

FLOAT_COLOR = re.compile(
    r"Color\(\s*([0-9.]+)\s*,\s*([0-9.]+)\s*,\s*([0-9.]+)\s*,?\s*([0-9.]+)?\s*\)")
HEX_COLOR = re.compile(r'Color\(\s*["\']#?([0-9a-fA-F]{6})["\']\s*\)')


def canon_rgbs():
    """The single source of truth: ThemeProvider's COLOR_* constants."""
    text = PROVIDER.read_text(encoding="utf-8")
    out = []
    for hexv in re.findall(r'const\s+COLOR_\w+\s*:=\s*Color\("#([0-9a-fA-F]{6})"\)', text):
        out.append(tuple(int(hexv[i:i + 2], 16) / 255.0 for i in (0, 2, 4)))
    for hexv in EXTRA:
        out.append(tuple(int(hexv[i:i + 2], 16) / 255.0 for i in (0, 2, 4)))
    assert len(out) >= 15, "ThemeProvider palette did not parse — gate would be vacuous"
    return out


def allowed(rgb, canon):
    return any(all(abs(a - b) < TOL for a, b in zip(rgb, c)) for c in canon)


def findings(canon):
    out = []
    for f in SCENES:
        for i, line in enumerate(f.read_text(encoding="utf-8").splitlines(), 1):
            for m in FLOAT_COLOR.finditer(line):
                rgb = tuple(float(x) for x in m.group(1, 2, 3))
                if allowed(rgb, canon):
                    continue
                greyscale = max(rgb) - min(rgb) < 0.001
                alpha = float(m.group(4)) if m.group(4) is not None else 1.0
                if alpha == 0.0:
                    continue  # fully transparent: no pixel is ever drawn
                if greyscale and "modulate" in line:
                    continue  # a functional transform, not a colour token
                out.append("%s:%d off-canon UI colour rgb=%s :: %s"
                           % (f.relative_to(ROOT).as_posix(), i, rgb, line.strip()[:80]))
    for f in SCRIPTS:
        if f.name in SKIP_SCRIPTS:
            continue
        for i, line in enumerate(f.read_text(encoding="utf-8").splitlines(), 1):
            for m in HEX_COLOR.finditer(line):
                if m.group(1).lower() not in {c for c in EXTRA} and not allowed(
                        tuple(int(m.group(1)[j:j + 2], 16) / 255.0 for j in (0, 2, 4)), canon):
                    out.append("%s:%d off-canon UI colour #%s :: %s"
                               % (f.relative_to(ROOT).as_posix(), i, m.group(1), line.strip()[:80]))
    return out


def demo(canon):
    """Inject a purple gradient colour into a real UI scene and prove we catch it."""
    f = ROOT / "scenes" / "ui" / "main_menu.tscn"
    real = f.read_text(encoding="utf-8")
    target = "color = Color(0.0235294, 0.0588235, 0.0745098, 1.0000)"
    assert target in real, "demo anchor missing in main_menu.tscn"
    mutant = real.replace(target, "color = Color(0.42, 0.13, 0.68, 1.0)", 1)
    bad_real = [x for x in findings(canon) if x.startswith("scenes/ui/main_menu.tscn")]
    # Evaluate the mutant with the exact same rules the real tree is judged by.
    mutant_bad = []
    for i, line in enumerate(mutant.splitlines(), 1):
        for m in FLOAT_COLOR.finditer(line):
            rgb = tuple(float(x) for x in m.group(1, 2, 3))
            alpha = float(m.group(4)) if m.group(4) is not None else 1.0
            if alpha == 0.0:
                continue
            if not allowed(rgb, canon):
                mutant_bad.append((i, rgb))
    bites = (not bad_real) and bool(mutant_bad) and mutant != real
    print("menu_style_unify_check --demo: real=%s mutant=%s changed=%s -> %s"
          % ("PASS" if not bad_real else "FAIL",
             "FAIL" if mutant_bad else "PASS", mutant != real,
             "BITES" if bites else "VACUOUS"))
    return 0 if bites else 1


def main(argv):
    canon = canon_rgbs()
    if "--demo" in argv:
        return demo(canon)
    bad = findings(canon)
    for b in bad:
        print("FAIL", b)
    print("menu_style_unify_check: %d finding(s), %d canon tokens, %d UI files"
          % (len(bad), len(canon), len(SCENES) + len(SCRIPTS) - len(SKIP_SCRIPTS)))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
