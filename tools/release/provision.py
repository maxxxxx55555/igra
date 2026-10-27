"""Pinned official Godot editor/templates. No administrator rights or PATH changes."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import stat
import urllib.request
import zipfile

VERSION = "4.7.2"
BASE = f"https://github.com/godotengine/godot-builds/releases/download/{VERSION}-stable/"
ASSETS = {
    "windows": (f"Godot_v{VERSION}-stable_win64.exe.zip", "731980f9608d61333e5baf54a2ef17210acc7a538446c0cb9969f002aca1e953"),
    "linux": (f"Godot_v{VERSION}-stable_linux.x86_64.zip", "cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4"),
    "templates": (f"Godot_v{VERSION}-stable_export_templates.tpz", "f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011"),
}


def sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def download(cache, name, expected, base=BASE):
    path = cache / name
    if path.is_file() and sha256(path) == expected:
        return path
    temp = path.with_suffix(path.suffix + ".partial")
    print(f"Downloading official {name} (templates: approximately 1.3 GB)", flush=True)
    request = urllib.request.Request(base + name, headers={"User-Agent": "Igra-Release/1.0.1"})
    with urllib.request.urlopen(request, timeout=120) as remote, temp.open("wb") as local:
        shutil.copyfileobj(remote, local, 1024 * 1024)
    if sha256(temp) != expected:
        temp.unlink()
        raise RuntimeError(f"SHA256 mismatch: {name}; download rejected")
    temp.replace(path)
    return path


def extract_file(archive, member, target):
    """Only exact, named files; archive paths are never used as destinations."""
    target.parent.mkdir(parents=True, exist_ok=True)
    with archive.open(member) as source, target.open("wb") as dest:
        shutil.copyfileobj(source, dest)
    target.chmod(target.stat().st_mode | stat.S_IXUSR)


def provision(root, android=False):
    root = Path(root).resolve()
    cache = root / "downloads"
    cache.mkdir(parents=True, exist_ok=True)
    system = "windows" if os.name == "nt" else "linux"
    archive = download(cache, *ASSETS[system])
    editor_dir = root / "godot"
    editor_dir.mkdir(exist_ok=True)
    with zipfile.ZipFile(archive) as files:
        name = f"Godot_v{VERSION}-stable_win64_console.exe" if os.name == "nt" else f"Godot_v{VERSION}-stable_linux.x86_64"
        if os.name == "nt":
            # The console launcher needs its adjacent GUI executable too.
            extract_file(files, f"Godot_v{VERSION}-stable_win64.exe", editor_dir / f"Godot_v{VERSION}-stable_win64.exe")
        extract_file(files, name, editor_dir / name)
    # Godot's supported self-contained mode keeps templates/settings inside this folder.
    (editor_dir / "_sc_").touch()
    templates = editor_dir / "editor_data" / "export_templates" / f"{VERSION}.stable"
    archive = download(cache, *ASSETS["templates"])
    names = ["version.txt", "windows_release_x86_64.exe", "web_nothreads_release.zip", "web_nothreads_debug.zip"]
    if android:
        names += ["android_release.apk", "android_debug.apk", "android_source.zip"]
    with zipfile.ZipFile(archive) as files:
        for template in names:
            extract_file(files, "templates/" + template, templates / template)
    result = {"godot": str(editor_dir / name), "templates": str(templates), "version": VERSION}
    if android:
        result["bundletool"] = str(download(cache, "bundletool-all-1.18.3.jar",
            "a099cfa1543f55593bc2ed16a70a7c67fe54b1747bb7301f37fdfd6d91028e29",
            "https://github.com/google/bundletool/releases/download/1.18.3/"))
    (root / "toolchain.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps(result), flush=True)
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", required=True)
    parser.add_argument("--android", action="store_true")
    args = parser.parse_args()
    provision(args.root, args.android)
