# -*- coding: utf-8 -*-
"""Loudness measurement of the shipped audio (Session 23, CON1): integrated loudness (LUFS, EBU R128) and true peak (dBFS) of every file of each category, with ffmpeg.

usage: python tools/qa_sim/audio_loudness.py [--write docs/AUDIO_LOUDNESS_TABLE.md] [--check] [--demo]
Categories are directories of assets/audio. A file shorter than 0.4 s has no integrated loudness (R128 gates it); it is reported by its mean volume (volumedetect) in a column of its own.
--check fails when a file's true peak is above PEAK_LIMIT_DB (the directive's -1 dBFS) or when ffmpeg is missing.
"""
import pathlib
import re
import shutil
import statistics
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
CATEGORIES = {
    "music": ["assets/audio/music"],
    "ambient beds": ["assets/audio/ambience/districts"],
    "ambient details": ["assets/audio/ambience/district_details"],
    "sfx": ["assets/audio/sfx"],
    "ui": ["assets/audio/ui"],
    "jingles": ["assets/audio/jingles"],
}
# The directive's targets (-14 music, -10 sfx, -20 ambient) and the canon of docs/PRODUCTION_BIBLE.md and docs/STYLE_GUIDE.md section 5 as measured in docs/AUDIO_CONSISTENCY.md.
DIRECTIVE_LUFS = {"music": -14.0, "sfx": -10.0, "ambient beds": -20.0, "ambient details": -20.0}
PEAK_LIMIT_DB = -1.0
SPREAD_LU = 3.0
SUFFIXES = {".ogg", ".wav", ".mp3"}
GATED = -69.0


def ffmpeg():
    path = shutil.which("ffmpeg")
    if path is None:
        sys.exit("audio_loudness: ffmpeg is not on the PATH")
    return path


def measure(tool, path):
    r = subprocess.run([tool, "-nostats", "-hide_banner", "-i", str(path), "-af", "ebur128=peak=true", "-f", "null", "-"], capture_output=True, text=True, encoding="utf-8", errors="replace")
    summary = r.stderr[r.stderr.rfind("Summary:"):]
    lufs = re.search(r"I:\s+(-?[\d.]+) LUFS", summary)
    peak = re.search(r"Peak:\s+(-?[\d.]+|-inf) dBFS", summary)
    mean = None
    if lufs is None or float(lufs.group(1)) <= GATED:
        v = subprocess.run([tool, "-nostats", "-hide_banner", "-i", str(path), "-af", "volumedetect", "-f", "null", "-"], capture_output=True, text=True, encoding="utf-8", errors="replace")
        m = re.search(r"mean_volume:\s+(-?[\d.]+) dB", v.stderr)
        mean = float(m.group(1)) if m else None
        lufs = None
    p = float(peak.group(1)) if peak and peak.group(1) != "-inf" else None
    return (float(lufs.group(1)) if lufs else None), p, mean


def collect(tool):
    rows = {}
    for category, dirs in CATEGORIES.items():
        for d in dirs:
            for f in sorted((ROOT / d).rglob("*")):
                if f.suffix in SUFFIXES:
                    rows.setdefault(category, []).append((f.relative_to(ROOT).as_posix(),) + measure(tool, f))
    return rows


def summary(rows):
    out = []
    for category, items in rows.items():
        lufs = [i[1] for i in items if i[1] is not None]
        peaks = [i[2] for i in items if i[2] is not None]
        short = [i for i in items if i[1] is None]
        loud = [i[0] for i in items if i[2] is not None and i[2] > PEAK_LIMIT_DB]
        median = statistics.median(lufs) if lufs else 0.0
        far = [i[0] for i in items if i[1] is not None and abs(i[1] - median) > SPREAD_LU]
        out.append((category, len(items), lufs, peaks, len(short), loud, far))
    return out


def table(rows):
    lines = ["| Category | Files | Integrated LUFS: min / median / max | Mean | Spread (SD, LU) | Files over %.0f LU from the median | True peak max (dBFS) | Files over %.0f dBFS | Gated (under 0.4 s) | Directive target |" % (SPREAD_LU, PEAK_LIMIT_DB),
             "|---|---|---|---|---|---|---|---|---|---|"]
    for category, n, lufs, peaks, short, loud, far in summary(rows):
        target = DIRECTIVE_LUFS.get(category)
        lines.append("| %s | %d | %s | %s | %s | %d | %s | %d | %d | %s |" % (
            category, n,
            "%.1f / %.1f / %.1f" % (min(lufs), statistics.median(lufs), max(lufs)) if lufs else "-",
            "%.1f" % statistics.mean(lufs) if lufs else "-",
            "%.2f" % statistics.pstdev(lufs) if lufs else "-", len(far),
            "%.1f" % max(peaks) if peaks else "-", len(loud), short,
            "%.0f LUFS" % target if target is not None else "none"))
    return "\n".join(lines)


def main(argv):
    if "--demo" in argv:
        rows = {"x": [("a.ogg", -14.0, -3.0, None), ("b.ogg", -21.0, -0.5, None), ("c.ogg", None, None, -30.0), ("d.ogg", -14.5, -3.0, None)]}
        s = summary(rows)[0]
        assert s[1] == 4 and s[4] == 1 and s[5] == ["b.ogg"] and s[6] == ["b.ogg"]
        print("audio_loudness demo: a file over the peak limit, a file far from the median and a gated file are all counted")
        return 0
    rows = collect(ffmpeg())
    text = table(rows)
    print(text)
    over = [f for _, _, _, _, _, loud, _ in summary(rows) for f in loud]
    if "--write" in argv:
        pathlib.Path(argv[argv.index("--write") + 1]).write_text("# Loudness of the shipped audio (Session 23)\n\nMeasured by `python tools/qa_sim/audio_loudness.py --write docs/AUDIO_LOUDNESS_TABLE.md` (ffmpeg ebur128, integrated loudness and true peak of each file).\n\n" + text + "\n\nFiles over the peak limit:\n\n" + ("\n".join("- `%s`" % f for f in over) if over else "none") + "\n", encoding="utf-8")
    return 1 if ("--check" in argv and over) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
