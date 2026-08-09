# THE LAST STREETLIGHT

3D FPS survival horror. Godot 4.7, GL Compatibility. Android + PC.

## Запуск

1. Открой `project.godot` в **Godot 4.7 Stable**.
2. Нажми **F5** (или кнопку Run).
3. Рендерер: **GL Compatibility** (уже настроен).

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

```bash
godot --headless --path . res://scenes/tools/compile_gate_scene.tscn
godot --headless --path . res://scenes/tools/signal_arity_check_scene.tscn
godot --headless --path . res://scenes/tools/i18n_check_scene.tscn
godot --headless --path . res://scenes/tools/asset_check_scene.tscn
```

Все должны завершиться с кодом 0.
