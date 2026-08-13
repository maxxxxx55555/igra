#!/usr/bin/env python3
"""Статическая проверка сцен и скриптов без запуска Godot.

Ловит три класса ошибок, которые иначе видно только в консоли движка:

1. `# комментарии` в .tscn/.tres — формат ресурсов Godot их НЕ поддерживает,
   парсер обрывает файл и следующие за комментарием ноды пропадают из сцены.
2. Ресурсы (StyleBoxFlat, Gradient, ...), объявленные как [node] — движок
   пишет "StyleBoxFlat cannot be created" и вставляет заглушку.
3. `$Path` / `@onready ... = $Path` в скрипте, указывающие на ноду,
   которой нет в сцене, где этот скрипт стоит корнем.

Запуск:  python3 tools/scene_node_check.py
Код возврата 0 — чисто, иначе число найденных проблем.
"""
from __future__ import annotations

import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Типы, которые являются Resource, а не Node. Список не исчерпывающий —
# только то, что реально встречается в проекте и ломает загрузку сцены.
RESOURCE_TYPES = {
    "StyleBoxFlat", "StyleBoxTexture", "StyleBoxLine", "StyleBoxEmpty",
    "Gradient", "GradientTexture1D", "GradientTexture2D", "Curve",
    "Theme", "Font", "FontFile", "FontVariation", "Texture2D", "ImageTexture",
    "Material", "StandardMaterial3D", "ShaderMaterial", "Shader",
    "Environment", "CameraAttributesPractical", "World3D", "Animation",
    "AudioStream", "AudioStreamWAV", "AudioStreamOggVorbis", "Resource",
    "BoxShape3D", "SphereShape3D", "CapsuleShape3D", "BoxMesh", "SphereMesh",
    "QuadMesh", "PlaneMesh", "CylinderMesh", "ArrayMesh", "PackedScene",
}

NODE_RE = re.compile(r'^\[node name="([^"]+)" type="([^"]+)"(?: parent="([^"]*)")?', re.M)
NODE_ANY_RE = re.compile(r'^\[node name="([^"]+)"(?:\s+type="([^"]+)")?(?:\s+parent="([^"]*)")?', re.M)
SCRIPT_RE = re.compile(r'script = ExtResource\("([^"]+)"\)')
EXT_RE = re.compile(r'^\[ext_resource type="([^"]+)" (?:uid="[^"]*" )?path="([^"]+)" id="([^"]+)"', re.M)
INSTANCE_RE = re.compile(r'^\[node name="([^"]+)"(?:\s+[^]]*?)?\s+instance=ExtResource\("([^"]+)"\)', re.M)


def scene_nodes(text: str) -> set[str]:
    """Полные пути всех нод сцены относительно корня ('' = корень)."""
    paths: set[str] = set()
    for m in NODE_ANY_RE.finditer(text):
        name, _typ, parent = m.group(1), m.group(2), m.group(3)
        if parent is None:  # корневая нода
            paths.add("")
            continue
        if parent == ".":
            paths.add(name)
        else:
            paths.add(f"{parent}/{name}")
    return paths


def main() -> int:
    os.chdir(ROOT)
    problems = 0

    scenes = sorted(glob.glob("scenes/**/*.tscn", recursive=True)) + \
             sorted(glob.glob("assets/**/*.tscn", recursive=True))
    resources = sorted(glob.glob("**/*.tres", recursive=True))

    # ── 1. комментарии в .tscn/.tres ────────────────────────────────────────
    print("── Комментарии в файлах ресурсов (Godot их не поддерживает)")
    bad_comments = []
    for p in scenes + resources:
        if "/.git" in p:
            continue
        for i, line in enumerate(open(p, encoding="utf-8", errors="ignore"), 1):
            if line.lstrip().startswith("#") and not line.lstrip().startswith("#!"):
                bad_comments.append((p, i, line.strip()[:60]))
    if bad_comments:
        problems += len(bad_comments)
        for p, i, s in bad_comments:
            print(f"  FAIL {p}:{i}  {s}")
    else:
        print(f"  OK   проверено {len(scenes) + len(resources)} файлов")

    # ── 2. Resource, объявленный как [node] ─────────────────────────────────
    print("\n── Ресурсы, ошибочно объявленные как [node]")
    bad_nodes = []
    for p in scenes:
        text = open(p, encoding="utf-8", errors="ignore").read()
        for m in NODE_RE.finditer(text):
            name, typ = m.group(1), m.group(2)
            if typ in RESOURCE_TYPES:
                line = text[: m.start()].count("\n") + 1
                bad_nodes.append((p, line, name, typ))
    if bad_nodes:
        problems += len(bad_nodes)
        for p, line, name, typ in bad_nodes:
            print(f'  FAIL {p}:{line}  нода "{name}" имеет тип ресурса {typ}')
    else:
        print(f"  OK   проверено {len(scenes)} сцен")

    # ── 3. $NodePath из скрипта в его сцену ─────────────────────────────────
    print("\n── Ссылки $NodePath на несуществующие ноды сцены")
    # скрипт -> сцена, где он назначен корню
    script_to_scene: dict[str, str] = {}
    for p in scenes:
        text = open(p, encoding="utf-8", errors="ignore").read()
        ext = {i: path for _t, path, i in EXT_RE.findall(text)}
        root_m = re.search(r'^\[node name="[^"]+" type="[^"]+"\]\n((?:[^\[]*\n)*)', text, re.M)
        if not root_m:
            continue
        sm = SCRIPT_RE.search(root_m.group(1))
        if not sm:
            continue
        spath = ext.get(sm.group(1), "")
        if spath.startswith("res://"):
            script_to_scene.setdefault(spath[6:], p)

    # $Node, $"Node", а также get_node("Node") — последний тоже роняет сцену,
    # если пути нет (get_node_or_null сознательно не проверяем: он для
    # необязательных нод и возвращает null штатно).
    # $Node, $"Node", а также get_node("Node") НА СЕБЕ — последний тоже роняет
    # сцену, если пути нет. Вызовы вида other.get_node(...) пропускаем: там
    # путь резолвится в чужом дереве (и обычно закрыт has_node).
    # get_node_or_null сознательно не проверяем — он для необязательных нод.
    dollar_re = re.compile(
        r'\$(?:"([^"]+)"|([A-Za-z_][\w/]*))'
        r'|(?<![\w.])get_node\(\s*"([^"/][^"]*)"\s*\)')
    bad_paths = []
    for script, scene in sorted(script_to_scene.items()):
        if not os.path.exists(script):
            continue
        text = open(scene, encoding="utf-8", errors="ignore").read()
        nodes = scene_nodes(text)
        # ноды из вложенных инстансов сцен нам не видны -> считаем их валидными
        instanced = {m.group(1) for m in INSTANCE_RE.finditer(text)}
        for i, line in enumerate(open(script, encoding="utf-8", errors="ignore"), 1):
            code = line.split("#")[0]
            for m in dollar_re.finditer(code):
                path = m.group(1) or m.group(2) or m.group(3)
                if not path or path.startswith("/"):
                    continue
                if path in nodes:
                    continue
                # путь внутрь инстанцированной сцены — не проверяем
                if any(path == n or path.startswith(n + "/") for n in instanced):
                    continue
                bad_paths.append((script, i, path, scene))
    if bad_paths:
        problems += len(bad_paths)
        for s, i, path, scene in bad_paths:
            print(f"  FAIL {s}:{i}  ${path} — нет такой ноды в {scene}")
    else:
        print(f"  OK   проверено {len(script_to_scene)} пар скрипт/сцена")

    print("\n" + "─" * 50)
    if problems == 0:
        print("Всё чисто.")
    else:
        print(f"Найдено проблем: {problems}")
    return min(problems, 250)


if __name__ == "__main__":
    sys.exit(main())
