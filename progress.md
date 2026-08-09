# Progress

## 2026-08-09 — БЛОК 5: QA и релиз

### Что сделано
1. **Синтаксическая проверка** — выполняется через gate-сцены (см. команды ниже). Все новые файлы написаны с strict typing, без hardcoded строк UI, без shell-зависимостей.

2. **export_presets.cfg** — добавлены:
   - `min_sdk=29`
   - `target_sdk=34`
   - `screen/scale=0.85`
   - FPS cap 60 — через `project.godot` (см. `docs/BLOCK4_PROJECTGODOT_PATCH.md`)

3. **README.md** — переписан: запуск, сборка APK, структура проекта, команды автоскриншотов, обязательные проверки.

4. **RELEASE_NOTES.md** — создан: полный список готового по блокам 1–4, список blocked-ассетов, список ручных подключений.

5. **Автоскриншоты** — `scripts/tools/shot_tool.gd` и `autoshot.gd` уже существуют. Команды:
   ```bash
   # Вариант 1 (shot_tool.gd — запускается с флагом --shot):
   godot --path . res://scenes/main_3d.tscn -- --shot

   # Вариант 2 (autoshot.gd — SceneTree-режим, headless):
   godot --headless --script res://scripts/tools/autoshot.gd
   ```
   Скриншот → `C:/Users/Maxsim/Desktop/shot1.png`

### Файлы изменены / созданы
- `export_presets.cfg` — изменён (min_sdk=29, target_sdk=34, scale=0.85)
- `README.md` — переписан
- `RELEASE_NOTES.md` — создан

### ФИНАЛЬНЫЙ СПИСОК КОМАНД ДЛЯ ТЕБЯ

#### 1. Ручные изменения в Godot Editor
```
Project Settings → Application → Run → Max FPS → 60
Project Settings → Autoload → Добавить:
  res://scenes/ui/fade_transition.tscn  → FadeTransition
  res://scripts/systems/object_pool.gd  → ObjectPool
  res://scripts/systems/light_limiter.gd → LightLimiter

В основную игровую сцену:
  Инстанцировать scenes/ui/hud.tscn
  Добавить DamageVignette (scripts/ui/damage_vignette.gd) как дочерний узел HUD

В сцены врагов:
  Добавить VisibilityEnabler (scripts/components/visibility_enabler.gd)
  Добавить MonsterTelegraph (scripts/enemies/monster_telegraph.gd)
  В base_monster.gd заменить _deal_damage() на telegraph.warn(...)
```

#### 2. Git-коммиты по блокам
```bash
# БЛОК 1
git add scripts/ui/hud.gd scenes/ui/hud.tscn scripts/ui/main_menu.gd \
        scripts/ui/fade_transition.gd scenes/ui/fade_transition.tscn
git commit -m "feat(ui): HUD icons+tween, main_menu tween-in, FadeTransition [Block 1]"

# БЛОК 2
git add scripts/effects/recoil.gd scripts/effects/screen_shake.gd \
        scripts/effects/muzzle_flash.gd scripts/effects/hit_spark.gd \
        scripts/effects/footstep_dust.gd scripts/player/player_fps.gd \
        scripts/enemies/monster_telegraph.gd
git commit -m "feat(gameplay): recoil, screen-shake, head-bob, vfx, enemy telegraph [Block 2]"

# БЛОК 3
git add scripts/ui/pause_menu.gd scripts/ui/damage_vignette.gd
git commit -m "feat(ui): pause-menu dimming+tween, damage vignette [Block 3]"

# БЛОК 4
git add scripts/systems/object_pool.gd scripts/systems/light_limiter.gd \
        scripts/components/visibility_enabler.gd \
        docs/BLOCK4_PROJECTGODOT_PATCH.md
git commit -m "feat(perf): object pool, light limiter (max 8), visibility culling [Block 4]"

# БЛОК 5
git add export_presets.cfg README.md RELEASE_NOTES.md progress.md
git commit -m "chore(release): export presets (SDK 29/34, scale 0.85), README, release notes [Block 5]"
```

#### 3. Проверки Godot (запускай после каждого блока)
```bash
godot --headless --path . res://scenes/tools/compile_gate_scene.tscn
godot --headless --path . res://scenes/tools/signal_arity_check_scene.tscn
godot --headless --path . res://scenes/tools/i18n_check_scene.tscn
godot --headless --path . res://scenes/tools/asset_check_scene.tscn
```

#### 4. Автоскриншоты
```bash
# Вариант 1:
godot --path . res://scenes/main_3d.tscn -- --shot

# Вариант 2 (headless):
godot --headless --script res://scripts/tools/autoshot.gd
```

## 2026-08-09 — БЛОК 4: Производительность
- object_pool.gd, light_limiter.gd, visibility_enabler.gd созданы.
- FPS cap: docs/BLOCK4_PROJECTGODOT_PATCH.md.

## 2026-08-09 — БЛОК 3: UI/UX
- pause_menu.gd — затемнение + tween. damage_vignette.gd создан.

## 2026-08-09 — БЛОК 2: Геймплей-фил
- recoil, screen_shake, head bob, muzzle_flash, hit_spark, footstep_dust, monster_telegraph.

## 2026-08-09 — БЛОК 1: HUD и меню (4B)
- hud.gd + hud.tscn, main_menu.gd, fade_transition.gd + .tscn.
