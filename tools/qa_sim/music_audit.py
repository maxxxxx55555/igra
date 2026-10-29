#!/usr/bin/env python3
"""The music of the game against the mood matrix of docs/AUDIO_COVERAGE.md (MEGA_PROMPT v7, phase 3), by the numbers a script can read: the length of the loop, the step at its seam, the loudness, the tempo and how steady a pulse there is, the colour of the sound.
It says KEEP, RE-EDIT (a length, a seam, a loudness off, a tempo within 8 % of its row: a time stretch) or REPLACE (a tempo further off) for each track, and nothing about what the ear hears: the acceptance is the owner's listening sheet (a 30 minute soak, the menu for 10 minutes without "bored").
The tempo is the strongest period of the onset flux between 40 and 180 BPM; a drone or a bed has no pulse (strength under 0.15) and shows "-".

usage: python tools/qa_sim/music_audit.py [--demo] [--write]   (--write puts the table into the section "Script audit" of docs/AUDIO_COVERAGE.md)
"""
import pathlib
import sys

import numpy as np

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import music_post as mp  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parents[2]
MUSIC = ROOT / "assets" / "audio" / "music"
DOC = ROOT / "docs" / "AUDIO_COVERAGE.md"
SEAM_MAX = 0.037
LUFS_TOLERANCE = mp.LUFS_TOLERANCE
STING_MAX_S = 8.0
LOOP_MIN_S = {"menu": 90.0, "other": 60.0}
# context -> (BPM low, BPM high) of the matrix row, or None where the row has no tempo
TEMPO = {"menu": (60.0, 70.0), "tension": (70.0, 85.0), "combat": (90.0, 110.0)}
MIN_STRENGTH = 0.15


def context(name):
    if name.startswith("cue_"):
        return "cue"  # the wow cues of the music manager: played once at an event, the matrix has no row for their length
    if name.endswith("_sting"):
        return "sting"
    if name == "music_menu_dark":
        return "menu"
    if name == "music_tension":
        return "tension"
    if name in ("music_combat", "music_battle"):
        return "combat"
    if name.startswith("music_boss"):
        return "boss"
    if name == "music_victory":
        return "victory"
    if name.startswith("layer_"):
        return "layer"
    return "district"


def pulse(audio, seconds=120):
    """(BPM, strength) of the strongest period of the onset flux of the first `seconds`, BPM None when the strength is under MIN_STRENGTH."""
    audio = audio[: int(seconds * mp.SR)].astype(np.float32)
    n_fft, hop = 2048, 1024
    frames = (len(audio) - n_fft) // hop
    if frames < 200:
        return None, 0.0
    idx = np.arange(n_fft)[None, :] + hop * np.arange(frames)[:, None]
    mag = np.log1p(np.abs(np.fft.rfft(audio[idx] * np.hanning(n_fft).astype(np.float32), axis=1)) * 10.0)
    flux = np.maximum(mag[1:] - mag[:-1], 0.0).sum(axis=1)
    flux -= flux.mean()
    spec = np.fft.rfft(flux, 2 * len(flux))
    ac = np.fft.irfft(spec * np.conj(spec))[: len(flux)]
    ac /= ac[0] + 1e-12
    ac = np.convolve(ac, [0.25, 0.5, 0.25], mode="same")  # a period of a fractional number of frames lands on two of them
    fps = mp.SR / hop
    lo, hi = int(60.0 / 180.0 * fps), int(60.0 / 40.0 * fps)
    best = lo + int(np.argmax(ac[lo:hi]))
    strength = float(ac[best])
    for divisor in (4, 3, 2):  # the fundamental is the shortest lag that is nearly as strong as the strongest (a click train peaks at every multiple)
        lag = round(best / divisor)
        if lag >= lo and ac[lag - 1:lag + 2].max() >= 0.55 * strength:
            best = lag
            break
    return (60.0 * fps / best if strength >= MIN_STRENGTH else None), strength


def colour(audio):
    """Spectral centroid in Hz of the first 60 s."""
    audio = audio[: 60 * mp.SR].astype(np.float32)
    frames = (len(audio) - 2048) // 2048
    idx = np.arange(2048)[None, :] + 2048 * np.arange(frames)[:, None]
    mag = np.abs(np.fft.rfft(audio[idx] * np.hanning(2048).astype(np.float32), axis=1)).mean(axis=0)
    return float((np.fft.rfftfreq(2048, 1.0 / mp.SR) * mag).sum() / (mag.sum() + 1e-12))


def judge(ctx, seconds, step, bpm, lufs, target_lufs):
    """(verdict, [reasons]) of one track against its matrix row."""
    reasons, replace = [], False
    if ctx == "sting":
        if seconds > STING_MAX_S:
            reasons.append("a sting of %.1f s (at most %.0f)" % (seconds, STING_MAX_S))
    elif ctx != "cue":
        floor = LOOP_MIN_S["menu" if ctx == "menu" else "other"]
        if seconds < floor and ctx not in ("victory", "boss"):
            reasons.append("loop of %.0f s (at least %.0f)" % (seconds, floor))
        if step > SEAM_MAX:
            reasons.append("seam step %.3f (at most %.3f)" % (step, SEAM_MAX))
    if target_lufs is not None and abs(lufs - target_lufs) > LUFS_TOLERANCE:
        reasons.append("%.1f LUFS, the table says %.1f" % (lufs, target_lufs))
    if ctx in TEMPO and bpm is not None:
        low, high = TEMPO[ctx]
        # a pulse is read at the beat or at half or double of it: the variant nearest to the row is the one that counts
        off = min(0.0 if low <= v <= high else ((low - v) / low if v < low else (v - high) / high) for v in (bpm, bpm / 2.0, bpm * 2.0))
        if off > 0.0:
            reasons.append("%.0f BPM (or %.0f, %.0f), the row says %.0f to %.0f" % (bpm, bpm / 2.0, bpm * 2.0, low, high))
            replace = off > 0.08
    return ("REPLACE" if replace else ("RE-EDIT" if reasons else "KEEP")), reasons


def loudness_targets():
    """File stem -> target LUFS from docs/AUDIO_LOUDNESS_TABLE.md, where a row names the file and a number."""
    import re
    table = ROOT / "docs" / "AUDIO_LOUDNESS_TABLE.md"
    out = {}
    if table.exists():
        for line in table.read_text(encoding="utf-8").splitlines():
            m = re.match(r"\|\s*`?([\w./-]*?)(\w+)\.ogg`?\s*\|.*?(-\d+(?:\.\d+)?)\s*(?:LUFS)?\s*\|", line)
            if m:
                out[m.group(2)] = float(m.group(3))
    return out


def audit():
    targets = loudness_targets()
    rows = []
    for path in sorted(MUSIC.glob("*.ogg")):
        audio = mp.decode(path)
        lufs, peak, seconds = mp.measure(path)
        bpm, strength = pulse(audio)
        step = abs(float(audio[0]) - float(audio[-1]))
        ctx = context(path.stem)
        verdict, reasons = judge(ctx, seconds, step, bpm, lufs, targets.get(path.stem))
        rows.append((path.stem, ctx, seconds, step, lufs, bpm, strength, colour(audio), verdict, reasons))
    boss = {r[0]: r[5] for r in rows if r[1] == "boss" and r[5]}
    if len(boss) >= 2 and max(boss.values()) > 1.5 * min(boss.values()):
        rows = [r if r[1] != "boss" else r[:8] + ("RE-EDIT", r[9] + ["the boss phases differ by %.0f to %.0f BPM: escalation is by layers, not by tempo" % (min(boss.values()), max(boss.values()))]) for r in rows]
    return rows


def table(rows):
    lines = ["| Track | Row | Seconds | Seam step | LUFS | BPM (strength) | Centroid Hz | Verdict |", "|---|---|---|---|---|---|---|---|"]
    for name, ctx, seconds, step, lufs, bpm, strength, centroid, verdict, reasons in rows:
        lines.append("| `%s` | %s | %.0f | %.3f | %.1f | %s | %.0f | %s%s |" % (name, ctx, seconds, step, lufs, ("%.0f (%.2f)" % (bpm, strength)) if bpm else "- (%.2f)" % strength, centroid, verdict, (": " + "; ".join(reasons)) if reasons else ""))
    return "\n".join(lines)


def demo():
    sr = mp.SR
    beat = np.zeros(sr * 40, dtype=np.float32)
    for k in range(0, 40 * 2):  # 120 BPM clicks
        beat[int(k * 0.5 * sr): int(k * 0.5 * sr) + 400] = 0.8 * np.hanning(400)
    bpm, strength = pulse(beat)
    assert bpm is not None and abs(bpm - 120.0) < 4.0, (bpm, strength)
    noise = np.random.default_rng(3).normal(0, 0.05, sr * 40).astype(np.float32)
    assert pulse(noise)[0] is None, "a drone has no pulse"
    assert judge("combat", 90.0, 0.0, 40.0, -16.0, -16.0)[0] == "REPLACE", "a combat bed at 40 BPM (80 doubled) is further than 8 % off its row"
    assert judge("combat", 90.0, 0.0, 50.0, -16.0, -16.0)[0] == "KEEP", "a pulse read at half of a combat tempo is in its row"
    assert judge("tension", 90.0, 0.0, 66.0, -16.0, None)[0] == "RE-EDIT", "a tempo within 8 % is a stretch"
    assert judge("district", 30.0, 0.0, None, -16.0, None)[0] == "RE-EDIT", "a loop under 60 s"
    assert judge("sting", 9.5, 0.0, None, -16.0, None)[0] == "RE-EDIT", "a sting over 8 s"
    assert judge("district", 90.0, 0.0, None, -16.0, None)[0] == "KEEP"
    assert context("cue_death") == "cue" and context("ending_hope_sting") == "sting" and context("music_boss_dark_p2") == "boss" and context("suburbs") == "district"
    assert judge("cue", 120.0, 0.5, None, -16.0, None)[0] == "KEEP", "a cue has no length row and no seam"
    print("music_audit demo OK (a 120 BPM click train reads 120, noise has no pulse, the verdict rules hold)")


def write(rows):
    text = DOC.read_bytes().decode("utf-8")
    eol = "\r\n" if "\r\n" in text else "\n"
    head = "## Script audit of the music (tools/qa_sim/music_audit.py, MEGA_PROMPT v7 phase 3)"
    block = eol.join([head, "", "The numbers a script can read; the ear is the owner's (the listening sheet). KEEP means that no number is against the matrix, not that it was heard.", "", table(rows).replace("\n", eol), ""])
    if head in text:
        start = text.index(head)
        nxt = text.find(eol + "## ", start + 1)
        text = text[:start] + block + (text[nxt + len(eol):] if nxt >= 0 else "")
    else:
        text = text.rstrip("\r\n") + eol + eol + block
    DOC.write_bytes(text.encode("utf-8"))


def main():
    if "--demo" in sys.argv:
        demo()
        return
    rows = audit()
    print(table(rows))
    print("\n%d track(s): %d KEEP, %d RE-EDIT, %d REPLACE" % (len(rows), sum(r[8] == "KEEP" for r in rows), sum(r[8] == "RE-EDIT" for r in rows), sum(r[8] == "REPLACE" for r in rows)))
    if "--write" in sys.argv:
        write(rows)


if __name__ == "__main__":
    main()
