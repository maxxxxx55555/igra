# upgrade_part4.ps1 -- THE_LAST_STREETLIGHT
# Part 4: fixes Part 2/3 indent bugs + adds gameplay systems.
# Run AFTER upgrade.ps1 (Parts 1-3). Does NOT auto-commit.

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Write-Utf8([string]$rel, [string]$content) {
	$full = Join-Path $root $rel
	$dir = Split-Path -Parent $full
	if (-not (Test-Path $dir)) { [void](New-Item -ItemType Directory -Force -Path $dir) }
	[System.IO.File]::WriteAllText($full, $content, $utf8)
	Write-Host ('WROTE    ' + $rel)
}

function Add-Autoload([string]$name, [string]$path) {
	$godotFile = Join-Path $root 'project.godot'
	if (-not (Test-Path $godotFile)) { Write-Host ('WARN project.godot missing -- skipping ' + $name); return }
	$text = [System.IO.File]::ReadAllText($godotFile, $utf8)
	if ($text -match ('^' + [regex]::Escape($name) + '=')) {
		Write-Host ('AUTOLOAD ' + $name + ' (exists)'); return
	}
	$entry = ($name + '="*' + $path + '"') + [Environment]::NewLine
	if ($text -match '\[autoload\]\s*\r?\n') {
		$newText = [regex]::Replace($text, '(\[autoload\]\s*\r?\n)', ('$1' + $entry), 1)
		[System.IO.File]::WriteAllText($godotFile, $newText, $utf8)
	} else {
		$append = [Environment]::NewLine + '[autoload]' + [Environment]::NewLine + $entry
		[System.IO.File]::AppendAllText($godotFile, $append, $utf8)
	}
	Write-Host ('AUTOLOAD ' + $name + ' -> ' + $path)
}

# ============================================================================
# FIX 1/5: scripts/audio/music_manager.gd  (was: col-0 connect line)
# ============================================================================
$music_manager = @'
extends Node
## Autoload "MusicManager". Creates Music/Ambient/SFX buses, crossfades per district.

@export var fade_duration: float = 1.5

var _active: AudioStreamPlayer = null
var _fading: AudioStreamPlayer = null

func _ready() -> void:
	_ensure_buses()
	if not DistrictThemes.theme_changed.is_connected(_on_theme):
		DistrictThemes.theme_changed.connect(_on_theme)
	_on_theme(DistrictThemes.current_id)

func _ensure_buses() -> void:
	var names: PackedStringArray = AudioServer.bus_get_names()
	for n in ["Music", "Ambient", "SFX"]:
		if not names.has(n):
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, n)
		var idx: int = AudioServer.bus_count - 1
		if n == "Ambient":
			AudioServer.set_bus_volume_db(idx, -6.0)
		elif n == "SFX":
			AudioServer.set_bus_volume_db(idx, -3.0)

func _on_theme(district_id: StringName) -> void:
	_crossfade_to(district_id)

func _crossfade_to(district_id: StringName) -> void:
	var path: String = "res://audio/music/%s.wav" % district_id
	if not ResourceLoader.exists(path):
		path = "res://audio/music/%s.ogg" % district_id
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if _active != null and _active.stream == stream:
		return
	var next := AudioStreamPlayer.new()
	next.bus = &"Music"
	next.stream = stream
	add_child(next)
	next.volume_db = -60.0
	next.play()
	_fading = _active
	_active = next
	var tw := create_tween()
	tw.tween_property(next, "volume_db", 0.0, fade_duration)
	if _fading != null:
		tw.parallel().tween_property(_fading, "volume_db", -60.0, fade_duration)
	tw.tween_callback(_cleanup_fading)

func _cleanup_fading() -> void:
	if _fading != null:
		_fading.queue_free()
		_fading = null
'@
Write-Utf8 'scripts/audio/music_manager.gd' $music_manager

# ============================================================================
# FIX 2/5: scripts/enemy/enemy_light_ai.gd  (was: col-0 State.CHASE line)
# ============================================================================
$enemy_ai = @'
extends CharacterBody3D
class_name EnemyLightAI
## Light-aware enemy. Bolder in dark, cautious in light, runs from flashlight.

@export var move_speed: float = 2.5
@export var patrol_speed: float = 1.2
@export var flee_speed: float = 4.5
@export var detection_range: float = 12.0
@export var dark_boost: float = 1.5
@export var catch_distance: float = 1.2

enum State { PATROL, CHASE, FLEE }

var _state: int = State.PATROL
var _player: Node3D
var _patrol: Array[Vector3] = []
var _patrol_i: int = 0

func _ready() -> void:
	_player = get_tree().get_first_node_in_group(&"player")
	_collect_patrol()
	set_physics_process(true)

func _collect_patrol() -> void:
	_patrol.clear()
	for n in get_tree().get_nodes_in_group(&"patrol"):
		_patrol.append((n as Node3D).global_position)
	if _patrol.is_empty():
		_patrol.append(global_position)

func _physics_process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var to_p: Vector3 = _player.global_position - global_position
	var dist: float = to_p.length()
	var lit: bool = LightGrid.is_lit(global_position, 0.25)
	var br: float = LightGrid.cell_brightness(global_position)
	var det: float = detection_range * (dark_boost if not lit else 1.0)

	var flash: Variant = LightGrid.nearest_flashlight(global_position)
	var near_flash: bool = false
	var flash_pos: Vector3 = Vector3.ZERO
	if flash != null and flash is Array and (flash as Array).size() >= 2:
		var fda: Array = flash
		flash_pos = fda[0]
		if float(fda[1]) < 6.0:
			near_flash = true

	if near_flash:
		_set_state(State.FLEE)
	elif dist < det and not lit:
		_set_state(State.CHASE)
	elif dist < det * 0.5 and lit:
		_set_state(State.CHASE)
	else:
		_set_state(State.PATROL)

	match _state:
		State.PATROL:
			_tick_patrol()
		State.CHASE:
			_tick_chase(br)
		State.FLEE:
			_tick_flee(flash_pos, to_p)

func _set_state(s: int) -> void:
	if s == _state:
		return
	_state = s

func _tick_patrol() -> void:
	if _patrol.is_empty():
		return
	var t: Vector3 = _patrol[_patrol_i]
	_move(t, patrol_speed)
	if global_position.distance_to(t) < 1.5:
		_patrol_i = (_patrol_i + 1) % _patrol.size()

func _tick_chase(br: float) -> void:
	var sp: float = move_speed * (1.4 if br < 0.2 else 0.6)
	_move(_player.global_position, sp)

func _tick_flee(flash_pos: Vector3, to_p: Vector3) -> void:
	var away: Vector3 = global_position - flash_pos
	if away.length() < 0.1:
		away = -to_p
	_move(global_position + away.normalized() * 5.0, flee_speed)

func _move(target: Vector3, speed: float) -> void:
	var dir: Vector3 = target - global_position
	dir.y = 0.0
	if dir.length() < 0.01:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	velocity = dir.normalized() * speed
	move_and_slide()

func state_name() -> StringName:
	match _state:
		State.PATROL:
			return &"PATROL"
		State.CHASE:
			return &"CHASE"
		State.FLEE:
			return &"FLEE"
	return &"?"

func caught_player() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	return global_position.distance_to(_player.global_position) < catch_distance
'@
Write-Utf8 'scripts/enemy/enemy_light_ai.gd' $enemy_ai

# ============================================================================
# FIX 3/5: scripts/ui/hud_touch.gd  (was: UISFX.click() at col 1, return at col 2)
# ============================================================================
$hud_touch = @'
extends Control
class_name HUDTouch

signal stick_input(dir: Vector2)
signal action_pressed(name: StringName)
signal action_released(name: StringName)

const DEAD_ZONE: float = 16.0
const STICK_RADIUS: float = 64.0
const STICK_KNOB: float = 32.0

@export var stick_origin: Vector2 = Vector2(180, 580)
@export var action_button_specs: Array[Dictionary] = [
	{"name": &"flashlight", "pos": Vector2(680, 500), "radius": 56.0, "color": Color(1, 1, 0.6)},
	{"name": &"interact",   "pos": Vector2(580, 580), "radius": 56.0, "color": Color(0.6, 1, 0.6)},
	{"name": &"sprint",     "pos": Vector2(780, 580), "radius": 56.0, "color": Color(0.6, 0.8, 1)},
	{"name": &"pause",      "pos": Vector2(960,  60), "radius": 32.0, "color": Color(1, 1, 1)},
]

var _touch_index: Dictionary = {}
var _last_pos: Dictionary = {}
var _stick_pos: Vector2
var _stick_dir: Vector2 = Vector2.ZERO

func _ready() -> void:
	_stick_pos = stick_origin
	set_process(true)
	set_process_input(true)

func _process(_dt: float) -> void:
	var stick_touch: int = -1
	for idx in _touch_index.keys():
		if String(_touch_index[idx]) == "stick":
			stick_touch = int(idx)
			break
	if stick_touch >= 0:
		var pos: Vector2 = _last_pos.get(stick_touch, stick_origin)
		var delta: Vector2 = pos - stick_origin
		if delta.length() > DEAD_ZONE:
			_stick_dir = (delta / STICK_RADIUS).limit_length(1.0)
			_stick_pos = stick_origin + _stick_dir * STICK_RADIUS
		else:
			_stick_dir = Vector2.ZERO
			_stick_pos = stick_origin
	else:
		_stick_dir = Vector2.ZERO
		_stick_pos = stick_origin
	stick_input.emit(_stick_dir)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event
		if st.pressed:
			_on_touch_begin(st.index, st.position)
		else:
			_on_touch_end(st.index)
	elif event is InputEventScreenDrag:
		var sd: InputEventScreenDrag = event
		_on_touch_drag(sd.index, sd.position)

func _on_touch_begin(idx: int, pos: Vector2) -> void:
	for spec in action_button_specs:
		var sp: Vector2 = spec["pos"]
		var r: float = spec["radius"]
		if pos.distance_to(sp) <= r:
			_touch_index[idx] = spec["name"]
			action_pressed.emit(spec["name"])
			UISFX.click()
			return
	if pos.distance_to(stick_origin) <= STICK_RADIUS * 1.6:
		_touch_index[idx] = "stick"
		_last_pos[idx] = pos
		_stick_pos = pos

func _on_touch_drag(idx: int, pos: Vector2) -> void:
	if String(_touch_index.get(idx, "")) == "stick":
		_last_pos[idx] = pos
		_stick_pos = pos

func _on_touch_end(idx: int) -> void:
	var tag: Variant = _touch_index.get(idx)
	if tag == null:
		return
	if tag is StringName:
		action_released.emit(tag)
	_touch_index.erase(idx)
	_last_pos.erase(idx)

func _draw() -> void:
	draw_circle(stick_origin, STICK_RADIUS, Color(1, 1, 1, 0.15))
	draw_circle(_stick_pos, STICK_KNOB, Color(1, 1, 1, 0.5))
	for spec in action_button_specs:
		var p: Vector2 = spec["pos"]
		var r: float = spec["radius"]
		var nm: StringName = spec["name"]
		var pressed: bool = false
		for idx in _touch_index.keys():
			if _touch_index[idx] == nm:
				pressed = true
				break
		var col: Color = spec["color"]
		col.a = 0.85 if pressed else 0.35
		draw_circle(p, r, col)
		var f: Font = ThemeDB.fallback_font
		if f != null:
			draw_string(f, p - Vector2(28, 6), String(nm), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
'@
Write-Utf8 'scripts/ui/hud_touch.gd' $hud_touch

# ============================================================================
# FIX 4/5: scripts/ui/hud_main.gd  (was: _minimap.call at col 0)
# ============================================================================
$hud_main = @'
extends Control
class_name HUDMain

@export var minimap_path: NodePath
@export var banner_path: NodePath
@export var touch_path: NodePath
@export var player_path: NodePath

var _minimap: Control
var _banner: Control
var _touch: Control
var _player: Node3D
var _paused: bool = false
var _sprinting: bool = false

func _ready() -> void:
	_minimap = get_node_or_null(minimap_path) as Control
	_banner = get_node_or_null(banner_path) as Control
	_touch = get_node_or_null(touch_path) as Control
	_player = get_node_or_null(player_path) as Node3D
	if _touch != null:
		if _touch.has_signal("stick_input"):
			_touch.stick_input.connect(_on_stick)
		if _touch.has_signal("action_pressed"):
			_touch.action_pressed.connect(_on_action_pressed)
		if _touch.has_signal("action_released"):
			_touch.action_released.connect(_on_action_released)
	if not DistrictThemes.theme_changed.is_connected(_on_theme):
		DistrictThemes.theme_changed.connect(_on_theme)
	set_process(true)
	call_deferred("_on_theme", DistrictThemes.current_id)

func _process(_dt: float) -> void:
	if _player == null:
		return
	if _minimap != null and _minimap.has_method("set_focus"):
		_minimap.call("set_focus", _player.global_position)

func _on_stick(dir: Vector2) -> void:
	if _player == null:
		return
	var speed: float = 5.0 * (1.6 if _sprinting else 1.0)
	var dir3: Vector3 = Vector3(dir.x, 0, dir.y)
	if dir3.length() < 0.01:
		if _player.has_method("set_move_input"):
			_player.call("set_move_input", Vector3.ZERO)
		return
	if _player.has_method("set_move_input"):
		_player.call("set_move_input", dir3.normalized() * speed)

func _on_action_pressed(name: StringName) -> void:
	if name == &"pause":
		_paused = not _paused
		get_tree().paused = _paused
		return
	if _player == null:
		return
	if name == &"flashlight":
		if _player.has_method("toggle_flashlight"):
			_player.call("toggle_flashlight")
	elif name == &"sprint":
		_sprinting = true
	elif name == &"interact":
		if _player.has_method("interact"):
			_player.call("interact")
	UISFX.click()

func _on_action_released(name: StringName) -> void:
	if name == &"sprint":
		_sprinting = false

func _on_theme(district_id: StringName) -> void:
	if _banner != null and _banner.has_method("set_district"):
		_banner.call("set_district", district_id)
	if _minimap != null and _minimap.has_method("set_district"):
		_minimap.call("set_district", district_id)
'@
Write-Utf8 'scripts/ui/hud_main.gd' $hud_main

# ============================================================================
# FIX 5/5: scripts/world/world_bootstrap.gd  (was: props./win. lines at col 0)
# ============================================================================
$world_bootstrap = @'
extends Node
## Autoload "WorldBootstrap". Walks every district (group "district" or child
## named "district_*"); attaches CityStreetProps, EmissiveWindows, DistrictGrading
## if missing. Idempotent: safe to re-run when scenes reload.

const _SB_NAME := &"StreetBuilder"
const _PROPS_NAME := &"Props"
const _WIN_NAME := &"Windows"
const _GRADING_NAME := &"Grading"

func _ready() -> void:
	call_deferred("_wire_all")

func _wire_all() -> void:
	var districts: Array[Node] = []
	var tagged := get_tree().get_nodes_in_group(&"district")
	for d in tagged:
		districts.append(d)
	var root: Node = get_tree().current_scene
	if root != null:
		var found := _find_districts(root)
		for f in found:
			if not districts.has(f):
				districts.append(f)
	for d in districts:
		_wire_district(d)

func _find_districts(n: Node) -> Array[Node]:
	var out: Array[Node] = []
	if n.is_in_group(&"district") or String(n.name).begins_with("district_"):
		out.append(n)
	for c in n.get_children():
		out.append_array(_find_districts(c))
	return out

func _wire_district(d: Node) -> void:
	if d == null:
		return
	var sb: Node = _find_child(d, _SB_NAME)
	if sb == null:
		return
	if _find_child(d, _PROPS_NAME) == null:
		var props := CityStreetProps.new()
		props.name = _PROPS_NAME
		props.street_builder_path = sb.get_path()
		d.add_child(props)
	if _find_child(d, _WIN_NAME) == null:
		var win := EmissiveWindows.new()
		win.name = _WIN_NAME
		d.add_child(win)
	if _find_child(d, _GRADING_NAME) == null:
		var script: Script = load("res://scripts/world/district_grading.gd")
		var grading: Node = script.new()
		grading.name = _GRADING_NAME
		var env_path: NodePath = _env_path(d)
		if env_path != NodePath(""):
			grading.set("world_environment_path", env_path)
		grading.set("district_root_path", d.get_path())
		d.add_child(grading)

func _env_path(d: Node) -> NodePath:
	var root: Node = d
	while root.get_parent() != null:
		root = root.get_parent()
	var env: Node = root.get_node_or_null("WorldEnvironment")
	if env != null:
		return env.get_path()
	var cur: Node = get_tree().current_scene
	if cur != null:
		var e2: Node = cur.get_node_or_null("WorldEnvironment")
		if e2 != null:
			return e2.get_path()
	return NodePath("")

func _find_child(n: Node, name_arg: StringName) -> Node:
	for c in n.get_children():
		if c.name == name_arg:
			return c
	return null
'@
Write-Utf8 'scripts/world/world_bootstrap.gd' $world_bootstrap

# ============================================================================
# NEW: PLAYER CONTROLLER (FPS + flashlight + sprint + interact)
# ============================================================================
$player = @'
extends CharacterBody3D
class_name Player
## FPS controller. Desktop WASD+mouse, Android gets input from HUDTouch.
## Required methods for HUDMain: set_move_input, toggle_flashlight, interact.

@export var walk_speed: float = 5.0
@export var run_multiplier: float = 1.6
@export var gravity: float = 12.0
@export var mouse_sensitivity: float = 0.0025
@export var flashlight_energy: float = 4.0
@export var flashlight_range: float = 18.0

var _move: Vector3 = Vector3.ZERO
var _yaw: float = 0.0
var _pitch: float = 0.0
var _sprinting: bool = false
var _flash_on: bool = false
var _flash: SpotLight3D
var _body: Node3D
var _head: Node3D
var _cam: Camera3D

func _ready() -> void:
	add_to_group(&"player")
	_body = get_node_or_null("Body") as Node3D
	_head = get_node_or_null("Body/Head") as Node3D
	_cam = get_node_or_null("Body/Head/Camera") as Camera3D
	if _cam == null:
		_cam = Camera3D.new()
		_cam.name = &"Camera"
		var parent: Node = _head if _head != null else (_body if _body != null else self)
		parent.add_child(_cam)
	_flash = _cam.get_node_or_null("Flashlight") as SpotLight3D
	if _flash == null:
		_flash = SpotLight3D.new()
		_flash.name = &"Flashlight"
		_flash.spot_range = flashlight_range
		_flash.spot_angle = 35.0
		_flash.light_color = Color(1.0, 0.9, 0.7)
		_flash.light_energy = 0.0
		_flash.add_to_group(&"flashlight")
		_cam.add_child(_flash)
	if not OS.has_feature("android"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	set_physics_process(true)
	set_process_unhandled_input(true)

func set_move_input(v: Vector3) -> void:
	_move = v

func sprinting_set(on: bool) -> void:
	_sprinting = on

func sprinting_get() -> bool:
	return _sprinting

func toggle_flashlight() -> void:
	_flash_on = not _flash_on
	_flash.light_energy = flashlight_energy if _flash_on else 0.0
	if _flash_on:
		LightGrid.register_light(_flash)
	else:
		LightGrid.unregister_light(_flash)

func interact() -> void:
	if _cam == null:
		return
	var origin: Vector3 = _cam.global_position
	var dir: Vector3 = -_cam.global_transform.basis.z
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(origin, origin + dir * 2.5)
	q.exclude = [get_rid()]
	var hit: Dictionary = space.intersect_ray(q)
	if hit.is_empty():
		return
	var c: Variant = hit["collider"]
	if c is Node:
		var n: Node = c
		if n.has_method("on_interact"):
			n.call("on_interact", self)

func _unhandled_input(event: InputEvent) -> void:
	if OS.has_feature("android"):
		return
	if event is InputEventMouseMotion:
		var m: InputEventMouseMotion = event
		_yaw -= m.relative.x * mouse_sensitivity
		_pitch = clamp(_pitch - m.relative.y * mouse_sensitivity, -1.4, 1.4)
		if _body != null:
			_body.rotation.y = _yaw
		if _head != null:
			_head.rotation.x = _pitch
	elif event is InputEventKey:
		var k: InputEventKey = event
		if k.pressed and k.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if k.keycode == KEY_F:
			toggle_flashlight()
		if k.keycode == KEY_SHIFT:
			_sprinting = k.pressed

func _physics_process(delta: float) -> void:
	var v: Vector3 = _move
	if not OS.has_feature("android"):
		var kb: Vector3 = Vector3.ZERO
		if Input.is_key_pressed(KEY_W): kb.z -= 1.0
		if Input.is_key_pressed(KEY_S): kb.z += 1.0
		if Input.is_key_pressed(KEY_A): kb.x -= 1.0
		if Input.is_key_pressed(KEY_D): kb.x += 1.0
		if kb.length() > 0.01:
			kb = kb.normalized()
			if _body != null:
				kb = _body.global_transform.basis * kb
			v = kb * walk_speed * (run_multiplier if _sprinting else 1.0)
		else:
			v = Vector3.ZERO
	v.y = velocity.y - gravity * delta
	velocity = v
	move_and_slide()
'@
Write-Utf8 'scripts/player/player_controller.gd' $player

# ============================================================================
# NEW: POWER GRID  (autoload "PowerGrid" -- CANON core loop state)
# ============================================================================
$power_grid = @'
extends Node
## Autoload "PowerGrid". Per-district power state. PowerSwitch.on_interact() flips it.

signal power_changed(district_id: StringName, on: bool)
signal all_powered

var _powered: Dictionary = {}
var _all: Array[StringName] = []

func _ready() -> void:
	for d in DistrictThemes.list_ids():
		register_district(d)

func register_district(district_id: StringName) -> void:
	if not _powered.has(district_id):
		_powered[district_id] = false
		_all.append(district_id)

func is_powered(district_id: StringName) -> bool:
	return bool(_powered.get(district_id, false))

func toggle(district_id: StringName) -> void:
	set_powered(district_id, not is_powered(district_id))

func set_powered(district_id: StringName, on: bool) -> void:
	_powered[district_id] = on
	power_changed.emit(district_id, on)
	if _all_powered():
		all_powered.emit()

func _all_powered() -> bool:
	if _all.is_empty():
		return false
	for d in _all:
		if not is_powered(d):
			return false
	return true

func progress() -> float:
	if _all.is_empty():
		return 0.0
	var on: int = 0
	for d in _all:
		if is_powered(d):
			on += 1
	return float(on) / float(_all.size())

func powered_count() -> int:
	var n: int = 0
	for d in _all:
		if is_powered(d):
			n += 1
	return n

func total_count() -> int:
	return _all.size()
'@
Write-Utf8 'scripts/systems/power_grid.gd' $power_grid
Add-Autoload 'PowerGrid' 'res://scripts/systems/power_grid.gd'

# ============================================================================
# NEW: POWER SWITCH  (place one per district; player interact() flips state)
# ============================================================================
$power_switch = @'
extends StaticBody3D
class_name PowerSwitch
## Place in scene; set district_id; player raycast calls on_interact().

@export var district_id: StringName = &""
@export var on_color: Color = Color(0.2, 1.0, 0.4)
@export var off_color: Color = Color(0.6, 0.1, 0.1)

@onready var _light: OmniLight3D = get_node_or_null("Light") as OmniLight3D
@onready var _panel: MeshInstance3D = get_node_or_null("Panel") as MeshInstance3D

func _ready() -> void:
	if not PowerGrid.power_changed.is_connected(_on_power_changed):
		PowerGrid.power_changed.connect(_on_power_changed)
	_on_power_changed(district_id, PowerGrid.is_powered(district_id))

func _on_power_changed(d: StringName, on: bool) -> void:
	if d != district_id:
		return
	if _light != null:
		_light.light_energy = 2.0 if on else 0.0
	if _panel != null:
		var m := StandardMaterial3D.new()
		m.emission_enabled = true
		m.emission = on_color if on else off_color
		m.emission_energy_multiplier = 1.5 if on else 0.3
		_panel.material_override = m

func on_interact(_player: Node) -> void:
	PowerGrid.toggle(district_id)
	UISFX.pickup()
'@
Write-Utf8 'scripts/systems/power_switch.gd' $power_switch

# ============================================================================
# NEW: DAY/NIGHT  (autoload "DayNight" -- 24-min cycle, drives Environment)
# ============================================================================
$day_night = @'
extends Node
## Autoload "DayNight". day_duration_sec = full 24h cycle. Updates WorldEnvironment.

@export var day_duration_sec: float = 1440.0
@export var start_hour: float = 20.0

var _t: float = 0.0
var _env: WorldEnvironment

func _ready() -> void:
	_env = get_tree().get_first_node_in_group(&"world_environment") as WorldEnvironment
	if _env == null:
		_env = get_tree().root.get_node_or_null("Main/WorldEnvironment") as WorldEnvironment
	set_process(true)
	_apply(get_hour())

func _process(delta: float) -> void:
	_t += delta
	_apply(get_hour())

func get_hour() -> float:
	return fmod(start_hour + _t / day_duration_sec * 24.0, 24.0)

func _apply(hours: float) -> void:
	if _env == null or _env.environment == null:
		return
	var e: Environment = _env.environment
	var night: float = 1.0 - clamp(1.0 - abs(hours - 12.0) / 6.0, 0.0, 1.0)
	var sky: Color = Color(0.05, 0.07, 0.12).lerp(Color(0.55, 0.70, 0.90), 1.0 - night)
	e.background_mode = Environment.BG_COLOR
	e.background_color = sky
	e.ambient_light_energy = 0.15 + 0.45 * (1.0 - night)
	e.ambient_light_color = Color(1.0, 0.9, 0.7).lerp(Color(0.4, 0.5, 0.8), night)
	e.fog_density = 0.008 + 0.012 * night
'@
Write-Utf8 'scripts/systems/day_night.gd' $day_night
Add-Autoload 'DayNight' 'res://scripts/systems/day_night.gd'

# ============================================================================
# NEW: SHOP  (autoload "Shop" -- coins only, CANON: no p2w)
# ============================================================================
$shop = @'
extends Node
## Autoload "Shop". Coins-only purchases. CANON: no p2w, no real-money IAP.

signal purchased(item_id: StringName)
signal purchase_failed(item_id: StringName, reason: String)

const ITEMS := {
	"battery": {"price": 50,  "max": 3},
	"stamina": {"price": 100, "max": 2},
	"medkit":  {"price": 30,  "max": 5},
}

var _coins: int = 0
var _owned: Dictionary = {}

func add_coins(n: int) -> void:
	_coins += n

func coins() -> int:
	return _coins

func owned(item_id: StringName) -> int:
	return int(_owned.get(item_id, 0))

func can_buy(item_id: StringName) -> bool:
	var item: Variant = ITEMS.get(String(item_id))
	if item == null or not (item is Dictionary):
		return false
	var d: Dictionary = item
	return _coins >= int(d.get("price", 0)) and owned(item_id) < int(d.get("max", 0))

func buy(item_id: StringName) -> bool:
	if not can_buy(item_id):
		purchase_failed.emit(item_id, "insufficient")
		return false
	var item: Variant = ITEMS.get(String(item_id))
	var d: Dictionary = item
	_coins -= int(d.get("price", 0))
	_owned[item_id] = owned(item_id) + 1
	purchased.emit(item_id)
	UISFX.pickup()
	return true

func list_items() -> Array[StringName]:
	var out: Array[StringName] = []
	for k in ITEMS.keys():
		out.append(StringName(k))
	return out

func price_of(item_id: StringName) -> int:
	var item: Variant = ITEMS.get(String(item_id))
	if item == null or not (item is Dictionary):
		return 0
	return int((item as Dictionary).get("price", 0))
'@
Write-Utf8 'scripts/systems/shop.gd' $shop
Add-Autoload 'Shop' 'res://scripts/systems/shop.gd'

# ============================================================================
# NEW: SAVE/LOAD  (autoload "SaveLoad" -- JSON to user://savegame.json)
# ============================================================================
$save_load = @'
extends Node
## Autoload "SaveLoad". JSON save/load to user://savegame.json.

const PATH := "user://savegame.json"

func save_data(data: Dictionary) -> bool:
	var f: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data))
	f.close()
	return true

func load_data() -> Variant:
	if not FileAccess.file_exists(PATH):
		return null
	var f: FileAccess = FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return null
	var text: String = f.get_as_text()
	f.close()
	return JSON.parse_string(text)

func delete_save() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
'@
Write-Utf8 'scripts/systems/save_load.gd' $save_load
Add-Autoload 'SaveLoad' 'res://scripts/systems/save_load.gd'

Write-Host ""
Write-Host "===== Part 4 done. Run check.ps1 to verify, then publish.ps1 to commit + push. ====="