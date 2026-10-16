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
const FACADES: Array[Color] = [Color("#0f151d"), Color("#141b24"), Color("#182029")]
const WIN_DARK := Color(0.02, 0.025, 0.04)
const FACADE_GLOW := Color(0.06, 0.08, 0.12)
## Per district: the three facade colours and the faint self-glow of the blocks (docs/DISTRICT_SIGNATURES.md). One family of hue each, dark, never over 25 % chroma (tools/qa_sim/consistency_check.py);
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
const _FACADE := preload("res://assets/shaders/soviet_facade.gdshader")
const _ROAD := preload("res://assets/shaders/soviet_road.gdshader")
const _SIGNS := preload("res://scripts/world/soviet_signs.gd")
## How much of its self-glow a block shows, by power stage (DARK, PARTIAL, STREETS, FULL): a restored district reads lighter, a dark one stays a silhouette.
const FACADE_GAIN: Array[float] = [0.22, 0.27, 0.32, 0.36]
## The ground between the streets, linear: dark earth, and patches of dead grass.
const GROUND_EARTH := Vector3(0.050, 0.052, 0.046)
const GROUND_GRASS := Vector3(0.050, 0.062, 0.040)
## Share of the windows that carry a balcony slab, by district: the flats of a panel block have them, a warehouse has none.
const BALCONIES := {&"suburbs": 0.30, &"residential": 0.35, &"hospital": 0.12, &"school": 0.08, &"police": 0.10}
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
var _facade_mat: ShaderMaterial = null
var _ground_mat: ShaderMaterial = null
var _fronts: Array[Transform3D] = []
var _widths: Array[float] = []

## half_extent: half the street grid's size in metres (24 for the 3x3 grid of 16 m blocks).
func build(district_id: StringName, half_extent: float, with_windows: bool) -> void:
	_district_id = district_id
	var style: Array = STYLE.get(district_id, STYLE[&"suburbs"])
	var palette: Array = PALETTES.get(district_id, [FACADES, FACADE_GLOW])
	var facades: Array = palette[0]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("skyline_" + String(district_id))
	var extra := RandomNumberGenerator.new()
	extra.seed = hash("skyline_extra_" + String(district_id))
	var balconies: float = float(BALCONIES.get(district_id, 0.0))
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
			var tint: Color = facades[rng.randi() % facades.size()]
			tints.append(tint)
			_fronts.append(Transform3D(turn, turn * Vector3(cx, 0.0, -edge)))
			_widths.append(w)
			_dress_block(extra, Transform3D(turn, turn * Vector3(cx, 0.0, -edge)), Vector3(w, h, d), tint, balconies if with_windows else 0.0, blocks, tints)
			if with_windows:
				var y := 2.6
				while y < h - 1.4:
					var x := cx - w * 0.5 + 1.2
					while x < cx + w * 0.5 - 1.0:
						panes.append(Transform3D(turn, turn * Vector3(x, y, -edge + 0.04)))
						x += 2.2
					y += 2.6
	_add_multimesh("Blocks", BoxMesh.new(), blocks, tints, false, palette[1])
	_apply_gain(PowerGrid.get_stage(district_id))
	EventBus.district_stage_changed.connect(_on_stage_changed)
	if not panes.is_empty():
		var quad := QuadMesh.new()
		quad.size = WIN_SIZE
		_add_multimesh("Windows", quad, panes, no_tints, true)
		_windows = get_node("Windows") as MultiMeshInstance3D
		for i in panes.size():
			_rolls.append(rng.randf())
			_tones.append(rng.randf())
		_light_windows(PowerGrid.get_stage(district_id))
		_SIGNS.build(self, district_id, _fronts, _widths)
	_add_ground()
	_add_solid_ground(edge)

## The roof of a panel block, a stairwell and now and then a water tank and an aerial, and a balcony slab under a share of its windows (`frame` is the front face of the block at the ground, x at its middle, z toward the street).
func _dress_block(rng: RandomNumberGenerator, frame: Transform3D, size: Vector3, tint: Color, balconies: float, blocks: Array[Transform3D], tints: Array[Color]) -> void:
	var lighter := tint.lightened(0.18)
	var stair := Vector3(rng.randf_range(2.2, 3.4), 2.4, rng.randf_range(2.4, minf(4.0, size.z * 0.45)))
	_put(blocks, tints, frame, Vector3(rng.randf_range(-0.25, 0.25) * size.x, size.y + stair.y * 0.5, -size.z * rng.randf_range(0.3, 0.6)), stair, lighter)
	if rng.randf() < 0.5:
		_put(blocks, tints, frame, Vector3(rng.randf_range(-0.4, 0.4) * size.x, size.y + 0.9, -size.z * 0.7), Vector3(1.6, 1.8, 1.6), tint)
	if rng.randf() < 0.4:
		_put(blocks, tints, frame, Vector3(rng.randf_range(-0.4, 0.4) * size.x, size.y + 2.2, -size.z * 0.5), Vector3(0.12, 4.4, 0.12), tint)
	if balconies <= 0.0:
		return
	var y := 2.6
	while y < size.y - 1.4:
		var x := 1.2 - size.x * 0.5
		while x < size.x * 0.5 - 1.0:
			if rng.randf() < balconies:
				_put(blocks, tints, frame, Vector3(x, y - 0.72, 0.375), Vector3(1.5, 0.14, 0.75), lighter)
			x += 2.2
		y += 2.6

func _put(blocks: Array[Transform3D], tints: Array[Color], frame: Transform3D, at: Vector3, size: Vector3, tint: Color) -> void:
	blocks.append(frame * Transform3D(Basis.from_scale(size), at))
	tints.append(tint)

func _add_multimesh(node_name: String, mesh: Mesh, xforms: Array[Transform3D], tints: Array[Color], unshaded: bool, glow: Color = FACADE_GLOW) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		mm.set_instance_color(i, tints[i] if i < tints.size() else WIN_DARK)
	var mat: Material
	if unshaded:
		var flat := StandardMaterial3D.new()
		flat.vertex_color_use_as_albedo = true
		flat.roughness = 1.0
		flat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat = flat
	else:
		# A faint cold self-glow so the blocks read as silhouettes against the sky; the shader weathers the panels (the tier of the graphics sets how much).
		_facade_mat = ShaderMaterial.new()
		_facade_mat.shader = _FACADE
		_facade_mat.set_shader_parameter("glow", Vector3(glow.r, glow.g, glow.b))
		_set_detail()
		EventBus.settings_changed.connect(_set_detail)
		mat = _facade_mat
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)

func _add_ground() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(260.0, 260.0)
	_ground_mat = ShaderMaterial.new()
	_ground_mat.shader = _ROAD
	_ground_mat.set_shader_parameter("tint", GROUND_EARTH)
	_ground_mat.set_shader_parameter("mean_lum", 1.0)
	_ground_mat.set_shader_parameter("tint_b", GROUND_GRASS)
	_ground_mat.set_shader_parameter("mix_b", 1.0)
	_ground_mat.set_shader_parameter("damp", 0.0)
	_set_detail()
	var ground := MeshInstance3D.new()
	ground.name = "DarkGround"
	ground.mesh = plane
	ground.material_override = _ground_mat
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

func _set_detail(key: String = "graphics_tier", _value: Variant = null) -> void:
	if key == "graphics_tier":
		var detail := float(clampi(int(SettingsManager.get_setting("graphics_tier", 2)), 0, 2))
		for mat: ShaderMaterial in [_facade_mat, _ground_mat]:
			if mat != null:
				mat.set_shader_parameter("detail", detail)

func _on_stage_changed(id: StringName, stage: int) -> void:
	if id == _district_id:
		_apply_gain(stage)
		if _windows != null:
			_light_windows(stage)

func _apply_gain(stage: int) -> void:
	_facade_mat.set_shader_parameter("gain", FACADE_GAIN[clampi(stage, 0, FACADE_GAIN.size() - 1)])

func _light_windows(stage: int) -> void:
	var lit_share: float = STAGE_LIT[clampi(stage, 0, STAGE_LIT.size() - 1)]
	var mm := _windows.multimesh
	for i in mm.instance_count:
		var color := WIN_DARK
		if _rolls[i] < lit_share:
			color = (WIN_BRASS if _tones[i] < 0.8 else WIN_BONE) * (0.7 + 0.3 * _tones[i])
		mm.set_instance_color(i, color)
