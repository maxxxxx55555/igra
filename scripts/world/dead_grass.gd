extends MultiMeshInstance3D
## The dead grass of the courtyards (the Soviet canon of Session 27): tufts of two crossed quads, one MultiMesh for the whole district (assets/shaders/dead_grass.gdshader draws the blades, swaying
## in the wind and not drawn beyond 38 m). The graphics tier decides how many tufts of every courtyard are shown, so a change of the setting shows or hides them without a rebuild;
## Motion Comfort and Reduce UI Motion hold the blades still, as they do the canopies of the street trees.

const _SHADER := preload("res://assets/shaders/dead_grass.gdshader")
## Tufts of a courtyard shown at the Low, Medium and High tier.
const PER_COURTYARD: Array[int] = [0, 8, 16]
## The courtyards are the cells of the grid between the streets: 16 m apart, 10 m across, and 1.5 m of sidewalk all round.
const CELL_STEP: float = 16.0
const CELL_REACH: float = 3.4
const SWAY_M: float = 0.08

@export var district_id: StringName = &""
var _mat: ShaderMaterial = null

func _ready() -> void:
	name = "DeadGrass"
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("dead_grass_" + String(district_id))
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = _tuft_mesh()
	multimesh.instance_count = 9 * PER_COURTYARD[-1]
	# round and round the courtyards, so that the first N tufts of the multimesh are the first N / 9 of every one
	for i in multimesh.instance_count:
		var cell: int = i % 9
		var at := Vector3((cell % 3 - 1) * CELL_STEP + rng.randf_range(-CELL_REACH, CELL_REACH), 0.0, (cell / 3 - 1) * CELL_STEP + rng.randf_range(-CELL_REACH, CELL_REACH))
		var width: float = rng.randf_range(0.8, 1.4)
		var basis := Basis(Vector3.UP, rng.randf() * TAU) * Basis.from_scale(Vector3(width, rng.randf_range(0.5, 0.95), width))
		multimesh.set_instance_transform(i, Transform3D(basis, at))
	_mat = ShaderMaterial.new()
	_mat.shader = _SHADER
	material_override = _mat
	_apply_tier()
	_apply_sway()
	EventBus.settings_changed.connect(_on_setting_changed)

## Two quads, one metre wide and one tall, crossed; the normals point up so that a lamp lights the tuft from above.
static func _tuft_mesh() -> ArrayMesh:
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for across: Vector3 in [Vector3.RIGHT, Vector3.BACK]:
		var first: int = verts.size()
		verts.append_array(PackedVector3Array([-across * 0.5, across * 0.5, across * 0.5 + Vector3.UP, -across * 0.5 + Vector3.UP]))
		uvs.append_array(PackedVector2Array([Vector2(0.0, 1.0), Vector2(1.0, 1.0), Vector2(1.0, 0.0), Vector2(0.0, 0.0)]))
		normals.append_array(PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP]))
		indices.append_array(PackedInt32Array([first, first + 1, first + 2, first, first + 2, first + 3]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _apply_tier() -> void:
	var tier: int = clampi(int(SettingsManager.get_setting("graphics_tier", 2)), 0, PER_COURTYARD.size() - 1)
	multimesh.visible_instance_count = 9 * PER_COURTYARD[tier]
	visible = tier > 0

func _apply_sway() -> void:
	var calm: bool = bool(SettingsManager.get_setting("reduce_camera_motion", false)) or bool(SettingsManager.get_setting("reduce_ui_motion", false))
	_mat.set_shader_parameter("sway", 0.0 if calm else SWAY_M)

func _on_setting_changed(key: String, _value: Variant) -> void:
	if key == "graphics_tier":
		_apply_tier()
	elif key == "reduce_camera_motion" or key == "reduce_ui_motion":
		_apply_sway()
