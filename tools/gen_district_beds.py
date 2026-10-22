#!/usr/bin/env python3
"""The lit beds of the districts that no generated track covers (WORKQUEUE M1, M5): improved SYNTHESIZED beds, not composed music. Each bed is a loop of LOOP_S seconds made of
  - a slow chord progression in the mode of the district (a root and a set of intervals of its own): every note is a few sine partials with a slow detune, the chords overlap with raised-cosine
    windows that sum to one, so the harmony moves without a seam;
  - a bed of filtered noise whose cutoff drifts with a slow LFO (the room, the wind, the hum);
  - a slow swell over the whole loop.
Every frequency is an exact number of cycles in the loop and every LFO an exact number of cycles too, so the bed wraps without a step. Everything is seeded: the same arguments give the same samples.
The house law (mono 44.1 kHz, -18 LUFS, true peak -1.5 dBFS, OGG q4, the seam proven) is applied by tools/qa_sim/music_post.py; tools/qa_sim/audio_cluster.py judges whether the bed belongs
with the generated tracks (a low body with a shimmer above it: 62 to 90 % of the energy under 250 Hz, a centroid between 600 and 1100 Hz, as the eight generated tracks).

usage: python tools/gen_district_beds.py <district>... [--out <dir>] [--master]      (--master runs music_post.py and writes assets/audio/ambience/districts/<district>_lit.ogg)
"""
import argparse
import pathlib
import re
import shutil
import subprocess
import sys
import wave

import numpy as np

SR = 44100
LOOP_S = 36
EXTRA_S = 4  # the loop continues this long past its end: music_post.py crossfades that tail into the head
ROOT = pathlib.Path(__file__).resolve().parents[1]

# district -> root note in Hz, the chords as semitone sets over the root, the number of partials, the cutoff of the noise bed (low, high) in Hz and its level, the swell depth
DISTRICTS = {
    "residential": {"root": 55.0, "chords": [(0, 7, 12, 15), (-4, 3, 8, 12), (-2, 5, 10, 14), (0, 7, 12, 17)], "partials": 9, "tilt": 0.9, "noise": (550.0, 3200.0), "noise_level": 0.25, "swell": 0.22, "seed": 11},
    "park": {"root": 73.42, "chords": [(0, 7, 12, 19), (-5, 2, 7, 14), (-3, 4, 9, 16), (0, 7, 14, 19)], "partials": 8, "tilt": 1.0, "noise": (500.0, 3000.0), "noise_level": 0.20, "swell": 0.30, "seed": 23},
    "industrial": {"root": 41.2, "chords": [(0, 7, 12, 13), (-2, 5, 10, 11), (0, 6, 12, 18), (-5, 2, 7, 8)], "partials": 9, "tilt": 0.9, "noise": (500.0, 3000.0), "noise_level": 0.25, "swell": 0.18, "seed": 37},
}


def snap(freq):
    """The frequency nearest to `freq` that has a whole number of cycles in the loop."""
    return round(freq * LOOP_S) / LOOP_S


def window_set(n_chords, length):
    """Raised-cosine windows, one per chord, that sum to one all round the loop (the last wraps into the first)."""
    t = np.arange(length) / length * n_chords
    out = []
    for k in range(n_chords):
        d = (t - k + n_chords / 2.0) % n_chords - n_chords / 2.0
        out.append(np.where(np.abs(d) < 1.0, np.cos(d * np.pi / 2.0) ** 2, 0.0))
    return out


def lfo(t, cycles, phase):
    return np.sin(2.0 * np.pi * (cycles * t / LOOP_S + phase))


def band_noise(rng, length, low, high):
    """Noise whose spectrum is flat between low and high Hz, periodic over the whole length."""
    spec = np.fft.rfft(rng.standard_normal(length))
    f = np.fft.rfftfreq(length, 1.0 / SR)
    spec *= np.exp(-((f / high) ** 4)) * (1.0 - np.exp(-((f / low) ** 2)))
    out = np.fft.irfft(spec, length)
    return out / np.abs(out).max()


def bed(name):
    p = DISTRICTS[name]
    rng = np.random.default_rng(p["seed"])
    length = (LOOP_S + EXTRA_S) * SR
    t = np.arange(length) / SR
    loop_len = LOOP_S * SR
    # the chord windows are made for one loop and tiled over the extra tail (the bed is periodic)
    wins = [np.tile(w, 2)[:length] for w in window_set(len(p["chords"]), loop_len)]
    out = np.zeros(length)
    for chord, win in zip(p["chords"], wins):
        voice = np.zeros(length)
        for semitone in chord:
            f0 = snap(p["root"] * 2.0 ** (semitone / 12.0))
            for detune_cents in (-6.0, 6.0):
                f = snap(f0 * 2.0 ** (detune_cents / 1200.0))
                for k in range(1, p["partials"] + 1):
                    phase = rng.random()
                    amp = 1.0 / (k ** p.get("tilt", 1.7))  # the steeper, the darker the chord
                    voice += amp * np.sin(2.0 * np.pi * (snap(f * k) * t + phase)) * (1.0 + 0.15 * lfo(t, int(rng.integers(2, 7)), rng.random()))
        out += win * voice
    out /= np.abs(out).max()
    noise = band_noise(rng, loop_len, *p["noise"])
    noise = np.tile(noise, 2)[:length]
    cutoff_mod = 0.5 + 0.5 * lfo(t, 3, 0.0)
    out += p["noise_level"] * noise * (0.45 + 0.55 * cutoff_mod)
    out *= 1.0 - p["swell"] + p["swell"] * (0.5 + 0.5 * lfo(t, 2, 0.25))
    return (out / np.abs(out).max() * 0.6).astype(np.float32)


def master(wav, target):
    """music_post.py at each start from 0 to 2 s in steps of a quarter second (it wants 2 s of audio past the end of the loop for its crossfade); the master with the lowest seam is kept: the loop is periodic, so every start
    is a valid cut, and the seam of the cut differs (0.001 to 0.12 across the starts of the first residential bed)."""
    best = None
    for start in (0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0):
        trial = target.with_name(target.stem + "_try.ogg")
        r = subprocess.run([sys.executable, str(ROOT / "tools/qa_sim/music_post.py"), str(wav), str(trial), "--loop", str(LOOP_S), "--start", "%.2f" % start], capture_output=True, text=True)
        m = re.search(r"seam=([0-9.]+)", r.stdout)
        if r.returncode == 0 and m and (best is None or float(m.group(1)) < best[0]):
            best = (float(m.group(1)), start, r.stdout.strip()[-300:])
            shutil.copy(trial, target)
    trial.unlink(missing_ok=True)
    return best


def write_wav(path, audio):
    data = np.round(np.clip(audio, -1.0, 1.0) * 32767.0).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("districts", nargs="+")
    ap.add_argument("--out", default=".")
    ap.add_argument("--master", action="store_true")
    args = ap.parse_args()
    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    for name in args.districts:
        wav = out / ("%s_bed.wav" % name)
        write_wav(wav, bed(name))
        print("%s: %s (%d s loop + %d s tail)" % (name, wav, LOOP_S, EXTRA_S))
        if args.master:
            best = master(wav, ROOT / "assets/audio/ambience/districts" / ("%s_lit.ogg" % name))
            if best is None:
                return 1
            print("%s: start %.2f s, seam %.3f: %s" % (name, best[1], best[0], best[2]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
