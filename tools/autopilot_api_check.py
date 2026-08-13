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
            if call in ("has_method", "get_node_or_null", "connect", "disconnect", "emit"):
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

    # 4. Сигналы EventBus, на которые подписывается автопилот.
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
