# -*- coding: utf-8 -*-
"""AF2 for Session 23, one launch: undo one fix of the pass per check and see that exactly that check fails.

usage: python tools/qa_sim/s23_mutations.py run [--tag s23]    applies every mutation, runs the s23 closeout group through proof_run --launch, restores the files byte for byte, and judges
       python tools/qa_sim/s23_mutations.py judge LOG           re-judges a saved run (no engine)
       python tools/qa_sim/s23_mutations.py --demo
A mutation is a one-line change that puts back what a fix of the pass changed (a constant, a clause). The run is judged against two sets: every check named by a mutation must FAIL, and every other
check must be ok. Together with a green run of the same group on the unmutated tree (the "post" run) that is the both-ways proof of AF2: the check fails on the old behaviour and passes on the new.
The whole-tree variant, tools/qa_sim/af2_both_ways.py, puts every runtime file back to the base commit and cannot run the checks of this pass, which preload the files the pass added.
"""
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
BAK = pathlib.Path(tempfile.gettempdir()) / "tls_s23_mutations"
# (file, old text, new text, the check that must fail)
MUTATIONS = [
    ("scripts/effects/screen_shake.gd", 'if SettingsManager.get_setting("reduce_screen_shake", false) or SettingsManager.get_setting("reduce_camera_motion", false):', 'if SettingsManager.get_setting("reduce_screen_shake", false):', "A11Y7"),
    ("scripts/systems/audio_ducker.gd", "const DUCK_DB: float = -12.0", "const DUCK_DB: float = -3.0", "AUD1"),
    ("scripts/effects/vfx_pool.gd", "const MAX_PER_SCENE: int = 5", "const MAX_PER_SCENE: int = 9", "VFX6"),
    ("scripts/systems/wow_director.gd", "int(minf(ms, 80.0))", "int(minf(ms, 20.0))", "JUICE1"),
    ("scripts/effects/screen_shake.gd", "@export var shake_intensity: float = 0.016", "@export var shake_intensity: float = 0.05", "JUICE3"),
    ("scripts/core/camera_follow_3d.gd", "const LAND_FOV_PUNCH: float = 2.0", "const LAND_FOV_PUNCH: float = 0.0", "JUICE4"),
    ("scripts/core/camera_follow_3d.gd", "const BREATH_M: float = 0.004", "const BREATH_M: float = 0.0", "POL3"),
    ("scripts/player/player_3d.gd", "const ACCEL_SEC: float = 0.12", "const ACCEL_SEC: float = 0.0001", "MOVE1"),
    ("scripts/weapons/weapon_shotgun.gd", "\trecoil = 1.0", "\trecoil = 0.5", "WEAPON1"),
    ("scripts/gameplay/noise_bomb.gd", "const NOISE_RADIUS: float = 24.0", "const NOISE_RADIUS: float = 4.0", "AI1"),
    ("scripts/enemies/base_monster.gd", "const ALERT_RANGE: float = 8.0", "const ALERT_RANGE: float = 0.5", "AI2"),
    ("scripts/systems/settings_manager.gd", '"search": [0.7, 1.0, 1.3],', '"search": [1.0, 1.0, 1.0],', "AI4"),
    ("scripts/ui/hud_3d.gd", "const GLIDE_PER_TICK: float = 0.15", "const GLIDE_PER_TICK: float = 1.0", "AI5"),
    ("scripts/systems/dynamic_resolution.gd", "const DROP_SCALE: float = 0.7", "const DROP_SCALE: float = 1.0", "PERF1"),
    ("scripts/tools/_perf_check_runner.gd", "const BUDGET_D1: int = 200", "const BUDGET_D1: int = 400", "PERF3"),
    ("scripts/systems/uisfx.gd", "const PRESS_SCALE: float = 0.95", "const PRESS_SCALE: float = 1.0", "POL1"),
    ("scripts/ui/ui_manager.gd", 'if scr.visible and id != &"main_menu" and _animates(id):', "if false:", "POL2"),
    ("scripts/weapons/weapon_base.gd", "* NewGamePlus.get_player_damage_multiplier()  # GDD 12.5: +10% per New Game+ level", "", "NGP1"),
    ("scripts/core/save_system.gd", "const BACKUP_DEPTH: int = 3", "const BACKUP_DEPTH: int = 2", "SAVEMIG"),
    ("scripts/systems/integrity_guard.gd", "const CLOCK_TOLERANCE: float = 0.25", "const CLOCK_TOLERANCE: float = 5.0", "SEC1"),
]
LINE = re.compile(r"^\[closeout\] (ok  |FAIL) +(\S+)")


def apply():
    BAK.mkdir(parents=True, exist_ok=True)
    for rel, old, new, _ in MUTATIONS:
        path = ROOT / rel
        backup = BAK / rel.replace("/", "_")
        if not backup.exists():
            shutil.copy2(path, backup)
        raw = path.read_bytes().decode("utf-8")
        newline = "\r\n" if "\r\n" in raw else "\n"
        text = raw.replace("\r\n", "\n")
        assert text.count(old) == 1, (rel, old[:60], text.count(old))
        path.write_bytes(text.replace(old, new).replace("\n", newline).encode("utf-8"))


def restore():
    for rel in sorted({m[0] for m in MUTATIONS}):
        path = ROOT / rel
        backup = BAK / rel.replace("/", "_")
        if backup.exists():
            shutil.copy2(backup, path)
            assert path.read_bytes() == backup.read_bytes(), rel
    shutil.rmtree(BAK, ignore_errors=True)


def parse(text):
    seen = {}
    for line in text.splitlines():
        m = LINE.match(line)
        if m and re.fullmatch(r"[A-Z][A-Z0-9.]*", m.group(2)):
            seen[m.group(2)] = "FAIL" if (m.group(1) == "FAIL" or seen.get(m.group(2)) == "FAIL") else "ok"
    return seen


def judge(text):
    seen = parse(text)
    expected = {m[3] for m in MUTATIONS}
    rows, bad = [], 0
    for check in sorted(expected):
        state = seen.get(check, "missing")
        verdict = "BITES" if state != "ok" else "VACUOUS"
        bad += verdict != "BITES"
        rows.append("%-8s mutated: %s -> %s" % (check, state, verdict))
    stray = sorted(c for c, s in seen.items() if s == "FAIL" and c not in expected)
    bad += len(stray)
    done = [ln for ln in text.splitlines() if ln.startswith("[closeout] DONE")]
    rows.append("failed without a mutation: %s" % (", ".join(stray) or "nothing"))
    rows.append("run: %s" % (done[-1] if done else "no DONE line"))
    rows.append("S23 MUTATIONS verdict=%s mutations=%d bad=%d" % ("PASS" if bad == 0 and expected else "FAIL", len(MUTATIONS), bad))
    return rows, bad


def run(tag):
    dirty = [x for x in subprocess.run(["git", "status", "--porcelain"], cwd=ROOT, capture_output=True, text=True).stdout.splitlines() if not x.startswith("??")]
    if dirty:
        raise SystemExit("the tree has modified tracked files, commit first: %s" % dirty[:3])
    run_id = "%s_mutations" % tag
    try:
        apply()
        subprocess.run(["bash", "tools/qa_sim/proof_run", "--launch", "--attach", ".qa_logs/closeout_check.log", run_id, "--", "bash", "-c",
                        "bash tools/qa_sim/guarded_headless res://scenes/tools/compile_gate_scene.tscn 120; CLOSEOUT_ONLY=s23 bash tools/qa_sim/closeout_check 400"], cwd=ROOT)
    finally:
        restore()
    rows, bad = judge((ROOT / ".qa_logs" / "proofs" / ("%s.attach.closeout_check.log" % run_id)).read_text(encoding="utf-8", errors="replace"))
    out = "\n".join(rows)
    print(out)
    (ROOT / "docs" / "artifacts" / "rc16" / ("%s_mutations.txt" % tag)).write_text(out + "\n", encoding="utf-8", newline="\n")
    return 1 if bad else 0


def demo():
    sample = "\n".join(["[closeout] ok   %s x" % m[3] for m in MUTATIONS])
    rows, bad = judge(sample)
    assert bad == len(MUTATIONS), "a run in which every mutated check is still ok is vacuous"
    broken = sample.replace("[closeout] ok   AI1 x", "[closeout] FAIL AI1 x").replace("[closeout] ok   AUD1 x", "[closeout] ok   AUD1 x\n[closeout] FAIL STRAY y")
    rows, bad = judge(broken)
    assert bad == len(MUTATIONS) - 1 + 1 and any("STRAY" in r for r in rows)
    ids = [m[3] for m in MUTATIONS]
    assert len(set(ids)) == len(ids), "one mutation per check"
    print("s23_mutations demo: a vacuous check, a biting check and a stray failure are told apart")
    return 0


if __name__ == "__main__":
    args = sys.argv[1:]
    if "--demo" in args:
        sys.exit(demo())
    if args and args[0] == "judge":
        rows, bad = judge(pathlib.Path(args[1]).read_text(encoding="utf-8", errors="replace"))
        print("\n".join(rows))
        sys.exit(1 if bad else 0)
    if args and args[0] == "run":
        sys.exit(run(args[args.index("--tag") + 1] if "--tag" in args else "s23"))
    sys.exit("usage: s23_mutations.py run [--tag s23] | judge LOG | --demo")
