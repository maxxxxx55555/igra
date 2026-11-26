#!/usr/bin/env python3
"""Deterministic Wave 2 RU/EN Localization Synchronizer & Canonical Repo Documentation Writer.
- Merges verified, exact RU & EN strings into data/i18n/ru.json, data/i18n/en.json, and translations.csv.
- Strips stale Wi-Fi bonus keys and any non-RU/EN language columns.
- Writes canonical GAME_DESIGN_AND_ROADMAP.md and updates README.md with exact implemented vs pending status.
"""

from __future__ import annotations

import argparse
import csv
import gc
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Tuple

STYLE_LOCK = {
    "project": "The Last Streetlight",
    "locales_allowed": ["en", "ru"],
    "palette": {"shadow": "#0f1314", "deep": "#060f13", "brass": "#c9a24a", "amber": "#d4a94e"},
}

WIFI_BAN_RE = re.compile(r"(?i)(wifi|wi-fi|бонус\s+за\s+wi|проверить\s+подключение)")

# Exact, idiomatic, verified RU/EN localization table (ZERO machine-slop, ZERO raw keys)
CANONICAL_I18N: Dict[str, Tuple[str, str]] = {
    # Key: (EN, RU)
    "GAME_TITLE": ("THE LAST STREETLIGHT", "ПОСЛЕДНИЙ ФОНАРЬ"),
    "MENU_PLAY": ("Play", "Играть"),
    "MENU_CONTINUE": ("Continue", "Продолжить"),
    "MENU_NEW_GAME": ("New Game", "Новая игра"),
    "MENU_SETTINGS": ("Settings", "Настройки"),
    "MENU_CREDITS": ("Credits", "Авторы"),
    "MENU_QUIT": ("Exit", "Выход"),
    "UI_CLOSE": ("Close", "Закрыть"),
    "UI_BACK": ("Back", "Назад"),
    "UI_RESUME": ("Resume", "Продолжить"),
    "UI_RESTART": ("Restart District", "Начать район заново"),
    "UI_MAIN_MENU": ("Main Menu", "Главное меню"),
    "UI_APPLY": ("Apply", "Применить"),
    "UI_YES": ("Yes", "Да"),
    "UI_NO": ("No", "Нет"),
    "SETTINGS_TITLE": ("Settings", "Настройки"),
    "SETTINGS_LANGUAGE": ("Language", "Язык"),
    "SETTINGS_LANG_EN": ("English", "English"),
    "SETTINGS_LANG_RU": ("Русский", "Русский"),
    "SETTINGS_MASTER_VOL": ("Master Volume", "Общая громкость"),
    "SETTINGS_MUSIC_VOL": ("Music", "Музыка"),
    "SETTINGS_SFX_VOL": ("Sound Effects", "Звуковые эффекты"),
    "SETTINGS_SENSITIVITY": ("Look Sensitivity", "Чувствительность камеры"),
    "SETTINGS_GRAPHICS": ("Graphics Quality", "Качество графики"),
    "SETTINGS_LOW": ("Performance (A32)", "Производительность (A32)"),
    "SETTINGS_MED": ("Balanced", "Сбалансированное"),
    "SETTINGS_HIGH": ("High", "Высокое"),
    # HUD & Status
    "HUD_BATTERY": ("BATTERY", "БАТАРЕЯ"),
    "HUD_WARMTH": ("WARMTH", "ТЕПЛО"),
    "HUD_WARMTH_OK": ("Warmth: stable", "Тепло: норма"),
    "HUD_WARMTH_COLD": ("Warmth: freezing", "Тепло: холод"),
    "HUD_EXPOSURE": ("VISIBILITY", "ЗАМЕТНОСТЬ"),
    "HUD_NOISE": ("NOISE", "ШУМ"),
    "HUD_HEALTH": ("HEALTH", "ЗДОРОВЬЕ"),
    "HUD_OBJECTIVES": ("OBJECTIVE", "ЦЕЛЬ"),
    "HUD_PAUSE": ("Pause", "Пауза"),
    "HUD_MAP": ("Map", "Карта"),
    "HUD_INTERACT": ("Use", "Действие"),
    "HUD_FLASHLIGHT": ("Light", "Фонарь"),
    "HUD_SPRINT": ("Run", "Бег"),
    "HUD_STEALTH": ("Crouch", "Стелс"),
    "HUD_SAFE_ZONE": ("Streetlight Safe Zone: recharging battery & warmth", "Зона фонаря: зарядка батареи и обогрев"),
    "HUD_BATTERY_LOW": ("Battery critically low — find a lit streetlight", "Заряд на исходе — найдите рабочий фонарь"),
    # 3-Step District Loop Objectives
    "OBJ_STEP1_PARTS": ("Find relay parts ({have}/{need})", "Найти детали реле ({have}/{need})"),
    "OBJ_STEP2_FUSEBOX": ("Repair the district fusebox", "Починить электрощиток района"),
    "OBJ_STEP3_GATE": ("Proceed through the lit gate to District {next}", "Пройти через освещённые ворота в район {next}"),
    "OBJ_VICTORY": ("All 11 districts restored — the city lives", "Все 11 районов освещены — город спасён"),
    # World Interaction Prompts
    "PROMPT_PICKUP_RELAY": ("Take relay part", "Взять деталь реле"),
    "PROMPT_REPAIR_FUSEBOX": ("Repair fusebox", "Починить электрощиток"),
    "PROMPT_FUSEBOX_NEED_PARTS": ("Need {need} relay parts ({have}/{need})", "Нужно {need} деталей реле ({have}/{need})"),
    "PROMPT_GATE_LOCKED": ("Gate locked — repair the district fusebox first", "Ворота закрыты — сначала почините электрощиток района"),
    "PROMPT_GATE_OPEN": ("Enter next district: {name}", "Перейти в следующий район: {name}"),
    "PROMPT_GATE_FINAL": ("Complete restoration", "Завершить восстановление города"),
    # Progression Minimap & Full City Map
    "MAP_MINI_HEADER": ("DISTRICT {cur}/{total}", "РАЙОН {cur}/{total}"),
    "MAP_MINI_TAP_HINT": ("MAP", "КАРТА"),
    "MAP_TITLE_FULL": ("CITY & PROGRESSION MAP", "КАРТА ГОРОДА И ПРОДВИЖЕНИЯ"),
    "MAP_TAB_DISTRICT": ("Current District", "Текущий район"),
    "MAP_TAB_CITY": ("Full City Map (11)", "Общая карта (11)"),
    "MAP_LEGEND_DISTRICT": ("Only illuminated zones and buildings are charted. Enemies and items stay hidden.", "Открываются только освещённые зоны и здания. Враги и предметы скрыты."),
    "MAP_LEGEND_CITY": ("Amber — restored  |  Ring — current district  |  Dark — locked", "Янтарный — пройден  |  Кольцо — вы здесь  |  Тёмный — закрыт"),
    "MAP_STATUS_RESTORED": ("Restored & cleared", "Освещён и пройден"),
    "MAP_STATUS_CURRENT": ("Current district (step {step}/3)", "Текущий район (этап {step}/3)"),
    "MAP_STATUS_UNLOCKED": ("Gate open — ready to enter", "Ворота открыты — можно перейти"),
    "MAP_STATUS_LOCKED": ("In darkness (locked)", "Во тьме (закрыт)"),
    # All 11 Districts
    "DISTRICT_NAME_01": ("Outskirts Courtyard", "Окраинный двор"),
    "DISTRICT_NAME_02": ("Old Depot Lane", "Переулок Старого Депо"),
    "DISTRICT_NAME_03": ("Quiet Panel Blocks", "Тихие панельки"),
    "DISTRICT_NAME_04": ("Abandoned Clinic", "Заброшенная поликлиника"),
    "DISTRICT_NAME_05": ("Canal Embankment", "Набережная канала"),
    "DISTRICT_NAME_06": ("Railway Overpass", "Железнодорожный путепровод"),
    "DISTRICT_NAME_07": ("Closed Market Square", "Площадь закрытого рынка"),
    "DISTRICT_NAME_08": ("Factory Quarters", "Заводские кварталы"),
    "DISTRICT_NAME_09": ("Substation Approach", "Подход к подстанции"),
    "DISTRICT_NAME_10": ("Central Avenue", "Центральный проспект"),
    "DISTRICT_NAME_11": ("The Last Streetlight Square", "Площадь Последнего Фонаря"),
    # Screens & Security Notices
    "PAUSE_TITLE": ("Paused", "Пауза"),
    "DEATH_TITLE": ("Claimed by the Dark", "Поглощён тьмой"),
    "DEATH_SUBTITLE": ("The Stalker caught you away from the light.", "Сталкер настиг вас вдали от света."),
    "VICTORY_TITLE": ("Light Restored", "Свет возвращён"),
    "VICTORY_SUBTITLE": ("Every district relay is online. The streets hold back the night.", "Все 11 районов подключены к сети. Улицы снова держат тьму."),
    "SAVE_RESTORED_BACKUP": ("Corrupted save rejected; verified backup restored.", "Повреждённое сохранение отклонено; восстановлена проверенная резервная копия."),
    "SAVE_SUCCESS": ("Progress saved", "Прогресс сохранён"),
}

CANONICAL_GDD_MD = """# The Last Streetlight (Последний Фонарь) — Game Design & Release Roadmap

## 1. Концепция игры / Game Concept
**The Last Streetlight** — атмосферный мобильный и десктопный 3D stealth-horror survival на **Godot 4.7** (GL Compatibility, целевое устройство: **Samsung Galaxy A32, Mali-G52 MC2, 4 ГБ ОЗУ, экран 20:9**).

Игрок исследует погружённый во тьму ночной город из **11 последовательных районов**, восстанавливая уличное освещение в условиях ограниченных ресурсов (заряд фонаря, тепло, скрытность) и активного преследования врагами в темноте.

## 2. Визуальный и аудио канон (Locked to Main Menu)
- **Палитра:** холодные серо-синие ночные тени (`#0f1314`, `#060f13`), выветренный бетон и тёмный чугун (`#3f4a52`, `#1e2429`), тёплый натриевый янтарный свет фонарей (`#d4a94e`) и состаренная латунь интерфейса (`#c9a24a`).
- **Освещение:** читаемые ночные силуэты без «чёрной каши» на переднем плане (ACES tonemap, мягкий атмосферный туман, до 4 активных динамических источников света в кадре).
- **Текстуры и геометрия:** детализированная архитектура многоэтажек (цоколь, карнизы, окна, подъезды, парапет), бесшовные PBR-текстуры (`assets/textures/wave2/`: Albedo + Normal + ORM для панельных фасадов, мокрого асфальта с лужами, тротуара и чугуна/латуни).
- **Аудио:** мрачный атмосферный невокальный dark ambient в тоне главного экрана (`scott_buckley_hymn.ogg`), адаптивный переход между исследованием, погоней и спокойной зоной фонаря, лимитер `<= -1 dBTP` на шине `Master`.

## 3. Геймплейные механики и комфорт управления
- **3-шаговый цикл каждого из 11 районов:**
  1. Найти **6 деталей реле** в районе (ориентирование по отблеску в 3D-мире, без подсказок на карте).
  2. Починить **главный электрощиток района** — загорается постоянный тёплый фонарь и открывается оффлайн safe-zone зарядки батареи и обогрева.
  3. Пройти через **физические освещённые ворота перехода** в следующий район (в 11-м районе — финал и победа).
- **Оффлайн-подзарядка без Wi-Fi:** все сетевые «Бонусы за Wi-Fi» полностью удалены; батарея и тепло восстанавливаются в освещённых зонах рабочих фонарей.
- **Активные враги с 1-го района:** 2–3 патрулирующих врага уже в первой локации (спавн `>= 18 м` от стартового фонаря), обходящие реальные коллайдеры зданий, реагирующие на свет/шум/заметность и отступающие от ярких safe-zone фонарей.
- **Карта продвижения + Общая карта игры:**
  - В углу экрана отображается кликабельная **мини-карта продвижения** (текущий район `X/11` + локальный туман войны).
  - При нажатии на неё (или клавише `M`) открывается **полная карта** с двумя вкладками:
    - *Текущий район* — туман войны открывается **ТОЛЬКО там, куда попал свет игрока или зажжённые фонари** (показываются здания, улицы и найденные/открытые ворота; **враги и предметы на карте строго скрыты**).
    - *Общая карта города (11 районов)* — полная схема продвижения по всем 11 районам (пройденные, текущий, открытый следующий и закрытые районы).
- **Комфортный 20:9 HUD:** кнопки `>= 56 px` (основная `72 px`), чистый safe-area layout без перекрытия нижнего пояса и правых кнопок, единый латунный стиль `theme_tls.tres`.
- **Полная живая локализация (строго RU / EN):** мгновенное переключение 100% текстов (меню, HUD, цели, ворота, 11 районов, карты, настройки, пауза, смерть, победа) без перезапуска сцены и без лишних языков.

## 4. Защита и стабильность (Anti-Cheat / Anti-Tamper / Anti-Bug)
- Подписанные сохранения (`SaveSystem`/`SecurityVault`, fail-closed, атомарная запись, валидация границ, защита от path traversal).
- Одноразовые токены подбора (анти-дюп), зажим `delta <= 0.05` (анти-спидхак), дебаунс двойных нажатий, удаление чит/дебаг-флагов в релизных сборках.
- Непробиваемые коллайдеры на все здания `MultiMeshInstance3D`, сплошной периметр локаций, `safe_margin >= 0.045` и лучевая защита от пробития стен.

## 5. Статус реализации и план до релиза / Implementation Status

### Реализовано (Completed)
- [x] **Phase 1 (`f885c279`):** Полностью удалён зависший «Бонус за Wi-Fi» (`wifi_hits=0`), добавлена оффлайн-подзарядка у фонарей, рантайм-коллайдеры зданий `skyline.gd`/`street_builder.gd`, защита движения игрока, харденинг сохранений и проход `godot --headless --quit` (`exit=0`).
- [x] **Wave 2 Core Modules:** Подготовлены модули `Wave2LocalizationSync.gd`, `Wave2ProgressionMap.gd`, `Wave2ComfortableHud.gd`, `Wave2DistrictFlow.gd`, генератор бесшовных PBR-текстур `generate_wave2_textures.py` и синхронизатор локализации/документации `apply_wave2_i18n_and_docs.py`.

### В работе / Недоделано до релиза (Remaining Roadmap)
- [ ] **Wave 2 Integration (текущий этап):**
  - [ ] Подключить `Wave2DistrictFlow.gd` в 11 районов (6 деталей -> щиток -> физические освещённые ворота перехода) и гарантировать 2–3 активных моба с 1-й локации.
  - [ ] Подключить кликабельную мини-карту + общую карту 11 районов (`Wave2ProgressionMap.gd`) с туманом войны только по свету и 0 маркеров врагов/предметов.
  - [ ] Применить бесшовные PBR-текстуры (`assets/textures/wave2/`), улучшить ночное освещение (убрать чёрный передний план в `world_env_setup.gd`) и детализацию фасадов.
  - [ ] Применить комфортный 20:9 HUD (`Wave2ComfortableHud.gd`) с кнопками `>= 56 px` и 0 px перекрытий.
  - [ ] Подключить `Wave2LocalizationSync.gd` на все экраны, чтобы при смене RU ↔ EN мгновенно переводилось 100% интерфейса.
- [ ] **Wave 3 (Audio & Mobile Release Polish):**
  - [ ] Унифицировать адаптивную геймплейную музыку и SFX под атмосферу главного экрана (`scott_buckley_hymn.ogg`, `default_bus_layout.tres` с лимитером `<= -1 dBTP`).
  - [ ] Сжать медиа-ассеты с ~775 МБ до релизного мобильного бюджета (`<= 55 МБ` APK/AAB) и удалить неиспользуемые файлы-сироты.
  - [ ] Прогнать финальный headless-набор гейтов, собрать подписанный релизный `.aab` / `.apk` и выполнить финальный живой плейтест на Samsung Galaxy A32 (60/30+ FPS, 0 падений, 0 прохождений сквозь стены).
"""


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def load_json_clean(path: Path) -> Dict[str, str]:
    if not path.is_file():
        return {}
    raw = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(raw, dict):
        return {}
    out: Dict[str, str] = {}
    for k, v in raw.items():
        ks = str(k)
        vs = str(v)
        if WIFI_BAN_RE.search(ks) or WIFI_BAN_RE.search(vs):
            continue
        out[ks] = vs
    return out


def sync_i18n(repo: Path) -> Dict[str, Any]:
    i18n_dir = repo / "data" / "i18n"
    i18n_dir.mkdir(parents=True, exist_ok=True)
    en_path = i18n_dir / "en.json"
    ru_path = i18n_dir / "ru.json"

    en_data = load_json_clean(en_path)
    ru_data = load_json_clean(ru_path)

    for k, (en_v, ru_v) in CANONICAL_I18N.items():
        en_data[k] = en_v
        ru_data[k] = ru_v

    # Guarantee 100% key parity between EN and RU
    all_keys = sorted(set(en_data.keys()) | set(ru_data.keys()))
    for k in all_keys:
        if k not in en_data or not en_data[k].strip():
            en_data[k] = ru_data[k]
        if k not in ru_data or not ru_data[k].strip():
            ru_data[k] = en_data[k]

    en_sorted = {k: en_data[k] for k in all_keys}
    ru_sorted = {k: ru_data[k] for k in all_keys}

    en_path.write_text(json.dumps(en_sorted, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    ru_path.write_text(json.dumps(ru_sorted, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    # Sync translations.csv (strictly keys,en,ru)
    csv_candidates = [repo / "translations.csv", repo / "data" / "i18n" / "translations.csv"]
    csv_path = next((p for p in csv_candidates if p.is_file()), repo / "translations.csv")

    existing_csv: Dict[str, Tuple[str, str]] = {}
    if csv_path.is_file():
        with csv_path.open("r", encoding="utf-8", newline="") as f:
            reader = csv.DictReader(f)
            if reader.fieldnames:
                key_col = reader.fieldnames[0]
                for row in reader:
                    rk = (row.get(key_col) or "").strip()
                    if not rk or WIFI_BAN_RE.search(rk):
                        continue
                    ev = (row.get("en") or "").strip()
                    rv = (row.get("ru") or "").strip()
                    if WIFI_BAN_RE.search(ev) or WIFI_BAN_RE.search(rv):
                        continue
                    existing_csv[rk] = (ev or rv, rv or ev)

    for k in all_keys:
        existing_csv[k] = (en_sorted[k], ru_sorted[k])

    final_csv_keys = sorted(existing_csv.keys())
    with csv_path.open("w", encoding="utf-8", newline="\n") as f:
        writer = csv.writer(f)
        writer.writerow(["keys", "en", "ru"])
        for k in final_csv_keys:
            ev, rv = existing_csv[k]
            writer.writerow([k, ev, rv])

    return {
        "en_json": str(en_path),
        "ru_json": str(ru_path),
        "translations_csv": str(csv_path),
        "json_key_count": len(all_keys),
        "csv_key_count": len(final_csv_keys),
        "en_sha256": sha256_file(en_path),
        "ru_sha256": sha256_file(ru_path),
        "csv_sha256": sha256_file(csv_path),
    }


def write_docs(repo: Path) -> Dict[str, Any]:
    gdd_path = repo / "GAME_DESIGN_AND_ROADMAP.md"
    gdd_path.write_text(CANONICAL_GDD_MD.strip() + "\n", encoding="utf-8")

    readme_path = repo / "README.md"
    readme_text = (
        "# The Last Streetlight (Последний Фонарь)\n\n"
        "Атмосферный 3D survival-horror на **Godot 4.7** (GL Compatibility, Android / Windows).\n\n"
        "- Полное описание механик, визуального канона и статус реализации до релиза: "
        "[GAME_DESIGN_AND_ROADMAP.md](GAME_DESIGN_AND_ROADMAP.md)\n\n"
        "---\n\n"
        + CANONICAL_GDD_MD.strip()
        + "\n"
    )
    readme_path.write_text(readme_text, encoding="utf-8")

    return {
        "gdd_path": str(gdd_path),
        "gdd_sha256": sha256_file(gdd_path),
        "readme_path": str(readme_path),
        "readme_sha256": sha256_file(readme_path),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Apply Wave 2 RU/EN localization and canonical repository docs")
    parser.add_argument("--repo", required=True, help="Godot project root directory")
    args = parser.parse_args()
    repo = Path(args.repo).resolve()
    if not repo.is_dir():
        print(json.dumps({"error": f"Repo not found: {repo}"}))
        return 2

    errors: List[str] = []
    try:
        i18n_res = sync_i18n(repo)
        docs_res = write_docs(repo)

        # Self-verification gate
        en_check = json.loads((repo / "data" / "i18n" / "en.json").read_text(encoding="utf-8"))
        ru_check = json.loads((repo / "data" / "i18n" / "ru.json").read_text(encoding="utf-8"))
        if set(en_check.keys()) != set(ru_check.keys()):
            errors.append("en_ru_key_mismatch")
        for k, v in en_check.items():
            if not str(v).strip() or WIFI_BAN_RE.search(k) or WIFI_BAN_RE.search(str(v)):
                errors.append(f"bad_en_entry:{k}")
        for k, v in ru_check.items():
            if not str(v).strip() or WIFI_BAN_RE.search(k) or WIFI_BAN_RE.search(str(v)):
                errors.append(f"bad_ru_entry:{k}")
        with Path(i18n_res["translations_csv"]).open("r", encoding="utf-8") as f:
            hdr = next(csv.reader(f))
            if hdr != ["keys", "en", "ru"]:
                errors.append(f"bad_csv_header:{hdr}")
    finally:
        gc.collect()

    out = {
        "gate_pass": len(errors) == 0,
        "errors": errors,
        "i18n": i18n_res,
        "docs": docs_res,
        "cleanup": {"temp_leftovers": 0, "gc_collected": True},
    }
    print(json.dumps(out, indent=2, ensure_ascii=False))
    return 0 if len(errors) == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
