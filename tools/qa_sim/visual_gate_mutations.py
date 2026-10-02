"""Mutation table of tools/qa_sim/visual_truth_gate.py: one threshold or constant is broken at a time and the gate must
lose a check (a corruption frame let through, a canon frame failed, or a --demo pattern turned the wrong way).

usage: python tools/qa_sim/visual_gate_mutations.py     (prints BASELINE and one CAUGHT/MISSED line per mutation;
                                                         exit 1 when the baseline fails or a mutation is missed)
Output of the sign-off run: docs/artifacts/rc15/visual_gate_mutations.txt
"""
import glob
import os
import pathlib
import sys
import types

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = (ROOT / "tools/qa_sim/visual_truth_gate.py").read_text(encoding="utf-8").replace("\r\n", "\n")
CANON = sorted(glob.glob(str(ROOT / "docs/stills/final/*.png")) + glob.glob(str(ROOT / "docs/stills/beauty/after/*.png")))
CORRUPT = sorted(glob.glob(str(ROOT / "docs/stills/evidence/r0_before_*.png"))
                 + [str(ROOT / "docs/stills/evidence/magenta_corruption_suburbs.png")]
                 + glob.glob(str(ROOT / "docs/stills/evidence/r1_scale08*.png")))
MUTATIONS = [
    ("BRIGHT_MIN_VAL 0.35 -> 0.12 (vignette counts)", "BRIGHT_MIN_VAL = 0.35", "BRIGHT_MIN_VAL = 0.12"),
    ("MAGENTA_FAIL_PCT 0.5 -> 100", "MAGENTA_FAIL_PCT = 0.5\n", "MAGENTA_FAIL_PCT = 100\n"),
    ("DIM_FAIL_PCT 10 -> 100", "DIM_FAIL_PCT = 10.0", "DIM_FAIL_PCT = 100.0"),
    ("VIVID_FAIL_PCT 0.13 -> 100", "VIVID_FAIL_PCT = 0.13", "VIVID_FAIL_PCT = 100"),
    ("VIVID_FAIL_PCT 0.13 -> 0.05 (the old value)", "VIVID_FAIL_PCT = 0.13", "VIVID_FAIL_PCT = 0.05"),
    ("VIVID_SAT 0.85 -> 0.5 (canon colours count)", "VIVID_SAT, VIVID_VAL = 0.85, 0.50", "VIVID_SAT, VIVID_VAL = 0.5, 0.50"),
    ("HUE_HIGH 345 -> 300 (pink escapes the band)", "HUE_LOW, HUE_HIGH = 260.0, 345.0", "HUE_LOW, HUE_HIGH = 260.0, 300.0"),
    ("HUE_LOW 260 -> 300 (purple escapes the band)", "HUE_LOW, HUE_HIGH = 260.0, 345.0", "HUE_LOW, HUE_HIGH = 300.0, 345.0"),
    ("BLACK_FAIL_PCT 40 -> 100", "BLACK_FAIL_PCT = 40.0", "BLACK_FAIL_PCT = 100.0"),
]


def run(src: str) -> tuple[int, int, str]:
    mod = types.ModuleType("gate")
    exec(compile(src, "gate", "exec"), mod.__dict__)
    missed = sum(1 for p in CORRUPT if mod.check(p)[0])
    failed = sum(1 for p in CANON if not mod.check(p)[0])
    try:
        mod._demo()
        demo = "demo passes"
    except AssertionError as e:
        demo = "demo FAILS on %s" % e.args[0][0]
    return missed, failed, demo


def main() -> int:
    os.chdir(ROOT)
    bad = 0
    try:
        missed, failed, demo = run(SRC)
        print("%-10s %-46s corruption frames missed %d of %d, canon frames failed %d of %d, %s" % ("baseline", "unmutated", missed, len(CORRUPT), failed, len(CANON), demo))
        bad += int(missed or failed or demo != "demo passes")
        for name, old, new in MUTATIONS:
            assert SRC.count(old) == 1, (name, SRC.count(old))
            missed, failed, demo = run(SRC.replace(old, new))
            caught = bool(missed or failed or demo != "demo passes")
            bad += int(not caught)
            print("%-10s %-46s corruption frames missed %d of %d, canon frames failed %d of %d, %s" % ("CAUGHT" if caught else "MISSED", name, missed, len(CORRUPT), failed, len(CANON), demo))
    finally:
        pathlib.Path("_tmp_gate_demo.png").unlink(missing_ok=True)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
