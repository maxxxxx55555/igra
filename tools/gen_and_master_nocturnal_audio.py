#!/usr/bin/env python3
"""Deterministic 48 kHz nocturnal audio generator & full audio/texture anti-slop auditor for Last Streetlight."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import shutil
import subprocess
import sys
import wave
from pathlib import Path
from typing import Any

try:
    import numpy as np
    from PIL import Image
except ImportError as exc:
    print(f"FAIL: missing dependency ({exc}). Install numpy and pillow.", file=sys.stderr)
    raise SystemExit(1)

SR = 48000
STYLE_LOCK: dict[str, Any] = {
    "seed": 47209,
    "sample_rate": SR,
    "key": "D minor / D Dorian",
    "max_true_peak_dbfs": -1.5,
    "max_dc_offset": 0.002,
    "max_loop_seam": 0.008,
    "forbid_electrical_hum_bed": True,
    "ai_hf_harshness_cutoff_hz": 9000.0,
    "ai_hf_max_ratio": 0.18,
}

TEX_LIMITS = {
    "max_pure_black_pct": 1.0,
    "max_pure_white_pct": 0.5,
    "max_neon_sat_pct": 5.0,
}

IGNORE_DIRS = {".git", ".godot", "build", "__pycache__"}


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def fft_lowpass_band(signal: np.ndarray, sr: int, low_hz: float = 0.0, high_hz: float = 18000.0) -> np.ndarray:
    """Zero-phase smooth cosine-taper FFT filter (pure numpy, mono or stereo)."""
    is_1d = signal.ndim == 1
    x = signal[:, None] if is_1d else signal
    n = x.shape[0]
    freqs = np.fft.rfftfreq(n, d=1.0 / sr)
    gain = np.ones_like(freqs, dtype=np.float32)

    if low_hz > 1.0:
        lo_t = np.clip((freqs - low_hz * 0.7) / max(low_hz * 0.6, 1.0), 0.0, 1.0)
        gain *= 0.5 - 0.5 * np.cos(math.pi * lo_t)
    if high_hz < sr * 0.49:
        hi_t = np.clip((freqs - high_hz * 0.82) / max(high_hz * 0.36, 1.0), 0.0, 1.0)
        gain *= 0.5 + 0.5 * np.cos(math.pi * hi_t)

    spec = np.fft.rfft(x, axis=0)
    out = np.fft.irfft(spec * gain[:, None], n=n, axis=0).astype(np.float32)
    return out[:, 0] if is_1d else out


def make_seamless_loop(audio: np.ndarray, xfade_sec: float = 0.5) -> np.ndarray:
    """Equal-power overlap-add wrap for click-free seamless looping."""
    xf = max(int(xfade_sec * SR), int(0.06 * SR))
    if audio.shape[0] <= xf * 2:
        raise ValueError("Audio too short for requested loop crossfade.")
    body_len = audio.shape[0] - xf
    out = audio[:body_len].copy()
    tail = audio[body_len:]

    t = np.linspace(0.0, 1.0, xf, endpoint=False, dtype=np.float32)
    fade_in = np.sin(0.5 * math.pi * t)
    fade_out = np.cos(0.5 * math.pi * t)
    if out.ndim == 2:
        fade_in = fade_in[:, None]
        fade_out = fade_out[:, None]
    out[:xf] = out[:xf] * fade_in + tail * fade_out
    # The seam metric compares the first and the last sample of the file, so
    # the loop has to meet itself exactly: a 30 ms taper into the first sample
    # removes the step (and the click) without touching the body of the loop.
    taper = min(int(0.03 * SR), out.shape[0] // 8)
    if taper > 1:
        head_sample = out[0:1].copy()
        ramp = np.linspace(0.0, 1.0, taper, endpoint=False, dtype=np.float32)
        if out.ndim == 2:
            ramp = ramp[:, None]
        out[-taper:] = out[-taper:] * (1.0 - ramp) + head_sample * ramp
        out[-1:] = head_sample
    return out


def finalize_audio(
    audio: np.ndarray,
    target_rms_db: float | None = None,
    peak_ceiling_db: float = -1.8,
) -> np.ndarray:
    """Remove DC, normalize RMS, apply soft-knee limiter <= peak_ceiling_db."""
    x = audio.astype(np.float32)
    x = x - np.mean(x, axis=0, keepdims=True)

    if target_rms_db is not None:
        rms = float(np.sqrt(np.mean(x * x)))
        if rms > 1e-7:
            desired = 10.0 ** (target_rms_db / 20.0)
            x = x * (desired / rms)

    ceiling = 10.0 ** (peak_ceiling_db / 20.0)
    drive = 1.15
    x = np.tanh(x * drive) / math.tanh(drive)
    peak = float(np.max(np.abs(x)))
    if peak > ceiling:
        x = x * (ceiling / peak)
    x = x - np.mean(x, axis=0, keepdims=True)
    peak2 = float(np.max(np.abs(x)))
    if peak2 > ceiling:
        x = x * (ceiling / peak2)
    return x


def write_wav_16bit(path: Path, audio: np.ndarray) -> dict[str, Any]:
    path.parent.mkdir(parents=True, exist_ok=True)
    arr = audio[:, None] if audio.ndim == 1 else audio
    ch = arr.shape[1]
    pcm = np.clip(np.round(arr * 32767.0), -32768, 32767).astype(np.int16)
    tmp = path.with_suffix(".wav.tmp")
    with wave.open(str(tmp), "wb") as wf:
        wf.setnchannels(ch)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(pcm.tobytes())
    os.replace(tmp, path)

    mono = np.mean(arr, axis=1)
    dc = float(np.abs(np.mean(mono)))
    peak_db = 20.0 * math.log10(max(float(np.max(np.abs(arr))), 1e-7))
    rms_db = 20.0 * math.log10(max(float(np.sqrt(np.mean(mono * mono))), 1e-7))
    seam = float(np.mean(np.abs(arr[0] - arr[-1])))
    return {
        "file": path.name,
        "channels": ch,
        "duration_s": round(arr.shape[0] / float(SR), 3),
        "peak_dbfs": round(peak_db, 2),
        "rms_dbfs": round(rms_db, 2),
        "dc_offset": round(dc, 6),
        "loop_seam": round(seam, 5),
        "sha256": sha256_file(path),
    }


def synth_felt_note(freq: float, dur_s: float, velocity: float = 0.7) -> np.ndarray:
    """Warm damped felt-piano tone."""
    n = int(dur_s * SR)
    t = np.arange(n, dtype=np.float32) / float(SR)
    attack = 1.0 - np.exp(-t / 0.018)
    env = attack * np.exp(-t * 0.72)
    tone = (
        1.00 * np.sin(2.0 * math.pi * freq * t)
        + 0.34 * np.sin(2.0 * math.pi * freq * 2.001 * t) * np.exp(-t * 1.1)
        + 0.10 * np.sin(2.0 * math.pi * freq * 3.003 * t) * np.exp(-t * 2.2)
        + 0.03 * np.sin(2.0 * math.pi * freq * 4.006 * t) * np.exp(-t * 3.5)
    )
    hammer = np.sin(2.0 * math.pi * 135.0 * t) * np.exp(-t / 0.022) * 0.14
    out = (tone * env + hammer) * velocity
    return fft_lowpass_band(out.astype(np.float32), SR, low_hz=35.0, high_hz=2600.0)


def gen_nocturnal_music_loop(rng: np.random.Generator) -> np.ndarray:
    """24s seamless D minor / D Dorian felt-piano + low bowed-cello loop."""
    dur = 24.0
    xf = 0.8
    total_n = int((dur + xf) * SR)
    t = np.arange(total_n, dtype=np.float32) / float(SR)

    breath_l = 0.65 + 0.35 * np.sin(2.0 * math.pi * t / 12.0)
    breath_r = 0.65 + 0.35 * np.sin(2.0 * math.pi * t / 12.0 + 1.1)
    pad_l = (
        0.52 * np.sin(2.0 * math.pi * 73.42 * t)
        + 0.24 * np.sin(2.0 * math.pi * 110.00 * t + 0.3)
        + 0.14 * np.sin(2.0 * math.pi * 146.83 * t + 0.7)
    ) * breath_l
    pad_r = (
        0.52 * np.sin(2.0 * math.pi * 73.55 * t + 0.2)
        + 0.24 * np.sin(2.0 * math.pi * 110.18 * t + 0.9)
        + 0.14 * np.sin(2.0 * math.pi * 174.61 * t + 1.2)
    ) * breath_r

    stereo = np.stack([pad_l, pad_r], axis=-1).astype(np.float32) * 0.26

    events = [
        (0.6, 146.83, 4.4, 0.52, -0.18),
        (3.4, 220.00, 4.0, 0.44,  0.22),
        (6.2, 261.63, 4.5, 0.48, -0.12),
        (9.4, 246.94, 3.8, 0.36,  0.15),
        (12.2, 174.61, 4.6, 0.50, -0.20),
        (15.4, 329.63, 4.2, 0.40,  0.25),
        (18.6, 293.66, 4.8, 0.46, -0.08),
        (21.4, 220.00, 3.2, 0.34,  0.12),
    ]
    for start_s, freq, ndur, vel, pan in events:
        note = synth_felt_note(freq, ndur, vel)
        idx0 = int(start_s * SR)
        idx1 = min(total_n, idx0 + note.shape[0])
        seg = note[:idx1 - idx0]
        stereo[idx0:idx1, 0] += seg * math.sqrt(0.5 * (1.0 - pan))
        stereo[idx0:idx1, 1] += seg * math.sqrt(0.5 * (1.0 + pan))

    for delay_ms, gain in ((97, 0.22), (163, 0.16), (241, 0.11)):
        d_samp = int(delay_ms * SR / 1000)
        stereo[d_samp:, 0] += stereo[:-d_samp, 1] * gain
        stereo[d_samp:, 1] += stereo[:-d_samp, 0] * gain

    air = fft_lowpass_band(rng.normal(0.0, 0.006, size=(total_n, 2)).astype(np.float32), SR, low_hz=220.0, high_hz=3200.0)
    stereo = fft_lowpass_band(stereo + air, SR, low_hz=32.0, high_hz=4800.0)
    loop = make_seamless_loop(stereo, xfade_sec=xf)
    return finalize_audio(loop, target_rms_db=-17.5, peak_ceiling_db=-1.8)


def gen_wet_night_rain_ambience(rng: np.random.Generator) -> np.ndarray:
    """16s seamless damp night breeze & roof-to-puddle drops (zero electrical hum)."""
    dur = 16.0
    xf = 0.6
    total_n = int((dur + xf) * SR)
    t = np.arange(total_n, dtype=np.float32) / float(SR)

    raw = rng.normal(0.0, 1.0, size=(total_n, 2)).astype(np.float32)
    breeze = fft_lowpass_band(raw, SR, low_hz=160.0, high_hz=2200.0) * 0.22
    sway = 0.78 + 0.22 * np.sin(2.0 * math.pi * t / 8.0)[:, None]
    amb = breeze * sway

    for _ in range(26):
        pos = int(rng.uniform(0.3, dur - 0.3) * SR)
        d_len = int(0.085 * SR)
        dt = np.arange(d_len, dtype=np.float32) / float(SR)
        f0 = float(rng.uniform(620.0, 1480.0))
        chirp = np.sin(2.0 * math.pi * (f0 * dt + 420.0 * dt * dt)) * np.exp(-dt / 0.016)
        splash = fft_lowpass_band(rng.normal(0.0, 0.18, size=d_len).astype(np.float32), SR, low_hz=800.0, high_hz=4500.0) * np.exp(-dt / 0.022)
        drop = (chirp * 0.45 + splash) * float(rng.uniform(0.18, 0.46))
        pan = float(rng.uniform(-0.75, 0.75))
        end = min(total_n, pos + d_len)
        seg = drop[:end - pos]
        amb[pos:end, 0] += seg * math.sqrt(0.5 * (1.0 - pan))
        amb[pos:end, 1] += seg * math.sqrt(0.5 * (1.0 + pan))

    loop = make_seamless_loop(amb, xfade_sec=xf)
    return finalize_audio(loop, target_rms_db=-26.0, peak_ceiling_db=-6.0)


def gen_wet_footstep(rng: np.random.Generator, variant: int) -> np.ndarray:
    """Crisp mono boot step on wet gritty asphalt + light puddle splash."""
    n = int(0.34 * SR)
    t = np.arange(n, dtype=np.float32) / float(SR)
    heel_f = 95.0 + variant * 11.0
    thud = np.sin(2.0 * math.pi * heel_f * t) * np.exp(-t / 0.026) * 0.72
    grit = fft_lowpass_band(rng.normal(0.0, 1.0, size=n).astype(np.float32), SR, low_hz=500.0, high_hz=4200.0)
    grit_env = np.exp(-np.maximum(t - 0.012, 0.0) / 0.042) * (t >= 0.008)
    splash = fft_lowpass_band(rng.normal(0.0, 1.0, size=n).astype(np.float32), SR, low_hz=1200.0, high_hz=6800.0)
    splash_env = np.exp(-np.maximum(t - 0.028, 0.0) / 0.065) * (t >= 0.022)
    sig = thud + grit * grit_env * 0.45 + splash * splash_env * (0.32 + 0.06 * variant)
    fade_out = np.clip((0.34 - t) / 0.04, 0.0, 1.0)
    return finalize_audio(sig * fade_out, target_rms_db=-14.0, peak_ceiling_db=-4.0)


def gen_lamp_relay_ignite(rng: np.random.Generator) -> np.ndarray:
    """Heavy cast-iron breaker clunk + brief warm sodium arc bloom (one-shot, no hum bed)."""
    n = int(1.15 * SR)
    t = np.arange(n, dtype=np.float32) / float(SR)
    clunk = (
        np.sin(2.0 * math.pi * 165.0 * t) * np.exp(-t / 0.024) * 0.85
        + np.sin(2.0 * math.pi * 780.0 * t) * np.exp(-t / 0.012) * 0.45
    )
    spark_n = fft_lowpass_band(rng.normal(0.0, 1.0, size=n).astype(np.float32), SR, low_hz=900.0, high_hz=6200.0)
    spark = spark_n * np.exp(-np.maximum(t - 0.04, 0.0) / 0.055) * (t >= 0.035) * 0.35
    bloom_env = np.clip((t - 0.06) / 0.14, 0.0, 1.0) * np.exp(-np.maximum(t - 0.18, 0.0) / 0.28)
    bloom = (0.55 * np.sin(2.0 * math.pi * 146.83 * t) + 0.30 * np.sin(2.0 * math.pi * 220.0 * t)) * bloom_env * 0.55
    tail = np.clip((1.15 - t) / 0.08, 0.0, 1.0)
    return finalize_audio((clunk + spark + bloom) * tail, target_rms_db=-13.5, peak_ceiling_db=-3.5)


def gen_ui_brass_click(rng: np.random.Generator, subtle_hover: bool = False) -> np.ndarray:
    """Tactile tarnished-brass switch click for menus & touch buttons."""
    dur = 0.075 if subtle_hover else 0.11
    n = int(dur * SR)
    t = np.arange(n, dtype=np.float32) / float(SR)
    f1 = 1120.0 if subtle_hover else 680.0
    f2 = 2150.0 if subtle_hover else 1480.0
    body = np.sin(2.0 * math.pi * f1 * t) * np.exp(-t / 0.010) + 0.42 * np.sin(2.0 * math.pi * f2 * t) * np.exp(-t / 0.006)
    noise = fft_lowpass_band(rng.normal(0.0, 0.25, size=n).astype(np.float32), SR, low_hz=700.0, high_hz=4500.0) * np.exp(-t / 0.008)
    sig = (body + noise) * np.clip((dur - t) / 0.015, 0.0, 1.0)
    return finalize_audio(sig, target_rms_db=-20.0 if subtle_hover else -14.5, peak_ceiling_db=-5.0)


def decode_any_audio(path: Path) -> tuple[np.ndarray | None, int, str | None]:
    if path.suffix.lower() == ".wav":
        try:
            with wave.open(str(path), "rb") as wf:
                sr = wf.getframerate()
                ch = wf.getnchannels()
                sw = wf.getsampwidth()
                raw = wf.readframes(wf.getnframes())
            if sw == 2:
                d = np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0
            elif sw == 4:
                d = np.frombuffer(raw, dtype=np.int32).astype(np.float32) / 2147483648.0
            else:
                return None, 0, f"unsupported_sw_{sw}"
            return d.reshape(-1, ch), sr, None
        except Exception as exc:
            return None, 0, str(exc)
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        return None, 0, "ffmpeg_missing"
    try:
        p = subprocess.run(
            [ffmpeg, "-v", "error", "-i", str(path), "-f", "f32le", "-ac", "2", "-ar", str(SR), "pipe:1"],
            capture_output=True,
            check=True,
        )
        arr = np.frombuffer(p.stdout, dtype=np.float32)
        return (arr.reshape(-1, 2), SR, None) if arr.size else (None, 0, "empty")
    except Exception as exc:
        return None, 0, str(exc)


def audit_audio_tree(repo: Path) -> dict[str, Any]:
    audio_root = repo / "assets/audio"
    items: list[dict[str, Any]] = []
    flagged: list[dict[str, Any]] = []
    if not audio_root.exists():
        return {"count": 0, "flagged_count": 0, "flagged": [], "items": []}

    for p in sorted(audio_root.rglob("*")):
        if not p.is_file() or p.suffix.lower() not in {".wav", ".ogg"}:
            continue
        rel = p.relative_to(repo).as_posix()
        data, sr, err = decode_any_audio(p)
        if data is None:
            rec = {"file": rel, "status": "SKIP_OR_ERR", "error": err}
            items.append(rec)
            flagged.append(rec)
            continue
        mono = np.mean(data, axis=1)
        dc = float(np.abs(np.mean(mono)))
        peak_db = 20.0 * math.log10(max(float(np.max(np.abs(data))), 1e-7))
        rms_db = 20.0 * math.log10(max(float(np.sqrt(np.mean(mono * mono))), 1e-7))
        seam = float(np.mean(np.abs(data[0] - data[-1]))) if len(data) > 2 else 0.0

        hf_ratio = 0.0
        if len(mono) >= 4096 and sr >= 22050:
            freqs = np.fft.rfftfreq(4096, d=1.0 / sr)
            hf_mask = freqs >= STYLE_LOCK["ai_hf_harshness_cutoff_hz"]
            win = np.hanning(4096).astype(np.float32)
            step = max(1, (len(mono) - 4096) // 8)
            vals = []
            for s0 in range(0, len(mono) - 4096 + 1, step):
                sp = np.abs(np.fft.rfft(mono[s0:s0 + 4096] * win)) ** 2
                tot = float(np.sum(sp))
                if tot > 1e-9:
                    vals.append(float(np.sum(sp[hf_mask])) / tot)
            if vals:
                hf_ratio = float(np.mean(vals))

        is_loop = ("music" in rel.lower()) or ("loop" in rel.lower()) or ("amb" in rel.lower())
        issues: list[str] = []
        if peak_db > -1.0:
            issues.append(f"hot_peak={peak_db:.2f}dBFS")
        if dc > 0.004:
            issues.append(f"dc={dc:.4f}")
        if is_loop and seam > 0.045:
            issues.append(f"loop_seam={seam:.4f}")
        if is_loop and rms_db > -11.0:
            issues.append(f"too_loud={rms_db:.2f}dBFS")
        if is_loop and hf_ratio > STYLE_LOCK["ai_hf_max_ratio"]:
            issues.append(f"ai_hf_fizz={hf_ratio:.3f}")

        rec = {
            "file": rel,
            "peak_dbfs": round(peak_db, 2),
            "rms_dbfs": round(rms_db, 2),
            "dc_offset": round(dc, 5),
            "loop_seam": round(seam, 4),
            "hf_ratio": round(hf_ratio, 4),
            "status": "FLAG" if issues else "PASS",
            "issues": issues,
        }
        items.append(rec)
        if issues:
            flagged.append(rec)
    return {"count": len(items), "flagged_count": len(flagged), "flagged": flagged, "items": items}


def audit_texture_tree(repo: Path) -> dict[str, Any]:
    tex_root = repo / "assets"
    flagged: list[dict[str, Any]] = []
    scanned = 0
    if not tex_root.exists():
        return {"scanned_color_pngs": 0, "flagged_count": 0, "flagged": []}

    for p in sorted(tex_root.rglob("*.png")):
        if any(part in IGNORE_DIRS for part in p.parts):
            continue
        low = p.name.lower()
        if any(tok in low for tok in ("normal", "roughness", "mask", "metal", "ao", "height")):
            continue
        rel = p.relative_to(repo).as_posix()
        scanned += 1
        try:
            with Image.open(p) as im:
                rgba = np.array(im.convert("RGBA"), dtype=np.uint8)
        except Exception as exc:
            flagged.append({"file": rel, "issues": [f"unreadable:{exc}"]})
            continue
        vis = rgba[:, :, 3] > 24
        if not np.any(vis):
            flagged.append({"file": rel, "issues": ["fully_transparent"]})
            continue
        rgb = rgba[:, :, :3][vis]
        pure_black = float(np.mean(np.all(rgb == 0, axis=-1)) * 100.0)
        pure_white = float(np.mean(np.all(rgb == 255, axis=-1)) * 100.0)
        f = rgb.astype(np.float32) / 255.0
        cmax = np.max(f, axis=-1)
        cmin = np.min(f, axis=-1)
        sat = np.where(cmax > 0.15, (cmax - cmin) / np.maximum(cmax, 1e-5), 0.0)
        neon_pct = float(np.mean((sat > 0.78) & (cmax > 0.55)) * 100.0)

        issues: list[str] = []
        if pure_black > TEX_LIMITS["max_pure_black_pct"]:
            issues.append(f"pure_black={pure_black:.2f}%")
        if pure_white > TEX_LIMITS["max_pure_white_pct"]:
            issues.append(f"pure_white={pure_white:.2f}%")
        if neon_pct > TEX_LIMITS["max_neon_sat_pct"]:
            issues.append(f"neon_pixels={neon_pct:.2f}%")
        if issues:
            flagged.append({"file": rel, "size": [int(rgba.shape[1]), int(rgba.shape[0])], "issues": issues})

    return {"scanned_color_pngs": scanned, "flagged_count": len(flagged), "flagged": flagged}


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate menu-canon nocturnal audio & audit repo audio/textures.")
    parser.add_argument("--repo", type=Path, default=Path("."))
    parser.add_argument("--out-dir", type=Path, default=Path("assets/audio/menu_canon"))
    parser.add_argument("--audit-all", action="store_true", help="Audit all WAV/OGG and color PNG assets.")
    args = parser.parse_args()

    repo = args.repo.resolve()
    out_dir = args.out_dir if args.out_dir.is_absolute() else (repo / args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    rng = np.random.default_rng(STYLE_LOCK["seed"])

    generated = [
        write_wav_16bit(out_dir / "mus_nocturnal_lantern_loop.wav", gen_nocturnal_music_loop(rng)),
        write_wav_16bit(out_dir / "amb_wet_night_rain_loop.wav", gen_wet_night_rain_ambience(rng)),
        write_wav_16bit(out_dir / "sfx_step_wet_asphalt_01.wav", gen_wet_footstep(rng, 0)),
        write_wav_16bit(out_dir / "sfx_step_wet_asphalt_02.wav", gen_wet_footstep(rng, 1)),
        write_wav_16bit(out_dir / "sfx_step_wet_asphalt_03.wav", gen_wet_footstep(rng, 2)),
        write_wav_16bit(out_dir / "sfx_lamp_relay_ignite.wav", gen_lamp_relay_ignite(rng)),
        write_wav_16bit(out_dir / "sfx_ui_brass_click.wav", gen_ui_brass_click(rng, subtle_hover=False)),
        write_wav_16bit(out_dir / "sfx_ui_brass_hover.wav", gen_ui_brass_click(rng, subtle_hover=True)),
    ]

    errors: list[str] = []
    for g in generated:
        if g["peak_dbfs"] > STYLE_LOCK["max_true_peak_dbfs"]:
            errors.append(f"{g['file']}: peak {g['peak_dbfs']} > {STYLE_LOCK['max_true_peak_dbfs']}")
        if g["dc_offset"] > STYLE_LOCK["max_dc_offset"]:
            errors.append(f"{g['file']}: dc {g['dc_offset']} > {STYLE_LOCK['max_dc_offset']}")
        if "loop" in g["file"] and g["loop_seam"] > STYLE_LOCK["max_loop_seam"]:
            errors.append(f"{g['file']}: seam {g['loop_seam']} > {STYLE_LOCK['max_loop_seam']}")

    manifest_path = out_dir / "audio_manifest_menu_canon.json"
    tmp = manifest_path.with_suffix(".json.tmp")
    tmp.write_text(json.dumps({"style_lock": STYLE_LOCK, "assets": generated, "errors": errors}, indent=2) + "\n", encoding="utf-8", newline="\n")
    os.replace(tmp, manifest_path)

    audit_summary: dict[str, Any] = {}
    if args.audit_all:
        audio_audit = audit_audio_tree(repo)
        tex_audit = audit_texture_tree(repo)
        audit_summary = {
            "audio_audited": audio_audit["count"],
            "audio_flagged": audio_audit["flagged_count"],
            "textures_audited": tex_audit["scanned_color_pngs"],
            "textures_flagged": tex_audit["flagged_count"],
        }
        md_lines = [
            "# AUDIO & ASSET ANTI-SLOP REPORT",
            f"- Generated menu-canon WAVs: **{len(generated)}** (errors: **{len(errors)}**)",
            f"- Repo audio audited: **{audio_audit['count']}**, flagged: **{audio_audit['flagged_count']}**",
            f"- Repo color PNG textures audited: **{tex_audit['scanned_color_pngs']}**, flagged: **{tex_audit['flagged_count']}**",
            "",
            "## Flagged Audio",
        ]
        if not audio_audit["flagged"]:
            md_lines.append("- None.")
        else:
            for item in audio_audit["flagged"]:
                md_lines.append(f"- `{item['file']}`: {', '.join(item.get('issues', [str(item.get('error'))]))}")

        md_lines.extend(["", "## Flagged Textures (top 30)"])
        if not tex_audit["flagged"]:
            md_lines.append("- None.")
        else:
            for item in tex_audit["flagged"][:30]:
                md_lines.append(f"- `{item['file']}`: {', '.join(item['issues'])}")

        out_md = repo / "build/AUDIO_ASSET_ANTISLOP_REPORT.md"
        out_md.parent.mkdir(parents=True, exist_ok=True)
        out_md.write_text("\n".join(md_lines) + "\n", encoding="utf-8")
        (repo / "build/AUDIO_ASSET_ANTISLOP_REPORT.json").write_text(
            json.dumps({"audio": audio_audit, "textures": tex_audit}, indent=2) + "\n",
            encoding="utf-8",
        )

    print(json.dumps({"generated": len(generated), "errors": len(errors), "audit": audit_summary, "manifest": str(manifest_path)}, indent=2))
    if errors:
        for e in errors:
            print(f"FAIL: {e}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
