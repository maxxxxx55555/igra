# -*- coding: utf-8 -*-
"""M1 of Session 27: the post-production pass of docs/MUSIC_RECIPE.md for one generated track, with ffmpeg: cut `--loop` seconds from `--start`, close the seam of a loop with an equal-power crossfade of the
audio that would have followed the loop into its head (a one-shot gets 3 ms edge fades instead), downmix to mono 44.1 kHz (the house format of the beds, docs/MUSIC_SPEC.md), gain it to the house
law (beds and music -18 LUFS integrated, true peak at most -1.5 dBFS) and write OGG q4 or 16-bit WAV by the extension of the target. It measures the file it wrote and exits 1 when the loudness or the true peak is off.

usage: python tools/qa_sim/music_post.py <input> <target.ogg|.wav> --loop <seconds> [--start <seconds>] [--one-shot] [--lufs -18] [--tp -1.5]
       python tools/qa_sim/music_post.py --demo
"""
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

import numpy as np

SR = 44100
FADE_MS = 3.0
CROSSFADE_S = 2.0
LUFS_TOLERANCE = 0.7
# the lossy encode can overshoot the peak it was normalised to by a few tenths of a dB: aim lower, verify at the law
TP_HEADROOM = 0.5


def ffmpeg():
    path = shutil.which("ffmpeg")
    if path is None:
        sys.exit("music_post: ffmpeg is not on the PATH")
    return path


def decode(path):
    r = subprocess.run([ffmpeg(), "-v", "error", "-i", str(path), "-f", "f32le", "-ac", "1", "-ar", str(SR), "-"], capture_output=True)
    if r.returncode != 0:
        sys.exit("music_post: ffmpeg could not read %s: %s" % (path, r.stderr.decode("utf-8", "replace")))
    return np.frombuffer(r.stdout, dtype="<f4").copy()


def cut(audio, start, seconds, one_shot):
    """The loop (its seam closed) or the one-shot (3 ms fades) of `seconds` from `start`."""
    s, n = int(round(start * SR)), int(round(seconds * SR))
    if one_shot:
        if len(audio) < s + n:
            sys.exit("music_post: %.2f s asked from %.2f s, the file holds %.2f s" % (seconds, start, len(audio) / SR))
        out = audio[s:s + n].copy()
        k = int(FADE_MS / 1000.0 * SR)
        ramp = np.sin(np.linspace(0.0, np.pi / 2.0, k)).astype("<f4")
        out[:k] *= ramp
        out[-k:] *= ramp[::-1]
        return out
    x = min(int(CROSSFADE_S * SR), n // 8)
    if len(audio) < s + n + x:
        sys.exit("music_post: a loop of %.2f s from %.2f s needs %.2f s of audio, the file holds %.2f s" % (seconds, start, (s + n + x) / SR, len(audio) / SR))
    body = audio[s:s + n + x]
    out = body[:n].copy()
    t = np.linspace(0.0, np.pi / 2.0, x)
    out[:x] = body[n:n + x] * np.cos(t) + body[:x] * np.sin(t)
    return out


def level(raw):
    """Integrated loudness (LUFS) and true peak (dBFS) of float32 mono samples, EBU R128 by ffmpeg."""
    r = subprocess.run([ffmpeg(), "-nostats", "-hide_banner", "-f", "f32le", "-ar", str(SR), "-ac", "1", "-i", "-", "-af", "ebur128=peak=true", "-f", "null", "-"], input=raw, capture_output=True)
    summary = r.stderr.decode("utf-8", "replace")
    summary = summary[summary.rfind("Summary:"):]
    return float(re.search(r"I:\s+(-?[\d.]+) LUFS", summary).group(1)), float(re.search(r"Peak:\s+(-?[\d.]+) dBFS", summary).group(1))


def normalise(audio, lufs, tp):
    """One linear gain to the target loudness, held back if it would take the true peak over the law (the file then reads a little quieter and the check after the encode says so). loudnorm is not used: it
    measures over windows of 3 s and a one-shot or a short loop comes out a dB off (the demo found 1.8)."""
    loudness, peak = level(audio.astype("<f4").tobytes())
    gain = min(lufs - loudness, tp - TP_HEADROOM - peak)
    return (audio * 10.0 ** (gain / 20.0)).astype("<f4")


def write(audio, target):
    codec = ["-c:a", "libvorbis", "-q:a", "4"] if target.suffix == ".ogg" else ["-c:a", "pcm_s16le"]
    target.parent.mkdir(parents=True, exist_ok=True)
    r = subprocess.run([ffmpeg(), "-y", "-v", "error", "-f", "f32le", "-ar", str(SR), "-ac", "1", "-i", "-", *codec, "-ar", str(SR), "-ac", "1", str(target)], input=audio.astype("<f4").tobytes(), capture_output=True)
    if r.returncode != 0:
        sys.exit("music_post: could not write %s: %s" % (target, r.stderr.decode("utf-8", "replace")))


def measure(path):
    """Integrated loudness (LUFS), true peak (dBFS) and duration (s) of the file as written, EBU R128 by ffmpeg."""
    r = subprocess.run([ffmpeg(), "-nostats", "-hide_banner", "-i", str(path), "-af", "ebur128=peak=true", "-f", "null", "-"], capture_output=True, text=True, encoding="utf-8", errors="replace")
    summary = r.stderr[r.stderr.rfind("Summary:"):]
    lufs = float(re.search(r"I:\s+(-?[\d.]+) LUFS", summary).group(1))
    peak = float(re.search(r"Peak:\s+(-?[\d.]+) dBFS", summary).group(1))
    seconds = len(decode(path)) / SR
    return lufs, peak, seconds


def seam(audio):
    """How far the loop jumps where its end meets its start, as a share of the loudness of its last 50 ms (0 is a seamless join)."""
    k = int(0.05 * SR)
    return float(abs(audio[0] - audio[-1]) / (np.sqrt(np.mean(audio[-k:] ** 2)) + 1e-9))


def process(source, target, seconds, start, one_shot, lufs, tp):
    audio = normalise(cut(decode(source), start, seconds, one_shot), lufs, tp)
    write(audio, target)
    got_lufs, got_tp, got_seconds = measure(target)
    jump = 0.0 if one_shot else seam(decode(target))
    print("music_post: %s %s %.3f s lufs=%.2f tp=%.2f seam=%.3f (law %g LUFS, tp <= %g)" % (target, "one-shot" if one_shot else "loop", got_seconds, got_lufs, got_tp, jump, lufs, tp))
    ok = abs(got_lufs - lufs) <= LUFS_TOLERANCE and got_tp <= tp and abs(got_seconds - seconds) <= 0.01
    return ok


def demo():
    """A synthetic pad of 12 s (two tones, a slow swell, a little noise) becomes a loop of 4 s and a one-shot of 0.5 s: both on the law, the seam shut."""
    t = np.arange(12 * SR) / SR
    pad = (np.sin(2 * np.pi * 220 * t) + 0.6 * np.sin(2 * np.pi * 330.5 * t)) * (0.5 + 0.4 * np.sin(2 * np.pi * 0.2 * t))
    pad = (pad + 0.05 * np.random.default_rng(1).standard_normal(len(t))) * 0.3
    with tempfile.TemporaryDirectory() as tmp:
        source = pathlib.Path(tmp) / "pad.wav"
        write(pad.astype("<f4"), source)
        loop_ok = process(source, pathlib.Path(tmp) / "loop.ogg", 4.0, 1.0, False, -18.0, -1.5)
        shot_ok = process(source, pathlib.Path(tmp) / "shot.wav", 0.5, 0.0, True, -14.0, -1.5)
        jump = seam(decode(pathlib.Path(tmp) / "loop.ogg"))
    assert loop_ok and shot_ok and jump < 0.5, (loop_ok, shot_ok, jump)
    print("music_post demo: a loop and a one-shot come out on the loudness law, the right length, and the seam of the loop is shut")


def main(argv):
    if "--demo" in argv:
        demo()
        return 0
    if len(argv) < 3 or "--loop" not in argv:
        print(__doc__)
        return 2
    opts = {}
    for flag, default in (("--loop", None), ("--start", "0"), ("--lufs", "-18"), ("--tp", "-1.5")):
        opts[flag] = float(argv[argv.index(flag) + 1]) if flag in argv else (float(default) if default is not None else None)
    ok = process(pathlib.Path(argv[1]), pathlib.Path(argv[2]), opts["--loop"], opts["--start"], "--one-shot" in argv, opts["--lufs"], opts["--tp"])
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
