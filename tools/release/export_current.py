# -*- coding: utf-8 -*-
"""Export Windows + Web release builds from a clean frozen source copy.

Mirrors tools/release/pipeline.py's import/export steps exactly, but skips the
QA-gate loop (run separately via tools/check.sh) and the disposable-profile
reset that trips bulk-delete guards in sandboxed environments.

Usage:
  python tools/release/export_current.py --source SRC --output OUT \
      --godot GODOT --commit HASH
"""
import argparse
import contextlib
import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import zipfile

EXCLUDED = {".git", ".godot", ".qa_logs", "build", "exports", "__pycache__",
            ".ruff_cache", ".venv", ".signing"}


def sha256(path):
    d = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            d.update(block)
    return d.hexdigest()


def copy_project(source, dest):
    def ignore(_dir, names):
        return [n for n in names if n in EXCLUDED or n.startswith(".lint-demo-")
                or n.endswith((".jks", ".keystore", ".pfx", ".pem", ".env"))]
    shutil.copytree(source, dest, ignore=ignore)


@contextlib.contextmanager
def import_configuration(project):
    """A fresh editor cannot load a font-backed custom theme before importing fonts."""
    path = project / "project.godot"
    original = path.read_bytes()
    text = re.sub(r'(?m)^theme/custom\s*=.*$', 'theme/custom=""', original.decode("utf-8"))
    path.write_text(text, encoding="utf-8")
    try:
        yield
    finally:
        path.write_bytes(original)


def run(cmd, cwd, timeout, log_name, logs):
    log = logs / (log_name + ".log")
    print(f"[export] {log_name}: {' '.join(str(c) for c in cmd[:3])} ...", flush=True)
    with log.open("wb") as out:
        proc = subprocess.Popen(list(map(str, cmd)), cwd=cwd, stdout=out,
                                stderr=subprocess.STDOUT,
                                creationflags=getattr(subprocess, "CREATE_NEW_PROCESS_GROUP", 0))
        try:
            code = proc.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            subprocess.run(["taskkill", "/PID", str(proc.pid), "/T", "/F"], capture_output=True)
            proc.wait()
            code = 124
    text = log.read_text(encoding="utf-8", errors="replace")
    errors = [l for l in text.splitlines() if re.search(r"SCRIPT ERROR:|ERROR:|error:", l)]
    print(f"[export] {log_name}: exit={code}, error-lines={len(errors)}", flush=True)
    for line in errors[:12]:
        print("   ", line[:200], flush=True)
    if code != 0:
        raise RuntimeError(f"{log_name} failed with {code}; see {log}")
    return text


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--source", required=True)
    ap.add_argument("--output", required=True)
    ap.add_argument("--godot", required=True)
    ap.add_argument("--commit", required=True)
    a = ap.parse_args()

    source = Path(a.source).resolve()
    out = Path(a.output).resolve()
    godot = Path(a.godot).resolve()
    if out == source or source in out.parents:
        raise ValueError("output must be outside source")
    out.mkdir(parents=True, exist_ok=True)
    logs = out / "logs"
    logs.mkdir(exist_ok=True)
    builds = out / "builds"
    builds.mkdir(exist_ok=True)
    artifacts = out / "artifacts"
    artifacts.mkdir(exist_ok=True)

    report = {"source_commit": a.commit, "godot": "", "builds": [],
              "started_utc": datetime.datetime.now(datetime.timezone.utc).isoformat()}

    version = run([godot, "--version"], source, 120, "godot_version", logs)
    report["godot"] = version.strip()

    project = out / "export-project"
    if project.exists():
        shutil.rmtree(project)
    copy_project(source, project)
    print(f"[export] frozen project copied to {project}", flush=True)

    # Canonical import: clear theme/custom so a fresh editor can import fonts.
    with import_configuration(project):
        run([godot, "--headless", "--editor", "--import", "--quit", "--path", project],
            project, 900, "import", logs)
    # Verify import settled (pipeline.py does the same retry).
    with import_configuration(project):
        run([godot, "--headless", "--editor", "--import", "--quit", "--path", project],
            project, 900, "import_verify", logs)
    report["project_godot_restored"] = (project / "project.godot").read_bytes() == (source / "project.godot").read_bytes()

    for preset, directory, filename in (("Windows Desktop", "windows", "LastStreetlight.exe"),
                                        ("Web", "web", "index.html")):
        dest = builds / directory
        dest.mkdir(parents=True, exist_ok=True)
        target = dest / filename
        run([godot, "--headless", "--export-release", preset, str(target), "--path", project],
            project, 1800, "export_" + directory, logs)
        if not target.is_file():
            raise RuntimeError(f"Godot did not create {target}")
        if directory == "web":
            for ext in ("wasm", "pck", "js"):
                if not (dest / ("index." + ext)).is_file():
                    raise RuntimeError("Incomplete Web export: missing index." + ext)
        for temp in dest.glob("*.tmp"):
            temp.unlink()
        (dest / "BUILD_INFO.json").write_text(json.dumps({
            "source_commit": a.commit, "godot": report["godot"],
            "built_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "platform": directory, "manual_device_review": "PENDING"}, indent=2), encoding="utf-8")
        # Third-party notices ship with every archive: CC-BY 4.0 music requires
        # attribution, SIL OFL 1.1 / Apache 2.0 fonts require their licence text.
        notices = dest / "THIRD_PARTY_NOTICES"
        notices.mkdir(exist_ok=True)
        for rel in ("docs/ASSET_LICENSES.md", "docs/LICENSED_MUSIC_REFRESH.md",
                    "assets/fonts/THIRD_PARTY_FONTS.md",
                    "assets/fonts/RobotoCondensed-Full-VF.LICENSE.md",
                    "assets/fonts/RobotoCondensed-Full-VF.SOURCE.md"):
            src = source / rel
            if src.is_file():
                (notices / src.name).write_bytes(src.read_bytes())
        archive = artifacts / ("LastStreetlight-1.0.1-" + directory + ".zip")
        with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as z:
            for p in sorted(dest.rglob("*")):
                if p.is_file():
                    z.write(p, p.relative_to(dest))
        report["builds"].append({"platform": directory, "archive": archive.name,
                                 "bytes": archive.stat().st_size, "sha256": sha256(archive),
                                 "files": sorted(p.name for p in dest.rglob("*") if p.is_file())})
        print(f"[export] {directory}: {archive.name} {archive.stat().st_size} bytes", flush=True)

    report["finished_utc"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
    report["state"] = "BUILDS_CREATED_MANUAL_REVIEW_PENDING"
    (artifacts / "export-report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    paths = sorted(p for p in artifacts.iterdir() if p.is_file() and p.name != "SHA256SUMS.txt")
    (artifacts / "SHA256SUMS.txt").write_text(
        "".join(f"{sha256(p)}  {p.name}\n" for p in paths), encoding="utf-8")
    print("BUILDS_CREATED_MANUAL_REVIEW_PENDING: " + str(artifacts), flush=True)


if __name__ == "__main__":
    main()
