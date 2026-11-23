#!/usr/bin/env python3
"""Deterministic Samsung A32 (4GB/Mali-G52/20:9) config patcher + collision/UI/WiFi/asset auditor (V2)."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import struct
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

STYLE_LOCK: Dict[str, Any] = {
    "target_device": "Samsung Galaxy A32 (4GB RAM, Mali-G52 MC2, 1080x2400 20:9)",
    "max_texture_px": 1024,
    "max_wav_bytes": 256 * 1024,
    "max_image_bytes": 1024 * 1024,
    "min_character_safe_margin": 0.04,
    "project_godot_patches": {
        "display": {
            "window/stretch/mode": '"canvas_items"',
            "window/stretch/aspect": '"expand"',
            "window/stretch/scale_mode": '"fractional"',
        },
        "physics": {
            "common/physics_ticks_per_second": "60",
            "common/max_physics_steps_per_frame": "4",
        },
        "rendering": {
            "renderer/rendering_method": '"gl_compatibility"',
            "renderer/rendering_method.mobile": '"gl_compatibility"',
            "textures/vram_compression/import_etc2_astc": "true",
            "anti_aliasing/quality/msaa_3d": "0",
            "anti_aliasing/quality/screen_space_aa": "0",
            "lights_and_shadows/directional_shadow/size": "1024",
            "lights_and_shadows/directional_shadow/size.mobile": "1024",
            "lights_and_shadows/positional_shadow/atlas_size": "1024",
            "lights_and_shadows/positional_shadow/atlas_size.mobile": "1024",
            "environment/glow/upscale_mode": "0",
        },
    },
}

EXCLUDE_DIRS = {
    ".git", ".godot", ".import", "_backup_raw_media",
    "_chat_upload_batches", "builds", "build", "export", "addons",
}
DECORATIVE_MESH_RE = re.compile(
    r"(?i)(sky|fog|cloud|dust|rain|puddle|decal|light|glow|halo|beam|cone|flare|particle|grass|leaf|wire|cable|shadow|vignette|marker|indicator)"
)
UI_SCENE_RE = re.compile(r"(?i)(menu|ui|hud|title|load|pause|setting|map|splash|end|gameover|dialog|inventory)")
WIFI_PATTERN_RE = re.compile(r"(?i)(бонус\s+за\s+wi-?fi|wifi_bonus|wifibonus|не\s+удалось\s+проверить\s+подключение|check_wifi|verify_connection)")


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def read_png_dimensions(path: Path) -> Optional[Tuple[int, int]]:
    try:
        with path.open("rb") as f:
            header = f.read(24)
        if len(header) == 24 and header[:8] == b"\x89PNG\r\n\x1a\n" and header[12:16] == b"IHDR":
            w, h = struct.unpack(">II", header[16:24])
            return int(w), int(h)
    except OSError:
        return None
    return None


def _parse_ini_sections(lines: List[str]) -> Tuple[List[Optional[str]], Dict[Optional[str], List[str]]]:
    sections: List[Tuple[Optional[str], List[str]]] = []
    current_sec: Optional[str] = None
    current_lines: List[str] = []
    sec_re = re.compile(r"^\[([^\]]+)\]\s*$")
    for line in lines:
        m = sec_re.match(line)
        if m:
            sections.append((current_sec, current_lines))
            current_sec = m.group(1)
            current_lines = [line]
        else:
            current_lines.append(line)
    sections.append((current_sec, current_lines))
    order: List[Optional[str]] = []
    sec_map: Dict[Optional[str], List[str]] = {}
    for name, slines in sections:
        if name not in sec_map:
            order.append(name)
            sec_map[name] = list(slines)
        else:
            sec_map[name].extend(slines[1:])
    return order, sec_map


def _get_ini_value(sec_lines: List[str], key: str) -> Optional[str]:
    key_re = re.compile(rf"^{re.escape(key)}\s*=\s*(.*)$")
    for ln in sec_lines:
        m = key_re.match(ln)
        if m:
            return m.group(1).strip()
    return None


def _set_ini_value(sec_lines: List[str], key: str, desired: str) -> Optional[str]:
    key_re = re.compile(rf"^{re.escape(key)}\s*=\s*(.*)$")
    for idx, ln in enumerate(sec_lines):
        m = key_re.match(ln)
        if m:
            old = m.group(1).strip()
            if old != desired:
                sec_lines[idx] = f"{key}={desired}"
                return f"{key}: {old} -> {desired}"
            return None
    sec_lines.append(f"{key}={desired}")
    return f"{key}: <missing> -> {desired}"


def patch_project_godot(project_file: Path, apply_changes: bool) -> Dict[str, Any]:
    if not project_file.is_file():
        return {"status": "FAIL", "error": f"Missing {project_file}"}

    order, sec_map = _parse_ini_sections(project_file.read_text(encoding="utf-8").splitlines())
    display_lines = sec_map.get("display", [])
    cur_orient = _get_ini_value(display_lines, "window/handheld/orientation")
    cur_w = _get_ini_value(display_lines, "window/size/viewport_width")
    cur_h = _get_ini_value(display_lines, "window/size/viewport_height")
    is_portrait = cur_orient in {"1", '"portrait"', '"sensor_portrait"', "5"} or (
        bool(cur_w and cur_h and cur_w.isdigit() and cur_h.isdigit() and int(cur_h) > int(cur_w))
    )

    patches: Dict[str, Dict[str, str]] = {sec: dict(kv) for sec, kv in STYLE_LOCK["project_godot_patches"].items()}
    if is_portrait:
        patches["display"]["window/size/viewport_width"] = "720"
        patches["display"]["window/size/viewport_height"] = "1280"
        patches["display"]["window/handheld/orientation"] = "1"
    else:
        patches["display"]["window/size/viewport_width"] = "1280"
        patches["display"]["window/size/viewport_height"] = "720"
        patches["display"]["window/handheld/orientation"] = "4"

    changes: List[str] = []
    for sec_name, kv in patches.items():
        if sec_name not in sec_map:
            order.append(sec_name)
            sec_map[sec_name] = ["", f"[{sec_name}]"]
        for key, desired in kv.items():
            diff = _set_ini_value(sec_map[sec_name], key, desired)
            if diff:
                changes.append(f"[{sec_name}] {diff}")

    if apply_changes and changes:
        bak = project_file.with_suffix(".godot.bak")
        if not bak.exists():
            shutil.copy2(project_file, bak)
        new_lines: List[str] = []
        for name in order:
            new_lines.extend(sec_map[name])
        tmp = project_file.with_suffix(".godot.tmp")
        tmp.write_text("\n".join(new_lines) + "\n", encoding="utf-8", newline="\n")
        os.replace(tmp, project_file)

    return {
        "status": "PATCHED" if (apply_changes and changes) else ("CLEAN" if not changes else "NEEDS_PATCH"),
        "orientation": "portrait" if is_portrait else "landscape",
        "changes_count": len(changes),
        "changes": changes,
        "sha256": sha256_file(project_file),
    }


def patch_export_presets(export_file: Path, apply_changes: bool) -> Dict[str, Any]:
    if not export_file.is_file():
        return {"status": "SKIPPED", "changes_count": 0, "changes": []}

    order, sec_map = _parse_ini_sections(export_file.read_text(encoding="utf-8", errors="replace").splitlines())
    android_secs: List[str] = []
    for sec in order:
        if sec and re.match(r"^preset\.\d+$", sec):
            plat = _get_ini_value(sec_map[sec], "platform")
            if plat and "android" in plat.lower() and f"{sec}.options" in sec_map:
                android_secs.append(f"{sec}.options")

    changes: List[str] = []
    desired = {
        "architectures/armeabi-v7a": "false",
        "architectures/arm64-v8a": "true",
        "architectures/x86": "false",
        "architectures/x86_64": "false",
        "screen/immersive_mode": "true",
        "screen/edge_to_edge": "true",
    }
    for opt_sec in android_secs:
        for k, v in desired.items():
            diff = _set_ini_value(sec_map[opt_sec], k, v)
            if diff:
                changes.append(f"[{opt_sec}] {diff}")

    if apply_changes and changes:
        bak = export_file.with_suffix(".cfg.bak")
        if not bak.exists():
            shutil.copy2(export_file, bak)
        new_lines: List[str] = []
        for name in order:
            new_lines.extend(sec_map[name])
        tmp = export_file.with_suffix(".cfg.tmp")
        tmp.write_text("\n".join(new_lines) + "\n", encoding="utf-8", newline="\n")
        os.replace(tmp, export_file)

    return {
        "status": "PATCHED" if (apply_changes and changes) else ("CLEAN" if not changes else "NEEDS_PATCH"),
        "changes_count": len(changes),
        "changes": changes,
        "sha256": sha256_file(export_file),
    }


def audit_wifi_bonus_leftovers(repo: Path) -> Dict[str, Any]:
    hits: List[Dict[str, Any]] = []
    for path in sorted(repo.rglob("*")):
        if not path.is_file() or path.suffix.lower() not in {".gd", ".tscn", ".tres", ".csv", ".json"}:
            continue
        if any(part in EXCLUDE_DIRS for part in path.parts) or "tools" in path.parts or path.name.startswith(("OVERHAUL_", "MOBILE_AUDIT_", "RELEASE_GATE_")):
            continue
        rel = str(path.relative_to(repo)).replace("\\", "/")
        for lineno, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), start=1):
            if WIFI_PATTERN_RE.search(line):
                hits.append({"location": f"{rel}:{lineno}", "snippet": line.strip()[:120]})
    return {"wifi_hits_count": len(hits), "wifi_hits": hits}


def audit_tscn_collisions_and_ui(repo: Path) -> Dict[str, Any]:
    collision_findings: List[Dict[str, Any]] = []
    ui_findings: List[Dict[str, Any]] = []
    node_re = re.compile(r'^\[node\s+name="([^"]+)"(?:\s+type="([^"]+)")?(?:\s+parent="([^"]*)")?')
    prop_re = re.compile(r"^([a-zA-Z0-9_/]+)\s*=\s*(.+)$")

    for path in sorted(repo.rglob("*.tscn")):
        if any(part in EXCLUDE_DIRS for part in path.parts):
            continue
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        nodes: List[Dict[str, str]] = []
        subresources: Dict[str, Dict[str, str]] = {}
        current_node: Optional[Dict[str, str]] = None
        current_sub: Optional[str] = None

        for lineno, line in enumerate(lines, start=1):
            if line.startswith("[sub_resource "):
                current_node = None
                m_sub = re.search(r'type="([^"]+)"\s+id="([^"]+)"', line)
                if m_sub:
                    current_sub = m_sub.group(2)
                    subresources[current_sub] = {"type": m_sub.group(1), "line": str(lineno)}
                continue
            m_node = node_re.match(line)
            if m_node:
                current_sub = None
                current_node = {
                    "name": m_node.group(1),
                    "type": m_node.group(2) or "Instance",
                    "parent": m_node.group(3) if m_node.group(3) is not None else "__ROOT__",
                    "line": str(lineno),
                }
                nodes.append(current_node)
                continue
            m_prop = prop_re.match(line)
            if m_prop:
                if current_node is not None:
                    current_node[m_prop.group(1)] = m_prop.group(2).strip()
                elif current_sub is not None:
                    subresources[current_sub][m_prop.group(1)] = m_prop.group(2).strip()

        rel = str(path.relative_to(repo)).replace("\\", "/")
        collider_owners = set()
        for n in nodes:
            if n["type"] in {"StaticBody3D", "RigidBody3D", "AnimatableBody3D", "CollisionShape3D", "CSGBox3D", "CSGMesh3D", "CSGCombiner3D"}:
                if n["parent"] != "__ROOT__":
                    collider_owners.add(n["parent"])
                own_path = n["name"] if n["parent"] in {".", "__ROOT__"} else f"{n['parent']}/{n['name']}"
                collider_owners.add(own_path)

        for n in nodes:
            ntype = n["type"]
            if ntype == "MeshInstance3D" and not DECORATIVE_MESH_RE.search(n["name"]):
                node_path = n["name"] if n["parent"] in {".", "__ROOT__"} else f"{n['parent']}/{n['name']}"
                if node_path not in collider_owners and n["parent"] not in collider_owners:
                    collision_findings.append({
                        "severity": "HIGH",
                        "rule": "MESH_WITHOUT_COLLIDER",
                        "location": f"{rel}:{n['line']}",
                        "detail": f"MeshInstance3D '{n['name']}' lacks StaticBody3D/CollisionShape3D",
                    })
            elif ntype == "CharacterBody3D":
                try:
                    margin = float(n.get("safe_margin", "0.001"))
                except ValueError:
                    margin = 0.0
                if margin < float(STYLE_LOCK["min_character_safe_margin"]):
                    collision_findings.append({
                        "severity": "MEDIUM",
                        "rule": "LOW_SAFE_MARGIN",
                        "location": f"{rel}:{n['line']}",
                        "detail": f"CharacterBody3D '{n['name']}' safe_margin={margin} (< 0.04)",
                    })
            elif n["parent"] == "__ROOT__" and ntype in {"Control", "Panel", "PanelContainer", "MarginContainer"}:
                preset = n.get("anchors_preset", "")
                ar = n.get("anchor_right", "")
                ab = n.get("anchor_bottom", "")
                if not ((preset == "15") or (ar in {"1", "1.0"} and ab in {"1", "1.0"})) and UI_SCENE_RE.search(rel):
                    ui_findings.append({
                        "severity": "HIGH",
                        "rule": "UI_ROOT_NOT_FULL_RECT",
                        "location": f"{rel}:{n['line']}",
                        "detail": f"Root {ntype} '{n['name']}' not Full Rect (anchors_preset=15)",
                    })

        for sid, sdata in subresources.items():
            if sdata.get("type") == "ConcavePolygonShape3D" and sdata.get("backface_collision", "false") != "true":
                collision_findings.append({
                    "severity": "HIGH",
                    "rule": "CONCAVE_NO_BACKFACE",
                    "location": f"{rel}:{sdata['line']}",
                    "detail": f"ConcavePolygonShape3D '{sid}' has backface_collision=false",
                })

    return {
        "collision_findings_count": len(collision_findings),
        "collision_findings": collision_findings,
        "ui_findings_count": len(ui_findings),
        "ui_findings": ui_findings,
    }


def audit_assets_bloat(repo: Path) -> Dict[str, Any]:
    issues: List[Dict[str, Any]] = []
    total_bytes = 0
    max_tex = int(STYLE_LOCK["max_texture_px"])
    max_wav = int(STYLE_LOCK["max_wav_bytes"])
    max_img = int(STYLE_LOCK["max_image_bytes"])

    for path in sorted(repo.rglob("*")):
        if not path.is_file() or any(part in EXCLUDE_DIRS for part in path.parts):
            continue
        size = path.stat().st_size
        total_bytes += size
        ext = path.suffix.lower()
        rel = str(path.relative_to(repo)).replace("\\", "/")

        if ext in {".wav", ".flac", ".mp3"} and (ext != ".wav" or size > max_wav):
            issues.append({"severity": "HIGH", "rule": "UNOPTIMIZED_AUDIO_FORMAT", "file": rel, "size_kb": round(size / 1024.0, 1)})
        elif ext == ".png":
            dims = read_png_dimensions(path)
            if dims and (dims[0] > max_tex or dims[1] > max_tex):
                issues.append({"severity": "HIGH", "rule": "OVERSIZED_TEXTURE", "file": rel, "dimensions": f"{dims[0]}x{dims[1]}"})
            elif size > max_img:
                issues.append({"severity": "MEDIUM", "rule": "LARGE_IMAGE_FILE", "file": rel, "size_kb": round(size / 1024.0, 1)})

    return {"repo_asset_total_mb": round(total_bytes / (1024.0 * 1024.0), 2), "issues_count": len(issues), "issues": issues}


def main() -> int:
    parser = argparse.ArgumentParser(description="Samsung A32 config patcher + collision/UI/WiFi/asset auditor V2")
    parser.add_argument("--repo", required=True, help="Godot project root")
    parser.add_argument("--apply", action="store_true", help="Apply project.godot and export_presets.cfg patches")
    args = parser.parse_args()

    repo = Path(args.repo).resolve()
    if not repo.is_dir():
        print(json.dumps({"error": f"Repo not found: {repo}"}))
        return 2

    cfg_res = patch_project_godot(repo / "project.godot", apply_changes=args.apply)
    exp_res = patch_export_presets(repo / "export_presets.cfg", apply_changes=args.apply)
    wifi_res = audit_wifi_bonus_leftovers(repo)
    scene_res = audit_tscn_collisions_and_ui(repo)
    ast_res = audit_assets_bloat(repo)

    gate_pass = (
        cfg_res.get("status") in {"CLEAN", "PATCHED"}
        and exp_res.get("status") in {"CLEAN", "PATCHED", "SKIPPED"}
        and wifi_res["wifi_hits_count"] == 0
        and scene_res["collision_findings_count"] == 0
        and scene_res["ui_findings_count"] == 0
        and ast_res["issues_count"] == 0
    )

    report = {
        "style_lock": STYLE_LOCK["target_device"],
        "gate_pass": gate_pass,
        "project_godot": cfg_res,
        "export_presets": exp_res,
        "wifi_bonus_audit": wifi_res,
        "scenes": scene_res,
        "assets": ast_res,
    }
    report_path = repo / "MOBILE_AUDIT_REPORT.json"
    report_path.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({
        "report": str(report_path),
        "report_sha256": sha256_file(report_path),
        "gate_pass": gate_pass,
        "project_godot_status": cfg_res.get("status"),
        "wifi_hits": wifi_res["wifi_hits_count"],
        "collision_findings": scene_res["collision_findings_count"],
        "ui_findings": scene_res["ui_findings_count"],
        "asset_issues": ast_res["issues_count"],
        "repo_total_mb": ast_res["repo_asset_total_mb"],
    }, indent=2))
    return 0 if gate_pass else 1


if __name__ == "__main__":
    sys.exit(main())
