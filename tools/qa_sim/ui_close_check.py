#!/usr/bin/env python3
"""AF-CLOSE: a blocking screen must end up hidden after UIManager.close().

The rc15 closeout suite intermittently reported
`FAIL V.5 the inventory screen closes`: close() relied solely on a 0.15 s
fade tween callback setting `visible = false`. A killed tween, a re-entrant
open during the fade, or a paused/scaled frame could leave the blocking screen
on top of the game forever - a soft lock on a phone (no Escape key).

The fix has two halves, both required:
  1. a stale `fade_out` meta is cancelled instead of early-returning;
  2. `_arm_fade_out()` arms a pause-mode-independent, time-scale-independent
     deadline that hides the screen if the fade never finished.

--demo removes each half in turn and asserts the gate FAILS on both mutants
while the real tree PASSES - a mutation that bites, twice.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
UIM = ROOT / "scripts" / "ui" / "ui_manager.gd"


def findings(text: str):
    out = []
    if not re.search(r"func _fade_out\(scr: Control\)", text):
        out.append("no _fade_out() in ui_manager.gd")
    if not re.search(r"if scr\.has_meta\(&\"fade_out\"\):\s*\n\s*_cancel_fade_out\(scr\)", text):
        out.append("a stale fade_out meta is not cancelled (early return strands the screen)")
    if not re.search(r"\b_arm_fade_out\(scr, tween, alpha\)", text):
        out.append("close() does not arm the hidden-state failsafe")
    m = re.search(r"func _arm_fade_out\(.*?\n(?=\S|\Z)", text, re.S)
    if not m:
        out.append("_arm_fade_out() helper is missing")
    else:
        body = m.group(0)
        if "create_timer" not in body:
            out.append("no deadline timer in _arm_fade_out()")
        if not re.search(r"create_timer\([^)]*true,\s*false,\s*true\)", body):
            out.append("deadline timer does not ignore pause/time scale (4th arg true)")
        if "scr.visible = false" not in body:
            out.append("deadline does not actually hide the screen")
        if "is_instance_valid(scr)" not in body:
            out.append("deadline does not guard against a freed screen")
    return out


def main(argv):
    real = UIM.read_text(encoding="utf-8")
    real_bad = findings(real)
    if "--demo" in argv:
        mutants = {
            "no_stale_cancel": real.replace(
                "\t\t_cancel_fade_out(scr)  # a stale/stalled fade must not strand the screen open",
                "\t\treturn", 1),
            "no_failsafe": re.sub(
                r"\b_arm_fade_out\(scr, tween, alpha\)",
                "scr.set_meta(&\"fade_out\", [tween, alpha])", real, count=1),
        }
        results = {}
        for name, m in mutants.items():
            results[name] = bool(findings(m)) and m != real
        bites = (not real_bad) and all(results.values())
        print("ui_close_check --demo: real=%s %s changed=%s -> %s"
              % ("PASS" if not real_bad else "FAIL",
                 " ".join("%s=%s" % (k, "FAIL" if v else "PASS") for k, v in results.items()),
                 all(m != real for m in mutants.values()),
                 "BITES" if bites else "VACUOUS"))
        return 0 if bites else 1
    for f in real_bad:
        print("FAIL", f)
    print("ui_close_check: %d finding(s)" % len(real_bad))
    return 1 if real_bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
