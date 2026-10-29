extends RefCounted
## What makes a batched streetlight read as built and not as a bright stick (the v8 contract): a flared foot where the pole meets the ground and a shade over the bulb. Two MultiMeshes of low cylinders on the
## pole's own material, so two draw calls a district; they take no part in the shadow pass. The poles and heads themselves are street_props.gd's.

const FOOT_HEIGHT_M: float = 0.7
const SHADE_LIFT_M: float = 0.1  # the shade sits this far over the bulb

static func build(parent: Node3D, spots: Array[Vector3], head_offset: Vector3, mat: Material, segments: int) -> void:
	var foot := CylinderMesh.new()
	foot.top_radius = 0.1
	foot.bottom_radius = 0.2
	foot.height = FOOT_HEIGHT_M
	var shade := CylinderMesh.new()
	shade.top_radius = 0.03
	shade.bottom_radius = 0.26
	shade.height = 0.16
	for part: Array in [["StreetlightFeet", foot, Vector3(0.0, FOOT_HEIGHT_M * 0.5, 0.0)], ["StreetlightShades", shade, head_offset + Vector3(0.0, SHADE_LIFT_M, 0.0)]]:
		var mesh: CylinderMesh = part[1]
		mesh.radial_segments = segments
		mesh.rings = 1
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = spots.size()
		for i in spots.size():
			mm.set_instance_transform(i, Transform3D(Basis(), spots[i] + (part[2] as Vector3)))
		var mmi := MultiMeshInstance3D.new()
		mmi.name = part[0]
		mmi.multimesh = mm
		mmi.material_override = mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mmi)
