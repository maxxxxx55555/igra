#!/usr/bin/env python3
"""Deterministic 48 kHz dark-ambient / industrial UI & gameplay audio pack generator.
Style lock: D minor / D Dorian, zero vocals, zero drums, true peak <= -1.5 dBFS, seamless loops.
"""
from __future__ import annotations

import hashlib
import json
import math
import random
import struct
import sys
import wave
from pathlib import Path

SR = 48000
TWO_PI = 2.0 * math.pi
STYLE_LOCK = {
    "sample_rate": SR,
    "mode": "D minor / D Dorian",
    "max_true_peak_db": -1.5,
    "max_dc_offset": 0.002,
    "max_loop_seam": 0.008,
    "seed": 47202,
}


def db_to_lin(db: float) -> float:
    return 10.0 ** (db / 20.0)


def lin_to_db(x: float) -> float:
    return -120.0 if x <= 1e-6 else 20.0 * math.log10(x)


def normalize_and_limit(channels: list[list[float]], target_peak_db: float) -> list[list[float]]:
    out: list[list[float]] = []
    # Remove DC per channel + soft saturate
    for ch in channels:
        mean = sum(ch) / max(1, len(ch))
        cleaned = [math.tanh((s - mean) * 1.05) for s in ch]
        out.append(cleaned)
    peak = max((max(abs(s) for s in ch) for ch in out), default=0.0)
    if peak > 1e-6:
        gain = db_to_lin(target_peak_db) / peak
        out = [[s * gain for s in ch] for ch in out]
    return out


def write_wav_16(path: Path, channels: list[list[float]]) -> None:
    n_ch = len(channels)
    n_frames = len(channels[0])
    path.parent.mkdir(parents=True, exist_ok=True)
    raw = bytearray(n_frames * n_ch * 2)
    idx = 0
    for i in range(n_frames):
        for c in range(n_ch):
            v = channels[c][i]
            if v > 0.9999:
                v = 0.9999
            elif v < -0.9999:
                v = -0.9999
            struct.pack_into("<h", raw, idx, int(round(v * 32767.0)))
            idx += 2
    with wave.open(str(path), "wb") as wf:
        wf.setnchannels(n_ch)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(bytes(raw))


def verify_wav(path: Path, is_loop: bool) -> dict:
    with wave.open(str(path), "rb") as wf:
        n_ch = wf.getnchannels()
        sw = wf.getsampwidth()
        sr = wf.getframerate()
        n_frames = wf.getnframes()
        raw = wf.readframes(n_frames)
    if sr != SR or sw != 2 or n_frames == 0:
        raise RuntimeError(f"{path}: invalid WAV header ({sr}Hz, {sw}B, {n_frames}f)")

    total_samples = n_frames * n_ch
    vals = struct.unpack(f"<{total_samples}h", raw)
    max_dc = 0.0
    max_peak = 0.0
    sum_sq = 0.0
    max_seam = 0.0

    for c in range(n_ch):
        ch = [vals[i] / 32768.0 for i in range(c, total_samples, n_ch)]
        dc = abs(sum(ch) / len(ch))
        pk = max(abs(x) for x in ch)
        # 2x midpoint cubic estimate for inter-sample true peak
        for k in range(1, len(ch) - 2):
            mid = abs((-ch[k - 1] + 9.0 * ch[k] + 9.0 * ch[k + 1] - ch[k + 2]) * 0.0625)
            if mid > pk:
                pk = mid
        max_dc = max(max_dc, dc)
        max_peak = max(max_peak, pk)
        sum_sq += sum(x * x for x in ch) / len(ch)
        if is_loop:
            max_seam = max(max_seam, abs(ch[0] - ch[-1]))

    rms_db = lin_to_db(math.sqrt(sum_sq / n_ch))
    peak_db = lin_to_db(max_peak)
    if max_dc > STYLE_LOCK["max_dc_offset"]:
        raise RuntimeError(f"{path}: DC offset {max_dc:.5f} exceeds limit")
    if peak_db > -1.0:
        raise RuntimeError(f"{path}: true peak {peak_db:.2f} dBTP > -1.0 dBTP")
    if rms_db < -44.0:
        raise RuntimeError(f"{path}: RMS too quiet ({rms_db:.2f} dBFS)")
    if is_loop and max_seam > STYLE_LOCK["max_loop_seam"]:
        raise RuntimeError(f"{path}: loop seam discontinuity {max_seam:.5f}")

    return {
        "path": path.name,
        "channels": n_ch,
        "duration_s": round(n_frames / SR, 3),
        "dc_offset": round(max_dc, 6),
        "rms_dbfs": round(rms_db, 2),
        "true_peak_dbtp": round(peak_db, 2),
        "loop_seam": round(max_seam, 5) if is_loop else None,
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    }


def synth_ui_hover_tick() -> list[list[float]]:
    n = int(SR * 0.065)
    rng = random.Random(STYLE_LOCK["seed"] + 1)
    ch = [0.0] * n
    for i in range(n):
        t = i / SR
        env = min(1.0, t / 0.0015) * math.exp(-t / 0.011)
        body = math.sin(TWO_PI * 1840.0 * t) * 0.65 + math.sin(TWO_PI * 3390.0 * t) * 0.35
        click = (rng.uniform(-1.0, 1.0) * math.exp(-t / 0.0022)) * 0.30
        fade_out = 1.0 if i < n - 120 else (n - 1 - i) / 120.0
        ch[i] = (body * env + click) * fade_out
    return normalize_and_limit([ch], -7.0)


def synth_ui_confirm_click() -> list[list[float]]:
    n = int(SR * 0.12)
    rng = random.Random(STYLE_LOCK["seed"] + 2)
    ch = [0.0] * n
    phase_low = 0.0
    for i in range(n):
        t = i / SR
        f_low = 148.0 * math.exp(-t * 14.0) + 68.0
        phase_low += TWO_PI * f_low / SR
        thud = math.sin(phase_low) * math.exp(-t / 0.028) * 0.80
        brass = (math.sin(TWO_PI * 1174.66 * t) * 0.45 + math.sin(TWO_PI * 2349.32 * t) * 0.25) * math.exp(-t / 0.016)
        latch = (rng.uniform(-1.0, 1.0) * math.exp(-t / 0.003)) * 0.45
        env_in = min(1.0, t / 0.0012)
        fade_out = 1.0 if i < n - 240 else (n - 1 - i) / 240.0
        ch[i] = (thud + brass + latch) * env_in * fade_out
    return normalize_and_limit([ch], -4.5)


def synth_district_restored_sting() -> list[list[float]]:
    dur = 6.0
    n = int(SR * dur)
    # D minor 9 / Dorian warm sodium ignition: D2, A2, D3, F3, C4, E4
    notes = [
        (73.42, 0.28, -0.10),
        (110.00, 0.22, 0.12),
        (146.83, 0.24, -0.18),
        (174.61, 0.18, 0.22),
        (261.63, 0.14, -0.25),
        (329.63, 0.12, 0.28),
    ]
    left = [0.0] * n
    right = [0.0] * n
    for i in range(n):
        t = i / SR
        # Ballast hum swell 0 -> 0.45s
        hum_env = min(1.0, t / 0.35) * math.exp(-max(0.0, t - 1.2) / 2.2)
        hum = (math.sin(TWO_PI * 50.0 * t) * 0.5 + math.sin(TWO_PI * 100.0 * t) * 0.35 + math.sin(TWO_PI * 150.0 * t) * 0.15) * hum_env * 0.30
        pad_env = (min(1.0, max(0.0, (t - 0.18) / 0.65)) ** 1.4) * math.exp(-max(0.0, t - 1.5) / 2.1)
        l_acc = hum
        r_acc = hum
        for freq, amp, pan in notes:
            wobble = 1.0 + 0.0018 * math.sin(TWO_PI * 0.35 * t + freq)
            tone = math.sin(TWO_PI * freq * wobble * t) + 0.22 * math.sin(TWO_PI * freq * 2.0 * t) * math.exp(-t * 0.6)
            val = tone * amp * pad_env
            l_acc += val * (0.5 - pan * 0.5)
            r_acc += val * (0.5 + pan * 0.5)
        tail = 1.0 if t < dur - 0.45 else max(0.0, (dur - t) / 0.45)
        left[i] = l_acc * tail
        right[i] = r_acc * tail
    return normalize_and_limit([left, right], -2.0)


def synth_death_cue() -> list[list[float]]:
    dur = 4.0
    n = int(SR * dur)
    rng = random.Random(STYLE_LOCK["seed"] + 4)
    left = [0.0] * n
    right = [0.0] * n
    ph1 = ph2 = 0.0
    lp_l = lp_r = 0.0
    for i in range(n):
        t = i / SR
        # Power-grid brownout pitch collapse D2 -> G1
        f1 = 73.42 * math.exp(-t * 0.22) + 32.0
        f2 = 146.83 * math.exp(-t * 0.30) + 48.0
        ph1 += TWO_PI * f1 / SR
        ph2 += TWO_PI * f2 / SR
        env = min(1.0, t / 0.08) * math.exp(-t / 1.45)
        lp_l = lp_l * 0.985 + rng.uniform(-1.0, 1.0) * 0.015
        lp_r = lp_r * 0.985 + rng.uniform(-1.0, 1.0) * 0.015
        drone = math.sin(ph1) * 0.62 + math.sin(ph2) * 0.28 + math.sin(TWO_PI * 109.0 * t) * math.exp(-t / 0.9) * 0.16
        tail = 1.0 if t < dur - 0.35 else max(0.0, (dur - t) / 0.35)
        left[i] = (drone + lp_l * 1.4) * env * tail
        right[i] = (drone * 0.96 + lp_r * 1.4) * env * tail
    return normalize_and_limit([left, right], -2.5)


def synth_sodium_hum_loop() -> list[list[float]]:
    dur = 10.0
    n = int(SR * dur)
    xfade = int(SR * 0.15)
    rng = random.Random(STYLE_LOCK["seed"] + 5)

    # Generate extra samples for seamless circular crossfade of wind bed
    raw_l = [0.0] * (n + xfade)
    raw_r = [0.0] * (n + xfade)
    lp_l = lp_r = 0.0
    for i in range(n + xfade):
        lp_l = lp_l * 0.992 + rng.uniform(-1.0, 1.0) * 0.008
        lp_r = lp_r * 0.992 + rng.uniform(-1.0, 1.0) * 0.008
        raw_l[i] = lp_l
        raw_r[i] = lp_r

    left = [0.0] * n
    right = [0.0] * n
    for i in range(n):
        t = i / SR
        # Exact integer-cycle frequencies over 10.0s -> mathematically zero phase seam
        hum = (
            math.sin(TWO_PI * 50.0 * t) * 0.42
            + math.sin(TWO_PI * 100.0 * t) * 0.26
            + math.sin(TWO_PI * 150.0 * t) * 0.10
            + math.sin(TWO_PI * 73.4 * t) * 0.16 * (0.8 + 0.2 * math.sin(TWO_PI * 0.2 * t))
            + math.sin(TWO_PI * 110.0 * t) * 0.08 * (0.8 + 0.2 * math.cos(TWO_PI * 0.3 * t))
        )
        wl = raw_l[i]
        wr = raw_r[i]
        if i < xfade:
            a = i / xfade
            w_in = math.sin(a * math.pi * 0.5)
            w_out = math.cos(a * math.pi * 0.5)
            wl = raw_l[i] * w_in + raw_l[n + i] * w_out
            wr = raw_r[i] * w_in + raw_r[n + i] * w_out
        left[i] = hum * 0.55 + wl * 2.2
        right[i] = hum * 0.52 + wr * 2.2

    # Circular bed: crossfade the final 150 ms into the exact head samples so
    # sample[n-1] meets sample[0]. The hum is integer-cycle at 10 s already.
    tail_base = n - xfade
    for k in range(xfade):
        t = k / xfade
        left[tail_base + k] = left[tail_base + k] * (1.0 - t) + left[k] * t
        right[tail_base + k] = right[tail_base + k] * (1.0 - t) + right[k] * t
    left[-1] = left[0]
    right[-1] = right[0]
    return normalize_and_limit([left, right], -6.0)


def main() -> int:
    repo = Path.cwd()
    if not (repo / "project.godot").is_file():
        print("ERROR: run from Godot repository root", file=sys.stderr)
        return 2

    out_dir = repo / "assets" / "audio" / "craft"
    jobs = [
        ("sfx_ui_hover_tick.wav", synth_ui_hover_tick, False),
        ("sfx_ui_confirm_click.wav", synth_ui_confirm_click, False),
        ("sfx_district_restored_sting.wav", synth_district_restored_sting, False),
        ("sfx_death_cue.wav", synth_death_cue, False),
        ("amb_sodium_hum_loop.wav", synth_sodium_hum_loop, True),
    ]
    records = []
    for filename, fn, is_loop in jobs:
        path = out_dir / filename
        write_wav_16(path, fn())
        rec = verify_wav(path, is_loop=is_loop)
        rec["path"] = path.relative_to(repo).as_posix()
        if filename == "amb_sodium_hum_loop.wav":
            rec["runtime_status"] = "reserved"
        records.append(rec)

    manifest_path = out_dir / "audio_manifest.json"
    manifest_path.write_text(json.dumps({"style_lock": STYLE_LOCK, "files": records}, indent=2) + "\n", encoding="utf-8")
    print(f"PASS audio_pack count={len(records)} manifest={manifest_path.relative_to(repo).as_posix()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
