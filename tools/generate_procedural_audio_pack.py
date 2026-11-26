#!/usr/bin/env python3
"""Deterministic survival-horror music & SFX pack generator for The Last Streetlight (48kHz OGG Vorbis)."""

from __future__ import annotations

import argparse
import array
import hashlib
import json
import math
import os
import random
import re
import shutil
import subprocess
import sys
import tempfile
import wave
from pathlib import Path
from typing import Any, Dict, List, Tuple

STYLE_LOCK: Dict[str, Any] = {
    "key_mode": "D_minor_Dorian",
    "sample_rate": 48000,
    "music_bitrate": "96k",
    "sfx_bitrate": "64k",
    "music_target_lufs": -16.0,
    "music_lufs_tol": 1.6,
    "true_peak_max_dbtp": -1.0,
    "loop_crossfade_sec": 0.25,
    "max_dc_offset": 0.008,
    "max_loop_seam_delta": 0.12,
    "seed": 47101,
}

# D minor / Dorian frequencies (Hz)
NOTE_HZ: Dict[str, float] = {
    "D1": 36.708, "A1": 55.000, "D2": 73.416, "E2": 82.407, "F2": 87.307,
    "G2": 97.999, "A2": 110.000, "Bb2": 116.541, "C3": 130.813,
    "D3": 146.832, "E3": 164.814, "F3": 174.614, "G3": 195.998,
    "A3": 220.000, "Bb3": 233.082, "C4": 261.626, "D4": 293.665,
    "E4": 329.628, "F4": 349.228, "G4": 391.995, "A4": 440.000,
}


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def run_cmd(cmd: List[str]) -> Tuple[int, str, str]:
    proc = subprocess.run(cmd, capture_output=True, text=True, check=False)
    return proc.returncode, proc.stdout, proc.stderr


def _make_seamless_stereo(left: List[float], right: List[float], sr: int, xfade_sec: float) -> Tuple[List[float], List[float]]:
    n_xf = min(int(sr * xfade_sec), len(left) // 4)
    body_len = len(left) - n_xf
    out_l = left[:body_len]
    out_r = right[:body_len]
    for i in range(n_xf):
        t = float(i) / float(n_xf)
        fade_in = math.sin(t * math.pi * 0.5)
        fade_out = math.cos(t * math.pi * 0.5)
        out_l[i] = out_l[i] * fade_in + left[body_len + i] * fade_out
        out_r[i] = out_r[i] * fade_in + right[body_len + i] * fade_out
    return out_l, out_r


def _write_wav(path: Path, sr: int, channels: List[List[float]]) -> None:
    n_ch = len(channels)
    n_frames = len(channels[0])
    peak = 1e-6
    for ch in channels:
        m = max(abs(x) for x in ch)
        if m > peak:
            peak = m
    scale = 0.88 / peak
    pcm = array.array("h")
    for i in range(n_frames):
        for c in range(n_ch):
            v = max(-1.0, min(1.0, channels[c][i] * scale))
            pcm.append(int(round(v * 32767.0)))
    if sys.byteorder != "little":
        pcm.byteswap()
    with wave.open(str(path), "wb") as wf:
        wf.setnchannels(n_ch)
        wf.setsampwidth(2)
        wf.setframerate(sr)
        wf.writeframes(pcm.tobytes())


def synth_dark_ambient_loop(sr: int, duration_sec: float = 16.0) -> Tuple[List[float], List[float]]:
    xf = float(STYLE_LOCK["loop_crossfade_sec"])
    total_n = int((duration_sec + xf) * sr)
    rng = random.Random(int(STYLE_LOCK["seed"]) + 1)
    left = [0.0] * total_n
    right = [0.0] * total_n
    lp_l = 0.0
    lp_r = 0.0
    two_pi = 2.0 * math.pi
    f_sub = NOTE_HZ["D1"]
    f_root = NOTE_HZ["D2"]
    f_fifth = NOTE_HZ["A2"]
    f_min3 = NOTE_HZ["F3"]
    f_ninth = NOTE_HZ["E3"]

    for i in range(total_n):
        t = float(i) / float(sr)
        swell = 0.55 + 0.45 * math.sin(two_pi * t / 8.0)
        shimmer = 0.5 + 0.5 * math.sin(two_pi * t / 5.333 + 1.1)
        sub = 0.34 * math.sin(two_pi * f_sub * t)
        drone_l = 0.24 * math.sin(two_pi * f_root * t) + 0.14 * math.sin(two_pi * (f_fifth + 0.18) * t)
        drone_r = 0.24 * math.sin(two_pi * (f_root + 0.12) * t) + 0.14 * math.sin(two_pi * (f_fifth - 0.16) * t)
        pad_l = 0.11 * swell * math.sin(two_pi * f_min3 * t + 0.3 * math.sin(two_pi * 0.25 * t))
        pad_r = 0.11 * shimmer * math.sin(two_pi * f_ninth * t + 0.3 * math.cos(two_pi * 0.2 * t))

        # Filtered night-wind air texture
        wn_l = rng.uniform(-1.0, 1.0)
        wn_r = rng.uniform(-1.0, 1.0)
        alpha = 0.014 + 0.008 * swell
        lp_l += alpha * (wn_l - lp_l)
        lp_r += alpha * (wn_r - lp_r)
        wind_l = lp_l * (0.28 + 0.18 * shimmer)
        wind_r = lp_r * (0.28 + 0.18 * swell)

        left[i] = sub + drone_l + pad_l + wind_l
        right[i] = sub + drone_r + pad_r + wind_r

    return _make_seamless_stereo(left, right, sr, xf)


def synth_felt_piano_nocturne_loop(sr: int, duration_sec: float = 16.0) -> Tuple[List[float], List[float]]:
    xf = float(STYLE_LOCK["loop_crossfade_sec"])
    total_n = int((duration_sec + xf) * sr)
    left = [0.0] * total_n
    right = [0.0] * total_n
    two_pi = 2.0 * math.pi

    # Quiet D-minor felt-piano nocturne arpeggio (start_sec, note, vel, pan)
    events: List[Tuple[float, str, float, float]] = [
        (0.0, "D2", 0.55, -0.15), (0.05, "A3", 0.48, 0.20), (1.0, "F3", 0.42, -0.10),
        (2.0, "D3", 0.46, 0.05), (3.0, "E3", 0.40, 0.18),
        (4.0, "Bb2", 0.52, -0.20), (4.05, "F3", 0.45, 0.15), (5.0, "D4", 0.44, 0.22),
        (6.0, "A3", 0.38, -0.08), (7.0, "G3", 0.36, 0.12),
        (8.0, "G2", 0.50, -0.18), (8.05, "D3", 0.44, 0.10), (9.0, "Bb3", 0.42, 0.25),
        (10.0, "A3", 0.40, -0.12), (11.0, "F3", 0.38, 0.08),
        (12.0, "A2", 0.52, -0.15), (12.05, "E3", 0.44, 0.15), (13.0, "C4", 0.42, 0.20),
        (14.0, "A3", 0.40, -0.10), (15.0, "E3", 0.35, 0.05),
    ]

    # Subtle warm room bed underneath
    for i in range(total_n):
        t = float(i) / float(sr)
        bed = 0.07 * math.sin(two_pi * NOTE_HZ["D2"] * t) + 0.04 * math.sin(two_pi * NOTE_HZ["A2"] * t)
        left[i] = bed
        right[i] = bed

    # Felt piano voice: warm fundamental + damped 2nd/3rd harmonics + soft hammer attack
    for start_s, note_name, vel, pan in events:
        freq = NOTE_HZ[note_name]
        start_i = int(start_s * sr)
        note_len = int(3.4 * sr)
        gain_l = vel * (0.5 - 0.35 * pan)
        gain_r = vel * (0.5 + 0.35 * pan)
        for k in range(note_len):
            idx = start_i + k
            if idx >= total_n:
                break
            dt = float(k) / float(sr)
            att = min(1.0, dt / 0.018)
            env1 = att * math.exp(-dt * 1.35)
            env2 = att * math.exp(-dt * 3.10)
            env3 = att * math.exp(-dt * 5.80)
            sig = (
                0.76 * env1 * math.sin(two_pi * freq * dt)
                + 0.19 * env2 * math.sin(two_pi * freq * 2.001 * dt)
                + 0.05 * env3 * math.sin(two_pi * freq * 3.003 * dt)
            )
            left[idx] += sig * gain_l
            right[idx] += sig * gain_r

    # Simple soft feedback delay tail for nocturnal hall depth
    d1 = int(0.17 * sr)
    d2 = int(0.29 * sr)
    for i in range(d2, total_n):
        left[i] += 0.18 * right[i - d1] + 0.11 * left[i - d2]
        right[i] += 0.18 * left[i - d1] + 0.11 * right[i - d2]

    return _make_seamless_stereo(left, right, sr, xf)


def synth_tension_loop(sr: int, duration_sec: float = 12.0) -> Tuple[List[float], List[float]]:
    xf = float(STYLE_LOCK["loop_crossfade_sec"])
    total_n = int((duration_sec + xf) * sr)
    rng = random.Random(int(STYLE_LOCK["seed"]) + 3)
    left = [0.0] * total_n
    right = [0.0] * total_n
    two_pi = 2.0 * math.pi
    lp = 0.0

    for i in range(total_n):
        t = float(i) / float(sr)
        beat_phase = (t * 1.5) % 1.0  # 90 BPM low heartbeat pulse
        pulse = math.exp(-beat_phase * 8.5)
        sub_pulse = 0.42 * pulse * math.sin(two_pi * (46.0 + 18.0 * math.exp(-beat_phase * 18.0)) * t)
        # Tense minor-2nd metallic scrape undertone (D2 + Eb2)
        swell = 0.5 + 0.5 * math.sin(two_pi * t / 6.0)
        metal_l = 0.16 * swell * math.sin(two_pi * 146.83 * t + 1.4 * math.sin(two_pi * 155.56 * t))
        metal_r = 0.16 * (1.0 - 0.5 * swell) * math.sin(two_pi * 155.56 * t + 1.1 * math.sin(two_pi * 146.83 * t))
        wn = rng.uniform(-1.0, 1.0)
        lp += 0.03 * (wn - lp)
        grit = 0.15 * lp * pulse
        left[i] = sub_pulse + metal_l + grit
        right[i] = sub_pulse + metal_r - grit

    return _make_seamless_stereo(left, right, sr, xf)


def synth_ui_brass_click(sr: int, pitch_mul: float = 1.0, dur_s: float = 0.085) -> List[float]:
    n = int(sr * dur_s)
    rng = random.Random(int(STYLE_LOCK["seed"]) + int(pitch_mul * 100))
    out = [0.0] * n
    two_pi = 2.0 * math.pi
    for i in range(n):
        t = float(i) / float(sr)
        env = math.exp(-t * 55.0)
        transient = rng.uniform(-1.0, 1.0) * math.exp(-t * 240.0) * 0.45
        body = (
            0.55 * math.sin(two_pi * 920.0 * pitch_mul * t) * math.exp(-t * 68.0)
            + 0.30 * math.sin(two_pi * 2180.0 * pitch_mul * t) * math.exp(-t * 110.0)
            + 0.25 * math.sin(two_pi * 310.0 * pitch_mul * t) * env
        )
        out[i] = transient + body
    return out


def synth_drawer_latch(sr: int, opening: bool) -> List[float]:
    n = int(sr * 0.16)
    rng = random.Random(int(STYLE_LOCK["seed"]) + (17 if opening else 23))
    out = [0.0] * n
    two_pi = 2.0 * math.pi
    lp = 0.0
    for i in range(n):
        t = float(i) / float(sr)
        frac = t / 0.16
        f_sweep = (420.0 + 520.0 * frac) if opening else (860.0 - 460.0 * frac)
        env = math.sin(min(1.0, frac) * math.pi) * math.exp(-t * 11.0)
        wn = rng.uniform(-1.0, 1.0)
        lp += 0.18 * (wn - lp)
        out[i] = 0.55 * env * math.sin(two_pi * f_sweep * t) + 0.45 * lp * env
    return out


def synth_flashlight_toggle(sr: int) -> List[float]:
    n = int(sr * 0.11)
    rng = random.Random(int(STYLE_LOCK["seed"]) + 31)
    out = [0.0] * n
    two_pi = 2.0 * math.pi
    for i in range(n):
        t = float(i) / float(sr)
        c1 = math.exp(-t * 210.0) * (0.65 * rng.uniform(-1.0, 1.0) + 0.55 * math.sin(two_pi * 1650.0 * t))
        t2 = max(0.0, t - 0.022)
        c2 = (1.0 if t >= 0.022 else 0.0) * math.exp(-t2 * 130.0) * (
            0.45 * math.sin(two_pi * 2450.0 * t2) + 0.40 * math.sin(two_pi * 620.0 * t2)
        )
        out[i] = c1 + c2
    return out


def synth_footstep_wet_asphalt(sr: int, variant_idx: int) -> List[float]:
    n = int(sr * 0.21)
    rng = random.Random(int(STYLE_LOCK["seed"]) + 100 + variant_idx * 19)
    out = [0.0] * n
    two_pi = 2.0 * math.pi
    lp_thud = 0.0
    hp_prev = 0.0
    base_f = 95.0 + variant_idx * 11.0
    for i in range(n):
        t = float(i) / float(sr)
        thud = 0.65 * math.exp(-t * 36.0) * math.sin(two_pi * (base_f * math.exp(-t * 8.0)) * t)
        wn = rng.uniform(-1.0, 1.0)
        lp_thud += 0.12 * (wn - lp_thud)
        hp = wn - hp_prev
        hp_prev = wn
        grit = 0.45 * lp_thud * math.exp(-t * 24.0)
        t_splash = max(0.0, t - 0.014)
        splash = (1.0 if t >= 0.014 else 0.0) * 0.24 * hp * math.exp(-t_splash * 28.0)
        out[i] = thud + grit + splash
    return out


def encode_and_verify(
    raw_wav: Path,
    dst_ogg: Path,
    is_music: bool,
    is_loop: bool,
) -> Dict[str, Any]:
    dst_ogg.parent.mkdir(parents=True, exist_ok=True)
    tmp_ogg = dst_ogg.with_name(dst_ogg.stem + ".tmp.ogg")

    if is_music:
        c1, _, e1 = run_cmd([
            "ffmpeg", "-hide_banner", "-y", "-i", str(raw_wav),
            "-af", "highpass=f=20,loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json",
            "-f", "null", "-",
        ])
        m_json = re.search(r"\{[^{}]*\"input_i\"[^{}]*\}", e1, re.DOTALL)
        if c1 == 0 and m_json:
            st = json.loads(m_json.group(0))
            af = (
                f"highpass=f=20,loudnorm=I=-16:TP=-1.5:LRA=11:linear=true:"
                f"measured_I={st['input_i']}:measured_TP={st['input_tp']}:"
                f"measured_LRA={st['input_lra']}:measured_thresh={st['input_thresh']}:"
                f"offset={st['target_offset']},alimiter=limit=-1.2dB:attack=5:release=50"
            )
        else:
            af = "highpass=f=20,loudnorm=I=-16:TP=-1.5:LRA=11,alimiter=limit=-1.2dB"
        cmd = [
            "ffmpeg", "-hide_banner", "-y", "-i", str(raw_wav),
            "-af", af, "-ac", "2", "-ar", str(STYLE_LOCK["sample_rate"]),
            "-c:a", "libvorbis", "-b:a", str(STYLE_LOCK["music_bitrate"]),
            str(tmp_ogg),
        ]
    else:
        cmd = [
            "ffmpeg", "-hide_banner", "-y", "-i", str(raw_wav),
            "-af", "highpass=f=25,volume=-3.5dB,alimiter=limit=-1.5dB:attack=2:release=30",
            "-ac", "1", "-ar", str(STYLE_LOCK["sample_rate"]),
            "-c:a", "libvorbis", "-b:a", str(STYLE_LOCK["sfx_bitrate"]),
            str(tmp_ogg),
        ]

    code, _, err = run_cmd(cmd)
    if code != 0 or not tmp_ogg.is_file():
        return {"file": str(dst_ogg), "pass": False, "errors": [f"ffmpeg_encode_failed:{err[-200:]}"]}

    os.replace(tmp_ogg, dst_ogg)

    # Verify loudness, peak, DC offset, loop seam
    c_m, _, e_m = run_cmd([
        "ffmpeg", "-hide_banner", "-nostats", "-i", str(dst_ogg),
        "-af", "ebur128=peak=true", "-f", "null", "-",
    ])
    lufs_m = re.findall(r"I:\s*(-?\d+(?:\.\d+)?)\s*LUFS", e_m)
    tp_m = re.findall(r"Peak:\s*(-?\d+(?:\.\d+)?)\s*dBFS", e_m)
    lufs = float(lufs_m[-1]) if lufs_m else -99.0
    tp = float(tp_m[-1]) if tp_m else -99.0

    pcm_proc = subprocess.run(
        ["ffmpeg", "-hide_banner", "-v", "error", "-i", str(dst_ogg), "-ac", "1", "-ar", "48000", "-f", "f32le", "-"],
        capture_output=True,
        check=False,
    )
    samples = array.array("f")
    samples.frombytes(pcm_proc.stdout[: len(pcm_proc.stdout) - (len(pcm_proc.stdout) % 4)])
    if sys.byteorder != "little":
        samples.byteswap()
    dc = abs(sum(samples) / float(max(1, len(samples))))
    peak_lin = max(abs(x) for x in samples) if samples else 0.0
    sp_dbfs = 20.0 * math.log10(peak_lin) if peak_lin > 1e-9 else -120.0
    seam = abs(samples[0] - samples[-1]) if samples else 1.0

    errors: List[str] = []
    if c_m != 0:
        errors.append("ebur128_failed")
    if dc > float(STYLE_LOCK["max_dc_offset"]):
        errors.append(f"dc_high:{dc:.5f}")
    if tp > float(STYLE_LOCK["true_peak_max_dbtp"]):
        errors.append(f"tp_over:{tp:.2f}dBTP")
    if is_music and abs(lufs - float(STYLE_LOCK["music_target_lufs"])) > float(STYLE_LOCK["music_lufs_tol"]):
        errors.append(f"lufs_drift:{lufs:.2f}")
    if is_loop and seam > float(STYLE_LOCK["max_loop_seam_delta"]):
        errors.append(f"loop_seam_click:{seam:.4f}")

    return {
        "file": dst_ogg.name,
        "type": "music" if is_music else "sfx",
        "size_kb": round(dst_ogg.stat().st_size / 1024.0, 1),
        "lufs": round(lufs, 2),
        "true_peak_dbtp": round(tp, 2),
        "sample_peak_dbfs": round(sp_dbfs, 2),
        "dc_offset": round(dc, 6),
        "seam_delta": round(seam, 4),
        "sha256": sha256_file(dst_ogg),
        "pass": len(errors) == 0,
        "errors": errors,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate locked survival-horror OGG audio pack")
    parser.add_argument("--repo", required=True, help="Godot project root")
    parser.add_argument("--out-subdir", default="assets/audio/overhaul", help="Target subdir inside repo")
    args = parser.parse_args()

    if shutil.which("ffmpeg") is None:
        print(json.dumps({"error": "ffmpeg not found in PATH"}))
        return 3

    repo = Path(args.repo).resolve()
    out_dir = repo / args.out_subdir
    out_dir.mkdir(parents=True, exist_ok=True)
    sr = int(STYLE_LOCK["sample_rate"])

    results: List[Dict[str, Any]] = []
    with tempfile.TemporaryDirectory() as tmp_s:
        tmp = Path(tmp_s)
        music_specs = [
            ("music_city_ambient_loop.ogg", synth_dark_ambient_loop(sr, 16.0)),
            ("music_felt_piano_nocturne_loop.ogg", synth_felt_piano_nocturne_loop(sr, 16.0)),
            ("music_stealth_tension_loop.ogg", synth_tension_loop(sr, 12.0)),
        ]
        for fname, (ch_l, ch_r) in music_specs:
            wav_p = tmp / (fname + ".wav")
            _write_wav(wav_p, sr, [ch_l, ch_r])
            results.append(encode_and_verify(wav_p, out_dir / fname, is_music=True, is_loop=True))

        sfx_specs = [
            ("sfx_ui_brass_click.ogg", synth_ui_brass_click(sr, 1.0)),
            ("sfx_interact_confirm.ogg", synth_ui_brass_click(sr, 0.78, 0.11)),
            ("sfx_ui_drawer_open.ogg", synth_drawer_latch(sr, True)),
            ("sfx_ui_drawer_close.ogg", synth_drawer_latch(sr, False)),
            ("sfx_flashlight_toggle.ogg", synth_flashlight_toggle(sr)),
            ("sfx_footstep_asphalt_01.ogg", synth_footstep_wet_asphalt(sr, 0)),
            ("sfx_footstep_asphalt_02.ogg", synth_footstep_wet_asphalt(sr, 1)),
            ("sfx_footstep_asphalt_03.ogg", synth_footstep_wet_asphalt(sr, 2)),
        ]
        for fname, mono in sfx_specs:
            wav_p = tmp / (fname + ".wav")
            _write_wav(wav_p, sr, [mono])
            results.append(encode_and_verify(wav_p, out_dir / fname, is_music=False, is_loop=False))

    gate_pass = all(r["pass"] for r in results)
    manifest = {
        "style_lock": STYLE_LOCK,
        "out_dir": str(out_dir.relative_to(repo)).replace("\\", "/"),
        "gate_pass": gate_pass,
        "total_size_kb": round(sum(r.get("size_kb", 0.0) for r in results), 1),
        "tracks": results,
    }
    m_path = repo / "AUDIO_PACK_MANIFEST.json"
    m_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({
        "manifest": str(m_path),
        "manifest_sha256": sha256_file(m_path),
        "gate_pass": gate_pass,
        "tracks_count": len(results),
        "total_size_kb": manifest["total_size_kb"],
    }, indent=2))
    return 0 if gate_pass else 1


if __name__ == "__main__":
    sys.exit(main())
