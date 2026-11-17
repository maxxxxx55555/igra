#!/usr/bin/env python3
"""T7 two-finger touch regression: a HUD touch handler must not restrict
activation to the first finger (index == 0).

KNOWN_ISSUES.md:11 — "on a phone, whether a second finger presses a HUD
Button while a thumb holds the joystick is not verified (Godot turns only
the first finger into a click)." The historical bug shape is a touch-press
handler that only fires when `event.index == 0` (or skips when
`event.index != 0`): the second finger would then never reach the HUD
control. The game's real touch code is index-agnostic (it guards by
`device != DEVICE_ID_EMULATION`, not by index), so this gate must PASS on
the real tree and FAIL if an index==0 restriction is (re)introduced.

Hard headless constraint (verified 2026-11-11): Input.parse_input_event()
does not dispatch synthetic GUI input to a Control in --headless, so the
runtime probe (scripts/tools/_two_finger_probe.gd) exercises the game's
own touch handlers directly instead of Godot's BaseButton. This static
gate locks the index-agnostic invariant in source; the --demo mode
re-introduces the index==0 restriction and confirms the gate FAILS on that
mutant while the real file PASSES — a mutation that bites.

Real-tree PASS condition: hud_3d.gd exposes an InputEventScreenTouch press
handler AND contains no `index == 0` / `index != 0` restriction around it.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
HUD = ROOT / "scripts" / "ui" / "hud_3d.gd"

# A touch-press handler that only fires for the first finger.
RESTRICTION = re.compile(r"\bindex\s*(==|!=)\s*0\b")
# The game's index-agnostic screen-touch handler must be present.
SCREEN_TOUCH = re.compile(r"event is InputEventScreenTouch and event\.pressed")

# Mutation: inject an index==0 restriction into the quick-slot handler.
MUT = re.compile(
    r"(elif event is InputEventScreenTouch and event\.pressed and event\.device != InputEvent\.DEVICE_ID_EMULATION:\n)"
    r"(\s*)_use_quick_slot\(si\)"
)


def findings(text: str):
    out = []
    if not SCREEN_TOUCH.search(text):
        out.append("no InputEventScreenTouch press handler in hud_3d.gd "
                   "(the index-agnostic touch entry point is gone)")
    for i, line in enumerate(text.splitlines(), 1):
        if RESTRICTION.search(line):
            out.append("index==0 touch restriction (T7 second-finger bug) at line %d: %s"
                       % (i, line.strip()[-80:]))
    return out


def mutate(text: str) -> str:
    """Re-introduce the historical defect: a second finger is ignored."""
    return MUT.sub(r"\1\2if event.index != 0: return\n\2_use_quick_slot(si)", text)


def main(argv):
    real = HUD.read_text(encoding="utf-8")
    real_bad = findings(real)
    if "--demo" in argv:
        mutant = mutate(real)
        mut_bad = findings(mutant)
        bites = (not real_bad) and bool(mut_bad) and mutant != real
        print("two_finger_touch_check --demo: real=%s mutation=%s changed=%s -> %s"
              % ("PASS" if not real_bad else "FAIL",
                 "FAIL" if mut_bad else "PASS",
                 mutant != real,
                 "BITES" if bites else "VACUOUS"))
        return 0 if bites else 1
    for f in real_bad:
        print("FAIL %s" % f)
    print("two_finger_touch_check: %d finding(s)" % len(real_bad))
    return 1 if real_bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
