extends Node
## Per-district visual grading. Drives Environment tints + fog.
## Listens to DistrictThemes.theme_changed.

@export var world_environment_path: NodePath
@export var district_root_path: NodePath

var _env: WorldEnvironment
var _root: Node3D
var _ready_done: bool = false

func _ready() -> void:
	_env = get_node_or_null(world_environment_path) as WorldEnvironment
	_root = get_node_or_null(district_root_path) as Node3D
	if not DistrictThemes.theme_changed.is_connected(_apply):
		DistrictThemes.theme_changed.connect(_apply)
	_ready_done = true
	call_deferred("_apply", DistrictThemes.current_id)

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
		e.fog_density = 0.012 if String(district_id) != "park" else 0.006
		e.ambient_light_color = Color(theme.get("ambient", Color.WHITE))
		e.ambient_light_energy = 0.4
		e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	if _root != null:
		_apply_ground(_root, Color(theme.get("primary", Color.GRAY)))

func _apply_ground(root: Node3D, c: Color) -> void:
	for child in root.get_children():
		if child is MeshInstance3D and String((child as MeshInstance3D).name) == "Ground":
			var mi: MeshInstance3D = child
			var m := StandardMaterial3D.new()
			m.albedo_color = c
			m.roughness = 0.95
			mi.material_override = m