extends Node3D
## LampDust (Session 28, V1): the dust that hangs in the cone of a lit streetlamp and the cracks in the pavement at the foot of its pole. One MultiMesh each (two draw calls), built from the batched lamps
## and poles of the district's props; the drift of the dust is all in the shader (lamp_motes.gdshader) and nothing here runs per frame. Both follow the graphics tier (the Low tier has neither) and the dust
## follows the power of the district (no lamp is lit in the dark, so there is no dust). Seeded by the district, so a district looks the same on every visit.

const _MOTES := preload("res://assets/shaders/lamp_motes.gdshader")
const _WEAR := preload("res://assets/shaders/ground_wear.gdshader")
## Motes per lamp by graphics tier (Low, Medium, High), the strength of the dust by power stage (DARK, PARTIAL, STREETS, FULL), and a crack quad at the foot of every n-th pole by tier (0: none).
const MOTES_PER_LAMP: Array[int] = [0, 3, 6]
const STRENGTH_BY_STAGE: Array[float] = [0.0, 0.5, 0.8, 1.0]
const CRACK_EVERY: Array[int] = [0, 2, 1]
## The cone under a lamp head: the dust fills from 0.3 m below it to this depth, a quarter of a metre wide at the head and widening by this much per metre.
const CONE_DEPTH_M: float = 3.6
const CONE_SPREAD: float = 0.38
## The cracks lie just over the slabs (0.06 m) and under the lane marking (0.08 m).
const CRACK_Y: float = 0.07

var _district_id: StringName = &""
var _mote_mat: ShaderMaterial = null
var _motes: MultiMeshInstance3D = null

## `props` is the node that holds the batched lamps and poles of the district (the parent of the dressing).
func build(district_id: StringName, props: Node) -> void:
	_district_id = district_id
	var tier: int = clampi(int(SettingsManager.get_setting("graphics_tier", 2)), 0, 2)
	var lamps := props.get_node_or_null("StreetlightLampsBatched") as MultiMeshInstance3D
	var poles := props.get_node_or_null("StreetlightPolesBatched") as MultiMeshInstance3D
	if tier == 0 or lamps == null or poles == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("lamp_dust_" + String(district_id))
	_add_motes(lamps.multimesh, MOTES_PER_LAMP[tier], rng)
	_add_cracks(poles.multimesh, CRACK_EVERY[tier], rng)
	EventBus.district_stage_changed.connect(_on_stage_changed)
	_apply_stage(PowerGrid.get_stage(district_id))

func _add_motes(lamps: MultiMesh, per_lamp: int, rng: RandomNumberGenerator) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = QuadMesh.new()
	mm.instance_count = lamps.instance_count * per_lamp
	for i in lamps.instance_count:
		var head: Vector3 = lamps.get_instance_transform(i).origin
		for n in per_lamp:
			var below: float = rng.randf_range(0.3, CONE_DEPTH_M)
			var reach: float = 0.25 + CONE_SPREAD * below
			var radius: float = reach * sqrt(rng.randf())
			var around: float = rng.randf() * TAU
			var index: int = i * per_lamp + n
			mm.set_instance_transform(index, Transform3D(Basis(), head + Vector3(cos(around) * radius, -below, sin(around) * radius)))
			mm.set_instance_color(index, Color(1.0 - radius / reach, rng.randf(), rng.randf()))
	_mote_mat = ShaderMaterial.new()
	_mote_mat.shader = _MOTES
	_motes = _instance("LampMotes", mm, _mote_mat)

func _add_cracks(poles: MultiMesh, every: int, rng: RandomNumberGenerator) -> void:
	var spots: Array[Transform3D] = []
	for i in poles.instance_count:
		if i % every != 0:
			continue
		var foot: Vector3 = poles.get_instance_transform(i).origin
		var size: float = rng.randf_range(1.8, 2.8)
		var at := foot + Vector3(rng.randf_range(-0.9, 0.9), 0.0, rng.randf_range(-0.9, 0.9))
		spots.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(size, 1.0, size)), Vector3(at.x, CRACK_Y, at.z)))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE
	mm.mesh = plane
	mm.instance_count = spots.size()
	for i in spots.size():
		mm.set_instance_transform(i, spots[i])
	var wear := ShaderMaterial.new()
	wear.shader = _WEAR
	_instance("Cracks", mm, wear)

func _instance(node_name: String, mm: MultiMesh, material: Material) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = material
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	return mmi

func _on_stage_changed(id: StringName, stage: int) -> void:
	if id == _district_id:
		_apply_stage(stage)

func _apply_stage(stage: int) -> void:
	if _motes == null:
		return
	var strength: float = STRENGTH_BY_STAGE[clampi(stage, 0, STRENGTH_BY_STAGE.size() - 1)]
	_mote_mat.set_shader_parameter("strength", strength)
	_motes.visible = strength > 0.0  # a blended quad of strength 0 still costs its fill
