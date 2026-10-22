#!/usr/bin/env python3
"""Do the eleven lit beds of the districts sound like one generation? (WORKQUEUE M1, M-AUD, the DoD point 12.) The beds named in music_manager.gd AMBIENCE_LIT_BY_DISTRICT are decoded to mono 44.1 kHz and measured: integrated
loudness (LUFS, EBU R128, with the true peak) and the spectrum (the centroid and the 85 % rolloff of the mean magnitude spectrum, the shares of the energy below 250 Hz and above 2 kHz). The REFERENCE is the bed set that was
generated in one run (the files under assets/audio/music, the Session-27 tracks); a bed is an OUTLIER when its loudness is more than LUFS_BAND LU from the median of the reference, or its centroid or its rolloff lies outside the
range of the reference widened by WIDEN on each side. The bands are set here, before anything is measured, and are not tuned: a bed that fails is remade or the verdict says so.

usage: python tools/qa_sim/audio_cluster.py [--json out.json] [--demo]   (exit 1 when a bed is an outlier)
"""
import json
import pathlib
import re
import statistics
import subprocess
import sys

import numpy as np

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import audio_loudness  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parents[2]
RATE = 44100
LUFS_BAND = 3.0
WIDEN = 0.25
FRAME = 4096


def lit_table():
    src = (ROOT / "scripts/systems/music_manager.gd").read_text(encoding="utf-8")
    block = src[src.index("const AMBIENCE_LIT_BY_DISTRICT"):]
    block = block[:block.index("}")]
    return re.findall(r'&"(\w+)":\s*"res://([^"]+)"', block)


def decode(tool, path):
    r = subprocess.run([tool, "-v", "error", "-i", str(path), "-ac", "1", "-ar", str(RATE), "-f", "f32le", "-"], capture_output=True)
    return np.frombuffer(r.stdout, dtype="<f4")


def spectrum(x):
    """The mean magnitude spectrum over frames of FRAME samples, Hann windowed, and its centroid, rolloff and band shares."""
    n = (len(x) // FRAME) * FRAME
    frames = x[:n].reshape(-1, FRAME) * np.hanning(FRAME)
    mag = np.abs(np.fft.rfft(frames, axis=1)).mean(axis=0)
    freq = np.fft.rfftfreq(FRAME, 1.0 / RATE)
    power = mag ** 2
    total = power.sum()
    centroid = float((freq * mag).sum() / mag.sum())
    rolloff = float(freq[np.searchsorted(np.cumsum(power), 0.85 * total)])
    return centroid, rolloff, float(power[freq < 250.0].sum() / total), float(power[freq > 2000.0].sum() / total)


def measure_all(tool):
    rows = []
    for district, rel in lit_table():
        path = ROOT / rel
        lufs, peak, mean = audio_loudness.measure(tool, path)
        centroid, rolloff, low, high = spectrum(decode(tool, path))
        rows.append({"district": district, "file": rel, "reference": rel.startswith("assets/audio/music/"), "lufs": lufs, "peak": peak, "centroid": centroid, "rolloff": rolloff, "low": low, "high": high})
    return rows


def verdict(rows):
    ref = [r for r in rows if r["reference"]]
    lo_c, hi_c = min(r["centroid"] for r in ref), max(r["centroid"] for r in ref)
    lo_r, hi_r = min(r["rolloff"] for r in ref), max(r["rolloff"] for r in ref)
    median = statistics.median(r["lufs"] for r in ref)
    out = []
    for r in rows:
        why = []
        if abs(r["lufs"] - median) > LUFS_BAND:
            why.append("loudness %.1f LUFS is %.1f LU from the median %.1f" % (r["lufs"], r["lufs"] - median, median))
        if not (lo_c * (1 - WIDEN) <= r["centroid"] <= hi_c * (1 + WIDEN)):
            why.append("centroid %.0f Hz outside %.0f..%.0f" % (r["centroid"], lo_c * (1 - WIDEN), hi_c * (1 + WIDEN)))
        if not (lo_r * (1 - WIDEN) <= r["rolloff"] <= hi_r * (1 + WIDEN)):
            why.append("rolloff %.0f Hz outside %.0f..%.0f" % (r["rolloff"], lo_r * (1 - WIDEN), hi_r * (1 + WIDEN)))
        out.append((r, why))
    return out


def main(argv):
    if "--demo" in argv:
        rows = [{"district": "a", "file": "assets/audio/music/a.ogg", "reference": True, "lufs": -18.0, "peak": -2.0, "centroid": 900.0, "rolloff": 2500.0, "low": 0.5, "high": 0.02},
                {"district": "b", "file": "assets/audio/music/b.ogg", "reference": True, "lufs": -17.5, "peak": -2.0, "centroid": 1100.0, "rolloff": 3000.0, "low": 0.4, "high": 0.03},
                {"district": "c", "file": "assets/audio/ambience/c.ogg", "reference": False, "lufs": -18.2, "peak": -2.0, "centroid": 1000.0, "rolloff": 2800.0, "low": 0.4, "high": 0.03},
                {"district": "d", "file": "assets/audio/ambience/d.ogg", "reference": False, "lufs": -26.0, "peak": -2.0, "centroid": 4000.0, "rolloff": 9000.0, "low": 0.1, "high": 0.4}]
        v = verdict(rows)
        assert [bool(w) for _, w in v] == [False, False, False, True] and len(v[3][1]) == 3
        print("audio_cluster demo: a bed of the same generation passes, a quiet and bright one fails on loudness, centroid and rolloff")
        return 0
    tool = audio_loudness.ffmpeg()
    rows = measure_all(tool)
    print("%-14s %-48s %7s %7s %8s %8s %6s %6s %s" % ("district", "file", "LUFS", "peak", "centroid", "rolloff", "<250", ">2k", "set"))
    for r in rows:
        print("%-14s %-48s %7.1f %7s %8.0f %8.0f %6.2f %6.3f %s" % (r["district"], r["file"][-48:], r["lufs"], "%.1f" % r["peak"] if r["peak"] is not None else "-", r["centroid"], r["rolloff"], r["low"], r["high"], "reference" if r["reference"] else "tested"))
    bad = [(r, why) for r, why in verdict(rows) if why]
    for r, why in bad:
        print("OUTLIER %s: %s" % (r["district"], "; ".join(why)))
    print("%d of %d lit beds are of the cluster of the reference generation (%d reference, %d tested)" % (len(rows) - len(bad), len(rows), sum(r["reference"] for r in rows), sum(not r["reference"] for r in rows)))
    if "--json" in argv:
        pathlib.Path(argv[argv.index("--json") + 1]).write_text(json.dumps(rows, indent=1), encoding="utf-8")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
