# RELEASE NOTES — THE LAST STREETLIGHT

## v1.0 — Финальная сборка (2026-08-09)

### Готово

#### БЛОК 1 — HUD и меню
- HUD: иконки HP/патроны/батарея/фонарик (TextureRect), плавные значения через Tween
- Главное меню: фон `menu_bg.png`, tween-появление панели
- FadeTransition: чёрный fade-out/in между экранами (CanvasLayer, автозагрузка)

#### БЛОК 2 — Геймплей-фил
- Recoil камеры при выстреле (горизонтальное + вертикальное смещение)
- Screen shake при уроне и взрывах (квадратичная кривая травмы)
- Head bob при ходьбе (амплитуда 0.03, ускорение при спринте)
- Muzzle flash (OmniLight3D + SphereMesh, 0.06 с)
- Hit spark (6 искр в точке попадания, 0.25 с)
- Footstep dust (4 частицы пыли при шаге, 0.3 с)
- Телеграф атаки врага: двойная вспышка + sfx за 0.4 с до удара

#### БЛОК 3 — UI/UX
- Settings: слайдеры Master/Music/SFX/Voice, качество графики (low/med/high), чувствительность мыши; сохранение в `user://settings.cfg`
- Tutorial: 10 шагов (движение, фонарик, interact и др.), показ один раз (`user://tutorial.cfg`)
- Pause menu: затемнение фона, tween-появление, Resume/Settings/Restart/Quit
- Damage vignette: красная кайма при HP < 30%, синусоидальный пульс

#### БЛОК 4 — Производительность
- Object pool (`ObjectPool` автозагрузка): универсальный пул для врагов/пикапов/частиц
- Light limiter (`LightLimiter` автозагрузка): не более 8 видимых OmniLight3D
- Culling (`VisibilityEnabler` компонент): VisibleOnScreenNotifier3D для врагов/пропсов
- FPS cap 60 (`run/max_fps=60` в project.godot)

#### Текстуры окружения (ФАЗА 4A)
- Дорога: `asphalt.png` (roughness 0.9)
- Тротуар: `concrete.png` (roughness 0.9)
- Стены зданий: `brick.png`, `rusty_metal.png` (через `CityStreetProps.make_wall_mesh()`)

### Требует ручного подключения
- `FadeTransition` → добавить в Autoload (Project Settings)
- `ObjectPool`, `LightLimiter` → добавить в Autoload
- `scenes/ui/hud.tscn` → инстанцировать в основную игровую сцену
- `DamageVignette` → добавить как дочерний узел HUD
- `VisibilityEnabler` → добавить к сценам врагов/пропсов
- `project.godot`: добавить `run/max_fps=60` в секцию `[application]`
- `base_monster.gd`: подключить `MonsterTelegraph` (см. `progress.md`)

### Blocked (требуют внешних ассетов)
- `assets/ui/ui_health.svg`, `ui_ammo.svg`, `ui_battery.svg`, `ui_flashlight.svg` — иконки HUD
- `assets/art/menu_bg.png` — фон главного меню
- `assets/audio/sfx/sfx_enemy_warn.wav` — звук телеграфа атаки
- `assets/textures/environment/asphalt.png`, `concrete.png`, `brick.png`, `rusty_metal.png`
