# -*- coding: utf-8 -*-
"""D1 (Session 28, docs/DIFFICULTY_INTENT.md rule R1): every line of scripts/enemies/ that hurts the player is announced.

usage: python tools/qa_sim/telegraph_audit.py [--demo]
A call `<player or body>.take_damage(` sits in a function. The function must be the callback of a `_telegraph.warn(<function>)` of the same file (a flash and a sound 0.4 s before the hit), or the landing of a windup
that begins with `_telegraph.cue()` (the Crawler's leap, the Hunter's charge, the Brute's slam), or one of the Architect's two hazards, whose throw goes through the warn and whose beam has its marker (LANDINGS).
A windup constant must last 0.4 s or more. A new attack that hurts at once fails this audit; TEL1 of the closeout (scripts/tools/rc16/s28_checks.gd) measures the same rule in the engine.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
CUE = r"_telegraph\.cue\(\)"
LANDINGS = {
    ("crawler_3d.gd", "_tick_leap"): CUE,
    ("hunter_3d.gd", "_tick_charge"): CUE,
    ("brute_3d.gd", "_slam_and_charge"): CUE,
    ("boss_3d.gd", "_on_body_entered"): r"_telegraph\.warn\(_throw_energy_ball\)",
    ("boss_3d.gd", "_physics_process"): r"beam\.tree_exited\.connect\(ring\.queue_free\)",
}
HIT = re.compile(r"\b(?:player_ref|body)\.take_damage\(")
WINDUPS = re.compile(r"^const (\w*WINDUP\w*): float = ([\d.]+)", re.M)
MIN_WINDUP = 0.4


def audit(files):
    """files: {name: text}. The findings: a hit that is not announced, a windup that is too short."""
    bad = []
    for name, text in files.items():
        fn = ""
        for n, line in enumerate(text.splitlines(), 1):
            m = re.match(r"\s*func (\w+)", line)
            fn = m.group(1) if m else fn
            if HIT.search(line) and fn != "take_damage":
                sentinel = LANDINGS.get((name, fn))
                if not (re.search(r"_telegraph\.warn\(%s\)" % re.escape(fn), text) or (sentinel and re.search(sentinel, text))):
                    bad.append("%s:%d: %s hurts the player and nothing announces it (no _telegraph.warn(%s), not a landing of a cued windup)" % (name, n, fn, fn))
        bad += ["%s: %s is %s s, under %.1f s" % (name, k, v, MIN_WINDUP) for k, v in WINDUPS.findall(text) if float(v) < MIN_WINDUP]
    return bad


def demo():
    hit = "func _state_attack(delta: float) -> void:\n\tplayer_ref.take_damage(attack_damage, global_position)\n"
    assert audit({"x_3d.gd": hit}) and "hurts the player" in audit({"x_3d.gd": hit})[0]
    warned = "func _state_attack(delta: float) -> void:\n\t_telegraph.warn(_hit)\n\nfunc _hit() -> void:\n\tplayer_ref.take_damage(attack_damage, global_position)\n"
    assert audit({"x_3d.gd": warned}) == []
    assert audit({"x_3d.gd": "const LEAP_WINDUP: float = 0.2\n"}) == ["x_3d.gd: LEAP_WINDUP is 0.2 s, under 0.4 s"]
    assert audit({"crawler_3d.gd": "func _tick_leap(d: float) -> void:\n\tplayer_ref.take_damage(1.0)\n"})
    assert audit({"crawler_3d.gd": "func _tick_leap(d: float) -> void:\n\t_telegraph.cue()\n\tplayer_ref.take_damage(1.0)\n"}) == []
    print("telegraph_audit demo: a hit at once fails, a warned hit and a cued landing pass, a windup under 0.4 s fails")
    return 0


def main(argv):
    if "--demo" in argv:
        return demo()
    files = {p.name: p.read_text(encoding="utf-8", errors="replace") for p in sorted((ROOT / "scripts/enemies").glob("*.gd"))}
    bad = audit(files)
    for line in bad:
        print("FAIL", line)
    print("telegraph_audit: %d script(s) read, %d finding(s)" % (len(files), len(bad)))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
