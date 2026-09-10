extends MultiMeshInstance3D

@export var cols: int = 16
@export var rows: int = 4
@export var density: float = 0.55
@export var warm_bias: float = 0.75
@export var seed_value: int = 0
## Sibling node that carries district_id — present as "../StreetBuilder" in
## every scenes/districts/*.tscn. Used to react to that district's power stage.
@export var street_builder_path: NodePath = ^"../StreetBuilder"

var _rng := RandomNumberGenerator.new()
var _district_id: StringName = &""
## Per-window: the roll that decides how easily it lights, and its lit colour.
var _rolls: PackedFloat32Array = PackedFloat32Array()
var _lit_colors: PackedColorArray = PackedColorArray()

## GDD §4.2: windows come alive as a district gets power — DARK almost none,
## PARTIAL some, STREETS most, FULL all (FULL == the original behaviour).
const _STAGE_GATE: Array[float] = [0.10, 0.45, 0.85, 1.0]
const _STAGE_BRIGHT: Array[float] = [0.35, 0.60, 0.85, 1.0]
const _DARK_COL := Color(0.02, 0.025, 0.04)

func _ready() -> void:
	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.seed = hash(str(get_path()))
	var count := cols * rows
	multimesh = MultiMesh.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.5, 0.7)
	multimesh.mesh = qm
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.instance_count = count
	_rolls.resize(count)
	_lit_colors.resize(count)
	var ox := -cols * 1.6 * 0.5
	for r in rows:
		for c in cols:
			var idx := r * cols + c
			var t := Transform3D()
			t.origin = Vector3(ox + (c + 0.5) * 1.6, 1.5 + (r + 0.5) * 2.2, 0)
			multimesh.set_instance_transform(idx, t)
			_rolls[idx] = _rng.randf()
			_lit_colors[idx] = Color(1.0, 0.85, 0.55) if _rng.randf() < warm_bias else Color(0.55, 0.7, 1.0)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	material_override = mat

	var sb := get_node_or_null(street_builder_path)
	if sb != null:
		var d: Variant = sb.get("district_id")
		if d != null:
			_district_id = d
	EventBus.district_stage_changed.connect(_on_stage_changed)
	var dm := get_node_or_null("/root/DistrictManager")
	# No district context (procedural fallback) -> behave as before (FULL).
	var st: int = dm.get_stage(_district_id) if (dm != null and _district_id != &"") else 3
	_apply_stage(st)

func _on_stage_changed(id: StringName, stage: int) -> void:
	if id == _district_id:
		_apply_stage(stage)

func _apply_stage(stage: int) -> void:
	if multimesh == null:
		return
	var s: int = clampi(stage, 0, 3)
	var gate: float = density * _STAGE_GATE[s]
	var bright: float = _STAGE_BRIGHT[s]
	for idx in _rolls.size():
		if _rolls[idx] < gate:
			var c: Color = _lit_colors[idx]
			multimesh.set_instance_color(idx, Color(c.r * bright, c.g * bright, c.b * bright))
		else:
			multimesh.set_instance_color(idx, _DARK_COL)
