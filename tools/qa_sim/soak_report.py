# -*- coding: utf-8 -*-
"""The readings of a soak and a stress run, as the tables of the documents (docs/LONG_SESSION_TEST.md, MEMORY_TEST.md, THERMAL_TEST.md, STRESS_TEST.md).

usage: python tools/qa_sim/soak_report.py [--soak .qa_logs/soak_soak.log] [--rss .qa_logs/soak_soak_rss.csv] [--stress .qa_logs/soak_stress.log] [--demo]
Input: the `[soak] minute=` lines of `tools/qa_sim/soak soak <hash> <minutes>` (the frame time, the engine's static memory, the object, node and orphan counts, the video and texture memory, once a
minute), the csv its sampler writes (seconds since the start, the working set of the process in KiB, the performance and the utility of the processor in per cent), and the `[stress]` line of the
stress run. Output: the growth of each number from the median of the first five minutes to the median of the last five, the slope of the memory over the run (MiB an hour), the minutes
the frame rate held, and the clocks of the processor. A number printed here is a reading; the documents judge it.
"""
import pathlib
import re
import statistics
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
MINUTE = re.compile(r"\[soak\] minute=(\d+) frames=(\d+) mean_ms=([\d.]+) p95_ms=([\d.]+) p99_ms=([\d.]+) max_ms=([\d.]+) over50=(\d+) static_mib=([\d.]+) objects=(\d+) nodes=(\d+) orphans=(\d+) video_mib=([\d.]+) texture_mib=([\d.]+)")
KEYS = ["minute", "frames", "mean_ms", "p95_ms", "p99_ms", "max_ms", "over50", "static_mib", "objects", "nodes", "orphans", "video_mib", "texture_mib"]
GROWTH = ["static_mib", "objects", "nodes", "orphans", "video_mib", "texture_mib", "mean_ms", "p95_ms"]
FIRST_LAST = 5
FPS_HOLD = 55.0
P95_BUDGET_MS = 33.0


def parse_minutes(text):
    return [dict(zip(KEYS, (float(v) for v in m.groups()))) for m in MINUTE.finditer(text)]


def parse_rss(text):
    rows = []
    for line in text.splitlines():
        f = line.strip().split(",")
        if len(f) >= 2 and f[0].isdigit():
            rows.append({"sec": int(f[0]), "mib": int(f[1]) / 1024.0, "perf": float(f[2]) if len(f) > 2 else 0.0, "util": float(f[3]) if len(f) > 3 else 0.0})
    return rows


def slope_per_hour(xs, ys):
    """Least squares slope of ys over xs (xs in seconds), per hour."""
    if len(xs) < 3:
        return 0.0
    mx, my = statistics.mean(xs), statistics.mean(ys)
    den = sum((x - mx) ** 2 for x in xs)
    return 3600.0 * sum((x - mx) * (y - my) for x, y in zip(xs, ys)) / den if den else 0.0


def growth_table(rows):
    n = len(rows)
    lines = ["| Reading | First %d minutes (median) | Last %d minutes (median) | Growth |" % (FIRST_LAST, FIRST_LAST), "|---|---|---|---|"]
    for key in GROWTH:
        first = statistics.median(r[key] for r in rows[:FIRST_LAST])
        last = statistics.median(r[key] for r in rows[n - FIRST_LAST:])
        lines.append("| %s | %.2f | %.2f | %+.2f |" % (key, first, last, last - first))
    return "\n".join(lines)


def fps_table(rows):
    fps = [1000.0 / r["mean_ms"] for r in rows if r["mean_ms"] > 0]
    held = sum(1 for v in fps if v >= FPS_HOLD)
    p95 = sum(1 for r in rows if r["p95_ms"] <= P95_BUDGET_MS)
    return ["| Reading | Value |", "|---|---|",
            "| minutes read | %d |" % len(rows),
            "| mean frame rate of a minute: least, median, most | %.1f, %.1f, %.1f |" % (min(fps), statistics.median(fps), max(fps)),
            "| minutes at or over %.0f frames a second | %d of %d |" % (FPS_HOLD, held, len(fps)),
            "| minutes with a p95 within %.0f ms | %d of %d |" % (P95_BUDGET_MS, p95, len(rows)),
            "| worst frame of a minute: median, most | %.1f ms, %.1f ms |" % (statistics.median(r["max_ms"] for r in rows), max(r["max_ms"] for r in rows)),
            "| frames over 50 ms in the whole run | %d of %d |" % (sum(r["over50"] for r in rows), sum(r["frames"] for r in rows))]


def memory_lines(rss, rows):
    out = []
    if rss:
        n = len(rss)
        first = statistics.median(r["mib"] for r in rss[:FIRST_LAST])
        last = statistics.median(r["mib"] for r in rss[n - FIRST_LAST:])
        out.append("| working set of the process: first %d minutes, last %d minutes (median) | %.1f MiB, %.1f MiB (%+.1f) |" % (FIRST_LAST, FIRST_LAST, first, last, last - first))
        out.append("| working set: slope over the run | %+.1f MiB an hour |" % slope_per_hour([r["sec"] for r in rss], [r["mib"] for r in rss]))
        out.append("| working set: most | %.1f MiB |" % max(r["mib"] for r in rss))
    if rows:
        out.append("| engine static memory: slope over the run | %+.1f MiB an hour |" % slope_per_hour([r["minute"] * 60.0 for r in rows], [r["static_mib"] for r in rows]))
    return out


def clock_lines(rss):
    perf = [r["perf"] for r in rss if r["perf"] > 0]
    if not perf:
        return []
    n = len(perf)
    k = min(10, n // 2) or 1
    return ["| processor performance (per cent of the base clock): least, median, most | %.0f, %.0f, %.0f |" % (min(perf), statistics.median(perf), max(perf)),
            "| processor performance: first %d samples, last %d samples (median) | %.0f, %.0f |" % (k, k, statistics.median(perf[:k]), statistics.median(perf[n - k:])),
            "| samples under 100 (a clock below the base one) | %d of %d |" % (sum(1 for v in perf if v < 100), n),
            "| processor utility (per cent): median, most | %.0f, %.0f |" % (statistics.median(r["util"] for r in rss), max(r["util"] for r in rss))]


def stress_line(text):
    m = re.search(r"\[stress\] monsters=(\d+) alive=(\d+) moved=(\d+) frames=(\d+) mean_ms=([\d.]+) p95_ms=([\d.]+) p99_ms=([\d.]+) max_ms=([\d.]+) fps_mean=([\d.]+) over50=(\d+)", text)
    if not m:
        return None
    k = ["monsters", "alive", "moved", "frames", "mean_ms", "p95_ms", "p99_ms", "max_ms", "fps_mean", "over50"]
    return dict(zip(k, (float(v) for v in m.groups())))


def report(soak_text, rss_text, stress_text):
    rows, rss = parse_minutes(soak_text), parse_rss(rss_text)
    out = []
    if len(rows) >= 2 * FIRST_LAST:
        out += ["Growth from the first five minutes to the last five", "", growth_table(rows), "", "Frame rate and memory over the run", ""]
        out += fps_table(rows) + memory_lines(rss, rows) + clock_lines(rss)
    elif rows:
        out.append("too short: %d minute(s), %d needed" % (len(rows), 2 * FIRST_LAST))
    s = stress_line(stress_text)
    if s:
        out += ["", "Stress", "", "| Reading | Value |", "|---|---|", "| monsters spawned, alive at the end, that moved | %d, %d, %d |" % (s["monsters"], s["alive"], s["moved"]),
                "| frames, mean, p95, p99, most | %d, %.2f ms, %.2f ms, %.2f ms, %.1f ms |" % (s["frames"], s["mean_ms"], s["p95_ms"], s["p99_ms"], s["max_ms"]),
                "| mean frame rate, frames over 50 ms | %.1f, %d |" % (s["fps_mean"], s["over50"])]
    return "\n".join(out)


def demo():
    lines = "\n".join("[soak] minute=%d frames=3500 mean_ms=%.2f p95_ms=24.00 p99_ms=30.00 max_ms=48.0 over50=0 static_mib=%.1f objects=%d nodes=%d orphans=0 video_mib=150.0 texture_mib=120.0" % (i, 16.7 + 0.01 * i, 300 + 0.1 * i, 9000 + i, 5000 + i) for i in range(1, 21))
    rss = "\n".join("%d,%d,%d,%d" % (60 * i, (800 + i) * 1024, 150 - i, 50) for i in range(1, 21))
    stress = "[stress] monsters=120 alive=120 moved=118 frames=2000 mean_ms=20.00 p95_ms=30.00 p99_ms=40.00 max_ms=60.0 fps_mean=50.0 over50=3 static=300"
    text = report(lines, rss, stress)
    assert "| static_mib | 300.30 | 301.80 | +1.50 |" in text, text
    assert "minutes at or over 55 frames a second | 20 of 20" in text
    assert "118" in text and "samples under 100" in text
    assert slope_per_hour([0, 3600, 7200], [0, 10, 20]) == 10.0
    print("soak_report demo: the growth, the slope, the minutes held, the clocks and the stress line are read from a synthetic run")
    return 0


def main(argv):
    if "--demo" in argv:
        return demo()

    def arg(name, default):
        return pathlib.Path(argv[argv.index(name) + 1]) if name in argv else ROOT / default

    def read(path):
        return path.read_text(encoding="utf-8", errors="replace") if path.exists() else ""

    print(report(read(arg("--soak", ".qa_logs/soak_soak.log")), read(arg("--rss", ".qa_logs/soak_soak_rss.csv")), read(arg("--stress", ".qa_logs/soak_stress.log"))))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
