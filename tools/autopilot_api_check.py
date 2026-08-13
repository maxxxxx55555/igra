#!/usr/bin/env python3
"""Проверяет, что автопилот зовёт только существующие API.

Godot в песочнице недоступен, поэтому набор тестов нельзя прогнать перед
отправкой владельцу. Худший исход — автопилот падает у него на опечатке в
имени метода и весь прогон уходит в мусор. Этот валидатор ловит такие
опечатки статически:

  * автозагрузки, которые автопилот берёт через /root/<Имя>, обязаны быть
    объявлены в project.godot;
  * методы, вызванные у автозагрузки, обязаны существовать в её скрипте;
  * файлы сцен и скриптов, на которые автопилот ссылается строкой, должны
    лежать на диске.

Код возврата 0 — всё сходится.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TESTS = ROOT / "tools/autopilot/autopilot_tests.gd"
MAIN = ROOT / "tools/autopilot/autopilot_main.gd"
RUNTIME = ROOT / "tools/autopilot/autopilot_runtime.gd"

# Методы, встроенные в Object/Node: их не нужно искать в исходнике скрипта.
OBJECT_BUILTINS = {
    "has_method", "get_node_or_null", "get_node", "connect", "disconnect",
    "emit", "call", "call_deferred", "get", "set", "has_signal", "is_class",
    "add_child", "remove_child", "queue_free", "find_child",
}

fails: list[str] = []
checks = 0


def ok(cond: bool, msg: str) -> None:
    global checks
    checks += 1
    if not cond:
        fails.append(msg)


def autoloads() -> dict[str, Path]:
    out: dict[str, Path] = {}
    text = (ROOT / "project.godot").read_text(encoding="utf-8")
    section = text.split("[autoload]", 1)
    if len(section) < 2:
        return out
    body = section[1].split("\n[", 1)[0]
    for m in re.finditer(r'^(\w+)="\*?(res://[^"]+)"', body, re.M):
        out[m.group(1)] = ROOT / m.group(2).replace("res://", "")
    return out


def methods_of(path: Path) -> set[str]:
    if not path.exists():
        return set()
    src = path.read_text(encoding="utf-8", errors="ignore")
    names = set(re.findall(r"^func\s+([A-Za-z_]\w*)", src, re.M))
    # Публичные поля тоже допустимы: тесты читают, например, current_district.
    names |= set(re.findall(r"^var\s+([A-Za-z_]\w*)", src, re.M))
    names |= set(re.findall(r"^@export\s+var\s+([A-Za-z_]\w*)", src, re.M))
    names |= set(re.findall(r"^signal\s+([A-Za-z_]\w*)", src, re.M))
    return names


def main() -> int:
    for f in (TESTS, MAIN, RUNTIME):
        ok(f.exists(), f"нет файла автопилота: {f.relative_to(ROOT)}")
    if fails:
        report()
        return 1

    src = TESTS.read_text(encoding="utf-8")
    auto = autoloads()

    # 1. Автозагрузки, запрашиваемые через _autoload(tree, "Имя").
    wanted = set(re.findall(r'_autoload\(tree,\s*"(\w+)"\)', src))
    wanted |= set(re.findall(r'"(\w+)",?\s*$', "")) if False else set()
    # Имена из списка обязательных автозагрузок внутри теста.
    block = re.search(r"var need := \[(.*?)\]", src, re.S)
    if block:
        wanted |= set(re.findall(r'"(\w+)"', block.group(1)))
    for name in sorted(wanted):
        ok(name in auto, f"автопилот ждёт автозагрузку {name}, но её нет в project.godot")

    # 2. Методы, вызванные у переменных, полученных из автозагрузок.
    #    Сопоставляем локальное имя переменной с именем автозагрузки.
    var_to_auto: dict[str, str] = {}
    for m in re.finditer(r'var\s+(\w+)\s*:?=\s*_autoload\(tree,\s*"(\w+)"\)', src):
        var_to_auto[m.group(1)] = m.group(2)

    for var, auto_name in sorted(var_to_auto.items()):
        script = auto.get(auto_name)
        if script is None:
            continue
        available = methods_of(script)
        if not available:
            continue
        for call in sorted(set(re.findall(rf"\b{var}\.(\w+)\s*\(", src))):
            # Встроенные методы Object/Node есть у любого узла — их незачем
            # искать в тексте скрипта автозагрузки.
            if call in OBJECT_BUILTINS:
                continue
            ok(
                call in available,
                f"{auto_name}.{call}() вызывается автопилотом, но такого метода нет "
                f"в {script.relative_to(ROOT)}",
            )
        for field in sorted(set(re.findall(rf"\b{var}\.(\w+)\s*=", src))):
            ok(
                field in available,
                f"{auto_name}.{field} присваивается автопилотом, но такого поля нет "
                f"в {script.relative_to(ROOT)}",
            )

    # 3. Все res:// пути, упомянутые автопилотом, обязаны существовать.
    for path in sorted(set(re.findall(r'"(res://[^"]+)"', src))):
        target = ROOT / path.replace("res://", "")
        ok(target.exists(), f"автопилот ссылается на несуществующий путь {path}")

    # 4. Каждый тест из collect() должен быть реализован, и наоборот.
    listed = set(re.findall(r'"fn":\s*(_t_\w+)', src))
    defined = set(re.findall(r"^func\s+(_t_\w+)", src, re.M))
    for name in sorted(listed - defined):
        ok(False, f"тест {name} заявлен в collect(), но не реализован")
    for name in sorted(defined - listed):
        ok(False, f"тест {name} реализован, но не попал в collect() — не запустится")
    ok(len(listed) > 0, "в collect() нет ни одного теста")

    # 5. MainLoop._process возвращает bool: вернув true, он завершит цикл.
    #    Объявление -> void молча ломает весь прогон, поэтому проверяем.
    main_src = MAIN.read_text(encoding="utf-8")
    if re.search(r"^extends\s+(SceneTree|MainLoop)", main_src, re.M):
        m = re.search(r"^func\s+_process\s*\([^)]*\)\s*->\s*(\w+)", main_src, re.M)
        ok(
            m is not None and m.group(1) == "bool",
            "autopilot_main._process должен возвращать bool "
            f"(сейчас {m.group(1) if m else 'не объявлен'})",
        )

    # 6. Сигналы EventBus, на которые подписывается автопилот.
    bus = ROOT / "scripts/events/event_bus.gd"
    if bus.exists():
        bus_signals = set(re.findall(r"^signal\s+(\w+)", bus.read_text(encoding="utf-8"), re.M))
        for sig in sorted(set(re.findall(r"\bbus\.(\w+)\.(?:connect|disconnect)\(", src))):
            ok(sig in bus_signals, f"автопилот слушает несуществующий сигнал EventBus.{sig}")

    report()
    return 1 if fails else 0


def report() -> None:
    print("── автопилот: сверка API с проектом " + "─" * 24)
    if fails:
        for f in fails:
            print("  FAIL  " + f)
        print(f"\nПровалено: {len(fails)} из {checks}")
    else:
        print(f"  OK   все вызовы автопилота существуют ({checks} сверок)")


if __name__ == "__main__":
    sys.exit(main())
