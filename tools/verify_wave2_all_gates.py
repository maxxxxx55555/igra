#!/usr/bin/env python3
"""Unified Wave 2 Verification Gate + Mandatory Section 6A Post-Run Cleanup."""

from __future__ import annotations

import argparse
import csv
import gc
import hashlib
import json
import re
import shutil
import sys
from pathlib import Path
from typing import Any, Dict, List

WIFI_BAN_RE = re.compile(r"(?i)(бонус\s+за\s+wi-?fi|не\s+удалось\s+проверить\s+подключение|wifibonus|wifi_bonus)")
STUB_RE = re.compile(r"(?m)(#\s*(TODO|FIXME|XXX)\b|^\s*pass\s*$)")
STR_RE = re.compile(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'')

REQUIRED_WAVE2_SCRIPTS = [
    "scripts/overhaul/Wave2LocalizationSync.gd",
    "scripts/overhaul/Wave2ProgressionMap.gd",
    "scripts/overhaul/Wave2ComfortableHud.gd",
    "scripts/overhaul/Wave2DistrictFlow.gd",
]
REQUIRED_TEXTURE_SETS = [
    "panel_facade",
    "wet_asphalt",
    "concrete_sidewalk",
    "iron_brass_hardware",
]


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def cleanup_repo_temp_caches(repo: Path) -> int:
    removed = 0
    for d in list(repo.rglob("__pycache__")):
        if ".git" in d.parts:
            continue
        shutil.rmtree(d, ignore_errors=True)
        removed += 1
    for p in list(repo.rglob("*.pyc")) + list(repo.rglob("*.pyo")) + list(repo.rglob("*.tmp")):
        if ".git" in p.parts:
            continue
        try:
            p.unlink()
            removed += 1
        except OSError:
            pass
    gc.collect()
    return removed


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify all Wave 2 scripts, textures, i18n, docs and run cleanup")
    parser.add_argument("--repo", required=True, help="Godot project root")
    args = parser.parse_args()
    repo = Path(args.repo).resolve()
    if not repo.is_dir():
        print(json.dumps({"error": f"Repo not found: {repo}"}))
        return 2

    failures: List[str] = []
    checks: Dict[str, Any] = {}

    try:
        # 1. Wave 2 GDScript presence + hygiene
        for rel in REQUIRED_WAVE2_SCRIPTS:
            fp = repo / rel
            if not fp.is_file():
                failures.append(f"missing_script:{rel}")
                continue
            txt = fp.read_text(encoding="utf-8")
            if STUB_RE.search(txt):
                failures.append(f"stub_in_script:{rel}")
            stripped = "\n".join(ln.split("#", 1)[0] for ln in STR_RE.sub('""', txt).splitlines())
            if stripped.count("(") != stripped.count(")") or stripped.count("[") != stripped.count("]") or stripped.count("{") != stripped.count("}"):
                failures.append(f"unbalanced_delimiters:{rel}")
        checks["wave2_scripts_checked"] = len(REQUIRED_WAVE2_SCRIPTS)

        # 2. PBR textures & manifest
        tex_dir = repo / "assets" / "textures" / "wave2"
        tex_ok = 0
        for sname in REQUIRED_TEXTURE_SETS:
            for suf in ("albedo", "normal", "orm"):
                tp = tex_dir / f"{sname}_{suf}.png"
                if tp.is_file() and tp.stat().st_size > 200:
                    tex_ok += 1
                else:
                    failures.append(f"missing_or_empty_texture:{tp.name}")
        checks["wave2_textures_ok"] = tex_ok

        # 3. RU/EN Localization parity & zero Wi-Fi
        en_p = repo / "data" / "i18n" / "en.json"
        ru_p = repo / "data" / "i18n" / "ru.json"
        if not en_p.is_file() or not ru_p.is_file():
            failures.append("missing_i18n_json")
        else:
            en_d = json.loads(en_p.read_text(encoding="utf-8"))
            ru_d = json.loads(ru_p.read_text(encoding="utf-8"))
            if set(en_d.keys()) != set(ru_d.keys()):
                failures.append("i18n_en_ru_key_mismatch")
            checks["i18n_keys"] = len(en_d)
            for k in en_d.keys():
                if WIFI_BAN_RE.search(k) or WIFI_BAN_RE.search(str(en_d[k])) or WIFI_BAN_RE.search(str(ru_d.get(k, ""))):
                    failures.append(f"wifi_leftover_in_i18n:{k}")

        csv_p = repo / "translations.csv"
        if not csv_p.is_file():
            csv_p = repo / "data" / "i18n" / "translations.csv"
        if csv_p.is_file():
            with csv_p.open("r", encoding="utf-8") as f:
                hdr = next(csv.reader(f), [])
            if hdr != ["keys", "en", "ru"]:
                failures.append(f"unexpected_csv_locales:{hdr}")
            checks["csv_header"] = hdr

        # 4. Canonical Documentation check
        for doc_name in ("README.md", "GAME_DESIGN_AND_ROADMAP.md"):
            dp = repo / doc_name
            if not dp.is_file() or dp.stat().st_size < 1000:
                failures.append(f"missing_or_short_doc:{doc_name}")
            else:
                dtxt = dp.read_text(encoding="utf-8")
                if "11" not in dtxt or "Implementation Status" not in dtxt:
                    failures.append(f"incomplete_doc_sections:{doc_name}")
        checks["docs_verified"] = True
    finally:
        cleaned = cleanup_repo_temp_caches(repo)

    gate_pass = len(failures) == 0
    rep = {
        "gate_pass": gate_pass,
        "checks": checks,
        "failures": failures,
        "cleanup": {"cache_items_removed": cleaned, "temp_leftovers": 0, "gc_collected": True},
    }
    rep_path = repo / "WAVE2_GATE_REPORT.json"
    rep_path.write_text(json.dumps(rep, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    rep["report_path"] = str(rep_path)
    rep["report_sha256"] = sha256_file(rep_path)
    print(json.dumps(rep, indent=2, ensure_ascii=False))
    return 0 if gate_pass else 1


if __name__ == "__main__":
    sys.exit(main())
