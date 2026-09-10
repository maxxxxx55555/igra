#!/usr/bin/env python3
"""Prove DARK / PARTIAL / STREETS / FULL are visually distinct in code
(STATIC_AUDIT #7 emissive_windows, #8 streetlight_3d) — values, not vibes.

Ports the post-fix _apply_stage / _update_light logic from
scripts/world/streetlight_3d.gd and scripts/visual/emissive_windows.gd and
tabulates the per-stage output. Also shows the pre-fix collapse (PARTIAL == DARK).

No engine. Run: python tools/qa_sim/lighting_stage_sim.py
"""
import sys


# ---------------- streetlight_3d.gd ----------------
def streetlight_pre(stage):
    on = stage >= 2
    if not on:
        return dict(on=False, spot_e=0.0, spot_att=None, glow_e=0.0, glow_range=None)
    if stage >= 3:
        return dict(on=True, spot_e=3.5, spot_att=1.0, glow_e=1.5, glow_range=8.0)
    return dict(on=True, spot_e=2.5, spot_att=1.5, glow_e=1.0, glow_range=6.0)


def streetlight_post(stage, in_partial_set):
    partial_lit = stage == 1 and in_partial_set
    on = stage >= 2 or partial_lit
    escale = 0.55 if (partial_lit and stage < 2) else 1.0
    if not on:
        return dict(on=False, spot_e=0.0, spot_att=None, glow_e=0.0, glow_range=None, escale=escale)
    if stage >= 3:
        d = dict(spot_e=3.5, spot_att=1.0, glow_e=1.5, glow_range=8.0)
    elif stage >= 2:
        d = dict(spot_e=2.5, spot_att=1.5, glow_e=1.0, glow_range=6.0)
    else:  # PARTIAL
        d = dict(spot_e=1.4, spot_att=2.0, glow_e=0.5, glow_range=4.0)
    d.update(on=True, escale=escale)
    return d


# ---------------- emissive_windows.gd ----------------
STAGE_GATE = [0.10, 0.45, 0.85, 1.0]
STAGE_BRIGHT = [0.35, 0.60, 0.85, 1.0]
DENSITY = 0.55


def windows_pre(stage):
    # never read stage at all — one fixed roll of `density` lit, full colour
    return dict(lit_fraction=round(DENSITY, 3), brightness=1.0)


def windows_post(stage):
    s = max(0, min(3, stage))
    return dict(lit_fraction=round(DENSITY * STAGE_GATE[s], 3), brightness=STAGE_BRIGHT[s])


def distinct(rows):
    """True if every row differs from every other row."""
    seen = [tuple(sorted(r.items())) for r in rows]
    return len(set(seen)) == len(seen)


def main():
    names = ["DARK(0)", "PARTIAL(1)", "STREETS(2)", "FULL(3)"]
    ok = True

    print("=== streetlight_3d.gd ===")
    print("  PRE-FIX (partial lamp collapses to DARK):")
    pre = [streetlight_pre(s) for s in range(4)]
    for n, r in zip(names, pre):
        print(f"    {n:11s} {r}")
    collapsed = pre[0] == pre[1]
    print(f"    -> PARTIAL == DARK ? {collapsed}   (this is the #8 defect)\n")

    print("  POST-FIX (a lamp in the ~40% partial set):")
    post = [streetlight_post(s, in_partial_set=True) for s in range(4)]
    for n, r in zip(names, post):
        print(f"    {n:11s} {r}")
    d = distinct(post)
    ok &= d and post[0] != post[1]
    print(f"    -> all 4 stages distinct ? {d} ; PARTIAL != DARK ? {post[0] != post[1]}")
    print("  POST-FIX (a lamp NOT in the partial set): PARTIAL stays off, like DARK — by design (\"часть фонарей\")\n")

    print("=== emissive_windows.gd ===")
    print("  PRE-FIX (never reads stage):")
    wpre = [windows_pre(s) for s in range(4)]
    for n, r in zip(names, wpre):
        print(f"    {n:11s} {r}")
    print(f"    -> every stage identical ? {len(set(tuple(r.items()) for r in wpre)) == 1}   (this is the #7 defect)\n")

    print("  POST-FIX (lit fraction = density * stage_gate, brightness = stage_bright):")
    wpost = [windows_post(s) for s in range(4)]
    for n, r in zip(names, wpost):
        print(f"    {n:11s} {r}")
    wd = distinct(wpost)
    ok &= wd and wpost[3] == dict(lit_fraction=round(DENSITY, 3), brightness=1.0)
    print(f"    -> all 4 stages distinct ? {wd} ; FULL matches pre-fix behaviour ? "
          f"{wpost[3] == dict(lit_fraction=round(DENSITY, 3), brightness=1.0)}")
    print()

    print("PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
