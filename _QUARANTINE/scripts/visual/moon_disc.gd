extends Node3D
## Big procedural moon disc (white sprite quad facing camera).

const RADIUS := 8.0

func _ready() -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = SphereMesh.new()
	(mi.mesh as SphereMesh).radius = RADIUS
	(mi.mesh as SphereMesh).height = RADIUS * 2.0
	(mi.mesh as SphereMesh).radial_segments = 24
	(mi.mesh as SphereMesh).rings = 12
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.96, 0.96, 1.00)
	mat.emission_enabled = true
	mat.emission = Color(0.92, 0.94, 1.00)
	mat.emission_energy_multiplier = 1.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.disable_receive_shadows = true
	mi.material_override = mat
	add_child(mi)
	position = Vector3(60.0, 80.0, -120.0)