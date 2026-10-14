# -*- coding: utf-8 -*-
"""Export reachability gate (Session 23, CORRECTION_LOG 242, 243): a file that ships must not name a file the export leaves out.

usage: python tools/qa_sim/export_refs_check.py [--preset Android] [--bundle build/tls.aab] [--demo]
The editor runs the project with every file in place, so the compile gate cannot see a `preload` of a file that the export leaves out: in the bundle that script fails to load. This reads the
`exclude_filter` of the preset (Godot's wildcards: `*` matches any run of characters, `/` included, `?` one character), takes every script, scene and resource the filter lets through, and fails
for each literal `res://` path inside it (comments left out) that exists in the project and is matched by the filter, and for each autoload of project.godot that is.
A path in a `preload(...)`, an `extends "..."`, a scene's `ext_resource` or an autoload entry is read when the file loads, so the file fails in the bundle: FAIL, exit code 1, "FAIL <file>:<line>: <path> is excluded by <pattern>".
Any other literal path (a `load(...)`, a constant) is only read when that line runs, which a guard such as `OS.is_debug_build()` can keep from a release build: it prints "NOTE" and is read by a person.
A path built from a format string (`"res://assets/textures/icons/skills/%s_96.png" % id`) names every project file its pattern matches: all of them left out by the filter is a FAIL (the game asks for files the bundle does
not have; the `*` of a filter also matches `/`, so `icons/*.png` leaves out `icons/skills/*.png`), some of them left out a NOTE.
A sound that `play_ui("<name>")` asks for is the file `assets/audio/ui/ui_<name>.ogg` (the path is never one string in the code, so no other reading sees it, and a missing file is silent: CORRECTION_LOG 245): it must exist, and be packed.
With --bundle the same references are read against an exported bundle instead of the filter: every file they name that the filter does not leave out must be in the asset pack, as the export makes it
(a script or scene as `<path>.remap`, an imported file as the imported file its `.import` names, anything else as itself); a file that is not is a FAIL.
Dot folders (`.godot`, `.qa_logs`) and folders with a `.gdignore` are not the project's files. --demo proves the gate on a fixture.
"""
import fnmatch
import pathlib
import re
import sys
import tempfile
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
SHIPPED = (".gd", ".tscn", ".tres", ".gdshader")
PATH = re.compile(r"res://[^\"'\s)\]},]+")
CUE = re.compile(r'play_ui\("([A-Za-z0-9_]+)"\)')
PACK = "assetPackInstallTime/assets/"
IMPORTED = re.compile(r'(?m)^path[.\w]*="res://([^"]+)"')


def patterns(preset, root=ROOT):
    text = (root / "export_presets.cfg").read_text(encoding="utf-8")
    sections = re.split(r"(?m)^\[preset\.\d+\]\s*$", text)
    for sec in sections:
        if re.search(r'(?m)^name="%s"' % re.escape(preset), sec):
            m = re.search(r'(?m)^exclude_filter="([^"]*)"', sec)
            return [p.strip() for p in m.group(1).split(",") if p.strip()] if m else []
    raise SystemExit("no preset named %s in export_presets.cfg" % preset)


def matched(rel, pats):
    for p in pats:
        if fnmatch.fnmatchcase(rel, p):
            return p
    return None


def packed(root, names, target):
    """Whether the bundle's entries hold what the export makes of the project file `target`."""
    if target.endswith((".gd", ".tscn", ".tres")):
        return PACK + target + ".remap" in names
    sidecar = root / (target + ".import")
    made = IMPORTED.findall(sidecar.read_text(encoding="utf-8", errors="replace")) if sidecar.is_file() else []
    return any(PACK + m in names for m in made) if made else PACK + target in names


def strip_comment(line):
    quote = None
    for i, ch in enumerate(line):
        if quote:
            quote = None if ch == quote else quote
        elif ch in "\"'":
            quote = ch
        elif ch == "#":
            return line[:i]
    return line


def violations(root, pats, names=None):
    """The FAIL and NOTE lines. With `names`, the entries of a bundle, the question is whether the export packed a file, not whether the filter leaves it out."""
    out = []
    ignored = [p for p in root.rglob(".gdignore")]
    skip = tuple(str(p.parent.relative_to(root)).replace("\\", "/") + "/" for p in ignored)
    files = []
    everything = []
    for path in sorted(root.rglob("*")):
        if not path.is_file():
            continue
        rel = str(path.relative_to(root)).replace("\\", "/")
        if rel.startswith(skip) or any(part.startswith(".") for part in rel.split("/")):
            continue
        everything.append(rel)
        if path.suffix in SHIPPED and not matched(rel, pats):
            files.append((rel, path))

    def lacking(w):
        return matched(w, pats) if names is None else (not matched(w, pats) and not packed(root, names, w))

    def why(w):
        return "excluded by %s" % matched(w, pats) if names is None else "not in the bundle"

    for rel, path in files:
        for number, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
            code = strip_comment(line) if path.suffix in (".gd", ".gdshader") else line
            for m in PATH.finditer(code):
                target = m.group(0)[len("res://"):]
                if "%" in target:
                    wanted = [n for n in everything if fnmatch.fnmatchcase(n, re.sub(r"%[-+0-9.]*[sdif]", "*", target))] if path.suffix == ".gd" else []
                    left = [w for w in wanted if lacking(w)]
                    if left:
                        kind = "FAIL" if len(left) == len(wanted) or names is not None else "NOTE"
                        out.append("%s %s:%d: %d of the %d file(s) of %s are %s" % (kind, rel, number, len(left), len(wanted), target, why(left[0])))
                elif (root / target).is_file() and lacking(target):
                    before = code[:m.start()].rstrip("\"' ").rstrip("(").rstrip()
                    when_loaded = path.suffix != ".gd" or before.endswith(("preload", "extends")) or names is not None
                    out.append("%s %s:%d: %s is %s" % ("FAIL" if when_loaded else "NOTE", rel, number, target, why(target)))
            for m in CUE.finditer(code if path.suffix == ".gd" else ""):
                target = "assets/audio/ui/ui_%s.ogg" % m.group(1)
                if not (root / target).is_file():
                    out.append('FAIL %s:%d: play_ui("%s") has no %s' % (rel, number, m.group(1), target))
                elif lacking(target):
                    out.append('FAIL %s:%d: play_ui("%s") names %s, which is %s' % (rel, number, m.group(1), target, why(target)))
    in_autoload = False
    for number, line in enumerate((root / "project.godot").read_text(encoding="utf-8", errors="replace").splitlines(), 1):
        if line.startswith("["):
            in_autoload = line.strip() == "[autoload]"
        elif in_autoload and "res://" in line:
            target = PATH.search(line).group(0)[len("res://"):]
            if lacking(target):
                out.append("FAIL project.godot:%d: autoload %s is %s" % (number, target, why(target)))
    return out, len(files)


def demo():
    with tempfile.TemporaryDirectory() as tmp:
        root = pathlib.Path(tmp)
        (root / "scripts" / "security").mkdir(parents=True)
        (root / "scripts" / "systems").mkdir(parents=True)
        (root / "scripts" / "tools").mkdir(parents=True)
        (root / "scripts" / "security" / "log.gd").write_text("extends RefCounted\n", encoding="utf-8")
        (root / "scripts" / "systems" / "guard.gd").write_text('const _Log := preload("res://scripts/security/log.gd")\n# preload("res://scripts/security/log.gd") in a comment\n', encoding="utf-8")
        (root / "scripts" / "systems" / "fine.gd").write_text('const _T := preload("res://scripts/systems/guard.gd")\nvar f := "res://scripts/systems/%s.gd"\nfunc on_demand() -> Object:\n\treturn load("res://scripts/security/log.gd")\nfunc ring() -> void:\n\tplay_ui("ending_sting")\n', encoding="utf-8")
        (root / "scripts" / "tools" / "probe.gd").write_text('const _G := preload("res://scripts/security/log.gd")\n', encoding="utf-8")
        (root / "assets" / "icons" / "skills").mkdir(parents=True)
        (root / "assets" / "icons" / "skills" / "a_96.png").write_bytes(b"x")
        (root / "assets" / "icons" / "skills" / "b_96.png").write_bytes(b"x")
        (root / "assets" / "icons" / "skills" / "a_96.png.import").write_text('[remap]\npath.etc2="res://.godot/imported/a.etc2.ctex"\npath.s3tc="res://.godot/imported/a.s3tc.ctex"\n', encoding="utf-8")
        (root / "scripts" / "systems" / "icon.gd").write_text('var path := "res://assets/icons/skills/%s_96.png" % id\n', encoding="utf-8")
        (root / "project.godot").write_text('[autoload]\nGuard="*res://scripts/systems/guard.gd"\nLog="*res://scripts/security/log.gd"\n', encoding="utf-8")
        (root / "export_presets.cfg").write_text('[preset.0]\nname="Android"\nexclude_filter="scripts/tools/*,scripts/security/*,assets/icons/*.png"\n', encoding="utf-8")
        found, count = violations(root, patterns("Android", root))
        fails = [v for v in found if v.startswith("FAIL")]
        assert len(fails) == 4, found
        assert any("guard.gd:1" in v and "log.gd" in v for v in fails), found
        assert any("project.godot" in v for v in fails), found
        assert any("icon.gd:1" in v and "2 of the 2" in v for v in fails), found
        assert any("fine.gd:6" in v and "ending_sting" in v and "has no" in v for v in fails), found
        assert any(v.startswith("NOTE") and "fine.gd:4" in v for v in found), found
        (root / "assets" / "audio" / "ui").mkdir(parents=True)
        (root / "assets" / "audio" / "ui" / "ui_ending_sting.ogg").write_bytes(b"x")
        (root / "export_presets.cfg").write_text('[preset.0]\nname="Android"\nexclude_filter="scripts/tools/*"\n', encoding="utf-8")
        found, count = violations(root, patterns("Android", root))
        assert found == [], found
        whole = {PACK + n for n in ("scripts/systems/guard.gd.remap", "scripts/systems/fine.gd.remap", "scripts/systems/icon.gd.remap", "scripts/security/log.gd.remap", ".godot/imported/a.etc2.ctex", "assets/icons/skills/b_96.png", "assets/audio/ui/ui_ending_sting.ogg")}
        found, count = violations(root, patterns("Android", root), whole)
        assert found == [], found
        found, count = violations(root, patterns("Android", root), whole - {PACK + "scripts/security/log.gd.remap", PACK + ".godot/imported/a.etc2.ctex"})
        assert len(found) == 4 and all(v.startswith("FAIL") for v in found), found
    print("export_refs_check demo: a preload and an autoload that the filter leaves out fail; a format string whose files are all left out fails; a load() is a note; a comment, a shipped format string and a tools script are not read; "
          "against a bundle, a file the export did not pack fails and one platform variant of an imported file is enough")
    return 0


def main():
    if "--demo" in sys.argv:
        return demo()
    preset = sys.argv[sys.argv.index("--preset") + 1] if "--preset" in sys.argv else "Android"
    names = set(zipfile.ZipFile(sys.argv[sys.argv.index("--bundle") + 1]).namelist()) if "--bundle" in sys.argv else None
    found, count = violations(ROOT, patterns(preset), names)
    fails = [v for v in found if v.startswith("FAIL")]
    for v in found:
        print(v)
    print("export_refs_check: %d shipped file(s) read for the %s preset%s, %d violation(s), %d note(s)" % (count, preset, " against the bundle" if names else "", len(fails), len(found) - len(fails)))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
