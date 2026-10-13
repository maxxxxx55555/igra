# A model of scripts/systems/quality_manager.gd (the Session 23 version, CORRECTION_LOG 241) and of the sequences of checks QM1 to QM4 (scripts/tools/rc16/perf23_checks.gd, `_quality_manager`), run before any engine run:
# the clean manager passes the four, and each of the four mutation rows of tools/qa_sim/s23_mutations.py makes its own check fail. The model is the manager's logic written again in Python, not the script:
# whether it is faithful is read from the two files side by side, and the engine run of the last launch is the proof.
import math

CAPS = [30, 30, 60, 60]  # SettingsManager.GRAPHICS_TIERS: the frame cap of Low, Medium, High, Ultra
INF = math.inf


class World:
    def __init__(self):
        self.settings = {"graphics_tier": 2}
        self.max_fps = 60


class Manager:
    def __init__(self, w, mutate=()):
        self.w = w
        self.mutate = set(mutate)
        self.ceiling = 2
        self.low = 0.0
        self.stable = 0.0
        self.raise_after = 10.0
        self.adjusting = False

    def player_sets_tier(self, idx):
        """SettingsManager.set_graphics_tier(idx) and the manager's handler of the settings_changed signal."""
        self.w.settings["graphics_tier"] = idx
        self.w.max_fps = CAPS[idx]
        if self.adjusting:
            return
        self.ceiling = idx
        if "qm4" not in self.mutate:
            self.w.settings["graphics_ceiling"] = idx
        self.raise_after = 10.0
        self.low = 0.0
        self.stable = 0.0

    def set_tier(self, idx):
        self.adjusting = True
        if "qm3" not in self.mutate:
            self.w.settings["graphics_ceiling"] = self.ceiling
        self.player_sets_tier(idx)
        self.adjusting = False

    def step(self, fps, delta):
        tier = self.w.settings["graphics_tier"]
        limit = self.w.max_fps * 0.9
        stable_limit = 45.0 if "qm1" in self.mutate else min(45.0, limit)
        if fps < min(30.0, limit):
            self.low += delta
            self.stable = 0.0
            if self.low >= 5.0 and tier > 0:
                self.low = 0.0
                self.raise_after = self.raise_after * (1.0 if "qm2" in self.mutate else 2.0)
                self.set_tier(tier - 1)
        elif fps >= stable_limit:
            self.stable += delta
            self.low = 0.0
            if self.stable >= self.raise_after and tier < self.ceiling:
                self.stable = 0.0
                self.set_tier(tier + 1)
        else:
            self.low = 0.0
            self.stable = 0.0


def tier(w):
    return w.settings["graphics_tier"]


def feed(m, fps, seconds):
    for _ in range(int(seconds * 2.0)):
        m.step(fps, 0.5)


def until(m, fps, limit, target):
    t = 0.0
    while tier(m.w) != target and t < limit:
        m.step(fps, 0.5)
        t += 0.5
    return t if tier(m.w) == target else -1.0


def run(mutate=()):
    w = World()
    m = Manager(w, mutate)
    m.player_sets_tier(2)
    out = {}
    feed(m, 24.0, 4.5)
    early = tier(w) == 2
    feed(m, 24.0, 0.5)
    dropped = tier(w) == 1 and w.max_fps == 30
    feed(m, 29.5, 15.0)
    held = tier(w) == 1
    first = until(m, 29.5, 60.0, 2)
    raised = first > 0.0 and w.max_fps == 60
    feed(m, 60.0, 60.0)
    capped = tier(w) == 2
    out["QM1"] = early and dropped and held and raised and capped
    m.player_sets_tier(2)
    feed(m, 24.0, 5.0)
    one = until(m, 29.5, 700.0, 2)
    feed(m, 24.0, 5.0)
    two = until(m, 29.5, 700.0, 2)
    out["QM2"] = one > 0.0 and two > one
    out["waits"] = (one, two)
    m.player_sets_tier(2)
    w.settings["graphics_ceiling"] = -1
    feed(m, 24.0, 5.0)
    out["QM3"] = w.settings.get("graphics_ceiling") == 2 and tier(w) == 1
    w.settings["graphics_ceiling"] = -1
    m.player_sets_tier(1)
    out["QM4"] = w.settings.get("graphics_ceiling") == 1
    return out


if __name__ == "__main__":
    clean = run()
    print("clean:", {k: clean[k] for k in ("QM1", "QM2", "QM3", "QM4")}, "waits before a raise", clean["waits"])
    assert all(clean[k] for k in ("QM1", "QM2", "QM3", "QM4")), "the clean manager passes the four checks"
    expected = {"qm1": {"QM1", "QM2"}, "qm2": {"QM2"}, "qm3": {"QM3"}, "qm4": {"QM4"}}
    for name, failing in expected.items():
        r = run((name,))
        got = {k for k in ("QM1", "QM2", "QM3", "QM4") if not r[k]}
        print("mutation %s fails %s" % (name.upper(), sorted(got)))
        assert got == failing, (name, got)
    print("qm_model: the clean manager passes QM1 to QM4; each mutation fails its own check (QM1's also fails QM2, which has a row of its own)")
