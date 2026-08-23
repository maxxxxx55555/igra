extends Node
## Per-district visual grading. Drives Environment tints + fog.
## Listens to DistrictThemes.theme_changed.

@export var world_environment_path: NodePath
@export var district_root_path: NodePath

var _env: WorldEnvironment
var _root: Node3D
var _ready_done: bool = false

## Fog density scales with the graphics tier (LOW..ULTRA) so weaker presets
## read a touch clearer and the top tier leans into the mood a bit more.
const _FOG_TIER_MULT: Array[float] = [0.6, 0.85, 1.0, 1.15]

## GDD §11.1: DARK почти pitch-black (ambient 0.03), LIT/FULL 0.11/0.16.
## PARTIAL (между DARK и STREETS) не описан явно — берём среднее.
## Индексы соответствуют DistrictData.Stage (DARK/PARTIAL/STREETS/FULL).
const _STAGE_AMBIENT: Array[float] = [0.03, 0.06, 0.11, 0.16]

func _ready() -> void:
	_env = get_node_or_null(world_environment_path) as WorldEnvironment
	_root = get_node_or_null(district_root_path) as Node3D
	if not DistrictThemes.theme_changed.is_connected(_apply):
		DistrictThemes.theme_changed.connect(_apply)
	if not EventBus.settings_changed.is_connected(_on_settings_changed):
		EventBus.settings_changed.connect(_on_settings_changed)
	if not EventBus.district_stage_changed.is_connected(_on_stage_changed):
		EventBus.district_stage_changed.connect(_on_stage_changed)
	_ready_done = true
	call_deferred("_apply", DistrictThemes.current_id)

func _on_settings_changed(key: String, _value: Variant) -> void:
	if key == "graphics_tier":
		_apply(DistrictThemes.current_id)

## «Тьма → зажглись фонари» (GDD §11.1) — раньше ambient менялся только при
## входе в район и никогда при восстановлении питания в уже загруженном.
func _on_stage_changed(district_id: StringName, _stage: int) -> void:
	if district_id == DistrictThemes.current_id:
		_apply(district_id)

func _ambient_energy_for(district_id: StringName) -> float:
	var stage: int = clampi(PowerGrid.get_stage(district_id), 0, _STAGE_AMBIENT.size() - 1)
	return _STAGE_AMBIENT[stage]

func _fog_multiplier() -> float:
	var tier: int = clampi(int(SettingsManager.get_setting("graphics_tier", 2)), 0, _FOG_TIER_MULT.size() - 1)
	return _FOG_TIER_MULT[tier]

func _apply(district_id: StringName) -> void:
	if not _ready_done:
		return
	var theme: Dictionary = DistrictThemes.get_theme(district_id)
	if _env != null and _env.environment != null:
		var e: Environment = _env.environment
		e.background_mode = Environment.BG_COLOR
		e.background_color = Color(theme.get("sky", Color.BLACK))
		var fog: Color = Color(theme.get("fog", Color.GRAY))
		e.fog_enabled = true
		e.fog_color = fog
		e.fog_density = (0.012 if String(district_id) != "park" else 0.006) * _fog_multiplier()
		e.ambient_light_color = Color(theme.get("ambient", Color.WHITE))
		e.ambient_light_energy = _ambient_energy_for(district_id)
		e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	if _root != null:
		_apply_ground(_root, Color(theme.get("primary", Color.GRAY)), district_id)

## District floor tileset if the art pass generated one for this district;
## flat albedo_color tint always applies underneath/alongside it, so a
## district with no tileset yet still reads correctly (procedural fallback).
func _apply_ground(root: Node3D, c: Color, district_id: StringName) -> void:
	for child in root.get_children():
		if child is MeshInstance3D and String((child as MeshInstance3D).name) == "Ground":
			var mi: MeshInstance3D = child
			var m := StandardMaterial3D.new()
			m.albedo_color = c
			m.roughness = 0.95
			var tex_path := "res://assets/textures/tiles/%s_floor.png" % String(district_id)
			if ResourceLoader.exists(tex_path):
				m.albedo_texture = load(tex_path)
				m.uv1_scale = Vector3(4.0, 4.0, 1.0)
			mi.material_override = m