# -*- coding: utf-8 -*-
"""M1 of Session 27: the post-production pass of docs/MUSIC_RECIPE.md for one generated track, with ffmpeg: cut `--loop` seconds from `--start`, close the seam of a loop with an equal-power crossfade of the
audio that would have followed the loop into its head (a one-shot gets 3 ms edge fades instead), downmix to mono 44.1 kHz (the house format of the beds, docs/MUSIC_SPEC.md), gain it to the house
law (beds and music -18 LUFS integrated, true peak at most -1.5 dBFS; a track whose sharp peaks hold the gain back is limited to the law first) and write OGG q4 or 16-bit WAV by the extension of the target. It measures the file it wrote and exits 1 when the loudness or the true peak is off. `--relevel` puts a shipped file on the same law in place, its length kept (no cut, no new seam).

usage: python tools/qa_sim/music_post.py <input> <target.ogg|.wav> --loop <seconds> [--start <seconds>, else the steadiest stretch] [--one-shot] [--lufs -18] [--tp -1.5]
       python tools/qa_sim/music_post.py <file.ogg|.wav> --relevel [--lufs -18] [--tp -1.5]
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
# the lossy encode can overshoot the peak it was normalised to by half a dB (the substation take went from -2.0 to -1.5): aim a dB lower, verify at the law
TP_HEADROOM = 1.0
# samples that ffmpeg's alimiter at attack=5 ms delays its output at 44.1 kHz (an impulse at 1000 comes out at 1219)
LIMITER_LAG = 219


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


def steadiest_start(audio, seconds, one_shot):
    """The start (s) of the stretch of `seconds` (plus the crossfade of a loop) that sits stillest: the loudness of its seconds varies least and its end is as loud as its beginning, so a loop of it holds no intro,
    no break and no fade-out. Tried every half second between 4 s in and 4 s from the end."""
    n = int(round(seconds * SR)) + (0 if one_shot else min(int(CROSSFADE_S * SR), int(round(seconds * SR)) // 8))
    per_second = [float(np.sqrt(np.mean(audio[i:i + SR] ** 2)) + 1e-9) for i in range(0, len(audio) - SR + 1, SR)]
    best, best_score = None, None
    s = 4.0
    while int((s + 4.0) * SR) + n <= len(audio):
        window = np.array(per_second[int(s):int(s + n / SR) + 1])
        mean = float(window.mean())
        score = float(window.std()) / mean + abs(window[0] - window[-1]) / mean
        if best_score is None or score < best_score:
            best, best_score = s, score
        s += 0.5
    if best is None:
        sys.exit("music_post: the file (%.1f s) is too short for a stretch of %.1f s with 4 s of margin" % (len(audio) / SR, n / SR))
    return best


def level(raw):
    """Integrated loudness (LUFS) and true peak (dBFS) of float32 mono samples, EBU R128 by ffmpeg."""
    r = subprocess.run([ffmpeg(), "-nostats", "-hide_banner", "-f", "f32le", "-ar", str(SR), "-ac", "1", "-i", "-", "-af", "ebur128=peak=true", "-f", "null", "-"], input=raw, capture_output=True)
    summary = r.stderr.decode("utf-8", "replace")
    summary = summary[summary.rfind("Summary:"):]
    return float(re.search(r"I:\s+(-?[\d.]+) LUFS", summary).group(1)), float(re.search(r"Peak:\s+(-?[\d.]+) dBFS", summary).group(1))


def limit(audio, ceiling):
    """Peak-limit float32 mono samples to `ceiling` dBFS with ffmpeg's alimiter (5 ms lookahead, 50 ms release, no auto level). The limiter delays its output by LIMITER_LAG samples and cuts the tail, so it is fed
    that many samples of silence and the delay is dropped: the result lines up with the input (the demo checks it)."""
    chain = "alimiter=limit=%.5f:attack=5:release=50:level=0" % (10.0 ** (ceiling / 20.0))
    padded = np.concatenate([audio, np.zeros(LIMITER_LAG, "<f4")]).astype("<f4")
    r = subprocess.run([ffmpeg(), "-v", "error", "-f", "f32le", "-ar", str(SR), "-ac", "1", "-i", "-", "-af", chain, "-f", "f32le", "-"], input=padded.tobytes(), capture_output=True)
    if r.returncode != 0:
        sys.exit("music_post: the limiter failed: %s" % r.stderr.decode("utf-8", "replace"))
    return np.frombuffer(r.stdout, dtype="<f4")[LIMITER_LAG:LIMITER_LAG + len(audio)].copy()


def normalise(audio, lufs, tp):
    """One linear gain to the target loudness. If that gain would take the true peak over the law (sharp clanks or hits over a pad: the first warehouses take read -20.6 LUFS), the peaks are limited to the law and
    the gain is trimmed by what the limiter took, up to ten rounds, so the track still lands on the house loudness. loudnorm is not used: it measures over windows of 3 s and a one-shot or a short loop comes out
    a dB off (the demo found 1.8)."""
    loudness, peak = level(audio.astype("<f4").tobytes())
    gain, aim = lufs - loudness, tp - TP_HEADROOM
    if peak + gain <= aim:
        return (audio * 10.0 ** (gain / 20.0)).astype("<f4")
    ceiling = aim
    for _ in range(10):
        out = limit(audio * 10.0 ** (gain / 20.0), ceiling)
        got, got_peak = level(out.tobytes())
        if abs(got - lufs) <= 0.1 and got_peak <= aim:
            break
        gain += lufs - got
        ceiling -= max(0.0, got_peak - aim)
    return out


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
    raw = decode(source)
    if start is None:
        start = steadiest_start(raw, seconds, one_shot)
        print("music_post: the steadiest stretch starts at %.1f s" % start)
    audio = normalise(cut(raw, start, seconds, one_shot), lufs, tp)
    write(audio, target)
    got_lufs, got_tp, got_seconds = measure(target)
    jump = 0.0 if one_shot else seam(decode(target))
    print("music_post: %s %s %.3f s lufs=%.2f tp=%.2f seam=%.3f (law %g LUFS, tp <= %g)" % (target, "one-shot" if one_shot else "loop", got_seconds, got_lufs, got_tp, jump, lufs, tp))
    ok = abs(got_lufs - lufs) <= LUFS_TOLERANCE and got_tp <= tp and abs(got_seconds - seconds) <= 0.01
    return ok


def relevel(path, lufs, tp):
    """Put a shipped file on the law in place: decode, normalise, write, measure. The length is the file's own, so nothing is cut and no seam is made."""
    seconds = measure(path)[2]
    write(normalise(decode(path), lufs, tp), path)
    got_lufs, got_tp, got_seconds = measure(path)
    print("music_post: %s relevelled %.3f s lufs=%.2f tp=%.2f (law %g LUFS, tp <= %g)" % (path, got_seconds, got_lufs, got_tp, lufs, tp))
    return abs(got_lufs - lufs) <= LUFS_TOLERANCE and got_tp <= tp and abs(got_seconds - seconds) <= 0.01


def demo():
    """A synthetic pad of 20 s (two tones, a slow swell, a little noise) becomes a loop of 4 s and a one-shot of 0.5 s: both on the law, the seam shut; the same pad with a 5 ms noise burst every 1.5 s (a chain clank,
    20 dB over the pad) is limited and still lands on the law; and a loud intro of 7 s is not where the steadiest stretch starts."""
    t = np.arange(20 * SR) / SR
    pad = (np.sin(2 * np.pi * 220 * t) + 0.6 * np.sin(2 * np.pi * 330.5 * t)) * (0.5 + 0.4 * np.sin(2 * np.pi * 0.2 * t))
    pad = (pad + 0.05 * np.random.default_rng(1).standard_normal(len(t))) * 0.3
    with tempfile.TemporaryDirectory() as tmp:
        source = pathlib.Path(tmp) / "pad.wav"
        write(pad.astype("<f4"), source)
        loop_ok = process(source, pathlib.Path(tmp) / "loop.ogg", 4.0, 1.0, False, -18.0, -1.5)
        shot_ok = process(source, pathlib.Path(tmp) / "shot.wav", 0.5, 0.0, True, -14.0, -1.5)
        assert np.abs(limit(pad.astype("<f4"), -1.0) - pad).max() < 1e-3, "the limiter's output is not lined up with its input"
        clank = pad.copy()
        for at in range(int(1.7 * SR), 19 * SR, int(1.5 * SR)):
            clank[at:at + 220] += np.random.default_rng(at).standard_normal(220).astype("<f4") * 2.5 * np.linspace(1.0, 0.0, 220, dtype="<f4")
        write(clank.astype("<f4"), pathlib.Path(tmp) / "clank.wav")
        clank_ok = process(pathlib.Path(tmp) / "clank.wav", pathlib.Path(tmp) / "clank.ogg", 4.0, 1.0, False, -18.0, -1.5)
        quiet = pathlib.Path(tmp) / "quiet.ogg"
        write((clank * 0.1).astype("<f4"), quiet)
        relevel_ok = relevel(quiet, -18.0, -1.5)
        intro = pad.copy()
        intro[: 7 * SR] *= 6.0
        picked = steadiest_start(intro.astype("<f4"), 4.0, False)
        assert picked >= 7.0 and picked + 4.0 <= 20.0, picked
        jump = max(seam(decode(pathlib.Path(tmp) / "loop.ogg")), seam(decode(pathlib.Path(tmp) / "clank.ogg")))
    assert loop_ok and shot_ok and clank_ok and relevel_ok and jump < 0.5, (loop_ok, shot_ok, clank_ok, relevel_ok, jump)
    print("music_post demo: a loop, a one-shot, a loop with sharp clanks and a quiet file relevelled in place come out on the loudness law, the right length, and the seam of the loop is shut")


def main(argv):
    if "--demo" in argv:
        demo()
        return 0
    opts = {}
    for flag, default in (("--loop", None), ("--start", None), ("--lufs", "-18"), ("--tp", "-1.5")):
        opts[flag] = float(argv[argv.index(flag) + 1]) if flag in argv else (float(default) if default is not None else None)
    if "--relevel" in argv and len(argv) >= 2:
        return 0 if relevel(pathlib.Path(argv[1]), opts["--lufs"], opts["--tp"]) else 1
    if len(argv) < 3 or "--loop" not in argv:
        print(__doc__)
        return 2
    ok = process(pathlib.Path(argv[1]), pathlib.Path(argv[2]), opts["--loop"], opts["--start"], "--one-shot" in argv, opts["--lufs"], opts["--tp"])
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
