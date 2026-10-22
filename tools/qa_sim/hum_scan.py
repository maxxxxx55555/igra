# -*- coding: utf-8 -*-
"""The owner's rule since rc14 is "no hum beds" (docs/PRODUCTION_BIBLE.md section 3: "remove this humming sound from the project, it is unpleasant"). This reads the audio the game plays as an ambience bed or a district detail loop and
flags a file that is one steady low tone or a steady low rumble. The nitpick of the v10 pass (docs/NITPICK_v1.0.md N026, N027) found five dark beds and seven detail loops that were: a 120 Hz sine, mains hum at 100 Hz, a 49 Hz line.

usage: python tools/qa_sim/hum_scan.py [--check] [--root <a copy of the tree>] [--demo]
The files judged are the dark beds named by AMBIENCE_DARK_BY_DISTRICT of music_manager.gd and the detail loops named by DETAIL_BEDS of district_atmosphere.gd (--root reads a copy of the tree, a `git archive` of the commit before a fix: the scan must fail there).
The lit beds and the dark layer are listed, not judged: they are music (the dark layer of the adaptive music is a sub-bass drone by design, the rule names Ambient_Dark as the thing that carries the night, and the three synthesized lit
beds wait for generated tracks, N028). A file is a hum when its energy is one steady line below 400 Hz (half of it within 6 Hz of the peak, the level varying by less than its own mean over 0.1 s windows: a sparse event that rings is not
a bed) or when it is steady and nearly all below 300 Hz (at least 85 % of the energy, the level varying by less than 0.4 of its mean). --check exits 1 on a hum.
"""
import pathlib
import re
import sys

import numpy as np

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import music_post  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parents[2]
SR = 44100
FFT = 1 << 16
LINE_HZ = 400.0
LINE_SHARE = 0.5
LOW_HZ = 300.0
LOW_SHARE = 0.85
STEADY = 0.4
SPARSE = 1.0


def probe(x, sr=SR):
    """(peak Hz, share of the energy within 6 Hz of it, share below 300 Hz, level variation over 0.1 s windows) of a mono signal."""
    segs = x[: len(x) // FFT * FFT].reshape(-1, FFT) * np.hanning(FFT)
    p2 = np.abs(np.fft.rfft(segs, axis=1)).mean(0) ** 2
    f = np.fft.rfftfreq(FFT, 1.0 / sr)
    i = int(np.argmax(p2[1:])) + 1
    near = float(p2[(f > f[i] - 6) & (f < f[i] + 6)].sum() / p2.sum())
    low = float(p2[f < LOW_HZ].sum() / p2.sum())
    k = int(0.1 * sr)
    rms = np.sqrt((x[: len(x) // k * k].reshape(-1, k) ** 2).mean(1))
    return float(f[i]), near, low, float(rms.std() / max(rms.mean(), 1e-12))


def is_hum(peak, near, low, variation):
    return (peak < LINE_HZ and near >= LINE_SHARE and variation < SPARSE) or (low >= LOW_SHARE and variation < STEADY)


def files(root):
    """(kind, path) of the dark beds and detail loops (judged) and of the lit beds (listed) the game plays."""
    music = (root / "scripts/systems/music_manager.gd").read_text(encoding="utf-8")
    out = []
    for name, kind in (("AMBIENCE_DARK_BY_DISTRICT", "dark bed"), ("AMBIENCE_LIT_BY_DISTRICT", "lit bed")):
        m = re.search(r"(?ms)^const %s\b[^=]*=\s*\{(.*?)^\}" % name, music)
        out += [(kind, p) for p in sorted(set(re.findall(r'res://(assets/audio/[^"]+\.ogg)', m.group(1))))] if m else []
    text = (root / "scripts/world/district_atmosphere.gd").read_text(encoding="utf-8")
    block = re.search(r"const DETAIL_BEDS: Dictionary = \{(.*?)\n\}", text, re.S).group(1)
    out += [("detail", "assets/audio/ambience/district_details/%s.ogg" % n) for n in re.findall(r'"(\w+)":\s*[-\d.]+', block)]
    return out


def demo():
    t = np.arange(SR * 8) / SR
    rng = np.random.default_rng(1)
    sine = 0.1 * np.sin(2 * np.pi * 100.0 * t)
    mains = sum(0.1 / k * np.sin(2 * np.pi * 100.0 * k * t) for k in range(1, 6))
    noise = rng.standard_normal(len(t)) * 0.05
    gusts = noise * (0.15 + np.clip(np.sin(2 * np.pi * 0.2 * t), 0, None))
    low_rumble = np.fft.irfft(np.fft.rfft(rng.standard_normal(len(t))) * (np.fft.rfftfreq(len(t), 1 / SR) < 200), len(t)) * 0.05
    ring = np.zeros(len(t))
    ring[SR : SR + SR // 2] = 0.2 * np.sin(2 * np.pi * 164.0 * t[: SR // 2])
    flags = [is_hum(*probe(x)) for x in (sine, mains, noise, gusts, low_rumble, ring)]
    assert flags == [True, True, False, False, True, False], flags
    print("hum_scan demo: a 100 Hz sine, mains hum with harmonics and a steady low rumble are hums; white noise, noise in gusts and a ringing note in silence are not")


def main(argv):
    if "--demo" in argv:
        demo()
        return 0
    root = pathlib.Path(argv[argv.index("--root") + 1]).resolve() if "--root" in argv else ROOT
    humming = []
    seen = set()
    for kind, rel in files(root):
        if rel in seen or not (root / rel).exists():
            continue
        seen.add(rel)
        peak, near, low, variation = probe(music_post.decode(root / rel))
        hum = kind != "lit bed" and is_hum(peak, near, low, variation)
        humming += [rel] if hum else []
        print("%-9s %-62s peak %6.1f Hz  within 6 Hz %.2f  below 300 Hz %.2f  variation %.2f%s" % (kind, rel.split("assets/audio/ambience/")[-1], peak, near, low, variation, "  HUM" if hum else ("  (music: listed, not judged)" if kind == "lit bed" else "")))
    layers = [root / "assets/audio/music/layer_dark.ogg"]
    for path in layers:
        if path.exists():
            peak, near, low, variation = probe(music_post.decode(path))
            print("%-9s %-62s peak %6.1f Hz  within 6 Hz %.2f  below 300 Hz %.2f  variation %.2f  (a music layer: listed, not judged)" % ("layer", path.name, peak, near, low, variation))
    print("hum_scan: %d file(s) read, %d hum(s)%s" % (len(seen), len(humming), ": " + ", ".join(h.rsplit("/", 1)[-1] for h in humming) if humming else ""))
    return 1 if humming and "--check" in argv else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
