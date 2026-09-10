#!/usr/bin/env python3
"""Flag i18n strings likely to overflow their UI container (PHASE B.2).

NO-GODOT: can't measure rendered text width. Heuristic: a UI-label-sized
EN string (roughly 3..44 chars — buttons, captions, HUD, toasts, not lore
paragraphs) whose ru / de / fr translation is much longer is a probable
overflow in a fixed-size Label or Button. Lore/paragraph keys (long EN,
shown in autowrap scroll panels) are excluded.

For each flagged key it also greps scripts/ for the usage site and notes
whether that site looks autowrap-safe.

Run: python tools/qa_sim/overflow_check.py
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
I18N = ROOT / "data" / "i18n"
LONG_LOCALES = ["ru", "de", "fr"]

EN_MIN, EN_MAX = 3, 44      # UI-label band
RATIO = 1.7                 # other / en length
OTHER_MIN = 20              # ignore tiny absolute lengths

# key-name prefixes that are always shown in an autowrap scroll panel
PARA_PREFIXES = ("LORE_", "WORLD_", "END_", "ENDING_", "DIARY_", "NEWS_",
                 "RADIO_", "ONBOARD_", "TIP_", "CB_", "ENC_")


def load(loc):
    return json.loads((I18N / f"{loc}.json").read_text(encoding="utf-8"))


def usage(key):
    hits = []
    pat = re.compile(r'(?:LocalizationManager\.tf?|(?<![\w.])tr)\(\s*["\']' + re.escape(key) + r'["\']')
    for gd in ROOT.glob("scripts/**/*.gd"):
        if "tools" in gd.parts:
            continue
        lines = gd.read_text(encoding="utf-8").splitlines()
        for i, ln in enumerate(lines):
            if pat.search(ln):
                ctx = "\n".join(lines[max(0, i - 6):i + 3])
                cl = ctx.lower()
                # Risky only when the widget is given an explicit fixed width
                # AND doesn't wrap. A Button/Label added straight to a
                # VBox/HBox/PanelContainer with no size is container-managed.
                fixed = ("custom_minimum_size = vector2(" in cl
                         or re.search(r"\.size\s*=\s*vector2\(\s*\d", cl) is not None)
                safe = ("autowrap" in cl) or not fixed
                hits.append((str(gd.relative_to(ROOT)), i + 1,
                             "container/autowrap" if safe else "FIXED WIDTH"))
    return hits


def main():
    en = load("en")
    others = {l: load(l) for l in LONG_LOCALES}
    flagged = []
    for k, ev in en.items():
        if not isinstance(ev, str) or k.startswith(PARA_PREFIXES):
            continue
        el = len(ev)
        if not (EN_MIN <= el <= EN_MAX):
            continue
        worst = 0
        worst_loc = ""
        for l, d in others.items():
            ov = d.get(k, ev)
            if len(ov) > worst:
                worst, worst_loc = len(ov), l
        if worst >= OTHER_MIN and el and worst / el >= RATIO:
            flagged.append((round(worst / el, 2), k, ev, worst_loc, others[worst_loc].get(k, ev)))

    flagged.sort(reverse=True)
    print(f"{len(flagged)} keys flagged (EN {EN_MIN}-{EN_MAX} chars, "
          f"ru/de/fr >= {RATIO}x and >= {OTHER_MIN} chars):\n")
    hard = 0
    for ratio, k, ev, wl, ov in flagged:
        sites = usage(k)
        risky = [s for s in sites if s[2] == "FIXED WIDTH"]
        tag = "  <-- fixed-size site" if risky else ""
        if risky:
            hard += 1
        print(f"  {ratio:>4}x  {k}{tag}")
        print(f"         en[{len(ev):>2}] {ev!r}")
        print(f"         {wl}[{len(ov):>2}] {ov!r}")
        for s in sites:
            print(f"         @ {s[0]}:{s[1]}  ({s[2]})")
        if not sites:
            print("         @ (no direct scripts/ usage found — .tscn or indirect)")
        print()

    print(f"{hard} of {len(flagged)} at a FIXED WIDTH text site — want autowrap or a shorter string.")
    # informational: this check never fails the build, it's a review aid
    return 0


if __name__ == "__main__":
    sys.exit(main())
