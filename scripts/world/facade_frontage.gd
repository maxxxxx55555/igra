extends Node3D
## Four shared mesh/material batches give the skyline human scale without new
## lights, collision or navigation. All projection stays within the ring's apron.

const _PBR := preload("res://scripts/world/pbr_sets.gd")
const SERVICE_DISTRICTS: Array[StringName] = [&"warehouses", &"industrial", &"substation", &"power_station", &"gas_station"]

var _frames: Array[Transform3D] = []
var _recesses: Array[Transform3D] = []
var _metal: Array[Transform3D] = []
var _roof: Array[Transform3D] = []
var _rng := RandomNumberGenerator.new()
var _service: bool = false

func begin(district_id: StringName) -> void:
	_rng.seed = hash("frontage_" + String(district_id))
	_service = district_id in SERVICE_DISTRICTS

## Return the entry's horizontal interval so the caller can leave windows clear.
func add_block(frame: Transform3D, size: Vector3) -> Vector2:
	var width: float = 3.4 if _service else 1.22
	var height: float = 2.8 if _service else 2.25
	var x: float = -size.x * 0.5 + 2.3 if not _service else 0.0
	var door := frame.translated_local(Vector3(x, 0.0, 0.0))
	# Sit ahead of the existing base course (0.18 m) but behind the entry jambs.
	_box(_recesses, door, Vector3(0.0, height * 0.5, 0.24), Vector3(width, height, 0.08))
	for side: float in [-1.0, 1.0]:
		_box(_frames, door, Vector3(side * (width * 0.5 + 0.16), height * 0.5, 0.20), Vector3(0.26, height, 0.38))
	_box(_frames, door, Vector3(0.0, height + 0.13, 0.20), Vector3(width + 0.58, 0.26, 0.38))
	_box(_frames, door, Vector3(0.0, 0.09, 0.30), Vector3(width + 0.6, 0.18, 0.58))
	# The shallow canopy and its brackets break the flat wall from an oblique view.
	_box(_metal, door, Vector3(0.0, height + 0.40, 0.57), Vector3(width + 0.9, 0.12, 1.18))
	_box(_metal, door, Vector3(0.0, height + 0.29, 1.13), Vector3(width + 0.9, 0.22, 0.06))
	for side: float in [-1.0, 1.0]:
		_box(_metal, door, Vector3(side * (width * 0.5 + 0.22), height + 0.10, 0.54), Vector3(0.055, 0.055, 0.9), Vector3(-27.0, 0.0, 0.0))
	if _service:
		# Broad shutter slats, side guides and a central latch read as a service bay.
		for row: int in 13:
			_box(_metal, door, Vector3(0.0, 0.18 + row * 0.20, 0.32), Vector3(width - 0.10, 0.055, 0.08))
		_box(_metal, door, Vector3(0.0, 0.42, 0.38), Vector3(0.42, 0.06, 0.06))
	else:
		_box(_metal, door, Vector3(width * 0.32, 1.02, 0.36), Vector3(0.055, 0.28, 0.08))
		_box(_metal, door, Vector3(0.0, height * 0.68, 0.32), Vector3(width - 0.12, 0.05, 0.06))
		# A second blank panel is a sealed display window, not a false interaction.
		var display_x: float = size.x * 0.5 - 2.0
		_box(_recesses, frame, Vector3(display_x, 1.05, 0.24), Vector3(1.5, 1.34, 0.08))
		for y: float in [0.42, 1.06, 1.69]:
			_box(_metal, frame, Vector3(display_x, y, 0.34), Vector3(1.58, 0.08, 0.12))
	_roofline(frame, size)
	return Vector2(x, width)

func add_balcony(frame: Transform3D, x: float, y: float) -> void:
	var rail := frame.translated_local(Vector3(x, y - 0.65, 0.0))
	_box(_metal, rail, Vector3(0.0, 0.88, 0.73), Vector3(1.5, 0.06, 0.06))
	_box(_metal, rail, Vector3(0.0, 0.10, 0.73), Vector3(1.5, 0.045, 0.045))
	for post: int in 6:
		_box(_metal, rail, Vector3(-0.73 + post * 0.292, 0.47, 0.73), Vector3(0.035, 0.88, 0.035))
	for side: float in [-0.73, 0.73]:
		_box(_metal, rail, Vector3(side, 0.88, 0.37), Vector3(0.05, 0.06, 0.73))

func _roofline(frame: Transform3D, size: Vector3) -> void:
	var x: float = size.x * _rng.randf_range(-0.28, 0.28)
	var roof := frame.translated_local(Vector3(x, size.y, -size.z * 0.24))
	var chimney_height: float = _rng.randf_range(1.0, 2.3) if _service else _rng.randf_range(0.8, 1.35)
	_box(_roof, roof, Vector3(0.0, chimney_height * 0.5, 0.0), Vector3(0.72, chimney_height, 0.90))
	_box(_roof, roof, Vector3(0.0, chimney_height + 0.07, 0.0), Vector3(0.92, 0.14, 1.10))
	_box(_recesses, roof, Vector3(0.0, chimney_height + 0.15, 0.0), Vector3(0.53, 0.035, 0.64))
	# Aerial crossbars remain a silhouette; there is no emissive roof ornament.
	var mast := frame.translated_local(Vector3(-size.x * 0.32, size.y, -size.z * 0.55))
	_box(_metal, mast, Vector3(0.0, 1.5, 0.0), Vector3(0.055, 3.0, 0.055))
	_box(_metal, mast, Vector3(0.0, 2.6, 0.0), Vector3(1.8, 0.045, 0.045))
	for crossbar: int in 4:
		_box(_metal, mast, Vector3(-0.7 + crossbar * 0.45, 2.6, 0.0), Vector3(0.035, 0.035, 0.42 + crossbar * 0.13))
	# Interrupted parapets add a second roof edge instead of another plain cube.
	for side: float in [-1.0, 1.0]:
		_box(_roof, frame, Vector3(side * size.x * 0.5, size.y + 0.18, -size.z * 0.5), Vector3(0.20, 0.36, size.z))

func finish(detail: float) -> void:
	_batch("EntryFrames", _frames, "cracked_concrete", Color(0.42, 0.42, 0.38))
	_batch("Recesses", _recesses, "rusted_metal", Color(0.075, 0.095, 0.10))
	_batch("Metalwork", _metal, "rusted_metal", Color(0.29, 0.26, 0.21))
	_batch("RoofHardware", _roof, "painted_brick", Color(0.30, 0.29, 0.26))
	set_detail(detail)
	_frames.clear()
	_recesses.clear()
	_metal.clear()
	_roof.clear()

func set_detail(detail: float) -> void:
	for node_name: String in ["Metalwork", "RoofHardware"]:
		var node := get_node_or_null(node_name) as Node3D
		if node != null:
			node.visible = detail >= 1.0

func _box(batch: Array[Transform3D], frame: Transform3D, at: Vector3, size: Vector3, degrees: Vector3 = Vector3.ZERO) -> void:
	var angles := Vector3(deg_to_rad(degrees.x), deg_to_rad(degrees.y), deg_to_rad(degrees.z))
	batch.append(frame * Transform3D(Basis.from_euler(angles) * Basis.from_scale(size), at))

func _batch(node_name: String, transforms: Array[Transform3D], texture_set: String, tint: Color) -> void:
	if transforms.is_empty():
		return
	var mat := _PBR.apply(StandardMaterial3D.new(), texture_set)
	mat.albedo_color = tint
	mat.roughness = 0.9
	mat.emission_enabled = true
	mat.emission = Color(0.018, 0.021, 0.022) if node_name != "Recesses" else Color.BLACK
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = BoxMesh.new()
	mm.instance_count = transforms.size()
	for i: int in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var mesh := MultiMeshInstance3D.new()
	mesh.name = node_name
	mesh.multimesh = mm
	mesh.material_override = mat
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
