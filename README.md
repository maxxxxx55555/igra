# THE LAST STREETLIGHT

3D FPS survival horror. Godot 4.7, GL Compatibility. Android + PC.

## Запуск

1. Открой `project.godot` в **Godot 4.7 Stable**.
2. Дождись импорта ассетов (первое открытие — 156 файлов).
3. Нажми **F5** (или кнопку Run).
4. Рендерер: **GL Compatibility** (уже настроен).

> **Первый запуск после клонирования:** пройди
> [`docs/FINAL_CHECKLIST.md`](docs/FINAL_CHECKLIST.md) — там шаг за шагом
> описано, как сгенерировать и закоммитить `.import`/`.uid`, и что проверить
> глазами (раскладка HUD, свет, положение укрытий).

## Сборка APK (Android)

### Требования
- Godot 4.7 с Android Export Template
- Android SDK (min SDK 29, target SDK 34)
- JDK 17+
- Keystore (debug: `tls_debug.keystore`)

### Команды
```bash
# Экспорт APK через Godot CLI:
godot --headless --export-debug "Android" build/TLS.apk

# Или через редактор:
# Project → Export → Android → Export Project
```

### Параметры сборки
| Параметр | Значение |
|---|---|
| Min SDK | 29 |
| Target SDK | 34 |
| 3D Scale | 0.85 |
| FPS Cap | 60 |
| Renderer | GL Compatibility |

## Структура проекта

```
scenes/          — сцены (.tscn)
scripts/         — GDScript (.gd)
  core/          — EventBus, GameManager
  ui/            — HUD, меню, настройки
  player/        — player_fps.gd
  enemies/       — base_monster.gd
  effects/       — recoil, screen_shake, vfx
  systems/       — object_pool, light_limiter, settings_manager
  components/    — visibility_enabler
assets/          — текстуры, звуки, шрифты, UI
data/            — i18n, конфиги
docs/            — GDD, арт-библия, прогресс
```

## Автоскриншоты

```bash
# Скриншот через shot_tool.gd (запускается с флагом --shot):
godot --path . res://scenes/main_3d.tscn -- --shot

# Скриншот через autoshot.gd (SceneTree-режим):
godot --headless --script res://scripts/tools/autoshot.gd
```

Скриншот сохраняется в `C:/Users/Maxsim/Desktop/shot1.png`.

## Обязательные проверки перед коммитом

### Статические (Godot не нужен, ~1.5 минуты)

```bash
./tools/check.sh --static          # весь набор, ~1.5 мин
./tools/check.sh --static --fast   # без gdparse, ~2 секунды
```

Одной командой прогоняет весь набор:

| Проверка | Что ловит |
|---|---|
| `scene_node_check.py` | комментарии в `.tscn` (формат их не поддерживает и молча теряет ноды), ресурсы в роли `[node]`, `$NodePath` в никуда |
| `flow_check.py` | цепочку меню → уровень → подбор → пауза → смерть/победа → меню: сигнал без слушателя, битый `preload`, несовпадение арности, экран паузы, замороженный вместе с деревом |
| `orphan_check.py` | файлы, на которые не осталось ни одной ссылки (следит, чтобы список не рос) |
| локализация | паритет 13 языков, ключи из кода, `%`-плейсхолдеры |

Код возврата 0 — всё зелёное.

### В движке (нужен Godot 4.7)

```bash
./tools/check.sh                     # статические + гейты в движке
GODOT=/path/to/godot ./tools/check.sh
```

Отдельные гейты:

```bash
godot --headless --path . res://scenes/tools/compile_gate_scene.tscn
godot --headless --path . res://scenes/tools/signal_arity_check_scene.tscn
godot --headless --path . res://scenes/tools/i18n_check_scene.tscn
godot --headless --path . res://scenes/tools/asset_check_scene.tscn
```

Все должны завершиться с кодом 0.

## Первый запуск после клонирования

При первом открытии проекта Godot импортирует ассеты и создаёт рядом с ними
файлы `.import` и `.uid`, а также каталог `.godot/`. **Файлы `.import` и `.uid`
нужно коммитить** — без них следующий клон получает сотни предупреждений
`ext_resource, invalid UID ... using text path instead`, а ассеты
переимпортируются с настройками по умолчанию. В `.gitignore` игнорируется
только `.godot/` — так предписывает официальная документация для Godot 4.1+.

Если предупреждения об UID всё-таки появились: закройте редактор, удалите
каталог `.godot/` и откройте проект заново.
