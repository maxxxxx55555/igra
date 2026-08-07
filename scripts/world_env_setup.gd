extends Node

# Ночной город: темно, но геометрия обязана читаться.
#
# Раньше здесь стояли ambient 0.01 и moon 0.03 — «абсолютная тьма вне источников
# света». На практике это давало почти чёрный кадр: ни домов, ни дороги, ни
# силуэта монстра, играть было невозможно. Держим низкую, но ненулевую засветку,
# а разницу между стадиями восстановления города показываем контрастом.

@export var ambient_energy_default: float = 0.12
@export var moon_energy_default: float = 0.09
@export var moon_rotation_deg: Vector3 = Vector3(-55.0, -35.0, 0.0)
@export var fog_density: float = 0.012
@export var glow_intensity: float = 0.5

# Стадия района: DARK — только фонарик и луна, FULL — восстановленный свет.
const AMBIENT_DARK: float = 0.12
const AMBIENT_LIT: float = 0.20
const AMBIENT_FULL: float = 0.30
const AMBIENT_COLOR_DARK: Color = Color(0.075, 0.094, 0.137)
const AMBIENT_COLOR_LIT: Color = Color(0.098, 0.125, 0.184)
const AMBIENT_COLOR_FULL: Color = Color(0.125, 0.153, 0.212)
const MOON_DARK: float = 0.09
const MOON_LIT: float = 0.14
const MOON_FULL: float = 0.20
# Свечение вокруг игрока: в тёмном районе его нет, с восстановлением растёт.
const GLOW_DARK: float = 0.0
const GLOW_LIT: float = 0.35
const GLOW_FULL: float = 0.7

var _env: Environment = null
var _moon: DirectionalLight3D = null
var _player_glow: OmniLight3D = null
var _override_frames: int = 5

func _ready() -> void:
	var root = get_tree().current_scene
	if root == null: root = get_tree().root

	var we: WorldEnvironment = _find_we(root)
	if we == null:
		we = WorldEnvironment.new()
		we.name = "WorldEnvironment"
		we.environment = Environment.new()
		root.add_child(we)
		we.owner = root
	if we.environment == null:
		we.environment = Environment.new()
	_env = we.environment

	_env.tonemap_mode = Environment.TONE_MAPPER_AGX
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = AMBIENT_COLOR_DARK
	_env.ambient_light_energy = ambient_energy_default
	_env.glow_enabled = true
	_env.glow_intensity = glow_intensity
	_env.glow_strength = 1.0
	_env.glow_bloom = 0.1
	_env.ssao_enabled = false
	_env.ssil_enabled = false
	_env.volumetric_fog_enabled = false
	_env.fog_enabled = true
	_env.fog_density = fog_density
	_env.fog_light_color = Color(0.102, 0.129, 0.2)  # #1a2133
	# fog_light_energy = 0 гасил цвет тумана полностью — туман переставал быть
	# видимым как дымка и работал только на затемнение дали.
	_env.fog_light_energy = 0.6

	var moon: DirectionalLight3D = _find_moon(root)
	if moon == null:
		moon = DirectionalLight3D.new()
		moon.name = "Moon"
		root.add_child(moon)
		moon.owner = root
	_moon = moon
	_moon.light_energy = moon_energy_default
	_moon.light_color = Color(0.439, 0.502, 0.753)  # #7080C0
	_moon.rotation_degrees = moon_rotation_deg
	_moon.shadow_enabled = true

	# Flashlight defaults (set on player scene)
	# - spot_range = 8.0, spot_angle = 45, light_energy = 1.0, color = #c9a24a

	EventBus.district_stage_changed.connect(_on_district_stage_changed)
	EventBus.weather_changed.connect(_on_weather_changed)

	var grid := get_node_or_null("/root/PowerGridManager")
	if grid:
		grid.grid_updated.connect(_on_grid_updated)

	_player_glow = _find_player_glow()
	_sync_stage_from_grid()

func _process(delta: float) -> void:
	if _override_frames > 0:
		_override_frames -= 1
		var dm := get_node_or_null("/root/DistrictManager")
		if dm:
			apply_for_stage(dm.get_stage(dm.current_district))

func apply_for_stage(stage: int) -> void:
	if _env == null:
		return
	var ambient_energy: float
	var ambient_color: Color
	var moon_energy: float
	var glow_energy: float
	match stage:
		0, 1:
			ambient_energy = AMBIENT_DARK
			ambient_color = AMBIENT_COLOR_DARK
			moon_energy = MOON_DARK
			glow_energy = GLOW_DARK
		2:
			ambient_energy = AMBIENT_LIT
			ambient_color = AMBIENT_COLOR_LIT
			moon_energy = MOON_LIT
			glow_energy = GLOW_LIT
		_:
			ambient_energy = AMBIENT_FULL
			ambient_color = AMBIENT_COLOR_FULL
			moon_energy = MOON_FULL
			glow_energy = GLOW_FULL
	_env.ambient_light_energy = ambient_energy
	_env.ambient_light_color = ambient_color
	if _moon:
		_moon.light_energy = moon_energy
	if _player_glow:
		_player_glow.light_energy = glow_energy



func _on_district_stage_changed(_id: StringName, stage: int) -> void:
	apply_for_stage(stage)

func _on_weather_changed(_weather: int, _name: String, _fog: float, _rain: float) -> void:
	var dm := get_node_or_null("/root/DistrictManager")
	if dm:
		apply_for_stage(dm.get_stage(dm.current_district))

func _on_grid_updated(_v: float) -> void:
	_sync_stage_from_grid()

func _sync_stage_from_grid() -> void:
	var grid := get_node_or_null("/root/PowerGridManager")
	var dm := get_node_or_null("/root/DistrictManager")
	if grid == null or dm == null:
		return
	var did = dm.current_district
	if did.is_empty():
		return
	var restore = grid.get_restore(did)
	var new_stage := 0
	if restore >= 100:
		new_stage = 3
	elif restore >= 60:
		new_stage = 2
	elif restore > 0:
		new_stage = 1
	if new_stage > dm.get_stage(did):
		dm.set_stage(did, new_stage)

## Игрок ищется по группе: узел зовётся то "Player", то "PlayerFPS" в зависимости
## от того, как игрок попал в сцену, и поиск по имени молча возвращал null.
func _find_player_glow() -> OmniLight3D:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return null
	return player.find_child("PlayerGlow", true, false) as OmniLight3D

func _find_we(n: Node) -> WorldEnvironment:
	if n == null: return null
	if n is WorldEnvironment: return n
	for c in n.get_children():
		var r = _find_we(c)
		if r != null: return r
	return null

func _find_moon(n: Node) -> DirectionalLight3D:
	return _find_moon_r(n, null)

func _find_moon_r(n: Node, fallback: DirectionalLight3D) -> DirectionalLight3D:
	if n == null: return fallback
	if n is DirectionalLight3D:
		if "moon" in n.name.to_lower(): return n
		if fallback == null: fallback = n
	for c in n.get_children():
		var r = _find_moon_r(c, fallback)
		if r != null and "moon" in r.name.to_lower(): return r
		if r != null: fallback = r
	return fallback