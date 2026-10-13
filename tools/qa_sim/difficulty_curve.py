# -*- coding: utf-8 -*-
"""PX1 (Session 23): the enemy strength of each district at each power stage and the player's gains along the spine, read from the sources (docs/DIFFICULTY_CURVE.md).

usage: python tools/qa_sim/difficulty_curve.py [--check] [--demo]
A district spawns `base + bonus(stage)` monsters (`EnemyPool._target_count`, 3 + 3, 2, 1, 0 for DARK, PARTIAL, STREETS, FULL), the roster of the district taken in turn
(`ROSTER_BY_DISTRICT`). The strength of a monster is its hit points times its melee damage (the product that decides who wins a fight of equal rates: the square law of
Lanchester), the strength of a district the sum over its monsters, in thousands. Hit points and damage are read from `data/monsters/monster_*.tres`.
--check fails (exit 1) when
  - a district is not calmer as it is restored (the strength at a later stage is above an earlier one),
  - a step from one district to the next (the DARK strength) is over STEP_LIMIT: a spike,
and prints WATCH for a step over WATCH_STEP in a district where the player gains nothing (no weapon found, no more ammo than before): it is the sharpest rise the player
meets without a new tool, and a playtest question, not a failure.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
STEP_LIMIT = 2.2
WATCH_STEP = 1.8
STAGES = ["DARK", "PARTIAL", "STREETS", "FULL"]


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8", errors="replace")


def monsters():
    out = {}
    for p in sorted((ROOT / "data/monsters").glob("monster_*.tres")):
        text = p.read_text(encoding="utf-8", errors="replace")
        hp, dmg = (float(re.search(r"^%s = ([\d.]+)" % k, text, re.M).group(1)) for k in ("max_hp", "melee_damage"))
        out[p.stem.replace("monster_", "").upper()] = (hp, dmg)
    return out


def rosters():
    text = read("scripts/enemies/enemy_pool.gd")
    body = re.search(r"ROSTER_BY_DISTRICT: Dictionary = \{(.*?)\n\}", text, re.S).group(1)
    base = int(re.search(r"MIN_ENEMIES_PER_DISTRICT: int = (\d+)", text).group(1))
    bonuses = [int(b) for b in re.findall(r"base \+ (\d+)", re.search(r"func _target_count.*?(?=\nfunc )", text, re.S).group(0))] + [0]
    return {d: re.findall(r"\w+", types) for d, types in re.findall(r'&"(\w+)":\s*\[(.*?)\]', body)}, [base + b for b in bonuses]


def spine():
    return re.findall(r'&"(\w+)"', re.search(r"const DISTRICTS: Array\[StringName\] = \[(.*?)\]", read("scripts/world/district_scene_factory.gd"), re.S).group(1))


def gains(order):
    """{district: (weapon found, ammo pickups)} from district_loot.gd."""
    text = read("scripts/world/district_loot.gd")
    finds = dict(re.findall(r'&"(\w+)": &"(\w+)"', re.search(r"const WEAPON_FINDS: Dictionary = \{(.*?)\}", text).group(1)))
    double_from = int(re.search(r"const AMMO_DOUBLE_FROM: int = (\d+)", text).group(1))
    return {d: (finds.get(d, ""), 0 if i <= 0 else (1 if i < double_from else 2)) for i, d in enumerate(order)}


def strengths(order, roster, counts, stats):
    out = {}
    for d in order:
        out[d] = [sum(stats[roster[d][i % len(roster[d])]][0] * stats[roster[d][i % len(roster[d])]][1] for i in range(n)) / 1000.0 for n in counts]
    return out


def judge(order, st, gain):
    """(failures, watches) over the strengths of every district and the player's gains."""
    bad, watch = [], []
    for d in order:
        if any(st[d][i + 1] > st[d][i] for i in range(3)):
            bad.append("%s is not calmer as it is restored: %s" % (d, st[d]))
    for prev, d in zip(order, order[1:]):
        step = st[d][0] / st[prev][0]
        if step > STEP_LIMIT:
            bad.append("%s is a spike: DARK strength x%.2f over %s" % (d, step, prev))
        elif step > WATCH_STEP and not gain[d][0] and gain[d][1] <= gain[prev][1]:
            watch.append("%s: x%.2f over %s with no weapon found and no more ammo" % (d, step, prev))
    return bad, watch


def report():
    stats, (roster, counts), order = monsters(), rosters(), spine()
    st, gain = strengths(order, roster, counts, stats), gains(order)
    lines = ["Monsters per stage (%s): %s" % (", ".join(STAGES), ", ".join(str(n) for n in counts)), "",
             "| District | Roster | Strength DARK | PARTIAL | STREETS | FULL | DARK step | Weapon found | Ammo pickups |", "|---|---|---|---|---|---|---|---|---|"]
    prev = None
    for d in order:
        lines.append("| %s | %s | %.1f | %.1f | %.1f | %.1f | %s | %s | %d |" % (d, " ".join(r[:4] for r in roster[d]), *st[d], "-" if prev is None else "x%.2f" % (st[d][0] / st[prev][0]), gain[d][0] or "-", gain[d][1] * 12))
        prev = d
    bad, watch = judge(order, st, gain)
    return "\n".join(lines), bad, watch


def demo():
    order = ["a", "b", "c"]
    flat = {"a": [4.0, 3.0, 2.0, 1.0], "b": [5.0, 4.0, 3.0, 2.0], "c": [6.0, 5.0, 4.0, 3.0]}
    none = {"a": ("", 0), "b": ("", 1), "c": ("", 1)}
    assert judge(order, flat, none) == ([], [])
    spike = dict(flat, c=[20.0, 5.0, 4.0, 3.0])
    assert judge(order, spike, none)[0] and "spike" in judge(order, spike, none)[0][0]
    watched = dict(flat, c=[10.0, 5.0, 4.0, 3.0])
    assert judge(order, watched, none) == ([], ["c: x2.00 over b with no weapon found and no more ammo"])
    assert judge(order, watched, dict(none, c=("rifle", 1)))[1] == []
    wrong = dict(flat, b=[5.0, 6.0, 3.0, 2.0])
    assert "calmer" in judge(order, wrong, none)[0][0]
    print("difficulty_curve demo: a smooth curve passes, a spike and a district that does not calm fail, a rise without a gain is watched")
    return 0


def main(argv):
    if "--demo" in argv:
        return demo()
    text, bad, watch = report()
    print(text)
    for line in watch:
        print("WATCH", line)
    for line in bad:
        print("FAIL", line)
    return 1 if ("--check" in argv and bad) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
