# -*- coding: utf-8 -*-
"""The dark beds of five districts (gas station, hospital, industrial, power station, substation) were steady tones: a 120 Hz sine, mains hum at 100 Hz, a 49 Hz line (docs/NITPICK_v1.0.md N026; the owner's rule
since rc14 is no hum beds, docs/PRODUCTION_BIBLE.md section 3). This writes their replacements the way the six beds that were never a hum are made: a floor of moving air far below the loudness of the bed and sparse events over it
(gusts, thumps, creaks, ticks, hiss, crackle), all of them filtered noise, none a tone. Every filter is a circular FFT mask and every event wraps around the end of the loop, so the loop is periodic by construction (no seam), and
music_post.py puts the result on the house law (mono 44.1 kHz, -18 LUFS, true peak -1.5 dBFS, OGG q4). Deterministic: each bed is seeded by its name.

usage: python tools/qa_sim/bed_synth.py [--only gas_station,hospital] [--out assets/audio/ambience/districts] [--demo]
"""
import pathlib
import sys
import zlib

import numpy as np

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import hum_scan  # noqa: E402
import music_post  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parents[2]
SR = 44100
SECONDS = 36
N = SR * SECONDS
FLOOR = 0.035


def band(rng, n, lo, hi, tilt_db=0.0):
    """Noise of n samples at unit rms: flat (or falling by tilt_db per octave) between lo and hi Hz with soft edges, silent outside."""
    spec = np.fft.rfft(rng.standard_normal(n))
    f = np.fft.rfftfreq(n, 1.0 / SR)
    f[0] = f[1]
    w = 1.0 / (1.0 + np.exp(-8.0 * np.log2(f / lo))) / (1.0 + np.exp(8.0 * np.log2(f / hi)))
    w *= (np.maximum(f, lo) / lo) ** (-tilt_db / 6.02)
    x = np.fft.irfft(spec * w, n)
    return x / max(float(np.sqrt((x ** 2).mean())), 1e-9)


def swell(rng, depth, cycles):
    """A slow gain that repeats every loop: 1 plus or minus depth, `cycles` whole waves of random phase per loop."""
    t = np.arange(N) / N
    wave = sum(np.sin(2.0 * np.pi * c * t + rng.uniform(0.0, 2.0 * np.pi)) for c in cycles) / len(cycles)
    return np.clip(1.0 + depth * wave, 0.05, None)


def place(buf, event, at):
    """Adds an event at sample `at`; what passes the end of the loop comes back in at its start."""
    np.add.at(buf, (at + np.arange(len(event))) % N, event)


def gust(rng, seconds, lo, hi):
    n = int(seconds * SR)
    return band(rng, n, lo, hi, 3.0) * np.hanning(n) ** 1.5


def thump(rng, lo, hi, tau):
    n = int(tau * 6 * SR)
    env = np.exp(-np.arange(n) / SR / tau)
    ramp = int(0.004 * SR)
    env[:ramp] *= np.linspace(0.0, 1.0, ramp)
    return band(rng, n, lo, hi) * env


def creak(rng, seconds, lo, hi):
    """Noise whose colour travels from the low band to the high one under a shuddering envelope: strained metal without a pitch."""
    n = int(seconds * SR)
    k = np.linspace(0.0, 1.0, n)
    colour = band(rng, n, lo, lo * 1.8) * (1.0 - k) + band(rng, n, hi / 1.8, hi) * k
    return colour * np.hanning(n) ** 0.7 * (1.0 + 0.5 * band(rng, n, 8.0, 30.0)).clip(0.2, None)


def tick(rng, hi):
    n = int(0.03 * SR)
    return band(rng, n, 1500.0, hi) * np.exp(-np.arange(n) / SR / 0.006)


def hiss(rng, seconds, lo, hi):
    n = int(seconds * SR)
    return band(rng, n, lo, hi) * np.hanning(n) ** 2


def crackle(rng, buf, per_second, gain):
    for at in rng.integers(0, N, int(per_second * SECONDS)):
        n = int(0.002 * SR)
        place(buf, band(rng, n, 1200.0, 9000.0) * np.hanning(n) * gain * rng.uniform(0.2, 1.0), int(at))


def at_random(rng):
    return int(rng.integers(0, N))


def bed(name):
    """One bed as float samples: the floor of moving air plus the events of its district."""
    rng = np.random.default_rng(zlib.crc32(name.encode()))
    floor = band(rng, N, 90.0, 1100.0, 4.0) * swell(rng, 0.6, (2, 3, 5)) * FLOOR
    buf = floor.copy()
    if name == "gas_station":
        for _ in range(3):
            place(buf, gust(rng, rng.uniform(3.5, 6.0), 180.0, 1200.0) * 0.5, at_random(rng))
        for _ in range(5):
            place(buf, tick(rng, 5000.0) * 0.7, at_random(rng))
        place(buf, creak(rng, 1.2, 250.0, 1100.0) * 0.5, at_random(rng))
    elif name == "hospital":
        for _ in range(2):
            place(buf, thump(rng, 40.0, 250.0, 0.12) * 0.9, at_random(rng))
            place(buf, hiss(rng, 2.2, 2500.0, 6500.0) * 0.25, at_random(rng))
            place(buf, gust(rng, 5.0, 120.0, 700.0) * 0.35, at_random(rng))
    elif name == "substation":
        crackle(rng, buf, 3.0, 0.5)
        for _ in range(3):
            place(buf, hiss(rng, 1.8, 3000.0, 8000.0) * 0.2, at_random(rng))
        place(buf, thump(rng, 60.0, 300.0, 0.15) * 0.7, at_random(rng))
        for _ in range(2):
            place(buf, gust(rng, 4.5, 300.0, 1500.0) * 0.25, at_random(rng))
    elif name == "power_station":
        for _ in range(3):
            place(buf, thump(rng, 50.0, 400.0, 0.25) * 0.8, at_random(rng))
        for _ in range(2):
            place(buf, gust(rng, 6.0, 80.0, 500.0) * 0.5, at_random(rng))
            place(buf, creak(rng, 1.1, 150.0, 900.0) * 0.6, at_random(rng))
    elif name == "industrial":
        for i in range(5):
            place(buf, thump(rng, 60.0, 350.0, 0.18) * 0.8, int(i * N / 5 + rng.integers(0, SR // 3)))
        for _ in range(2):
            place(buf, hiss(rng, 1.6, 2000.0, 7000.0) * 0.35, at_random(rng))
            place(buf, creak(rng, 1.3, 200.0, 1000.0) * 0.5, at_random(rng))
    else:
        sys.exit("bed_synth: no recipe for %r" % name)
    return (buf / max(float(np.abs(buf).max()), 1e-9) * 0.9).astype("<f4")


BEDS = ["gas_station", "hospital", "industrial", "power_station", "substation"]


def demo():
    audio = bed("hospital")
    assert len(audio) == N and abs(float(audio[0]) - float(audio[-1])) < 0.04 * float(np.abs(audio).max()) + 0.04
    peak, near, low, variation = hum_scan.probe(audio)
    assert not hum_scan.is_hum(peak, near, low, variation), (peak, near, low, variation)
    assert np.array_equal(bed("hospital"), audio), "a bed is the same every run"
    print("bed_synth demo: a bed is %d s long, the same on every run, closed at its seam and not a hum (peak %.0f Hz, %.2f of it within 6 Hz, variation %.2f)" % (SECONDS, peak, near, variation))


def main(argv):
    if "--demo" in argv:
        demo()
        return 0
    out = ROOT / (argv[argv.index("--out") + 1] if "--out" in argv else "assets/audio/ambience/districts")
    only = argv[argv.index("--only") + 1].split(",") if "--only" in argv else BEDS
    for name in only:
        target = out / ("%s_dark.ogg" % name)
        lufs, tp, seconds = music_post.encode(bed(name), target, -18.0, -2.5)
        peak, near, low, variation = hum_scan.probe(music_post.decode(target))
        print("bed_synth: %s %.2f s lufs=%.2f tp=%.2f seam=%.3f | peak %.0f Hz, %.2f within 6 Hz, %.2f below 300 Hz, variation %.2f%s" % (
            target.name, seconds, lufs, tp, abs(float(music_post.decode(target)[0]) - float(music_post.decode(target)[-1])), peak, near, low, variation,
            "  STILL A HUM" if hum_scan.is_hum(peak, near, low, variation) else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
