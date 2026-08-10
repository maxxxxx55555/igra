# ANIMATION GUIDE — Mixamo

Анимации берутся из Mixamo (Adobe) — бесплатно, без б royalties для инди-игр.
Принцип: модель (T-pose, `.glb`/`.fbx`) загружаем на Mixamo → скачиваем FBX с
анимациями → импорт в Godot → AnimationPlayer с нормализацией имён.

## 1. Набор анимаций (GDD §18, §6.2)

Для игрока (FPS-слой) и риггед-монстров (Watcher, Hunter, Destroyer, Architect).

| Состояние / Действие | Mixamo-поиск | Имя в Godot (player.anim/weapon.anim) |
|----------------------|--------------|---------------------------------------|
| Idle                 | "rifle idle" / "pistol idle" | `idle` |
| Walk                 | "rifle walk forward" / "pistol walk" | `walk` |
| Run                  | "rifle run" | `run` |
| Shoot (Aim)          | "rifle aiming" / "pistol shoot" — даём стреляющую позицию | `shoot` |
| Reload               | "rifle reload" | `reload` |
| Hit reaction         | "hit reaction" (быстрый флинч) | `hit` |
| Death                | "death from right" / "dying" | `death` |

## 2. Пайплайн получения FBX

1. Модель: загружаем героя в формате `.glb` (плейсхолдер из `assets/models/player/`) или `.fbx`
   на https://www.mixamo.com — убедитесь, что риг содержит бунту ("auto-rigger").
2. Выбираем анимацию из списка. Подходит пресет: `Without Skin` — mesh уже есть,
   нам нужен только скелет с треками.
3. In-place: для FSM на NavigationAgent3D всегда включайте "In Place" —
   корневое смещение обрабатываем кодом в `player_fps.gd`.
4. Скачиваем: Format `FBX (.fbx)`, Frames per Second `30`, Skin `Without Skin`,
   на все 7 анимаций.

Структура каталогов:
```
assets/models/player/mixamo/idle.fbx
assets/models/player/mixamo/walk.fbx
...
assets/models/enemies/watcher/mixamo/idle.fbx
...
```

## 3. Подключение FBX в Godot

1. В Godot: **Import** → выбрать `.fbx` → Reimport.
2. В появившейся сцене `Node3D` — `Skeleton3D` + `AnimationPlayer`.
3. Переименовать треки в латинские camelCase (`mixamo.com/AnimStack` → `idle`).
4. Удалить лишние камеры/свет, если они в FBX.
5. Открыть `AnimationPlayer`, для всех loop-анимаций (`idle`, `walk`, `run`) —
   поставить цикл `Loop`, для `shoot`/`hit`/`death` — `Once`.
6. Для root motion у монстров без "In Place" — в `base_monster.gd` двигать
   `NavAgent` по `root_position_delta` трека.

## 4. Wiring к коду (минимум)

Есть `base_monster.gd` с FSM (`enum State`). Пример подключения в `_update_anim()`:

```gdscript
# Player: WeaponManager подаёт обочки в AnimationTree
# Monster: state-driven
@onready var anim_player: AnimationPlayer = $Pivot/Skeleton3D/AnimationPlayer

func set_anim(anim_name: String) -> void:
    if anim_player.current_animation == anim_name:
        return
    anim_player.play(anim_name)
```

События:
- `hit` — вызвать `EventBus.monster_hit` → `take_damage()` уже проигрывает `hit`.
- `death` — после конца клипа `anim_player.animation_finished.connect(_on_death_anim_end)` → `queue_free()`.

## 5. Чеклист (GDD §15)
- Частота кадров ≤30 FPS на трек.
- Число костей (bones) ≤65 для монстров, ≤75 для игрока.
- `AnimPlayer` в монстрах общий (на уровень) — без дублей.
- Line 0 в FBX-экспорте Mixamo: трек импортируется в `AnimationPlayer` автоматически.
