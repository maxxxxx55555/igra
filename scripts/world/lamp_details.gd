extends Node3D
## LampDetails (Session 28, V1): what a lit streetlamp does to its surroundings. A cone of faint light from the lamp head to the ground (one MultiMesh, lamp_cone.gdshader: brass-dim and additive, its edges melt
## away, it fades out near the camera and far away, and it follows the power of the district, so a lamp that is dark throws none). It is built from the district's batched lamps (one draw call), follows the graphics
## tier (the Low tier has none) and nothing here runs per frame. Cracks in the pavement at the foot of a pole were tried and went: at a strength the style allows they cannot be seen (docs/TZ_DECISIONS.md, V1-28).

const _CONE := preload("res://assets/shaders/lamp_cone.gdshader")
## The strength of the cone by power stage (DARK, PARTIAL, STREETS, FULL).
const STRENGTH_BY_STAGE: Array[float] = [0.0, 0.45, 0.8, 1.2]
## The cone is a cylinder this wide at the ground and this wide at the lamp head.
const CONE_FOOT_RADIUS_M: float = 2.2
const CONE_HEAD_RADIUS_M: float = 0.1

var _district_id: StringName = &""
var _cone_mat: ShaderMaterial = null
var _cones: MultiMeshInstance3D = null

## `props` is the node that holds the batched lamps of the district (the parent of the dressing).
func build(district_id: StringName, props: Node) -> void:
	_district_id = district_id
	var tier: int = clampi(int(SettingsManager.get_setting("graphics_tier", 2)), 0, 2)
	var lamps := props.get_node_or_null("StreetlightLampsBatched") as MultiMeshInstance3D
	if tier == 0 or lamps == null:
		return
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
	mm.instance_count = lamps.multimesh.instance_count
	for i in mm.instance_count:
		var head: Vector3 = lamps.multimesh.get_instance_transform(i).origin
		var length: float = maxf(head.y - 0.08, 0.5)
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(1.0, length, 1.0)), Vector3(head.x, head.y - length * 0.5, head.z)))
	_cone_mat = ShaderMaterial.new()
	_cone_mat.shader = _CONE
	_cones = MultiMeshInstance3D.new()
	_cones.name = "LampCones"
	_cones.multimesh = mm
	_cones.material_override = _cone_mat
	_cones.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_cones)
	EventBus.district_stage_changed.connect(_on_stage_changed)
	_apply_stage(PowerGrid.get_stage(district_id))

func _on_stage_changed(id: StringName, stage: int) -> void:
	if id == _district_id:
		_apply_stage(stage)

func _apply_stage(stage: int) -> void:
	if _cones == null:
		return
	var strength: float = STRENGTH_BY_STAGE[clampi(stage, 0, STRENGTH_BY_STAGE.size() - 1)]
	_cone_mat.set_shader_parameter("strength", strength)
	_cones.visible = strength > 0.0  # a blended cone of strength 0 still costs its fill
