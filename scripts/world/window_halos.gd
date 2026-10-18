extends RefCounted
## WindowHalos (Session 28, V1): the faint glow a lit pane throws on the wall round it. One MultiMesh of larger additive quads a centimetre behind the glass, one per pane (window_halo.gdshader), lit with the panes by
## their power stage. The skyline owns the panes and sets each halo's colour to its pane's lamp (black for a dark pane, which adds nothing); it builds none at the Low tier, which has no panes.

const _SHADER := preload("res://assets/shaders/window_halo.gdshader")
## The quad is this many times the pane; its strength by power stage (DARK, PARTIAL, STREETS, FULL): a strength of 1 was a haze nobody could see from the street, a boosted 8 a bold ring, and 3 at FULL a soft warm one.
const SCALE: float = 2.2
const BY_STAGE: Array[float] = [0.8, 1.6, 2.4, 3.0]

static func build(parent: Node3D, panes: Array[Transform3D], pane_size: Vector2) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var quad := QuadMesh.new()
	quad.size = pane_size * SCALE
	mm.mesh = quad
	mm.instance_count = panes.size()
	for i in panes.size():
		mm.set_instance_transform(i, Transform3D(panes[i].basis, panes[i].origin - panes[i].basis.z * 0.01))
		mm.set_instance_color(i, Color.BLACK)
	var material := ShaderMaterial.new()
	material.shader = _SHADER
	material.set_shader_parameter("scale", SCALE)
	var halos := MultiMeshInstance3D.new()
	halos.name = "WindowHalos"
	halos.multimesh = mm
	halos.material_override = material
	halos.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(halos)
	return halos

static func set_stage(halos: MultiMeshInstance3D, stage: int) -> void:
	(halos.material_override as ShaderMaterial).set_shader_parameter("strength", BY_STAGE[clampi(stage, 0, BY_STAGE.size() - 1)])
