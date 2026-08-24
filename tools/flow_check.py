#!/usr/bin/env python3
"""Проверка ключевого игрового цикла по исходникам, без запуска Godot.

Godot в этом окружении недоступен, поэтому цикл
  меню -> уровень -> подбор предмета -> пауза -> выход в меню
проверяется структурно: для каждого шага сверяем, что нужная связка
(сигнал -> подписчик, кнопка -> обработчик, вызов -> функция) реально
существует в коде. Такие проверки ловят именно те поломки, которые
были в этом репозитории: сигнал без единого слушателя, RPC самому себе,
твин, стоящий на паузе.

Запуск:  python3 tools/flow_check.py
"""
from __future__ import annotations

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def read(path: str) -> str:
    full = os.path.join(ROOT, path)
    if not os.path.exists(full):
        return ""
    return open(full, encoding="utf-8", errors="ignore").read()


def scripts_text() -> dict[str, str]:
    out: dict[str, str] = {}
    for base, _dirs, files in os.walk(os.path.join(ROOT, "scripts")):
        for f in files:
            if f.endswith(".gd"):
                p = os.path.join(base, f)
                out[os.path.relpath(p, ROOT)] = open(p, encoding="utf-8", errors="ignore").read()
    return out


ALL = scripts_text()


def emitters(signal: str) -> list[str]:
    pat = re.compile(r"EventBus\.%s\.emit\(" % re.escape(signal))
    return [p for p, t in ALL.items() if pat.search(t)]


def listeners(signal: str) -> list[str]:
    pat = re.compile(r"EventBus\.%s\.connect\(" % re.escape(signal))
    return [p for p, t in ALL.items() if pat.search(t)]


CHECKS: list[tuple[str, bool, str]] = []


def check(name: str, cond: bool, detail: str = "") -> None:
    CHECKS.append((name, bool(cond), detail))


# ── 1. Загрузка -> меню ─────────────────────────────────────────────────────
cfg = read("project.godot")
check("главная сцена — boot_loading", "boot_loading.tscn" in cfg)
check("boot уводит в меню", "Routes.to_menu()" in read("scripts/boot_loading.gd"))

# ── 2. Меню -> игра ─────────────────────────────────────────────────────────
menu = read("scripts/ui/main_menu.gd")
check("кнопка «Играть» стартует игру", "Routes.start_game()" in menu)
routes = read("scripts/core/routes.gd")
check("start_game ведёт в игровую сцену", "goto(LOADING if exists(LOADING) else GAME)" in routes)
check("игровая сцена существует", os.path.exists(os.path.join(ROOT, "scenes/main_3d.tscn")))
check("экран загрузки уходит в игру", "Routes.goto(Routes.GAME)" in read("scripts/ui/pre_loading.gd"))

# ── 3. Подбор предмета ──────────────────────────────────────────────────────
def code_only(text: str) -> str:
    """Текст без комментариев — чтобы не ловить упоминания в пояснениях."""
    return "\n".join(line.split("#")[0] for line in text.splitlines())


pick = read("scripts/pickups/item_pickup_3d.gd")
check("подбор не шлёт RPC самому себе", "rpc_id(" not in code_only(pick),
      "RPC в одиночной игре уходит OfflineMultiplayerPeer с id=1")
check("подбор кладёт вещь в инвентарь", "inventory.try_add(" in pick)
check("высота лута фиксируется после спавна", "_capture_base_y" in pick,
      "DistrictLoot задаёт позицию уже ПОСЛЕ add_child/_ready")
inv = read("scripts/inventory/inventory_manager.gd")
check("инвентарь шлёт item_picked_up", "EventBus.item_picked_up.emit(" in inv)
check("инвентарь не шлёт RPC вне сети", "_is_networked()" in inv)
check("сигнал подбора кто-то слушает", len(listeners("item_picked_up")) > 0,
      ", ".join(listeners("item_picked_up")))
check("лут раскладывается по районам", "LOOT_SCRIPT.populate" in read("scripts/world/district_scene_factory.gd"))

# ── 4. HUD ──────────────────────────────────────────────────────────────────
hud = read("scripts/ui/hud_3d.gd")
hud_scene = read("scenes/ui/hud_3d.tscn")
for node in ("NoiseLabel", "NoiseF", "VisibilityLabel", "VisibilityF"):
    check("HUD: нода %s есть в сцене" % node, 'name="%s"' % node in hud_scene)
check("HUD показывает здоровье", "player_health_changed.connect" in hud)
check("HUD показывает батарею", "player_battery_changed.connect" in hud)
check("HUD показывает шум", "_poll_noise_visibility" in hud and "get_noise_level" in hud)
check("HUD прячется под блокирующими экранами", "hud_visibility_changed.connect" in hud,
      "HUD на слое 20, экраны UIManager на слое 10")
player = read("scripts/player/player_3d.gd")
check("игрок отдаёт уровень шума", "func get_noise_level" in player)
check("игрок шлёт изменение батареи", "player_battery_changed.emit" in player)

# ── 5. Пауза ────────────────────────────────────────────────────────────────
uim = read("scripts/ui/ui_manager.gd")
check("Escape ставит паузу", 'is_action_pressed("ui_pause")' in uim)
check("Escape сперва закрывает справочники", "_topmost_closable" in uim)
gm = read("scripts/core/game_manager.gd")
check("пауза морозит дерево", "get_tree().paused = true" in gm)
check("снятие паузы размораживает", "get_tree().paused = false" in gm)
pause = read("scripts/ui/pause_menu.gd")
check("в паузе есть выход в меню", "GameManager.return_to_menu()" in pause)
fade = read("scripts/ui/fade_transition.gd")
check("затемнение работает на паузе", "PROCESS_MODE_ALWAYS" in fade,
      "иначе кнопки «В меню»/«Заново» вешают игру на чёрном экране")
check("UIManager работает на паузе", "PROCESS_MODE_ALWAYS" in uim)

# ── 6. Смерть и победа ──────────────────────────────────────────────────────
check("смерть игрока кем-то обрабатывается", len(listeners("game_over")) > 0,
      ", ".join(listeners("game_over")))
check("смерть переводит в состояние DEAD", "trigger_death()" in gm)
check("экран смерти открывается по состоянию", 'open(&"death")' in uim)
check("экран победы открывается по состоянию", 'open(&"win")' in uim)
check("с экрана смерти можно выйти в меню", "GameManager.return_to_menu()" in read("scripts/ui/death_screen.gd"))
check("«Заново» перезагружает сцену", "Routes.restart_game()" in read("scripts/ui/death_screen.gd"))

# ── 7. Кодекс / журнал / карта ──────────────────────────────────────────────
check("кодекс открывается", "func open_codex" in uim)
check("кодекс закрывается", 'UIManager.close(&"codex")' in read("scripts/ui/codex_ui.gd"))
check("карта переключается клавишей", 'is_action_pressed("city_map_toggle")' in uim)
check("журнал переключается клавишей", 'is_action_pressed("journal_toggle")' in uim)
for action in ("ui_pause", "city_map_toggle", "journal_toggle", "encyclopedia_toggle"):
    check("действие %s объявлено в проекте" % action, "%s={" % action in cfg)

# ── 8. Звук ─────────────────────────────────────────────────────────────────
buses = read("default_bus_layout.tres")
for bus in ("Master", "Music", "SFX", "Ambient", "UI"):
    check("аудио-шина %s существует" % bus, 'name = &"%s"' % bus in buses)
check("Master не заглушен на старте", "set_bus_mute(0, false)" in gm)
missing_audio: list[str] = []
for path, text in ALL.items():
    for ref in re.findall(r'"(res://[^"%]+\.(?:ogg|wav|mp3))"', text):
        if not os.path.exists(os.path.join(ROOT, ref[6:])):
            missing_audio.append("%s -> %s" % (path, ref))
check("все аудиофайлы из кода на диске", not missing_audio, "; ".join(missing_audio[:3]))

# ── 9. preload/load: битый путь = ошибка парсинга всего скрипта ─────────────
bad_preload: list[str] = []
for base, _dirs, files in os.walk(ROOT):
    if os.sep + ".git" in base or os.sep + ".claude" + os.sep + "worktrees" in base:
        continue
    for f in files:
        if not f.endswith(".gd"):
            continue
        p = os.path.join(base, f)
        text = open(p, encoding="utf-8", errors="ignore").read()
        for m in re.finditer(r'(?:preload|load)\(\s*"(res://[^"]+)"\s*\)', text):
            if not os.path.exists(os.path.join(ROOT, m.group(1)[6:])):
                line = text[: m.start()].count("\n") + 1
                bad_preload.append("%s:%d %s" % (os.path.relpath(p, ROOT), line, m.group(1)))
check("все preload/load ведут в существующие файлы", not bad_preload,
      "; ".join(bad_preload[:3]))

# ── 10. Арность подписок на сигналы автолоадов ──────────────────────────────
# В Godot 4 обработчик обязан принимать не меньше аргументов, чем шлёт сигнал,
# иначе КАЖДЫЙ emit — красная ошибка в консоли, а обработчик молчит.
auto_pairs = re.findall(r'^(\w+)="\*?(res://[^"]+)"',
                        cfg.split("[autoload]")[1].split("\n[")[0], re.M)
sig_arity: dict[str, int] = {}
for auto_name, auto_path in auto_pairs:
    src = read(auto_path[6:])
    for m in re.finditer(r"^signal\s+(\w+)\s*(?:\(([^)]*)\))?", src, re.M):
        args = (m.group(2) or "").strip()
        sig_arity["%s.%s" % (auto_name, m.group(1))] = (
            0 if not args else len([a for a in args.split(",") if a.strip()]))


def _params(sig: str) -> tuple[int, int] | None:
    sig = sig.strip()
    if not sig:
        return (0, 0)
    parts = [x for x in re.split(r",(?![^\[\]]*\])", sig) if x.strip()]
    return (len([x for x in parts if "=" not in x]), len(parts))


arity_bad: list[str] = []
if sig_arity:
    autos = "|".join(sorted({k.split(".")[0] for k in sig_arity}))
    conn_re = re.compile(r"(?<![A-Za-z0-9_.])(%s)\.([A-Za-z_]\w*)\.connect\(\s*(.*)" % autos)
    for path, text in ALL.items():
        if "scripts/tools/" in path.replace(os.sep, "/"):
            continue
        for i, raw in enumerate(text.splitlines(), 1):
            for m in conn_re.finditer(raw.split("#")[0]):
                key = "%s.%s" % (m.group(1), m.group(2))
                if key not in sig_arity:
                    continue
                rest = m.group(3).strip()
                if ".unbind(" in rest:
                    continue
                got = None
                lam = re.match(r"func\s*\(([^)]*)\)", rest)
                if lam:
                    got = _params(lam.group(1))
                else:
                    cm = re.match(r"(?:self\.)?([A-Za-z_]\w*)\s*[\),]", rest)
                    if cm:
                        fm = re.search(r"^func\s+%s\s*\(([^)]*)\)" % re.escape(cm.group(1)),
                                       text, re.M)
                        if fm:
                            got = _params(fm.group(1))
                            binds = len(re.findall(r"\.bind\(", rest))
                            if got and binds:
                                got = (max(0, got[0] - binds), got[1] - binds)
                if got is not None and got[1] < sig_arity[key]:
                    arity_bad.append("%s:%d %s шлёт %d, принимает %d"
                                     % (path, i, key, sig_arity[key], got[1]))
check("арность подписок на сигналы совпадает", not arity_bad, "; ".join(arity_bad[:3]))

# ── вывод ───────────────────────────────────────────────────────────────────
failed = [c for c in CHECKS if not c[1]]
width = max(len(c[0]) for c in CHECKS)
for name, ok, detail in CHECKS:
    mark = "OK  " if ok else "FAIL"
    line = "  %s  %s" % (mark, name.ljust(width))
    if detail and not ok:
        line += "   <- " + detail
    print(line)
print("\n" + "─" * 60)
if failed:
    print("Провалено: %d из %d" % (len(failed), len(CHECKS)))
else:
    print("Игровой цикл собран целиком: %d проверок пройдено." % len(CHECKS))
sys.exit(1 if failed else 0)
