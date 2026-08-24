class_name VFXBurst
extends GPUParticles3D
## One-shot burst VFX: hit/blood/muzzle scenes each set their own
## amount/lifetime/one_shot/explosiveness directly on the node and their
## look via the exports below. FINAL PERFECTION P2.2: the three vfx_*.tscn
## scenes used to share ambient_particles.gd, which overwrote every scene's
## amount/lifetime/one_shot with the same "background dust" values in
## _ready() - none of the per-scene tuning ever took effect, and nothing
## instantiated them anyway.

@export var burst_color: Color = Color(1.0, 0.6, 0.2, 1.0)
@export var burst_texture: Texture2D = null
@export var spread_deg: float = 45.0
@export var velocity_min: float = 1.5
@export var velocity_max: float = 4.0
@export var gravity: Vector3 = Vector3(0.0, -4.0, 0.0)
@export var particle_scale_min: float = 0.04
@export var particle_scale_max: float = 0.09
@export var emit_direction: Vector3 = Vector3(0.0, 1.0, 0.0)

func _ready() -> void:
	var mat := ParticleProcessMaterial.new()
	mat.direction = emit_direction
	mat.spread = spread_deg
	mat.initial_velocity_min = velocity_min
	mat.initial_velocity_max = velocity_max
	mat.gravity = gravity
	mat.scale_min = particle_scale_min
	mat.scale_max = particle_scale_max
	mat.color = burst_color
	process_material = mat
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.0, 1.0)
	if burst_texture != null:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_texture = burst_texture
		m.vertex_color_use_as_albedo = true
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		mesh.material = m
	draw_pass_1 = mesh
	if one_shot:
		finished.connect(queue_free)
	emitting = true
