# -*- coding: utf-8 -*-
"""Judges the three frame-independence runs (30, 60 and 120 FPS of simulated time) of scripts/tools/_timing_equiv_runner.gd.

usage: python tools/qa_sim/timing_compare.py <log30> <log60> <log120>
       python tools/qa_sim/timing_compare.py --demo
Each log holds lines "[timing] fps=<N> <key>=<value>". The 60 FPS run is the reference (the rate the game was tuned at); every other
value must sit inside the key's tolerance: "rel" is a fraction of the reference, "abs" is an absolute amount. A key that is missing,
an ERROR line, a run that did not reach DONE, or a run whose mean frame time is not 1/fps (the engine did not honour --fixed-fps)
fails. Exit 1 on any failure. The table is printed untrimmed; tools/qa_sim/proof_run keeps it as raw evidence.
"""
import re
import sys

TOL = {
    "timer_1s": ("abs", 0.05), "tween_1s": ("abs", 0.05),
    "walk_mps": ("rel", 0.03), "sprint_mps": ("rel", 0.03),
    "stamina_drain_per_s": ("rel", 0.05), "battery_drain_per_s": ("rel", 0.03),
    "rifle_shots_per_s": ("rel", 0.05), "pistol_shots_per_s": ("rel", 0.05), "rifle_reload_s": ("abs", 0.05),
    "melee_swings_per_s": ("rel", 0.05),
    "monster_hits_per_s": ("abs", 0.1), "monster_damage_per_s": ("rel", 0.1), "player_damage_per_s": ("rel", 0.15),
    "pickup_reach_m": ("abs", 0.25),
    "boss_ttk_s": ("rel", 0.05),
}
LINE = re.compile(r"^\[timing\] fps=(\d+) (\w+)=(\S+)(?: (.*))?$")
RATES = (30, 60, 120)


def parse(path):
    values, done = {}, False
    for raw in open(path, encoding="utf-8", errors="replace"):
        line = raw.strip()
        if line.startswith("[timing] DONE"):
            done = True
        m = LINE.match(line)
        if m:
            values[m.group(2)] = m.group(3) if m.group(3) == "ERROR" else float(m.group(3))
            if m.group(3) == "ERROR":
                values[m.group(2)] = "ERROR " + (m.group(4) or "")
    return values, done


def judge(runs):
    """runs: {fps: (values, done)} -> (table lines, failures)"""
    lines, fails = [], []
    ref = runs[60][0]
    lines.append("%-24s %10s %10s %10s  %10s %-9s %s" % ("key", "30", "60", "120", "max dev", "tolerance", "verdict"))
    for fps in RATES:
        values, done = runs[fps]
        if not done:
            fails.append("run at %d fps did not reach DONE" % fps)
        dt = values.get("delta_mean")
        if not isinstance(dt, float) or abs(dt * fps - 1.0) > 0.01:
            fails.append("run at %d fps: mean frame time %s is not 1/%d (--fixed-fps not honoured)" % (fps, dt, fps))
    for key, (kind, tol) in TOL.items():
        cells, worst, bad = [], 0.0, False
        r = ref.get(key)
        for fps in RATES:
            v = runs[fps][0].get(key)
            if not isinstance(v, float):
                cells.append("%10s" % ("missing" if v is None else "ERROR"))
                bad = True
                continue
            cells.append("%10.4f" % v)
            if isinstance(r, float):
                dev = abs(v - r) if kind == "abs" else (abs(v - r) / abs(r) if r else abs(v - r))
                worst = max(worst, dev)
                bad = bad or dev > tol
        if not isinstance(r, float):
            bad = True
        verdict = "FAIL" if bad else "ok"
        if bad:
            fails.append("%s outside %s %.3f" % (key, kind, tol))
        lines.append("%-24s %s  %10.4f %-9s %s" % (key, " ".join(cells), worst, "%s %.3f" % (kind, tol), verdict))
    return lines, fails


def demo():
    def run(fps, scale):
        v = {k: 10.0 * (scale if k == "rifle_shots_per_s" else 1.0) for k in TOL}
        v["delta_mean"] = 1.0 / fps
        return v, True
    good = {f: run(f, 1.0) for f in RATES}
    assert not judge(good)[1]
    slow = dict(good)
    slow[30] = run(30, 0.9)
    lines, fails = judge(slow)
    assert fails == ["rifle_shots_per_s outside rel 0.050"], fails
    wrong = dict(good)
    values, done = run(120, 1.0)
    values["delta_mean"] = 1.0 / 60
    wrong[120] = (values, done)
    assert any("not honoured" in f for f in judge(wrong)[1])
    print("timing_compare demo OK (equal runs pass, a 10 % slower 30 FPS rifle fails, a run that ignored --fixed-fps fails)")


def main():
    if "--demo" in sys.argv:
        demo()
        return 0
    paths = [a for a in sys.argv[1:] if not a.startswith("--")]
    runs = {fps: parse(p) for fps, p in zip(RATES, paths)}
    lines, fails = judge(runs)
    print("\n".join(lines))
    for f in fails:
        print("FAIL:", f)
    print("TIMING_EQUIV verdict=%s keys=%d failures=%d" % ("FAIL" if fails else "PASS", len(TOL), len(fails)))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
