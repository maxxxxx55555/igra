extends Node3D
class_name CitySkyline
## Visual-only backdrop of a district: a dark ground plane and a ring of building
## blocks around the street grid (no collision, no navigation, one draw call each
## for the blocks and the windows). Windows light up with the district's power
## stage, so the city reads as a city that is waking up (GDD 4.2, STYLE_GUIDE 1).

const RING_GAP := 8.0
const WIN_SIZE := Vector2(0.9, 1.3)
const GROUND_COLOR := Color(0.055, 0.066, 0.082)
const FACADES: Array[Color] = [Color("#0f151d"), Color("#141b24"), Color("#182029")]
const WIN_DARK := Color(0.02, 0.025, 0.04)
const FACADE_GLOW := Color(0.06, 0.08, 0.12)
const WIN_BRASS := Color(0.79, 0.635, 0.29)
const WIN_BONE := Color(0.85, 0.82, 0.77)
## Share of windows lit per power stage: DARK, PARTIAL, STREETS, FULL.
const STAGE_LIT: Array[float] = [0.04, 0.30, 0.60, 0.90]
## Per district: [min height, max height, min width, max width, share of empty lots].
const STYLE := {
	&"suburbs": [6.0, 9.0, 8.0, 11.0, 0.25],
	&"residential": [14.0, 22.0, 9.0, 12.0, 0.10],
	&"park": [6.0, 10.0, 8.0, 11.0, 0.55],
	&"school": [8.0, 12.0, 10.0, 14.0, 0.30],
	&"hospital": [14.0, 24.0, 10.0, 14.0, 0.15],
	&"gas_station": [5.0, 8.0, 8.0, 12.0, 0.45],
	&"police": [10.0, 16.0, 9.0, 12.0, 0.20],
	&"warehouses": [7.0, 10.0, 12.0, 18.0, 0.20],
	&"industrial": [10.0, 18.0, 10.0, 16.0, 0.20],
	&"substation": [6.0, 10.0, 8.0, 12.0, 0.40],
	&"power_station": [16.0, 28.0, 10.0, 16.0, 0.20],
}

var _district_id: StringName = &""
var _windows: MultiMeshInstance3D
var _rolls := PackedFloat32Array()
var _tones := PackedFloat32Array()

## half_extent: half the street grid's size in metres (24 for the 3x3 grid of 16 m blocks).
func build(district_id: StringName, half_extent: float, with_windows: bool) -> void:
	_district_id = district_id
	var style: Array = STYLE.get(district_id, STYLE[&"suburbs"])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("skyline_" + String(district_id))
	var edge := half_extent + RING_GAP
	var blocks: Array[Transform3D] = []
	var tints: Array[Color] = []
	var panes: Array[Transform3D] = []
	var no_tints: Array[Color] = []
	for side in 4:
		var turn := Basis(Vector3.UP, side * PI * 0.5)
		# North and south rings run past the corners, east and west stop short of them.
		var span := edge + 12.0 if side % 2 == 0 else edge
		var along := -span
		while along < span:
			var w: float = rng.randf_range(style[2], style[3])
			var d: float = rng.randf_range(8.0, 12.0)
			var h: float = rng.randf_range(style[0], style[1])
			var skip: bool = rng.randf() < float(style[4])
			var cx := along + w * 0.5
			along += w + rng.randf_range(1.0, 3.0)
			if skip:
				continue
			blocks.append(Transform3D(turn * Basis.from_scale(Vector3(w, h, d)), turn * Vector3(cx, h * 0.5, -edge - d * 0.5)))
			tints.append(FACADES[rng.randi() % FACADES.size()])
			if with_windows:
				var y := 2.6
				while y < h - 1.4:
					var x := cx - w * 0.5 + 1.2
					while x < cx + w * 0.5 - 1.0:
						panes.append(Transform3D(turn, turn * Vector3(x, y, -edge + 0.04)))
						x += 2.2
					y += 2.6
	_add_multimesh("Blocks", BoxMesh.new(), blocks, tints, false)
	if not panes.is_empty():
		var quad := QuadMesh.new()
		quad.size = WIN_SIZE
		_add_multimesh("Windows", quad, panes, no_tints, true)
		_windows = get_node("Windows") as MultiMeshInstance3D
		for i in panes.size():
			_rolls.append(rng.randf())
			_tones.append(rng.randf())
		EventBus.district_stage_changed.connect(_on_stage_changed)
		_light_windows(PowerGrid.get_stage(district_id))
	_add_ground()

func _add_multimesh(node_name: String, mesh: Mesh, xforms: Array[Transform3D], tints: Array[Color], unshaded: bool) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		mm.set_instance_color(i, tints[i] if i < tints.size() else WIN_DARK)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	else:
		# A faint cold self-glow so the blocks read as silhouettes against the sky.
		mat.emission_enabled = true
		mat.emission = FACADE_GLOW
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)

func _add_ground() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(260.0, 260.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = GROUND_COLOR
	mat.roughness = 1.0
	var ground := MeshInstance3D.new()
	ground.name = "DarkGround"
	ground.mesh = plane
	ground.material_override = mat
	ground.position.y = -0.05
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ground)

func _on_stage_changed(id: StringName, stage: int) -> void:
	if id == _district_id:
		_light_windows(stage)

func _light_windows(stage: int) -> void:
	var lit_share: float = STAGE_LIT[clampi(stage, 0, STAGE_LIT.size() - 1)]
	var mm := _windows.multimesh
	for i in mm.instance_count:
		var color := WIN_DARK
		if _rolls[i] < lit_share:
			color = (WIN_BRASS if _tones[i] < 0.8 else WIN_BONE) * (0.7 + 0.3 * _tones[i])
		mm.set_instance_color(i, color)
