#!/usr/bin/env python3
"""The four one-shots that the music recipe named and no take supplied (WORKQUEUE M6, docs/GEMINI_HANDOFF.md 2.3, docs/KNOWN_ISSUES.md): the sting of a restored district, the cue of a death and two ticks of the UI. Synthesized in
the style of tools/gen_audio.py (sine partials under an envelope, nothing else) at 44.1 kHz mono; every note is a few partials with a soft attack and an exponential decay, the sting and the cue carry a low hum, the ticks are bare.
  assets/audio/ui/ui_district_restored_sting.ogg   2.0 s   a warm rise of three notes over a hum that swells in: a lamp coming on (played by UISfx on district_restored; peak -11.2 dBFS like the other stings, which UISfx lifts by 9 dB)
  assets/audio/music/cue_death.ogg                 8.0 s   a hum that sinks an octave over a dissonant pad and a breath of noise, faded to zero (played by MusicManager on game_over; mastered to the house law by music_post.py --one-shot)
  assets/audio/sfx/ui_xp_tick.wav                  0.06 s  a bare tick (played by UISfx on xp_gained)
  assets/audio/sfx/ui_heal_soft.wav                0.3 s   two soft notes (played by UISfx when a healing consumable is used)
Honest label: synthesized cues, not composed music. Deterministic: the same call gives the same samples.
usage: python tools/gen_one_shots.py [--out .qa_logs/one_shots]   (writes the four files into assets/ after encoding when --install is given)
"""
import argparse
import pathlib
import shutil
import subprocess
import sys
import wave

import numpy as np

SR = 44100
ROOT = pathlib.Path(__file__).resolve().parents[1]


def tone(freq, seconds, partials=(1.0, 0.3, 0.1), attack=0.015, tau=0.9):
    t = np.arange(int(seconds * SR)) / SR
    wave_ = sum(a * np.sin(2.0 * np.pi * freq * (k + 1) * t) for k, a in enumerate(partials))
    return wave_ * np.minimum(t / attack, 1.0) * np.exp(-t / tau)


def place(out, sound, start):
    i = int(start * SR)
    out[i:i + len(sound)] += sound[: len(out) - i]


def fade_to_zero(x, seconds):
    n = int(seconds * SR)
    x[-n:] *= 0.5 + 0.5 * np.cos(np.linspace(0.0, np.pi, n))
    x[-1] = 0.0
    return x


def peak_to(x, dbfs):
    return x / np.abs(x).max() * 10.0 ** (dbfs / 20.0)


def sting():
    out = np.zeros(int(2.0 * SR))
    t = np.arange(len(out)) / SR
    hum = np.sin(2.0 * np.pi * 65.41 * t) * np.sin(np.pi * np.clip(t / 2.0, 0.0, 1.0)) ** 2 * 0.5
    out += hum
    for freq, start in ((261.63, 0.0), (392.0, 0.22), (523.25, 0.46)):
        place(out, tone(freq, 2.0 - start, tau=0.8) * 0.6, start)
    rng = np.random.default_rng(7)
    click = rng.standard_normal(int(0.012 * SR)) * np.linspace(1.0, 0.0, int(0.012 * SR)) * 0.08
    place(out, click, 0.0)
    return peak_to(fade_to_zero(out, 0.25), -11.2)


def death():
    seconds = 8.0
    t = np.arange(int(seconds * SR)) / SR
    glide = 110.0 * 2.0 ** (-t / seconds)  # an octave down over the cue
    phase = 2.0 * np.pi * np.cumsum(glide) / SR
    hum = np.sin(phase) * (1.0 + 0.25 * np.sin(2.0 * np.pi * 0.6 * t))
    pad = (np.sin(2.0 * np.pi * 55.0 * t) + np.sin(2.0 * np.pi * 58.27 * t)) * 0.35 * np.exp(-t / 5.0)  # a minor second that dies away
    rng = np.random.default_rng(11)
    noise = rng.standard_normal(len(t))
    kernel = np.ones(64) / 64.0  # a low-pass: the breath is dark
    breath = np.convolve(noise, kernel, mode="same") * 4.0 * np.exp(-t / 2.5) * 0.25
    out = (hum + pad + breath) * np.minimum(t / 0.4, 1.0)
    return peak_to(fade_to_zero(out, 1.5), -3.0)


def tick():
    t = np.arange(int(0.06 * SR)) / SR
    x = (np.sin(2.0 * np.pi * 1800.0 * t) + 0.2 * np.sin(2.0 * np.pi * 3600.0 * t)) * np.minimum(t / 0.002, 1.0) * np.exp(-t / 0.012)
    return peak_to(fade_to_zero(x, 0.01), -10.0)


def heal():
    out = np.zeros(int(0.3 * SR))
    place(out, tone(392.0, 0.3, partials=(1.0, 0.15), attack=0.025, tau=0.12), 0.0)
    place(out, tone(523.25, 0.21, partials=(1.0, 0.15), attack=0.025, tau=0.1), 0.09)
    return peak_to(fade_to_zero(out, 0.08), -12.0)


def write_wav(path, x):
    data = np.round(np.clip(x, -1.0, 1.0) * 32767.0).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=".qa_logs/one_shots")
    ap.add_argument("--install", action="store_true")
    args = ap.parse_args()
    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    for name, fn in (("ui_district_restored_sting", sting), ("cue_death", death), ("ui_xp_tick", tick), ("ui_heal_soft", heal)):
        write_wav(out / (name + ".wav"), fn())
        print("%s.wav: %.2f s" % (name, len(fn()) / SR))
    if not args.install:
        return 0
    ffmpeg = shutil.which("ffmpeg")
    audio = ROOT / "assets" / "audio"
    subprocess.run([ffmpeg, "-v", "error", "-y", "-i", str(out / "ui_district_restored_sting.wav"), "-map_metadata", "-1", "-c:a", "libvorbis", "-q:a", "4", str(audio / "ui" / "ui_district_restored_sting.ogg")], check=True)
    r = subprocess.run([sys.executable, str(ROOT / "tools/qa_sim/music_post.py"), str(out / "cue_death.wav"), str(audio / "music" / "cue_death.ogg"), "--loop", "8", "--start", "0", "--one-shot"], capture_output=True, text=True)
    print(r.stdout.strip()[-300:] or r.stderr.strip()[-300:])
    for name in ("ui_xp_tick", "ui_heal_soft"):
        shutil.copy(out / (name + ".wav"), audio / "sfx" / (name + ".wav"))
    return r.returncode


if __name__ == "__main__":
    sys.exit(main())
