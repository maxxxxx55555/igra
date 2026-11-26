#!/usr/bin/env python3
"""Master Release Gatekeeper for Samsung Galaxy A32 overhaul (blocks release on any violation)."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, List

EXCLUDE_DIRS = {
    ".git", ".godot", ".import", "_backup_raw_media",
    "_chat_upload_batches", "builds", "build", "export", "addons",
}
RES_REF_RE = re.compile(r'res://([A-Za-z0-9_./\-]+\.[A-Za-z0-9]+)')
STUB_RE = re.compile(r"(?m)(#\s*(TODO|FIXME|XXX)|^\s*pass\s*$)")


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def check_broken_res_references(repo: Path) -> List[str]:
    broken: List[str] = []
    for p in sorted(repo.rglob("*")):
        if not p.is_file() or p.suffix.lower() not in {".tscn", ".tres", ".gd", ".godot"}:
            continue
        if any(part in EXCLUDE_DIRS for part in p.parts):
            continue
        text = p.read_text(encoding="utf-8", errors="replace")
        rel_src = str(p.relative_to(repo)).replace("\\", "/")
        for m in RES_REF_RE.finditer(text):
            target = m.group(1)
            if not (repo / target).exists():
                broken.append(f"{rel_src} -> res://{target}")
    return sorted(set(broken))


def check_overhaul_code_hygiene(repo: Path) -> List[str]:
    issues: List[str] = []
    overhaul_dir = repo / "scripts" / "overhaul"
    if not overhaul_dir.is_dir():
        return ["missing_dir:scripts/overhaul"]
    for p in sorted(overhaul_dir.rglob("*.gd")):
        txt = p.read_text(encoding="utf-8", errors="replace")
        if STUB_RE.search(txt):
            issues.append(f"stub_or_todo_found:{p.relative_to(repo)}")
    return issues


def check_backup_gdignore(repo: Path) -> bool:
    bdir = repo / "_backup_raw_media"
    if not bdir.exists():
        return True
    return (bdir / ".gdignore").is_file()


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify all Samsung A32 release quality gates")
    parser.add_argument("--repo", required=True, help="Godot project root")
    parser.add_argument("--max-assets-mb", type=float, default=45.0, help="Max uncompressed repo assets MB")
    parser.add_argument("--godot", default="", help="Optional Godot binary path for headless smoke boot")
    args = parser.parse_args()

    repo = Path(args.repo).resolve()
    tools_dir = repo / "tools"
    failures: List[str] = []
    gates: Dict[str, Any] = {}

    # 1. Mobile audit gate
    audit_script = tools_dir / "audit_and_patch_mobile.py"
    p_audit = subprocess.run([sys.executable, str(audit_script), "--repo", str(repo)], capture_output=True, text=True)
    gates["audit_and_patch_mobile"] = {"exit": p_audit.returncode, "stdout": p_audit.stdout.strip()}
    if p_audit.returncode != 0:
        failures.append("audit_and_patch_mobile_failed")

    # 2. Media budget verification gate
    media_script = tools_dir / "optimize_mobile_media.py"
    p_media = subprocess.run(
        [sys.executable, str(media_script), "--repo", str(repo), "--verify-only"],
        capture_output=True, text=True,
    )
    gates["optimize_mobile_media_verify"] = {"exit": p_media.returncode, "stdout": p_media.stdout.strip()}
    if p_media.returncode != 0:
        failures.append("media_budget_gate_failed")

    # 3. Total repo size budget
    total_bytes = 0
    for p in repo.rglob("*"):
        if p.is_file() and not any(part in EXCLUDE_DIRS for part in p.parts):
            total_bytes += p.stat().st_size
    total_mb = round(total_bytes / (1024.0 * 1024.0), 2)
    gates["repo_size_budget"] = {"total_mb": total_mb, "max_mb": args.max_assets_mb, "pass": total_mb <= args.max_assets_mb}
    if total_mb > args.max_assets_mb:
        failures.append(f"repo_size_exceeded:{total_mb}MB>{args.max_assets_mb}MB")

    # 4. Broken res:// links
    broken_refs = check_broken_res_references(repo)
    gates["broken_res_references"] = {"count": len(broken_refs), "items": broken_refs[:40]}
    if broken_refs:
        failures.append(f"broken_res_references:{len(broken_refs)}")

    # 5. Overhaul code hygiene
    hygiene_issues = check_overhaul_code_hygiene(repo)
    gates["overhaul_code_hygiene"] = {"issues": hygiene_issues}
    if hygiene_issues:
        failures.append("overhaul_code_hygiene_failed")

    # 6. Backup .gdignore protection
    gdignore_ok = check_backup_gdignore(repo)
    gates["backup_gdignore"] = {"pass": gdignore_ok}
    if not gdignore_ok:
        failures.append("missing_backup_gdignore")

    # 7. Optional Godot headless smoke boot
    if args.godot:
        p_gd = subprocess.run(
            [args.godot, "--headless", "--path", str(repo), "--quit"],
            capture_output=True, text=True, timeout=90,
        )
        combined = (p_gd.stdout + "\n" + p_gd.stderr).strip()
        has_script_err = bool(re.search(r"(SCRIPT ERROR|Parse Error|Shader compilation failed|Cannot load source)", combined, re.IGNORECASE))
        gates["godot_headless_boot"] = {
            "exit": p_gd.returncode,
            "has_errors": has_script_err,
            "tail": combined[-800:],
        }
        if p_gd.returncode != 0 or has_script_err:
            failures.append("godot_headless_boot_failed")

    gate_pass = len(failures) == 0
    report = {
        "gate_pass": gate_pass,
        "failures": failures,
        "gates": gates,
    }
    out_path = repo / "RELEASE_GATE_REPORT.json"
    out_path.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({
        "report": str(out_path),
        "report_sha256": sha256_file(out_path),
        "gate_pass": gate_pass,
        "total_mb": total_mb,
        "failures": failures,
    }, indent=2))
    return 0 if gate_pass else 1


if __name__ == "__main__":
    sys.exit(main())
