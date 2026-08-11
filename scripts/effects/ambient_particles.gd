

extends GPUParticles3D
func _ready() -> void:
	emitting = true
	amount = 50
	lifetime = 8.0
	one_shot = false
		

	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, 1, 0)
	material.spread = 180.0
	material.initial_velocity_min = 0.1
	material.initial_velocity_max = 0.3
	material.gravity = Vector3(0, 0.05, 0)
	material.scale_min = 0.02
	material.scale_max = 0.05
	material.color = Color(1.0, 0.9, 0.6, 0.3)
	process_material = material
	var mesh = SphereMesh.new()
	mesh.radius = 0.01
	mesh.height = 0.02
	draw_pass_1 = mesh