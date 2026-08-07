# THE_LAST_STREETLIGHT — MEGA AI Rules (Godot 4.3+ 3D Android)
# Паттерны извлечены из: GDQuest Design Patterns, Metroidvania-System, Dialogue Manager,
# Inventory System, LimboAI, Phantom Camera, Gaea, Netfox, Godot Demos

## 1. CORE PHILOSOPHY
Before writing ANY code: 1) Need? 2) Built-in node? 3) stdlib? 4) One line? 5) Write minimum.
NEVER cut: validation, error handling, security.

## 2. GDSCRIPT STANDARDS
- Static typing: `var health: int = 100`, `func _ready() -> void:`
- `@export` for inspector, `@onready var node: Type = $Path`
- `preload()` in _ready, `load()` only dynamic
- Signals: `signal health_changed(new_health)` — NEVER direct parent calls
- `enum State {IDLE, WALK, ATTACK}` + `match current_state:`
- `await` (NEVER `yield`), `is_instance_valid()`, `class_name`

## 3. 3D MOVEMENT & PHYSICS (from godot-4-3d-third-person-controller)
- `CharacterBody3D` + `move_and_slide()`
- Gravity: `velocity += get_gravity() * delta` — NEVER hardcode 9.8
- Slope handling: `get_floor_angle()`, `get_floor_normal()`
- Jump buffering: queue jump if pressed 0.1s before landing
- Coyote time: allow jump 0.1s after leaving platform
- Air control: reduce `speed` multiplier to 0.3 in air

## 4. ANDROID OPTIMIZATION
- ETC2/ASTC textures, LOD, Occlusion Culling, LightmapGI
- Touch: `InputEventScreenTouch`, `InputEventScreenDrag`
- UI anchors, 80px buttons, `process_mode = PROCESS_MODE_ALWAYS` on pause menu
- Target 30-60 FPS, monitor `Engine.get_frames_per_second()`

## 5. STATE MACHINE (from godot-design-patterns)
- Use `enum State {IDLE, RUN, JUMP, ATTACK, HURT, DEAD}`
- `match current_state:` in `_physics_process`
- `change_state(new_state)` func: exit old → enter new
- Each state: separate script extending `State` class OR `match` branches
- `AnimationTree` StateMachine: `playback.travel("Run")` for visual editing

## 6. OBSERVER PATTERN (from godot-design-patterns)
- NEVER call `get_parent().take_damage()` — use `signal enemy_died`
- Global events: `EventBus` Autoload with `signal player_health_changed(amount)`
- Connect: `EventBus.player_health_changed.connect(_on_health_changed)`
- Disconnect in `_exit_tree()` to avoid errors

## 7. COMMAND PATTERN (from godot-design-patterns)
- Store actions as `Resource` or `Dictionary`: `{ "action": "move", "target": pos }`
- Undo/Redo: `Array[Dictionary]` history, `undo()` pops last and reverses
- Replay system: record input + timestamp, playback frame-by-frame

## 8. COMPONENT PATTERN (from godot-design-patterns)
- Instead of inheritance: `Node` children as components
- `HealthComponent` (extends Node): `@export var max_health: int`
- `AttackComponent` (extends Node): `func attack(target: Node3D)`
- `VelocityComponent` (extends Node): handles all movement logic
- Parent entity: `@onready var health: HealthComponent = $HealthComponent`

## 9. METROIDVANIA WORLD (from Metroidvania-System)
- Room = separate `.tscn`, connected by `Doorway` Area3D
- Map grid: `Dictionary[Vector2i, RoomData]` — `RoomData = { scene: String, visited: bool }`
- Collectibles: unique `String` ID per item, `Array[String]` collected in SaveData
- Ability gating: `if SaveData.has_ability("double_jump"): open_gate()`
- Transition: `AnimationPlayer` fade → `get_tree().change_scene_to_file(room_path)` → fade-in

## 10. DIALOGUE SYSTEM (from godot_dialogue_manager)
- Dialogue as `.dialogue` text files OR `Resource` with `lines: Array[Dictionary]`
- Line: `{ "text": "Hello", "choices": [{"text":"Yes","next":"node_02"}], "condition": "has_key" }`
- Speaker: `TextureRect` portrait + `Label` name + `RichTextLabel` text
- Typewriter: `visible_characters += 1` per frame, speed 30-60 chars/sec
- Skip: press `ui_accept` → `visible_characters = text.length()`
- Signal: `dialogue_finished`, `choice_made(choice_id)`

## 11. INVENTORY SYSTEM (from inventory-system)
- `class_name ItemData extends Resource`: `@export var name: String`, `@export var icon: Texture2D`, `@export var stack_size: int = 1`
- Inventory: `Array[ItemData]` or `Dictionary[ItemData, int]` for stackable
- Slot UI: `TextureButton` + `TextureRect` icon + `Label` count inside `GridContainer`
- Pickup: `Area3D` on item → `body_entered` → `inventory.add_item(item_data)`
- Equip: swap `equipment[slot]` Resource, emit `equipment_changed`
- Crafting: recipe = `{ "result": ItemData, "ingredients": Dictionary[ItemData, int] }`

## 12. BEHAVIOR TREES (from limboai)
- Root: `BehaviorTree` node → `Selector` or `Sequence` composite
- Selector: tries children until one succeeds (OR logic)
- Sequence: runs children until one fails (AND logic)
- Tasks: `BTAction` scripts with `_enter()`, `_tick()`, `_exit()`
- Blackboard: shared `Dictionary` between tasks for memory
- `BTCheck` conditions: `has_target()`, `is_in_range()`, `is_health_low()`

## 13. CAMERA SYSTEMS (from phantom-camera)
- Follow: `PhantomCamera3D` with `follow_target = player`, `follow_offset = Vector3(0, 3, -5)`
- Noise: `noise_emitter = true` for handheld feel, intensity 0.1-0.3
- Shake: trigger `shake(intensity, duration)` on damage/explosion
- Tween: `tween_duration = 0.5` for smooth position changes
- Collision: `collision_mask` to avoid clipping walls
- Mobile: right half screen drag = look, pinch = zoom

## 14. PROCEDURAL GENERATION (from Gaea)
- Grid: `Dictionary[Vector2i, TileData]` — `TileData = { type: String, walkable: bool }`
- Room templates: `Array[PackedScene]`, instantiate random at grid position
- Corridor: carve path between rooms using Bresenham line or A*
- Seed: `rng.seed = hash("world_" + save_slot)` for reproducible worlds
- Spawn: `Marker3D` in room template → instantiate enemy/loot at runtime
- Bake: after generation, `NavigationRegion3D.bake_navigation_mesh()`

## 15. MULTIPLAYER (from netfox)
- `ENetMultiplayerPeer`: host `create_server(port)`, client `create_client(ip, port)`
- RPC: `@rpc("any_peer", "call_local")` for shoot/jump, `@rpc("authority", "unreliable_ordered")` for position
- Rollback: store last 32 frames of input, resimulate on lag
- Networked physics: `NetworkedRigidBody3D` or manual sync `velocity` + `position`
- NEVER trust client — validate damage/position on server

## 16. QUEST SYSTEM
- `class_name Quest extends Resource`: `@export var title: String`, `@export var objectives: Array[String]`, `@export var reward: ItemData`
- States: `enum QuestState {NOT_STARTED, ACTIVE, COMPLETED, TURNED_IN}`
- Tracker: `Dictionary[String, Quest]` in GameManager
- Update: `objective_completed(index)` → check all → `quest_completed` signal
- UI: `VBoxContainer` with quest names, expand for objectives, checkmark for done

## 17. UI / UX
- CanvasLayer → Control → VBoxContainer/HBoxContainer
- Anchor presets, canvas_items stretch, 80px touch targets
- Pause: `get_tree().paused = true`, pause menu `process_mode = PROCESS_MODE_ALWAYS`

## 18. SAVE / LOAD (Auto-context: SaveManager, save_data, save.tres, ResourceSaver)
- **Единый SaveManager**: `scripts/core/save_manager.gd` (autoload, extends Node)
- **Format**: `class_name SaveData extends Resource` in `scripts/core/save_data.gd`
- **Fields**: player_position (Vector3), current_scene (String), inventory_items (Array[String]), inventory_dict (Dictionary), abilities (Array[String]), quests_state (Dictionary), settings (Dictionary), wallet, shop, upgrades, encyclopedia, power_grid, coins, achievements, progress
- **Path**: `user://save.tres` — ResourceSaver.save() / ResourceLoader.load()
- **Methods**: `save_game() -> bool`, `load_game() -> bool`, `has_save() -> bool`, `delete_save() -> bool`
- **Autosave**: 60s timer in `_process`, plus triggers on district_restored, puzzle_solved, purchase_success, secret_found
- **Integration**: GameManager.auto_save() → SaveManager.save_game(); вызывается при return_to_menu()
- `ConfigFile` for settings (keybinds, audio, graphics) — user://settings.cfg
- NEVER save to `res://` at runtime

## 19. AUDIO
- `AudioStreamPlayer3D` for positional, `AudioStreamPlayer` for UI/music
- Buses: Master > Music > SFX
- OGG for music, WAV for short SFX

## 20. DEBUGGING
- `print("[Tag] value: ", variable)` with context tags
- Remote Scene Tree, profiler, `assert(condition, "message")`

## 21. ANIMATION
- `AnimationTree` StateMachine + BlendSpace2D for locomotion
- `playback.travel("state_name")` for transitions
- OneShot for hit reactions

## 22. PARTICLES & VFX
- `GPUParticles3D`, max 50-100 per emitter on mobile
- `one_shot = true`, `explosiveness = 1.0` for explosions
- `trail_enabled = true` for bullet trails

## 23. TOUCH & MOBILE INPUT
- `TouchScreenButton` for on-screen controls
- `InputEventScreenDrag` for camera look
- `Input.vibrate_handheld(50)` for haptic feedback

## 24. TERRAIN & ENVIRONMENT
- `Terrain3D` or `HeightMap` for open worlds
- `MultiMeshInstance3D` for grass/foliage
- Wind shader with `TIME` uniform
- Day/night: animate `DirectionalLight3D.rotation`

## 25. OBJECT POOL (from godot-design-patterns)
- Pre-instantiate 50 bullets/enemies at level start
- `Array[Node]` pool, `get_from_pool()` → `show()`, `return_to_pool()` → `hide()`
- NEVER `queue_free()` + `instantiate()` in hot paths — лаги на Android

## 26. TWEEN & SMOOTH ANIMATIONS (Auto-context: tween, smooth, fade, slide, bounce, elastic)
- Use create_tween() instead of manual lerp in _process — cleaner and automatic
- Chain tweens: 	ween.chain().tween_property(node, \"position\", target, 0.5)
- Easing: Tween.TRANS_QUAD + Tween.EASE_OUT for UI popups; TRANS_LINEAR for gameplay
- Callback: 	ween.finished.connect(_on_tween_done) — use for sequential actions
- Kill old: if creating new tween on same object, call existing_tween.kill() first
- Loop: 	ween.set_loops(3) for pulse effects, set_loops() infinite for idle animations
- Parallel: 	ween.parallel().tween_property(...) to animate multiple properties simultaneously

## 27. LIGHTING & SHADOWS — MOBILE (Auto-context: light, shadow, bake, glow, ambient, sun)
- DirectionalLight3D (sun): enable shadows, size 1024-2048, blur 1-2, max distance 50
- OmniLight3D (lamps/torches): NO shadows on mobile — use projector texture instead
- SpotLight3D: use sparingly, disable shadows, small range
- LightmapGI: bake ALL static geometry, resolution 50-100 texels/unit, use Static bake mode
- Environment: mbient_light_source = SKY, eflected_light_source = SKY, energy 0.3-0.5
- Glow: glow_enabled = true, intensity = 0.5, strength = 1.0, lend_mode = Additive
- NEVER mix dynamic + baked lights on same object — artifacts on mobile

## 28. EXPORT & BUILD — ANDROID (Auto-context: export, APK, build, keystore, release, deploy)
- Project Settings → Export → Android: package com.yourcompany.thelaststreetlight
- Keystore: keytool -genkey -v -keystore debug.keystore -alias androiddebugkey -keyalg RSA -validity 10000
- In Export → Android: set debug_keystore, debug_user, debug_password
- Custom build: OFF unless using native plugins (AdMob, Firebase)
- APK size optimization: ETC2 textures, remove .import folder from export, strip debug
- Architectures: arm64-v8a (required), optionally arm32 for old devices
- Install: db install --user 0 game.apk or drag APK to phone
- Testing: use Remote Debug in Godot Editor with USB-connected phone

## 29. PROJECT STRUCTURE & NAMING (Auto-context: folder, organize, name, structure, path)
- es://scenes/ — .tscn files. Naming: player.tscn, enemy_wasp.tscn, ui_hud.tscn
- es://scripts/ — .gd files. Naming: match scene name — player.gd for player.tscn
- es://assets/ — imported files ONLY. Subfolders: models/, 	extures/, udio/, onts/
- es://resources/ — .tres files: item_sword.tres, 	heme_dark.tres, material_wood.tres
- es://autoload/ — singletons: game_manager.gd, event_bus.gd, save_manager.gd
- es://components/ — reusable: health_component.gd, ttack_component.gd
- es://shaders/ — .gdshader: water.gdshader, outline.gdshader
- NEVER put .gd scripts in root es:// — always in scripts/ or components/

## 30. PERFORMANCE MONITORING (Auto-context: fps, lag, slow, memory, optimize, profile)
- FPS: Performance.get_monitor(Performance.TIME_FPS) — target >30 on mid Android
- VRAM: RenderingServer.get_rendering_info(RENDERING_INFO_TEXTURE_MEM_USED) / 1048576 = MB
- RAM: OS.get_static_memory_usage() / 1048576 = MB
- Draw calls: check RenderingServer.get_rendering_info(RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
- If FPS < 30: reduce shadow size, disable OmniLight shadows, lower particle count, enable LOD
- Profiler: Editor → Debugger → Profiler tab — monitor CPU, GPU, memory
- Use VisibleOnScreenNotifier3D to pause off-screen enemies/animations

## 31. REPOSITORY EXAMPLES (Auto-context: example, template, reference, repo, copy from)
- В папке epo_examples/ лежат готовые .gd скрипты из скачанных репозиториев.
- Перед написанием сложной системы — проверь, есть ли готовый пример в epo_examples/.
- Скрипты именованы как РЕПОЗИТОРИЙ_имя.gd — например: godot-design-patterns_state.gd.
- Используй их как шаблон: скопируй в свой scripts/ и адаптируй.
- Полный список: см. REPOS_INDEX.md в корне проекта.

## 32. ASSETS & RESOURCES (Auto-context: texture, sound, model, asset, import, kenney)
- Все ассеты лежат в es://assets/:
  - udio/sfx/ — звуки (WAV для SFX, OGG для музыки)
  - 	extures/ui/ — иконки, фоны (PNG, 64x64 или 128x128)
  - 	extures/environment/ — стены, полы, потолки (PNG, seamless, tileable)
  - models/ — .glb / .obj (Kenney Weapon Pack и т.д.)
- Импорт Godot: при первом открытии проекта Godot создаст .import файлы
- Для замены placeholder: скопируй Kenney assets в ssets/ с теми же именами
- Audio: preload("res://assets/audio/sfx/sfx_shoot.wav") в weapon_pistol.gd
- Textures: preload("res://assets/textures/ui/icon_health.png") в HUD

## 33. LEVEL DESIGN (Auto-context: level, wave, checkpoint, spawn, arena, boss, phase)
- Уровень = сцена с NavigationRegion3D, WaveManager, чекпоинтами
- WaveManager: Array[WaveData], spawn по Marker3D, сигналы wave_started/completed/all_done
- Чекпоинт: Area3D + OmniLight3D cyan, сохраняет позицию в SaveManager
- Босс: 3 фазы по % HP, спавн миньонов, уникальная музыка
- Прогрессия: XP за убийство, LevelUp = level * 100 XP, SkillPoints
- Достижения: Dictionary, toast-уведомление при unlock

## 34. EFFECTS & POLISH (Auto-context: effect, shake, recoil, fade, damage, screen, polish)
- ScreenShake: Camera3D position jitter, trauma-based, decay over time
- Recoil: Camera3D rotation kick, recovery per frame
- FadeTransition: CanvasLayer ColorRect alpha tween, change_scene wrapper
- DamageIndicator: Red vignette flash on player_damaged
- DeathSequence: time_scale 0.3, red overlay, slow-mo death

## 35. INTERACTIVE WORLD (Auto-context: pickup, barrel, door, key, ammo, health, interact)
- WeaponPickup: Area3D, unlocks weapon in WeaponManager, floating animation
- AmmoPickup: Area3D, add_ammo to player
- HealthPickup: Area3D, heals HealthComponent
- ExplodingBarrel: RigidBody3D, take_damage → sphere cast damage + particles
- Door: StaticBody3D, interact() checks InventoryManager for key, tween open
- KeyItem: Area3D, adds key_id to inventory
