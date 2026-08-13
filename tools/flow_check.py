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

import glob
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

# ── 2b. Внутри игровой сцены ничто не уводит игрока обратно ─────────────────
# Splash инстанцируется и как отдельная сцена, и как узел main_3d.tscn.
# Если он безусловно вызывает Routes.goto(...), то уровень сам себя закрывает
# через 3 секунды — игра становится непроходимой.
main3d = read("scenes/main_3d.tscn")
splash = read("scripts/splash.gd")
check("заставка в игре выключена", "show_splash = false" in main3d,
      "иначе логотип перекрывает уровень")
check("заставка не уводит из игровой сцены",
      "get_tree().current_scene == self" in splash,
      "Routes.goto из узла main_3d выкидывал игрока на экран загрузки")

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
check("HUD обновляет слоты после подбора",
      "inventory_changed.connect" in hud,
      "счётчики рисовались один раз в _ready() и навсегда оставались нулями")
player = read("scripts/player/player_3d.gd")
check("игрок отдаёт уровень шума", "func get_noise_level" in player)
# Аптечка и батарейка обязаны что-то делать: инвентарь только СПИСЫВАЕТ предмет
# и шлёт item_consumed, а лечит и заряжает уже сам игрок.
check("расходники лечат и заряжают игрока",
      "item_consumed.connect" in player,
      "слушателем был только 2D-контроллер, которого нет в игровой сцене")
# Стелс — основная механика жанра: спрятавшегося игрока видеть нельзя.
check("зрение монстра учитывает заметность игрока",
      '"visibility" in player_ref' in read("scripts/enemies/base_monster.gd"),
      "иначе укрытия декоративные — монстр видит сквозь шкаф")
check("укрытия расставляются в районах",
      "_spawn_hiding_spots" in read("scripts/world/district_scene_factory.gd"),
      "класс HidingSpot есть, но прятаться негде")

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
# Победа — такая же цепочка сигнал -> слушатель, как и смерть, и рвётся так же
# незаметно: босс шлёт boss_defeated, а вызывает trigger_win() уже FinaleDirector.
check("победа над боссом кем-то обрабатывается", len(listeners("boss_defeated")) > 0,
      ", ".join(listeners("boss_defeated")))
check("обработчик боссa зовёт trigger_win",
      "trigger_win()" in read("scripts/world/finale_director.gd"))
check("состояние WIN достижимо", "func trigger_win" in gm)
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
    if os.sep + ".git" in base:
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

# ── 11. Сигналы критического пути обязаны иметь слушателя ───────────────────
# Именно так ломались смерть игрока (game_over) и едва не сломалась победа:
# сигнал шлётся, слушателя нет, и ничего не происходит — без единой ошибки.
CRITICAL_SIGNALS = [
    "game_over", "game_won", "boss_defeated", "game_started",
    "game_state_changed", "item_picked_up", "inventory_changed",
    "player_health_changed", "player_battery_changed", "toast_requested",
    "hud_visibility_changed", "district_entered",
]
deaf = [s for s in CRITICAL_SIGNALS if not listeners(s)]
check("у сигналов критического пути есть слушатели", not deaf, ", ".join(deaf))

# ── 12. Автозагрузки ищут только в /root ────────────────────────────────────
# Классика этого репозитория: player.get_node_or_null("InventoryManager").
# Автолоад — ребёнок /root, а не игрока, поэтому поиск ВСЕГДА возвращает null,
# и ветка с подбором ключа или открытием двери молча не выполняется.
autoload_names = {n for n, _ in auto_pairs}
wrong_lookup: list[str] = []
for path, text in ALL.items():
    for i, raw in enumerate(text.splitlines(), 1):
        for m in re.finditer(r'(\w+)\.get_node(?:_or_null)?\(\s*"(\w+)"\s*\)',
                             raw.split("#")[0]):
            if m.group(2) in autoload_names and m.group(1) != "root":
                wrong_lookup.append("%s:%d %s.get_node(\"%s\")"
                                    % (path, i, m.group(1), m.group(2)))
check("автозагрузки ищутся в /root, а не в чужом узле", not wrong_lookup,
      "; ".join(wrong_lookup[:3]))

# ── 13. Интерактивные объекты попадают в группу "interactable" ──────────────
# Interactor обходит именно эту группу. Объект с interact(), который в неё не
# встал, физически недостижим: подойти и нажать клавишу невозможно.
not_grouped: list[str] = []
for path, text in ALL.items():
    if not re.search(r"^func interact\s*\(", text, re.M):
        continue
    if 'add_to_group("interactable")' in text:
        continue
    scene_has_group = any(
        'groups=["interactable"' in s or '"interactable"' in s
        for p2, s in ALL.items()
        if p2.endswith(".tscn") and path.split("/")[-1] in s)
    if not scene_has_group:
        not_grouped.append(path)
# Осиротевшие скрипты сюда не считаем: они и так вне игры.
baseline_orphans: set[str] = set()
_bp = os.path.join(ROOT, "tools", "orphan_baseline.txt")
if os.path.exists(_bp):
    baseline_orphans = {l.strip() for l in open(_bp, encoding="utf-8")
                        if l.strip() and not l.startswith("#")}
not_grouped = [p for p in not_grouped if p not in baseline_orphans]
check("объекты с interact() состоят в группе interactable", not not_grouped,
      ", ".join(not_grouped[:3]))

# ── 14. Число аргументов в вызовах методов автолоадов ───────────────────────
# Лишний или недостающий аргумент — ошибка времени выполнения, которую
# компилятор пропускает при динамическом обращении.
def _call_arity(text: str) -> int:
    depth = 0
    count = 0
    current = ""
    for ch in text:
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            if depth == 0:
                break
            depth -= 1
        if ch == "," and depth == 0:
            count += 1
            current = ""
            continue
        current += ch
    if current.strip() or count > 0:
        count += 1
    return count


def _func_sigs(rel: str, seen: set[str] | None = None) -> dict[str, tuple[int, int]]:
    if seen is None:
        seen = set()
    if rel in seen:
        return {}
    seen.add(rel)
    src = read(rel)
    out: dict[str, tuple[int, int]] = {}
    for m in re.finditer(r"^(?:static\s+)?func\s+(\w+)\s*\(([^)]*)\)", src, re.M):
        params = [p.strip() for p in re.split(r",(?![^\[\]]*\])", m.group(2)) if p.strip()]
        out[m.group(1)] = (len([p for p in params if "=" not in p]), len(params))
    ext = re.search(r'^extends\s+"res://([^"]+)"', src, re.M)
    if ext:
        for k, v in _func_sigs(ext.group(1), seen).items():
            out.setdefault(k, v)
    return out


auto_sigs = {n: _func_sigs(p[6:]) for n, p in auto_pairs}
call_bad: list[str] = []
if auto_sigs:
    call_re = re.compile(r'(?<![\w."\'])(%s)\.(\w+)\('
                         % "|".join(sorted(auto_sigs, key=len, reverse=True)))
    for path, text in ALL.items():
        for i, raw in enumerate(text.splitlines(), 1):
            code = raw.split("#")[0]
            for m in call_re.finditer(code):
                sig = auto_sigs.get(m.group(1), {}).get(m.group(2))
                if sig is None:
                    continue
                got = _call_arity(code[m.end():])
                if got < sig[0] or got > sig[1]:
                    call_bad.append("%s:%d %s.%s ждёт %d..%d, передано %d"
                                    % (path, i, m.group(1), m.group(2),
                                       sig[0], sig[1], got))
check("число аргументов в вызовах автозагрузок верное", not call_bad,
      "; ".join(call_bad[:3]))

# ── 15. save / load / reset должны знать об одних и тех же подсистемах ──────
# Подсистема, которую сохраняют и загружают, но забыли сбросить, протекает
# из прошлого забега в новую игру: уровень, опыт и дерево навыков так и
# оставались от предыдущего прохождения.
_save_src = read("scripts/core/save_system.gd")


def _fn_body(name: str) -> str:
    m = re.search(r"^func %s\([^)]*\)[^:]*:\n((?:(?:\t.*)?\n)*)" % re.escape(name),
                  _save_src, re.M)
    return m.group(1) if m else ""


_save_body = _fn_body("_save")
_load_body = _fn_body("load_all")
_reset_body = _fn_body("reset_all")
# SettingsManager: настройки принадлежат игроку, а не забегу.
# SaveSystem: это он сам — имя попадает в тело собственных методов.
_RESET_EXEMPT = {"SettingsManager", "SaveSystem"}
persisted = {n for n, _ in auto_pairs
             if n in _save_body and n in _load_body} - _RESET_EXEMPT
never_reset = sorted(n for n in persisted if n not in _reset_body)
check("новая игра сбрасывает весь сохраняемый прогресс", not never_reset,
      ", ".join(never_reset))

# ── 16. Быстрое сохранение и слоты хранят одно и то же ──────────────────────
# Это два независимых блока кода с одинаковым смыслом, и они расходятся:
# в слот забыли положить район, и загрузка слота возвращала игрока в
# стартовые пригороды.
_slot_save = _fn_body("save_slot")
_slot_load = _fn_body("load_slot")
_quick_keys = set(re.findall(r'"(\w+)":', _save_body))
_slot_keys = set(re.findall(r'"(\w+)":', _slot_save)) - {"timestamp"}
_quick_read = set(re.findall(r'data\.get\("(\w+)"', _load_body))
_slot_read = set(re.findall(r'data\.get\("(\w+)"', _slot_load))
key_gap = sorted((_quick_keys - _slot_keys) | (_slot_keys - _quick_keys)
                 | (_quick_read - _slot_read))
check("быстрое сохранение и слоты хранят одинаковый набор данных",
      not key_gap, "расходятся ключи: " + ", ".join(key_gap))

# ── 17. Финал доступен после загрузки и во втором прохождении ───────────────
# district_restored при загрузке не эмитится, поэтому сейв с 11 районами на
# стадии FULL оставлял игрока в восстановленном городе без босса. А флаг
# _triggered без сброса лишал Архитектора и вторую игру подряд.
_finale = read("scripts/world/finale_director.gd")
_load_paths = [p for p in ("load_all", "load_slot")
               if "_resume_finale()" not in _fn_body(p)]
check("финал перепроверяется после загрузки сохранения",
      "func _resume_finale" in _save_src and not _load_paths,
      "нет вызова _resume_finale() в: " + ", ".join(_load_paths))
check("финал сбрасывается при новой игре",
      "func reset" in _finale and "fd.reset()" in _reset_body,
      "иначе второе прохождение идёт без босса")

# ── 18. Кто ставит паузу — работает во время паузы ─────────────────────────
# Узел с режимом PAUSABLE, который сам зовёт get_tree().paused = true,
# замораживает собственные кнопки и await: снять паузу становится нечем.
_pausers = []
for _p in sorted(glob.glob("scripts/**/*.gd", recursive=True)):
    _src = read(_p)
    if "paused = true" in _src and "PROCESS_MODE_ALWAYS" not in _src:
        _pausers.append(_p)
check("экраны, ставящие паузу, продолжают работать во время неё",
      not _pausers, "нет PROCESS_MODE_ALWAYS: " + ", ".join(_pausers))

# ── 19. Замедление времени всегда откатывается ─────────────────────────────
# Engine.time_scale — глобальное состояние. Если узел замедлил время и ждёт
# таймер, а таймер этого замедления не игнорирует (или узел встал на паузу),
# время так и останется замедленным: игра выглядит зависшей.
_slowers = []
for _p in sorted(glob.glob("scripts/**/*.gd", recursive=True)):
    _src = read(_p)
    if not re.search(r"Engine\.time_scale\s*=\s*(?!1\.0)", _src):
        continue
    if "PROCESS_MODE_ALWAYS" not in _src:
        _slowers.append(_p + " (нет PROCESS_MODE_ALWAYS)")
    elif re.search(r"await .*create_timer\(\s*[^,)]+\s*\)", _src):
        _slowers.append(_p + " (таймер не игнорирует time_scale)")
check("замедление времени не может залипнуть навсегда",
      not _slowers, "; ".join(_slowers))

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
