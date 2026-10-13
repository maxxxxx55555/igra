extends Node3D
class_name CitySkyline
## Visual-only backdrop of a district: a dark ground plane and a ring of building
## blocks around the street grid (no collision, no navigation, one draw call each
## for the blocks and the windows). Windows light up with the district's power
## stage, so the city reads as a city that is waking up (GDD 4.2, STYLE_GUIDE 1).

const RING_GAP := 8.0
## The ground slab is flush with the street tiles (their top is 0.05 m); the facade walls stop the player at the ring.
const GROUND_TOP := 0.05
const GROUND_THICKNESS := 0.2
const WALL_HEIGHT := 12.0
const WALL_THICKNESS := 0.4
const WIN_SIZE := Vector2(0.9, 1.3)
const GROUND_COLOR := Color(0.055, 0.066, 0.082)
const FACADES: Array[Color] = [Color("#0f151d"), Color("#141b24"), Color("#182029")]
const WIN_DARK := Color(0.02, 0.025, 0.04)
const FACADE_GLOW := Color(0.06, 0.08, 0.12)
## Per district: the three facade colours and the faint self-glow of the blocks (docs/DISTRICT_SIGNATURES.md). One family of hue each, dark, never over 25 % chroma (the spread of the largest and the smallest channel on 0..1, tools/qa_sim/consistency_check.py; STYLE_GUIDE section 2);
## a district that is not listed keeps FACADES and FACADE_GLOW.
const PALETTES := {
	&"suburbs": [[Color("#141917"), Color("#181e1c"), Color("#1c2321")], Color(0.07, 0.09, 0.09)],
	&"residential": [[Color("#17171e"), Color("#1c1c25"), Color("#21212c")], Color(0.085, 0.085, 0.115)],
	&"park": [[Color("#101a15"), Color("#14201b"), Color("#182621")], Color(0.05, 0.11, 0.09)],
	&"hospital": [[Color("#101a20"), Color("#142129"), Color("#18282f")], Color(0.05, 0.10, 0.14)],
	&"gas_station": [[Color("#1b1613"), Color("#211b17"), Color("#27201b")], Color(0.115, 0.09, 0.085)],
	&"police": [[Color("#0e1320"), Color("#131a2a"), Color("#182034")], Color(0.05, 0.07, 0.15)],
	&"warehouses": [[Color("#1d1514"), Color("#241b19"), Color("#2b211f")], Color(0.12, 0.085, 0.085)],
	&"industrial": [[Color("#1c1715"), Color("#241e1b"), Color("#2b2421")], Color(0.115, 0.09, 0.09)],
	&"substation": [[Color("#14181c"), Color("#191e23"), Color("#1e242a")], Color(0.09, 0.10, 0.115)],
	&"power_station": [[Color("#15191e"), Color("#1b2026"), Color("#21262d")], Color(0.10, 0.11, 0.13)],
}
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
	var palette: Array = PALETTES.get(district_id, [FACADES, FACADE_GLOW])
	var facades: Array = palette[0]
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
			tints.append(facades[rng.randi() % facades.size()])
			if with_windows:
				var y := 2.6
				while y < h - 1.4:
					var x := cx - w * 0.5 + 1.2
					while x < cx + w * 0.5 - 1.0:
						panes.append(Transform3D(turn, turn * Vector3(x, y, -edge + 0.04)))
						x += 2.2
					y += 2.6
	_add_multimesh("Blocks", BoxMesh.new(), blocks, tints, false, palette[1])
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
	_add_solid_ground(edge)

func _add_multimesh(node_name: String, mesh: Mesh, xforms: Array[Transform3D], tints: Array[Color], unshaded: bool, glow: Color = FACADE_GLOW) -> void:
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
		mat.emission = glow
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

## The dark ground is a floor, not a picture: the blocks between the streets can be walked, and four walls along the
## building fronts keep the player inside the district (the buildings themselves stay visual).
func _add_solid_ground(edge: float) -> void:
	var body := StaticBody3D.new()
	body.name = "GroundBody"
	add_child(body)
	var reach := edge + 12.0
	_add_box(body, Vector3(reach * 2.0, GROUND_THICKNESS, reach * 2.0), Vector3(0.0, GROUND_TOP - GROUND_THICKNESS * 0.5, 0.0))
	for side in [-1.0, 1.0]:
		_add_box(body, Vector3(WALL_THICKNESS, WALL_HEIGHT, reach * 2.0), Vector3(side * edge, WALL_HEIGHT * 0.5, 0.0))
		_add_box(body, Vector3(reach * 2.0, WALL_HEIGHT, WALL_THICKNESS), Vector3(0.0, WALL_HEIGHT * 0.5, side * edge))

func _add_box(body: StaticBody3D, size: Vector3, at: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = at
	body.add_child(shape)

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
