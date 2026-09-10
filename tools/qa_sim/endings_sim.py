#!/usr/bin/env python3
"""Static reachability sim for the 5 GDD endings (STATIC_AUDIT #6).

Mirrors scripts/systems/endings_manager.gd::_determine_ending() exactly, then
walks the reachable state space (constrained by the powered_by DAG parsed from
data/districts/*.tres and by which code path can call the evaluator) and
asserts every ending id is reachable from at least one real state.

No engine: pure text parse + enumeration. Run: python tools/qa_sim/endings_sim.py
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
DIST = ROOT / "data" / "districts"


# ---- 1. parse the powered_by DAG straight from the .tres files -------------
def load_dag():
    dag = {}
    for f in sorted(DIST.glob("district_*.tres")):
        txt = f.read_text(encoding="utf-8")
        did = re.search(r'^id\s*=\s*&"([^"]+)"', txt, re.M)
        pb = re.search(r'^powered_by\s*=\s*\[([^\]]*)\]', txt, re.M)
        if not did:
            continue
        parents = re.findall(r'&"([^"]+)"', pb.group(1)) if pb else []
        dag[did.group(1)] = parents
    return dag


def restorable_order(dag):
    """Districts that can be brought to FULL, in a legal order (all parents
    FULL first). Returns the full topological set."""
    done, order = set(), []
    changed = True
    while changed:
        changed = False
        for d, parents in dag.items():
            if d in done:
                continue
            if all(p in done for p in parents):
                done.add(d)
                order.append(d)
                changed = True
    return order


# ---- 2. exact port of _determine_ending() --------------------------------
def determine_ending(full, total, all_docs, bunker, all_audio, all_photos,
                     is_death, power_station_full):
    if is_death:
        if power_station_full and full < total:
            return "survivor"
        return "dark"
    if all_docs and bunker and all_audio and all_photos:
        return "truth"
    if full >= total and all_docs:
        return "light"
    if full >= total:
        return "hope"
    if power_station_full and full < total:
        return "survivor"
    return "dark"


# ---- 3. enumerate reachable states -------------------------------------------
def main():
    dag = load_dag()
    total = len(dag)
    order = restorable_order(dag)
    assert set(order) == set(dag), f"DAG not fully restorable: {set(dag) - set(order)}"

    leaves = [d for d in dag if not any(d in ps for ps in dag.values())]
    spine_to_station = set()
    # every ancestor of power_station (inclusive) must be FULL to light it
    stack = ["power_station"]
    while stack:
        n = stack.pop()
        if n in spine_to_station:
            continue
        spine_to_station.add(n)
        stack.extend(dag.get(n, []))

    print(f"districts parsed:        {total}")
    print(f"leaf districts:          {sorted(leaves)}")
    print(f"power_station requires:   {total - len(spine_to_station)} district(s) optional "
          f"to light it -> {sorted(set(dag) - spine_to_station)}")
    print()

    seen = {}

    def record(ending, note):
        seen.setdefault(ending, note)

    # --- WIN path: game_won only fires after all_restored() -> full == total ---
    # (power_grid.gd::_check_victory early-returns unless all_restored();
    #  finale_director spawns the boss only when pg.all_restored())
    for all_docs in (True, False):
        for bunker in (True, False):
            for all_audio in (True, False):
                for all_photos in (True, False):
                    e = determine_ending(total, total, all_docs, bunker,
                                         all_audio, all_photos,
                                         is_death=False, power_station_full=True)
                    record(e, f"win, full={total}, docs={all_docs}, "
                              f"bunker={bunker}, audio={all_audio}, photos={all_photos}")

    # --- DEATH path: trigger_death() -> evaluate_death_ending(), any run state ---
    # full can be anything 0..total; power_station_full requires the spine done,
    # which still leaves the leaf district(s) optional -> full in [total-len(leaves) .. total-1]
    optional_max = total - 1
    optional_min = len(spine_to_station)  # spine only, no leaves
    for full in range(0, total + 1):
        # station down: reachable for any full where the spine isn't complete
        if full <= total - 1:
            e = determine_ending(full, total, False, False, False, False,
                                 is_death=True, power_station_full=False)
            record(e, f"death, full={full}, station=down")
        # station up but grid incomplete: reachable when spine done, >=1 leaf skipped
        if optional_min <= full <= optional_max:
            e = determine_ending(full, total, False, False, False, False,
                                 is_death=True, power_station_full=True)
            record(e, f"death, full={full}, station=UP, {total - full} leaf(s) skipped")

    # ---- 4. verdict ----------------------------------------------------------
    print("REACHABILITY:")
    ok = True
    for ending in ("light", "hope", "truth", "survivor", "dark"):
        hit = ending in seen
        ok &= hit
        print(f"  {ending:9s} {'REACHABLE  ' if hit else 'UNREACHABLE'}  <- {seen.get(ending, '(no state produces it)')}")
    print()
    if ok:
        print("PASS: all 5 GDD endings reachable.")
        return 0
    print("FAIL: some endings unreachable.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
