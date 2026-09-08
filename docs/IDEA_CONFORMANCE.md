# IDEA.md → код: аудит соответствия

Сверка исходного описания игры (`IDEA.md`) с фактическим состоянием
репозитория. Дата аудита: 2026-09-07. Всё, что ниже, проверено по файлам
(пути и строки указаны), а не по памяти отчётов.

Легенда: **✔** — как в описании, **~** — реализовано иначе (осознанно),
**✗** — не реализовано.

## Ядро

| Пункт IDEA.md | Статус | Где |
|---|---|---|
| Godot 4.7.stable | ✔ | `project.godot`: `config/features=PackedStringArray("4.7", ...)` |
| 3D FPS, камера от первого лица | ✔ | `scenes/main_3d.tscn` → `Camera3D`; `player_3d.gd::_is_fps_view()`, `set_fps(true)` |
| GDScript, строгая типизация | ~ | 3630 типизированных `var` против 309 с выводом типа (`var x = ...`); `var x` без типа и без инициализатора в новых файлах не встречается |
| **Mobile renderer** | ✗ | `renderer/rendering_method="gl_compatibility"` — осознанное отклонение, см. ниже |

## Core mechanics

| Пункт | Статус | Где |
|---|---|---|
| Player: `CharacterBody3D` | ✔ | `scenes/player/player_3d.tscn:124` |
| WASD + мышь на ПК | ✔ | actions `move_*` в `project.godot`; `player_3d.gd::_apply_look()` |
| Виртуальные джойстики + тач-кнопки | ~ | `scripts/ui/virtual_joystick.gd` (Control, не `TouchScreenButton`) + `BtnAttack/Sprint/Stealth/Interact/Jump/Flash/Strobe/Wheel/Shoot/Reload/SwapWeapon` в `hud_3d.gd` |
| Weapons: hitscan через `RayCast3D` | ✔ | `weapon_base.gd::hitscan_ray()`; лучи в `weapon_pistol/rifle/shotgun.tscn`; маска = 3 (монстры на слое 2) |
| Reload system | ✔ | `weapon_base.gd::try_reload(reserve)` + `_finish_reload()`; ввод: `R` / `BtnReload` → `InputService.reload_requested` |
| Ammo inventory | ✔ | `data/items/ammo.tres` (универсальные патроны, GDD §17) → `InventoryManager`; резерв читает `weapon_manager.gd::get_reserve()` |
| Enemies: состояния Idle/Patrol/Chase/Attack/Dead | ✔ | `base_monster.gd:7` — `enum State { IDLE, PATROL, INVESTIGATE, CHASE, ATTACK, FLEE, STUN, DEAD }` (на три состояния больше, чем в описании) |
| `NavigationAgent3D` | ✔ | `base_monster.gd`, `minion.gd`, `main_3d.gd`, `scenes/enemies/{destroyer_3d,boss_architect_3d}.tscn` |
| Тёмный город, фонарик `SpotLight3D`, туман | ✔ | `player_3d.tscn:184` (`Flashlight`), `district_themes.gd:40` / `fog_setup.gd:15` (`fog_enabled`), `night_env.gd` |
| Health/damage: `HealthComponent` на игроке и врагах | ~ | Здоровье живёт inline: `player_3d.gd` (`hp`, `take_damage(amount, src_pos, type)`, `StatusEffects`) и `base_monster.gd` (статы из `data/balance/enemy_stats.tres`, сопротивления по `DamageType`, статусы). Скрипт `scripts/components/health_component.gd` существует, но не подключён ни к одной сцене — см. «Отклонения» |
| Levels: процедурные/ручные уличные блоки | ✔ | 11 сцен в `scenes/districts/`, узел `StreetBuilder` (`scripts/world/street_builder.gd` + `district_layouts.gd`), пропсы/грейдинг довязывает `world_bootstrap.gd` |

## Project structure

| Пункт | Статус | Факт |
|---|---|---|
| `scenes/player/` — сцена, камера, оружие | ✔ | `player_3d.tscn`; `WeaponManager` + 3 ствола теперь дети игрока |
| `scenes/enemies/` | ✔ | 13 сцен врагов |
| `scenes/levels/` | ~ | уровни лежат в `scenes/districts/` и `scenes/world/` |
| `scenes/ui/` — HUD, меню, тач-управление | ✔ | `hud_3d.tscn`, `main_menu.tscn`, `touch`-кластер `BottomLeft/BottomRight` |
| `scripts/autoload/` — GameState, SaveManager, AudioManager | ~ | автозагрузки (53 активных) лежат в `scripts/core/` (`game_manager.gd`, `save_system.gd`) и `scripts/systems/` (`audio_manager.gd`) |
| `scripts/components/` — Health, Damage, Interactable | ~ | жив только `visibility_enabler.gd` (3 сцены врагов); `health_component.gd`, `attack_component*.gd`, `procedural_anim.gd` не подключены. Дубль этого каталога в корне (`components/`, 4 мёртвых файла) удалён 2026-09-07 |
| `assets/models/`, `assets/textures/`, `assets/audio/` | ✔ | `assets/` (текстуры/аудио/UI/шейдеры); модели — процедурные меши и CSG |

## Android

| Пункт | Статус | Где |
|---|---|---|
| `TouchScreenButton` для движения и камеры | ~ | вместо него `Control`-джойстик (`virtual_joystick.gd`, пишет в `InputService`) и drag-обзор в `player_3d.gd::_unhandled_input` (`InputEventScreenDrag`) |
| Пресет Android, min SDK 29, target 34 | ✔ | `export_presets.cfg`: `min_sdk=29`, `target_sdk=34` |
| 3D scaling 0.85 | ✔ | `project.godot`: `scaling_3d/scale=0.85`; `export_presets.cfg`: `screen/scale=0.85` |
| 60 FPS cap | ✔ | `project.godot`: `run/max_fps=60` |
| Пауза при сворачивании | ✔ | `game_manager.gd::_notification(NOTIFICATION_APPLICATION_FOCUS_OUT)` → `pause_game()` + экран паузы + `save_slot(4)` |
| Автосейв | ✔ | `save_system.gd`: `AUTOSAVE_INTERVAL = 30.0` → `save_slot(4)`, плюс сейв на чекпоинтах/событиях |

## Code style

| Пункт | Статус | Комментарий |
|---|---|---|
| Строгая типизация | ~ | см. «Ядро»: ~92% объявлений типизированы |
| `@export` для параметров | ✔ | напр. `weapon_base.gd`, `player_3d.gd`, `district_data.gd` |
| `class_name` для переиспользуемого | ✔ | `WeaponBase`, `WeaponManager`, `ItemData`, `LootTable`, `DistrictLoot`, `ItemPickup3D` и др. |
| Сигналы для слабой связности | ✔ | `scripts/events/event_bus.gd` (86 сигналов), арность проверяет `signal_arity_check_scene.tscn` |

## Do NOT use

| Запрет | Статус | Комментарий |
|---|---|---|
| Физические пули (rigid bodies) | ✔ | ветка спавна `bullet_scene` удалена из `weapon_base.gd` (2026-09-07); весь урон — хитскан |
| Compatibility renderer | ✗ | стоит `gl_compatibility` — осознанно, см. ниже |
| Нетипизированные переменные | ~ | 309 объявлений с выводом типа остаются; в новых файлах волны — 0 |

## Осознанные отклонения (и почему)

1. **Рендерер `gl_compatibility` вместо Mobile.** Описание требует Mobile и
   запрещает Compatibility. Против переключения два факта из репозитория:
   в `export_presets.cfg` есть пресет **Web** (в Godot 4 веб-экспорт работает
   только на Compatibility), и весь проект тюнингован под слабые Android
   (`scaling_3d/scale`, `mesh_lod`, `LightLimiter`, `QualityManager`).
   Правка — одна строка, но проверять её не на чем: ни устройства, ни движка
   в текущей среде нет. **Вопрос к хозяину**, а не молчаливое решение.
2. **`HealthComponent` не подключён к игроку и врагам.** Универсальный узел
   из описания умеет только `take_damage(int)`/`heal(int)`. Реальная система
   богаче: типы урона (`EnemyRosterData.DamageType`), сопротивления из
   `enemy_stats.tres`, статусы (`status_effects.gd`), сетевые RPC
   (`_request_player_damage`). Переводить игрока и 13 врагов на узел — значит
   либо потерять это, либо переписать боевую систему. Оставлено как есть;
   мёртвый дубль компонента в корне удалён.
3. **Тач-управление на `Control`, а не `TouchScreenButton`.** `Control` даёт
   тему, локализацию и drag-обзор одним кодом; `TouchScreenButton` потребовал
   бы отдельного слоя ввода поверх CanvasLayer HUD. Поведение из описания
   (джойстик + кнопки) при этом есть.
4. **Каталоги `scenes/levels/` и `scripts/autoload/` не создавались.** Игра
   оперирует районами (`scenes/districts/`, 11 штук), а автозагрузки давно
   разложены по `scripts/core/` и `scripts/systems/` (53 штуки). Переезд
   каталогов сломал бы `res://`-пути в 100+ файлов без выигрыша для игрока.

## Что осталось из описания

- Рендерер: решение за хозяином (п. 1).
- 309 нетипизированных объявлений — технический долг, чинится порциями.
- `scripts/components/`: оставить как задел или добить до реального слоя
  компонентов — вопрос дизайна, не баг.
