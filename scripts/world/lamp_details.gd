extends Node3D
## LampDetails (Session 28, V1): what a lit streetlamp does to its surroundings. A cone of faint light from the lamp head to the ground (one MultiMesh, lamp_cone.gdshader: brass-dim and additive, its edges melt
## away, it fades out near the camera and far away, and it follows the power of the district, so a lamp that is dark throws none) and the cracks in the pavement at the foot of a pole (ground_wear.gdshader).
## Both are built from the district's batched lamps and poles (two draw calls) and follow the graphics tier (the Low tier has neither); nothing here runs per frame. Seeded by the district, so it looks the same
## on every visit.

const _CONE := preload("res://assets/shaders/lamp_cone.gdshader")
const _WEAR := preload("res://assets/shaders/ground_wear.gdshader")
## The strength of the cone by power stage (DARK, PARTIAL, STREETS, FULL), and a crack quad at the foot of every n-th pole by graphics tier (Low, Medium, High; 0: none).
const STRENGTH_BY_STAGE: Array[float] = [0.0, 0.10, 0.16, 0.22]
const CRACK_EVERY: Array[int] = [0, 2, 1]
## The cone is a cylinder this wide at the ground and this wide at the lamp head.
const CONE_FOOT_RADIUS_M: float = 2.2
const CONE_HEAD_RADIUS_M: float = 0.1
## The cracks lie just over the slabs (0.06 m) and under the lane marking (0.08 m).
const CRACK_Y: float = 0.07

var _district_id: StringName = &""
var _cone_mat: ShaderMaterial = null
var _cones: MultiMeshInstance3D = null

## `props` is the node that holds the batched lamps and poles of the district (the parent of the dressing).
func build(district_id: StringName, props: Node) -> void:
	_district_id = district_id
	var tier: int = clampi(int(SettingsManager.get_setting("graphics_tier", 2)), 0, 2)
	var lamps := props.get_node_or_null("StreetlightLampsBatched") as MultiMeshInstance3D
	var poles := props.get_node_or_null("StreetlightPolesBatched") as MultiMeshInstance3D
	if tier == 0 or lamps == null or poles == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("lamp_details_" + String(district_id))
	_add_cones(lamps.multimesh)
	_add_cracks(poles.multimesh, CRACK_EVERY[tier], rng)
	EventBus.district_stage_changed.connect(_on_stage_changed)
	_apply_stage(PowerGrid.get_stage(district_id))

func _add_cones(lamps: MultiMesh) -> void:
	var cone := CylinderMesh.new()
	cone.top_radius = CONE_HEAD_RADIUS_M
	cone.bottom_radius = CONE_FOOT_RADIUS_M
	cone.height = 1.0
	cone.radial_segments = 14
	cone.rings = 1
	cone.cap_top = false
	cone.cap_bottom = false
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cone
	mm.instance_count = lamps.instance_count
	for i in lamps.instance_count:
		var head: Vector3 = lamps.get_instance_transform(i).origin
		var length: float = maxf(head.y - 0.08, 0.5)
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(1.0, length, 1.0)), Vector3(head.x, head.y - length * 0.5, head.z)))
	_cone_mat = ShaderMaterial.new()
	_cone_mat.shader = _CONE
	_cones = _instance("LampCones", mm, _cone_mat)

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
	if _cones == null:
		return
	var strength: float = STRENGTH_BY_STAGE[clampi(stage, 0, STRENGTH_BY_STAGE.size() - 1)]
	_cone_mat.set_shader_parameter("strength", strength)
	_cones.visible = strength > 0.0  # a blended cone of strength 0 still costs its fill
