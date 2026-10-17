# -*- coding: utf-8 -*-
"""AF2 for the static gates of Session 28 (D1): put back the value one fix replaced, see that the gate named for it fails, restore the file, see that the gate passes again.

usage: python tools/qa_sim/s28_static_mutations.py
The engine-side checks (TEL1 to TEL7, DIF1 to DIF3, ESC1, RET1) have their mutation set in s26_mutations.py (its fifth set); these are the gates that need no engine. The files are
restored byte for byte before the verdict (an assert holds it) and the tool must not run beside another gate: it changes tracked files for the length of one gate run.
"""
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
CURVE = ["tools/qa_sim/difficulty_curve.py", "--check"]
# (what is put back, file, text in the tree, text put in its place, the gate that must fail)
MUTATIONS = [
    ("the park opens with the Crawler again (x1.65 over the residential district)", "scripts/enemies/enemy_pool.gd", "[SHADOW, CRAWLER, HUNTER, HOUND, ROTTER]", "[CRAWLER, HUNTER, SHADOW, HOUND, ROTTER]", CURVE),
    ("the ammo doubles from the police again (the gas station rises x1.93 with nothing new)", "scripts/world/district_loot.gd", "const AMMO_DOUBLE_FROM: int = 5", "const AMMO_DOUBLE_FROM: int = 6", CURVE),
    ("Hard has no hit cap of its own again (a hit costs 12 at Normal and at Hard)", "scripts/systems/settings_manager.gd", '\t"damage_cap": [1.0, 1.0, 1.25],\n', "", ["tools/qa_sim/balance_sim.py"]),
    ("a monster's hit lands at once again (the telegraph is skipped)", "scripts/enemies/base_monster.gd", "\t\t_telegraph.warn(_deal_damage)\n", "\t\t_deal_damage()\n", ["tools/qa_sim/telegraph_audit.py"]),
    ("the Crawler's leap winds up in 0.2 s", "scripts/enemies/crawler_3d.gd", "const LEAP_WINDUP: float = 0.5", "const LEAP_WINDUP: float = 0.2", ["tools/qa_sim/telegraph_audit.py"]),
]


def gate(command):
    r = subprocess.run([sys.executable, *command], cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace")
    return r.returncode, (r.stdout + r.stderr).strip().splitlines()


def main():
    rows, bad = [], 0
    for name, rel, old, new, command in MUTATIONS:
        path = ROOT / rel
        original = path.read_bytes()
        raw = original.decode("utf-8")
        newline = "\r\n" if "\r\n" in raw else "\n"
        text = raw.replace("\r\n", "\n")
        assert text.count(old) == 1, (rel, old[:60], text.count(old))
        try:
            path.write_bytes(text.replace(old, new).replace("\n", newline).encode("utf-8"))
            mutated_rc, mutated_out = gate(command)
        finally:
            path.write_bytes(original)
        assert path.read_bytes() == original, rel
        restored_rc, restored_out = gate(command)
        verdict = "BITES" if mutated_rc != 0 and restored_rc == 0 else ("VACUOUS" if mutated_rc == 0 else "RED BASELINE")
        bad += verdict != "BITES"
        rows.append("%s: %s | %s | gate rc %d mutated, %d restored" % (verdict, name, " ".join(command), mutated_rc, restored_rc))
        rows += ["    mutated: " + line for line in mutated_out[-3:]]
        rows.append("    restored: " + (restored_out[-1] if restored_out else "no output"))
    rows.append("S28 STATIC MUTATIONS verdict=%s mutations=%d bad=%d" % ("PASS" if bad == 0 else "FAIL", len(MUTATIONS), bad))
    print("\n".join(rows))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
