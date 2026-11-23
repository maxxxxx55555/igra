#!/usr/bin/env python3
"""Deterministic mobile texture & audio optimizer + auto reference updater (Samsung A32 / Mali-G52)."""

from __future__ import annotations

import argparse
import array
import hashlib
import json
import math
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, List, Tuple

STYLE_LOCK: Dict[str, Any] = {
    "target_device": "Samsung Galaxy A32 (4GB RAM, Mali-G52 MC2)",
    "max_prop_tex_px": 512,
    "max_ui_or_trim_tex_px": 1024,
    "music_sample_rate": 48000,
    "music_bitrate": "96k",
    "music_target_lufs": -16.0,
    "music_lufs_tolerance": 1.8,
    "music_true_peak_max_dbtp": -1.0,
    "sfx_sample_rate": 48000,
    "sfx_bitrate": "64k",
    "sfx_target_peak_dbfs": -3.5,
    "sfx_peak_min_dbfs": -7.5,
    "sfx_peak_max_dbfs": -1.0,
    "max_dc_offset": 0.008,
    "max_loop_seam_delta": 0.15,
    "music_duration_threshold_sec": 15.0,
}

EXCLUDE_DIRS = {
    ".git", ".godot", ".import", "_backup_raw_media",
    "_chat_upload_batches", "builds", "build", "export", "addons",
}
UI_OR_TRIM_RE = re.compile(r"(?i)(^|/)(ui|hud|icons?|menus?|fonts?|atlas|trim|sky|env|terrain|splash|title|banner)")
MUSIC_NAME_RE = re.compile(r"(?i)(music|bgm|ost|theme|ambient|ambience|nocturne|loop|tension)")
REF_EXTS = {".tscn", ".tres", ".gd", ".cfg", ".json", ".godot"}


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def ensure_backup(repo: Path, src: Path) -> Path:
    backup_root = repo / "_backup_raw_media"
    backup_root.mkdir(parents=True, exist_ok=True)
    gdignore = backup_root / ".gdignore"
    if not gdignore.exists():
        gdignore.write_text("", encoding="utf-8")
    rel = src.relative_to(repo)
    dst = backup_root / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    if not dst.exists():
        shutil.copy2(src, dst)
    return dst


def run_cmd(cmd: List[str]) -> Tuple[int, str, str]:
    proc = subprocess.run(cmd, capture_output=True, text=True, check=False)
    return proc.returncode, proc.stdout, proc.stderr


def probe_audio_duration(path: Path) -> float:
    code, out, _ = run_cmd([
        "ffprobe", "-v", "error",
        "-show_entries", "format=duration",
        "-of", "default=noprint_wrappers=1:nokey=1",
        str(path),
    ])
    if code != 0:
        return 0.0
    try:
        val = float(out.strip())
        return val if math.isfinite(val) and val > 0.0 else 0.0
    except ValueError:
        return 0.0


def measure_audio_metrics(path: Path) -> Dict[str, Any]:
    code, _, err = run_cmd([
        "ffmpeg", "-hide_banner", "-nostats", "-i", str(path),
        "-af", "ebur128=peak=true", "-f", "null", "-",
    ])
    if code != 0:
        return {"ok": False, "error": f"ebur128_failed: {err[-260:]}"}

    lufs_matches = re.findall(r"I:\s*(-?\d+(?:\.\d+)?)\s*LUFS", err)
    tp_matches = re.findall(r"Peak:\s*(-?\d+(?:\.\d+)?)\s*dBFS", err)
    lufs = float(lufs_matches[-1]) if lufs_matches else -99.0
    true_peak = float(tp_matches[-1]) if tp_matches else -99.0

    pcm_proc = subprocess.run(
        ["ffmpeg", "-hide_banner", "-v", "error", "-i", str(path), "-ac", "1", "-ar", "48000", "-f", "f32le", "-"],
        capture_output=True,
        check=False,
    )
    if pcm_proc.returncode != 0 or len(pcm_proc.stdout) < 16:
        return {"ok": False, "error": "pcm_decode_failed"}

    samples = array.array("f")
    samples.frombytes(pcm_proc.stdout[: len(pcm_proc.stdout) - (len(pcm_proc.stdout) % 4)])
    if sys.byteorder != "little":
        samples.byteswap()
    n = len(samples)
    if n == 0:
        return {"ok": False, "error": "empty_audio"}

    dc_offset = abs(sum(samples) / float(n))
    peak_lin = max(abs(x) for x in samples)
    sample_peak_dbfs = 20.0 * math.log10(peak_lin) if peak_lin > 1e-9 else -120.0
    seam_delta = abs(samples[0] - samples[-1])

    return {
        "ok": True,
        "lufs": round(lufs, 2),
        "true_peak_dbtp": round(true_peak, 2),
        "sample_peak_dbfs": round(sample_peak_dbfs, 2),
        "dc_offset": round(dc_offset, 6),
        "seam_delta": round(seam_delta, 4),
    }


def rewrite_res_references(repo: Path, rename_map: Dict[str, str]) -> int:
    if not rename_map:
        return 0
    files_updated = 0
    for p in sorted(repo.rglob("*")):
        if not p.is_file() or p.suffix.lower() not in REF_EXTS:
            continue
        if any(part in EXCLUDE_DIRS for part in p.parts):
            continue
        text = p.read_text(encoding="utf-8", errors="replace")
        new_text = text
        for old_rel, new_rel in rename_map.items():
            new_text = new_text.replace(f"res://{old_rel}", f"res://{new_rel}")
        if new_text != text:
            tmp = p.with_name(p.name + ".tmp")
            tmp.write_text(new_text, encoding="utf-8", newline="\n")
            os.replace(tmp, p)
            files_updated += 1
    return files_updated


def optimize_audio_file(
    repo: Path,
    src: Path,
    apply_changes: bool,
    rename_map: Dict[str, str],
) -> Dict[str, Any]:
    rel = str(src.relative_to(repo)).replace("\\", "/")
    dur = probe_audio_duration(src)
    is_music = bool(MUSIC_NAME_RE.search(rel)) or dur >= float(STYLE_LOCK["music_duration_threshold_sec"])
    target_ogg = src.with_suffix(".ogg")
    before_bytes = src.stat().st_size

    if apply_changes:
        ensure_backup(repo, src)
        tmp_ogg = target_ogg.with_name(target_ogg.stem + ".tmp.ogg")
        if is_music:
            c1, _, e1 = run_cmd([
                "ffmpeg", "-hide_banner", "-y", "-i", str(src),
                "-af", "highpass=f=20,loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json",
                "-f", "null", "-",
            ])
            m_json = re.search(r"\{[^{}]*\"input_i\"[^{}]*\}", e1, re.DOTALL)
            if c1 == 0 and m_json:
                stats = json.loads(m_json.group(0))
                if stats.get("input_i") not in {None, "-inf", "inf"}:
                    af = (
                        f"highpass=f=20,"
                        f"loudnorm=I=-16:TP=-1.5:LRA=11:linear=true:"
                        f"measured_I={stats['input_i']}:measured_TP={stats['input_tp']}:"
                        f"measured_LRA={stats['input_lra']}:measured_thresh={stats['input_thresh']}:"
                        f"offset={stats['target_offset']},"
                        f"alimiter=limit=-1.2dB:attack=5:release=50"
                    )
                else:
                    af = "highpass=f=20,alimiter=limit=-1.2dB:attack=5:release=50"
            else:
                af = "highpass=f=20,loudnorm=I=-16:TP=-1.5:LRA=11,alimiter=limit=-1.2dB"

            c2, _, e2 = run_cmd([
                "ffmpeg", "-hide_banner", "-y", "-i", str(src),
                "-af", af,
                "-ac", "2", "-ar", str(STYLE_LOCK["music_sample_rate"]),
                "-c:a", "libvorbis", "-b:a", str(STYLE_LOCK["music_bitrate"]),
                str(tmp_ogg),
            ])
        else:
            metrics_in = measure_audio_metrics(src)
            cur_peak = float(metrics_in.get("sample_peak_dbfs", -3.5)) if metrics_in.get("ok") else -3.5
            gain_db = max(-24.0, min(18.0, float(STYLE_LOCK["sfx_target_peak_dbfs"]) - cur_peak))
            af = f"highpass=f=25,volume={gain_db:.2f}dB,alimiter=limit=-1.5dB:attack=2:release=30"
            c2, _, e2 = run_cmd([
                "ffmpeg", "-hide_banner", "-y", "-i", str(src),
                "-af", af,
                "-ac", "1", "-ar", str(STYLE_LOCK["sfx_sample_rate"]),
                "-c:a", "libvorbis", "-b:a", str(STYLE_LOCK["sfx_bitrate"]),
                str(tmp_ogg),
            ])

        if c2 != 0 or not tmp_ogg.is_file():
            if tmp_ogg.exists():
                tmp_ogg.unlink()
            return {"file": rel, "type": "music" if is_music else "sfx", "pass": False, "error": e2[-300:]}

        os.replace(tmp_ogg, target_ogg)
        if src != target_ogg:
            new_rel = str(target_ogg.relative_to(repo)).replace("\\", "/")
            rename_map[rel] = new_rel
            if src.exists():
                src.unlink()
                imp = Path(str(src) + ".import")
                if imp.exists():
                    imp.unlink()

    check_path = target_ogg if target_ogg.is_file() else src
    metrics = measure_audio_metrics(check_path)
    gate_errors: List[str] = []

    if not metrics.get("ok"):
        gate_errors.append(str(metrics.get("error", "decode_error")))
    else:
        if check_path.suffix.lower() != ".ogg":
            gate_errors.append(f"non_ogg_format:{check_path.suffix.lower()}")
        if float(metrics["dc_offset"]) > float(STYLE_LOCK["max_dc_offset"]):
            gate_errors.append(f"dc_offset_high:{metrics['dc_offset']}")
        if float(metrics["true_peak_dbtp"]) > float(STYLE_LOCK["music_true_peak_max_dbtp"]):
            gate_errors.append(f"true_peak_over_limit:{metrics['true_peak_dbtp']}dBTP")
        if is_music:
            target_lufs = float(STYLE_LOCK["music_target_lufs"])
            tol = float(STYLE_LOCK["music_lufs_tolerance"])
            if abs(float(metrics["lufs"]) - target_lufs) > tol:
                gate_errors.append(f"lufs_out_of_range:{metrics['lufs']}")
            if "loop" in rel.lower() and float(metrics["seam_delta"]) > float(STYLE_LOCK["max_loop_seam_delta"]):
                gate_errors.append(f"loop_seam_click:{metrics['seam_delta']}")
        else:
            sp = float(metrics["sample_peak_dbfs"])
            if sp > float(STYLE_LOCK["sfx_peak_max_dbfs"]) or sp < float(STYLE_LOCK["sfx_peak_min_dbfs"]):
                gate_errors.append(f"sfx_peak_out_of_range:{sp}dBFS")

    return {
        "file": str(check_path.relative_to(repo)).replace("\\", "/"),
        "type": "music" if is_music else "sfx",
        "before_kb": round(before_bytes / 1024.0, 1),
        "after_kb": round(check_path.stat().st_size / 1024.0, 1),
        "metrics": metrics,
        "sha256": sha256_file(check_path),
        "pass": len(gate_errors) == 0,
        "errors": gate_errors,
    }


def optimize_texture_file(repo: Path, src: Path, apply_changes: bool) -> Dict[str, Any]:
    from PIL import Image  # type: ignore[import-not-found]

    rel = str(src.relative_to(repo)).replace("\\", "/")
    max_edge = int(STYLE_LOCK["max_ui_or_trim_tex_px"] if UI_OR_TRIM_RE.search(rel) else STYLE_LOCK["max_prop_tex_px"])
    before_bytes = src.stat().st_size

    with Image.open(src) as img:
        w, h = img.size
        mode = img.mode
        needs_resize = (w > max_edge or h > max_edge)

        if apply_changes and needs_resize:
            ensure_backup(repo, src)
            scale = min(max_edge / float(w), max_edge / float(h))
            nw = max(4, int(round(w * scale)))
            nh = max(4, int(round(h * scale)))

            if mode == "RGBA":
                resized = img.convert("RGBa").resize((nw, nh), Image.Resampling.LANCZOS).convert("RGBA")
            elif mode == "P":
                resized = img.convert("RGBA").convert("RGBa").resize((nw, nh), Image.Resampling.LANCZOS).convert("RGBA")
            else:
                resized = img.resize((nw, nh), Image.Resampling.LANCZOS)

            tmp = src.with_name(src.stem + ".tmp" + src.suffix)
            save_kwargs: Dict[str, Any] = {"optimize": True}
            if src.suffix.lower() in {".jpg", ".jpeg"}:
                save_kwargs["quality"] = 85
            resized.save(tmp, **save_kwargs)
            os.replace(tmp, src)
            w, h = nw, nh

    import_file = Path(str(src) + ".import")
    if apply_changes and import_file.is_file() and not UI_OR_TRIM_RE.search(rel):
        imp_txt = import_file.read_text(encoding="utf-8", errors="replace")
        imp_txt = re.sub(r"^compress/mode=\d+", "compress/mode=2", imp_txt, flags=re.MULTILINE)
        imp_txt = re.sub(r"^mipmaps/generate=(true|false)", "mipmaps/generate=true", imp_txt, flags=re.MULTILINE)
        import_file.write_text(imp_txt, encoding="utf-8", newline="\n")

    passed = (w <= max_edge and h <= max_edge)
    return {
        "file": rel,
        "dimensions": f"{w}x{h}",
        "max_edge": max_edge,
        "before_kb": round(before_bytes / 1024.0, 1),
        "after_kb": round(src.stat().st_size / 1024.0, 1),
        "sha256": sha256_file(src),
        "pass": passed,
        "errors": [] if passed else [f"exceeds_max_edge:{w}x{h}>{max_edge}"],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Deterministic mobile texture & audio optimizer")
    parser.add_argument("--repo", required=True, help="Path to Godot project root")
    parser.add_argument("--apply", action="store_true", help="Apply optimization in-place (backs up raw media)")
    parser.add_argument("--verify-only", action="store_true", help="Verify budgets without modifying files")
    args = parser.parse_args()

    repo = Path(args.repo).resolve()
    if not repo.is_dir():
        print(json.dumps({"error": f"Repo not found: {repo}"}))
        return 2

    apply_changes = bool(args.apply and not args.verify_only)

    audio_files: List[Path] = []
    tex_files: List[Path] = []
    for p in sorted(repo.rglob("*")):
        if not p.is_file() or any(part in EXCLUDE_DIRS for part in p.parts):
            continue
        ext = p.suffix.lower()
        if ext in {".wav", ".mp3", ".flac", ".ogg"}:
            audio_files.append(p)
        elif ext in {".png", ".jpg", ".jpeg", ".webp"}:
            tex_files.append(p)

    if audio_files and shutil.which("ffmpeg") is None:
        print(json.dumps({"error": "ffmpeg not found in PATH"}))
        return 3
    if tex_files:
        try:
            import PIL  # noqa: F401
        except ImportError:
            print(json.dumps({"error": "Pillow not installed; run: pip install Pillow"}))
            return 4

    rename_map: Dict[str, str] = {}
    audio_results = [optimize_audio_file(repo, p, apply_changes, rename_map) for p in audio_files]
    refs_updated = rewrite_res_references(repo, rename_map) if apply_changes else 0
    tex_results = [optimize_texture_file(repo, p, apply_changes) for p in tex_files]

    failed_audio = [r for r in audio_results if not r["pass"]]
    failed_tex = [r for r in tex_results if not r["pass"]]
    gate_pass = (len(failed_audio) == 0 and len(failed_tex) == 0)

    manifest = {
        "style_lock": STYLE_LOCK,
        "mode": "APPLY" if apply_changes else "VERIFY_ONLY",
        "gate_pass": gate_pass,
        "summary": {
            "audio_total": len(audio_results),
            "audio_failed": len(failed_audio),
            "audio_refs_updated_files": refs_updated,
            "textures_total": len(tex_results),
            "textures_failed": len(failed_tex),
            "total_media_mb": round(
                (sum(r["after_kb"] for r in audio_results) + sum(r["after_kb"] for r in tex_results)) / 1024.0,
                2,
            ),
        },
        "audio": audio_results,
        "textures": tex_results,
    }

    out_path = repo / "MEDIA_OPTIMIZATION_MANIFEST.json"
    out_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({
        "manifest": str(out_path),
        "manifest_sha256": sha256_file(out_path),
        "gate_pass": gate_pass,
        "summary": manifest["summary"],
    }, indent=2))
    return 0 if gate_pass else 1


if __name__ == "__main__":
    sys.exit(main())
