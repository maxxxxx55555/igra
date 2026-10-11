extends RefCounted
## The glow around a lit lamp head (assets/shaders/lamp_halo.gdshader): one camera-facing quad per lamp in a MultiMesh, one more draw per
## district, from the Medium tier up. Its strength follows the lamp head's power stage (street_props.gd), so a DARK district has none
## and "the streetlights turn on" reads from afar.

const SHADER := preload("res://assets/shaders/lamp_halo.gdshader")
const STRENGTH: Array[float] = [0.0, 0.35, 0.7, 1.0]
const SIZE: float = 3.0
const MIN_TIER: int = 1

static func wanted() -> bool:
	return int(SettingsManager.get_setting("graphics_tier", 2)) >= MIN_TIER

## A quad over each position (local to `parent`) plus the head offset, added to `parent` and set to the stage.
static func build(parent: Node3D, positions: Array[Vector3], head_offset: Vector3, stage: int) -> MultiMeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = Vector2(SIZE, SIZE)
	var halos := MultiMesh.new()
	halos.transform_format = MultiMesh.TRANSFORM_3D
	halos.mesh = quad
	halos.instance_count = positions.size()
	for i in positions.size():
		halos.set_instance_transform(i, Transform3D(Basis(), positions[i] + head_offset))
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "StreetlightHalosBatched"
	mmi.multimesh = halos
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)
	apply_stage(mmi, stage)
	return mmi

static func apply_stage(mmi: MultiMeshInstance3D, stage: int) -> void:
	if mmi == null:
		return
	var strength: float = STRENGTH[clampi(stage, 0, STRENGTH.size() - 1)]
	(mmi.material_override as ShaderMaterial).set_shader_parameter("strength", strength)
	mmi.visible = strength > 0.0
