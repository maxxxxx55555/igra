extends Node
## Per-district ground grading from DistrictThemes.theme_changed.
## The Environment branch that used to live here was dead (its world_environment_path export was never set by
## world_bootstrap.gd); the live stage fog/ambient owner is scripts/world_env_setup.gd, the single writer.

@export var district_root_path: NodePath

var _root: Node3D
var _ready_done: bool = false

func _ready() -> void:
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

func _apply(district_id: StringName) -> void:
	if not _ready_done:
		return
	var theme: Dictionary = DistrictThemes.get_theme(district_id)
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