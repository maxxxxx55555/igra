# A model of scripts/systems/dynamic_resolution.gd (the Session 23 version after CORRECTION_LOG 244) and of the sequences of checks PERF1, PERF4, PERF5 and PERF6 (scripts/tools/rc16/perf23_checks.gd), run before any engine run:
# the clean governor passes the four, and each mutation row of tools/qa_sim/s23_mutations.py (PERF4 to PERF6, and PERF1's own DROP_SCALE row) makes its checks fail. The model is the governor's logic written again in Python, not the script:
# whether it is faithful is read from the two files side by side, and the engine run of the last launch is the proof.


class Gov:
    LOW_FPS, HIGH_FPS, LOW_SEC, HIGH_SEC, DROP_SCALE, CAP_SHARE = 30.0, 45.0, 2.0, 4.0, 0.7, 0.9

    def __init__(self, cap, mutate=()):
        self.cap = cap
        self.mutate = set(mutate)
        self.dropped = False
        self.scale = 1.0
        self.low = 0.0
        self.high = 0.0
        self.high_after = self.HIGH_SEC

    def step(self, fps, seconds):
        limit = self.cap * self.CAP_SHARE
        low = self.LOW_FPS if "perf4" in self.mutate else min(self.LOW_FPS, limit)
        high = self.HIGH_FPS if "perf5" in self.mutate else min(self.HIGH_FPS, limit)
        if fps < low:
            self.low += seconds
            self.high = 0.0
        elif fps > high:
            self.high += seconds
            self.low = 0.0
        else:
            self.low = 0.0
            self.high = 0.0
        if not self.dropped and self.low >= self.LOW_SEC:
            self.apply(True)
        elif self.dropped and self.high >= self.high_after:
            self.high_after *= 1.0 if "perf6" in self.mutate else 2.0
            self.apply(False)

    def apply(self, drop):
        self.dropped = drop
        self.low = 0.0
        self.high = 0.0
        self.scale = (1.0 if "drop_scale" in self.mutate else self.DROP_SCALE) if drop else 1.0


def feed(g, fps, seconds):
    for _ in range(int(seconds * 2.0)):
        g.step(fps, 0.5)


def until_restored(g, fps, limit):
    t = 0.0
    while g.dropped and t < limit:
        g.step(fps, 0.5)
        t += 0.5
    return t if not g.dropped else -1.0


def perf1(mutate=()):
    g = Gov(60, mutate)
    feed(g, 25.0, 1.5)
    early = not g.dropped and g.scale == 1.0
    feed(g, 25.0, 0.5)
    dropped = g.dropped and g.scale == 0.7
    feed(g, 38.0, 5.0)
    band = g.dropped and g.scale == 0.7
    feed(g, 50.0, 3.5)
    slow = g.dropped
    feed(g, 50.0, 0.5)
    recovered = not g.dropped and g.scale == 1.0
    feed(g, 25.0, 2.0)
    feed(g, 50.0, 3.0)
    g.step(35.0, 0.5)
    feed(g, 50.0, 7.5)
    restarted = g.dropped
    g.step(50.0, 0.5)
    again = not g.dropped
    return early and dropped and band and slow and recovered and restarted and again


def capped(mutate=()):
    g = Gov(30, mutate)
    feed(g, 29.5, 6.0)
    steady = not g.dropped and g.scale == 1.0
    feed(g, 24.0, 2.0)
    dropped = g.dropped and g.scale == 0.7
    first = until_restored(g, 29.5, 60.0)
    feed(g, 24.0, 2.0)
    second = until_restored(g, 29.5, 120.0)
    return {"PERF4": steady and dropped, "PERF5": first > 0.0, "PERF6": first > 0.0 and second > first, "waits": (first, second)}


def verdict(mutate=()):
    c = capped(mutate)
    return {"PERF1": perf1(mutate), "PERF4": c["PERF4"], "PERF5": c["PERF5"], "PERF6": c["PERF6"]}, c["waits"]


if __name__ == "__main__":
    clean, waits = verdict()
    print("clean:", clean, "waits before a return at the 30 cap", waits)
    assert all(clean.values()), "the clean governor passes the four checks"
    expected = {"perf4": {"PERF4", "PERF5", "PERF6"}, "perf5": {"PERF5", "PERF6"}, "perf6": {"PERF1", "PERF6"}, "drop_scale": {"PERF1", "PERF4"}}
    rows = {"perf4", "perf5", "perf6", "drop_scale"}
    for name in sorted(rows):
        v, _ = verdict((name,))
        got = {k for k, ok in v.items() if not ok}
        print("mutation %s fails %s" % (name.upper(), sorted(got)))
        assert got == expected[name], (name, got)
    print("dynres_model: the clean governor passes PERF1 and PERF4 to PERF6; each mutation fails its own check (and the ones that depend on it, which have rows of their own)")
