#!/usr/bin/env python3
"""STATIC_AUDIT #31 — is the puzzle_system.gd bonus economy reachable?

Statically resolves every _puzzle_data id against the set of ids that a real
(non-test) interactable can actually feed to PuzzleSystem.start_puzzle().
Shows the pre-fix (11 rows) vs post-fix (1 row) reachability so the "delete
the dead path" decision is evidenced, not asserted.

No engine. Run: python tools/qa_sim/puzzle_economy_sim.py
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]

PRE_FIX_ROWS = [
    "generator_suburbs", "fuse_residential", "transformer_park", "switch_school",
    "generator_hospital", "fuse_gas_station", "transformer_police",
    "switch_warehouses", "generator_industrial", "fuse_substation",
    "reactor_power_station",
]


def current_rows():
    txt = (ROOT / "scripts/world/puzzle_system.gd").read_text(encoding="utf-8")
    m = re.search(r"_puzzle_data\s*=\s*\{(.*?)\n\t\}", txt, re.S)
    if not m:
        return []
    # top-level keys only: "<id>": { ... }
    return re.findall(r'"([a-z_]+)"\s*:\s*\{', m.group(1))


def reachable_ids():
    """ids that a real interactable can pass to start_puzzle().
    Sources: any PUZZLE_ID const on a non-test .gd that is referenced by a
    scene, plus any string literal argument to start_puzzle() outside tools/.
    """
    ids = set()
    for gd in ROOT.glob("scripts/**/*.gd"):
        if "tools" in gd.parts:
            continue
        txt = gd.read_text(encoding="utf-8")
        for lit in re.findall(r'start_puzzle\(\s*"([^"]+)"\s*\)', txt):
            ids.add(("literal", str(gd.relative_to(ROOT)), lit))
        for cst in re.findall(r'PUZZLE_ID\s*:\s*String\s*=\s*"([^"]+)"', txt):
            # only if this script is actually placed in a scene
            name = gd.stem
            placed = any(name in s.read_text(encoding="utf-8")
                         for s in ROOT.glob("scenes/**/*.tscn"))
            if placed:
                ids.add(("PUZZLE_ID const (scene-placed)", str(gd.relative_to(ROOT)), cst))
    return ids


def report(rows, reach, label):
    reach_vals = {r[2] for r in reach}
    print(f"--- {label}: {len(rows)} _puzzle_data rows ---")
    live = 0
    for r in rows:
        hit = r in reach_vals
        live += hit
        print(f"  {r:24s} {'REACHABLE' if hit else 'dead (no interactable calls start_puzzle with it)'}")
    print(f"  => {live}/{len(rows)} reachable\n")
    return live


def main():
    reach = reachable_ids()
    print("Ways a real interactable reaches PuzzleSystem.start_puzzle():")
    for kind, where, val in sorted(reach):
        print(f"  {val!r}  <- {kind}  {where}")
    print()

    pre = report(PRE_FIX_ROWS, reach, "PRE-FIX")
    cur_rows = current_rows()
    cur = report(cur_rows, reach, "CURRENT (post-fix)")

    ok = (pre == 1) and (cur == len(cur_rows) == 1)
    print("PRE-FIX: 10 of 11 rows were dead data cited as 'canon' by content packs.")
    print(f"DECISION: (b) delete the dead path — keep only the reachable row.")
    print("PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
