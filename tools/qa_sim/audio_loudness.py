# -*- coding: utf-8 -*-
"""Loudness measurement of the shipped audio (Session 23, CON1): integrated loudness (LUFS, EBU R128) and true peak (dBFS) of every file of each category, with ffmpeg.

usage: python tools/qa_sim/audio_loudness.py [--write docs/AUDIO_LOUDNESS_TABLE.md] [--check] [--seams] [--demo]
Categories are directories of assets/audio. A file shorter than 0.4 s has no integrated loudness (R128 gates it); it is reported by its mean volume (volumedetect) in a column of its own.
--check fails when a file's true peak is above PEAK_LIMIT_DB (the canon of -1.5 dBFS since v10 N030, the directive said -1), when a loop of music_manager.gd jumps where its end meets its start (F13: a click on every turn), or when ffmpeg is missing.
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
PEAK_LIMIT_DB = -1.5  # v10 N030: the canon of docs/STYLE_GUIDE.md section 5 (the gate stood at the directive's -1.0 and 17 files sat between the two; they are under -1.5 now)
CANON_PEAK_DB = -1.5  # docs/STYLE_GUIDE.md section 5: true peak at most -1.5 dBFS
SPREAD_LU = 3.0
SUFFIXES = {".ogg", ".wav", ".mp3"}
GATED = -69.0
# F13: the step between the last and the first sample of a loop (full scale is 1.0). The generated tracks read 0.000 to 0.037 once music_post.py closed their seams; a hard cut reads 0.1 and more.
SEAM_LIMIT = 0.037
LOOP_CONSTANTS = ("TRACKS", "BATTLE_VARIANTS", "BOSS_PHASES", "AMBIENCE_DARK_BY_DISTRICT", "AMBIENCE_LIT_BY_DISTRICT", "LAYERS")


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
    lines = ["| Category | Files | Integrated LUFS: min / median / max | Mean | Spread (SD, LU) | Files over %.0f LU from the median | True peak max (dBFS) | Files over %.0f dBFS | Files over %.1f dBFS (canon) | Gated (under 0.4 s) | Directive target |" % (SPREAD_LU, PEAK_LIMIT_DB, CANON_PEAK_DB),
             "|---|---|---|---|---|---|---|---|---|---|---|"]
    for category, n, lufs, peaks, short, loud, far in summary(rows):
        target = DIRECTIVE_LUFS.get(category)
        lines.append("| %s | %d | %s | %s | %s | %d | %s | %d | %d | %d | %s |" % (
            category, n,
            "%.1f / %.1f / %.1f" % (min(lufs), statistics.median(lufs), max(lufs)) if lufs else "-",
            "%.1f" % statistics.mean(lufs) if lufs else "-",
            "%.2f" % statistics.pstdev(lufs) if lufs else "-", len(far),
            "%.1f" % max(peaks) if peaks else "-", len(loud), sum(1 for p in peaks if p > CANON_PEAK_DB), short,
            "%.0f LUFS" % target if target is not None else "none"))
    return "\n".join(lines)


def loop_files():
    """The files music_manager.gd plays as loops: what its loop constants name, less the victory figure (a one-shot)."""
    src = (ROOT / "scripts/systems/music_manager.gd").read_text(encoding="utf-8")
    found = []
    for name in LOOP_CONSTANTS:
        m = re.search(r"(?ms)^const %s\b[^=]*=\s*[\[{](.*?)^[\]}]" % name, src)
        if not m:
            raise ValueError("Loop declaration missing: " + name)
        if m:
            found += [p for p in re.findall(r'res://(assets/audio/[^"]+\.ogg)', m.group(1)) if "music_victory" not in p]
    if not found:
        raise ValueError("No loop files discovered")
    return sorted(set(found))


def seam_step(audio):
    return abs(float(audio[0]) - float(audio[-1]))


def check_seams():
    import music_post
    steps = [(p, seam_step(music_post.decode(ROOT / p))) for p in loop_files()]
    clicks = [(p, s) for p, s in steps if s > SEAM_LIMIT]
    print("\nLoop seams (the step between the last and the first sample, limit %.3f): %d loops, %d over: %s" % (SEAM_LIMIT, len(steps), len(clicks), ", ".join("%s %.3f" % (p.rsplit("/", 1)[-1], s) for p, s in clicks) or "none"))
    return clicks


def main(argv):
    if "--demo" in argv:
        import numpy as np
        t = np.arange(44100) / 44100.0
        assert seam_step(np.sin(2 * np.pi * 4 * t)) < SEAM_LIMIT < seam_step(0.5 * np.sin(2 * np.pi * 4.25 * t)), "a closed loop passes and a hard cut fails"
        rows = {"x": [("a.ogg", -14.0, -3.0, None), ("b.ogg", -21.0, -0.5, None), ("c.ogg", None, None, -30.0), ("d.ogg", -14.5, -3.0, None)]}
        s = summary(rows)[0]
        assert s[1] == 4 and s[4] == 1 and s[5] == ["b.ogg"] and s[6] == ["b.ogg"]
        print("audio_loudness demo: a file over the peak limit, a file far from the median and a gated file are all counted; a hard-cut loop is over the seam limit and a closed one is not")
        return 0
    if "--seams" in argv:
        ffmpeg()
        return 1 if check_seams() else 0
    rows = collect(ffmpeg())
    text = table(rows)
    print(text)
    over = [f for _, _, _, _, _, loud, _ in summary(rows) for f in loud]
    clicks = check_seams()
    over += [p for p, _ in clicks]
    if "--write" in argv:
        pathlib.Path(argv[argv.index("--write") + 1]).write_text("# Loudness of the shipped audio (Session 23)\n\nMeasured by `python tools/qa_sim/audio_loudness.py --write docs/AUDIO_LOUDNESS_TABLE.md` (ffmpeg ebur128, integrated loudness and true peak of each file).\n\n" + text + "\n\nFiles over the peak limit:\n\n" + ("\n".join("- `%s`" % f for f in over) if over else "none") + "\n", encoding="utf-8")
    return 1 if ("--check" in argv and over) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
