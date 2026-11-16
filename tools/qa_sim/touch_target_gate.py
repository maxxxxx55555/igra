#!/usr/bin/env python3
"""T8 touch-target size regression gate.

`scripts/ui/ui_scale.gd` defines `const MIN_TOUCH: float = 48.0`, returned by
`min_touch()` and fed into the HUD button-size floor
(`hud_3d.gd:708` `clampf(..., UiScale.min_touch() / TOUCH_BTN.x, 2.0)` and
`settings_manager.gd:335`). So MIN_TOUCH governs the smallest on-screen touch
target.

Verified (2026-11-12 grep): there is NO `DisplayServer.screen_get_dpi()` /
display-DPI scaling call anywhere in `scripts/`. MIN_TOUCH is therefore a fixed
RAW-PIXEL constant. On a high-DPI phone, 48 raw px is physically smaller than
the platform recommendation (Android 48dp), so the FINAL physical target size is
an OWNER/DEVICE decision taken at P4 device sign-off. That decision is NOT
fabricated here.

This gate's job is narrow and non-weakening: lock the documented floor so nobody
silently drops the minimum touch target below 48 raw px (a regression guard).
The DPI-unsized nature is surfaced as a non-failing WARN for the owner at P4.

Real-tree PASS: MIN_TOUCH present and >= 48.0.
--demo: lower the mutant to 24.0 and confirm the gate FAILS (bites).
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "scripts" / "ui" / "ui_scale.gd"
SCRIPTS = ROOT / "scripts"
FLOOR = 48.0
RE_MIN = re.compile(r"const\s+MIN_TOUCH\s*:\s*float\s*=\s*([0-9]+(?:\.[0-9]+)?)")


def findings(text: str):
    out = []
    m = RE_MIN.search(text)
    if not m:
        out.append("MIN_TOUCH constant missing in ui_scale.gd")
        return out
    val = float(m.group(1))
    if val < FLOOR:
        out.append("MIN_TOUCH=%.1f below documented floor %.1f raw px" % (val, FLOOR))
    return out


def mutate(text: str) -> str:
    """Re-introduce the historical defect: a sub-floor touch target."""
    m = RE_MIN.search(text)
    if not m:
        return text
    return text[: m.start(1)] + "24.0" + text[m.end(1) :]


def dpi_scaled() -> bool:
    """Is there any display-DPI scaling anywhere in scripts/?"""
    for p in SCRIPTS.rglob("*.gd"):
        try:
            if "screen_get_dpi" in p.read_text(encoding="utf-8", errors="ignore"):
                return True
        except Exception:
            pass
    return False


def main(argv):
    real = SRC.read_text(encoding="utf-8")
    real_bad = findings(real)
    scaled = dpi_scaled()
    if "--demo" in argv:
        mutant = mutate(real)
        mut_bad = findings(mutant)
        bites = (not real_bad) and bool(mut_bad) and mutant != real
        print("touch_target_gate --demo: real=%s mutant=%s changed=%s dpi_scaled=%s -> %s"
              % ("PASS" if not real_bad else "FAIL",
                 "FAIL" if mut_bad else "PASS",
                 mutant != real, scaled,
                 "BITES" if bites else "VACUOUS"))
        return 0 if bites else 1
    for f in real_bad:
        print("FAIL %s" % f)
    if not scaled:
        print("WARN MIN_TOUCH is a fixed raw-px constant; no DisplayServer.screen_get_dpi() "
              "scaling in scripts/. Final physical target size is an owner/device decision at P4 (T8).")
    print("touch_target_gate: %d finding(s); MIN_TOUCH floor=%.0f; dpi_scaled=%s"
          % (len(real_bad), FLOOR, scaled))
    return 1 if real_bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
