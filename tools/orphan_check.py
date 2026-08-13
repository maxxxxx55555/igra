#!/usr/bin/env python3
"""Поиск файлов, на которые в проекте нет ни одной ссылки.

Строит карту всех `res://`-ссылок из сцен, ресурсов, скриптов и project.godot,
затем сверяет её со списком .gd/.tscn на диске. Учитывает три способа
сослаться на файл, помимо прямого пути:

* автозагрузки из project.godot;
* `class_name`, использованный где-то в коде;
* динамическая склейка пути ("res://scenes/districts/%s.tscn" % id) —
  такие каталоги перечислены в DYNAMIC_DIRS и не считаются осиротевшими.

Запуск:  python3 tools/orphan_check.py [--list]
Код возврата 0 — новых сирот нет.
"""
from __future__ import annotations

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Каталоги, куда код ходит по собранному в рантайме пути. Проверять их
# статически нельзя, поэтому содержимое считается используемым.
DYNAMIC_DIRS = (
    "scenes/districts/",   # district_scene_factory: "res://scenes/districts/%s.tscn"
    "scenes/effects/",     # particle-эффекты по имени
    "data/",               # ресурсы грузятся по id
    "assets/",             # ассеты подтягиваются по шаблону пути
)

# Инструменты и тесты: запускаются вручную из консоли, ссылок на них нет.
TOOL_DIRS = ("scenes/tools/", "scripts/tools/", "tools/", "tests/")

# Сцены, которые Godot грузит сам, без упоминания в коде.
ENTRY_POINTS = ("scenes/ui/boot_loading.tscn",)


def collect() -> tuple[dict[str, set[str]], set[str], set[str]]:
    text: dict[str, str] = {}
    for base, dirs, files in os.walk(ROOT):
        dirs[:] = [d for d in dirs if d != ".git"]
        for f in files:
            if f.endswith((".gd", ".tscn", ".tres", ".godot", ".cfg", ".json", ".txt")):
                p = os.path.join(base, f)
                try:
                    text[os.path.relpath(p, ROOT).replace(os.sep, "/")] = \
                        open(p, encoding="utf-8", errors="ignore").read()
                except OSError:
                    pass

    refs: dict[str, set[str]] = {}
    for p, t in text.items():
        for m in re.finditer(r'res://([^"\')\s\]]+)', t):
            refs.setdefault(m.group(1), set()).add(p)

    # class_name -> где объявлен, и какие имена реально встречаются в коде
    declared: dict[str, str] = {}
    for p, t in text.items():
        if p.endswith(".gd"):
            m = re.search(r"^class_name\s+(\w+)", t, re.M)
            if m:
                declared[m.group(1)] = p
    used_classes: set[str] = set()
    for cls, owner in declared.items():
        pat = re.compile(r"\b%s\b" % re.escape(cls))
        for p, t in text.items():
            if p != owner and pat.search(t):
                used_classes.add(cls)
                break

    autoloads: set[str] = set()
    cfg = text.get("project.godot", "")
    if "[autoload]" in cfg:
        block = cfg.split("[autoload]")[1].split("\n[")[0]
        autoloads = {m.group(1) for m in re.finditer(r'="\*?res://([^"]+)"', block)}

    return refs, autoloads, used_classes | set()


def main() -> int:
    refs, autoloads, used_classes = collect()
    owner_of_class = {}
    for base, dirs, files in os.walk(ROOT):
        dirs[:] = [d for d in dirs if d != ".git"]
        for f in files:
            if f.endswith(".gd"):
                p = os.path.relpath(os.path.join(base, f), ROOT).replace(os.sep, "/")
                m = re.search(r"^class_name\s+(\w+)",
                              open(os.path.join(base, f), encoding="utf-8",
                                   errors="ignore").read(), re.M)
                if m:
                    owner_of_class[p] = m.group(1)

    orphans: list[str] = []
    for base, dirs, files in os.walk(ROOT):
        dirs[:] = [d for d in dirs if d != ".git"]
        for f in files:
            if not f.endswith((".gd", ".tscn")):
                continue
            rel = os.path.relpath(os.path.join(base, f), ROOT).replace(os.sep, "/")
            if rel in ENTRY_POINTS or rel in autoloads:
                continue
            if rel.startswith(DYNAMIC_DIRS) or rel.startswith(TOOL_DIRS):
                continue
            external = {s for s in refs.get(rel, set()) if s != rel}
            if external:
                continue
            if owner_of_class.get(rel) in used_classes:
                continue
            orphans.append(rel)

    orphans = sorted(orphans)
    baseline_path = os.path.join(ROOT, "tools", "orphan_baseline.txt")
    baseline: set[str] = set()
    if os.path.exists(baseline_path):
        baseline = {l.strip() for l in open(baseline_path, encoding="utf-8")
                    if l.strip() and not l.startswith("#")}

    if "--list" in sys.argv:
        for o in orphans:
            print(o)
        return 0

    if "--freeze" in sys.argv:
        with open(baseline_path, "w", encoding="utf-8") as fh:
            fh.write("# Известные файлы без ссылок на момент заморозки.\n")
            fh.write("# Это задел под будущие фичи, а не мусор: систему пишут\n")
            fh.write("# раньше, чем к ней приделывают вызов. Гейт следит лишь\n")
            fh.write("# за тем, чтобы список НЕ РОС.\n")
            fh.write("\n".join(orphans) + "\n")
        print("Базовая линия записана: %d файлов" % len(orphans))
        return 0

    new = [o for o in orphans if o not in baseline]
    gone = [b for b in baseline if b not in orphans]
    if new:
        print("НОВЫЕ файлы без единой ссылки (%d):" % len(new))
        for o in new:
            print("  ", o)
        print("\nЕсли файл — задел под фичу, добавьте его в tools/orphan_baseline.txt")
        print("(или запустите: python3 tools/orphan_check.py --freeze)")
        return 1
    print("  OK   новых файлов-сирот нет (в базовой линии %d, подключено %d)"
          % (len(baseline), len(gone)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
