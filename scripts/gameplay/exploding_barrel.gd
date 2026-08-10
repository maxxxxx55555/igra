
extends RigidBody3D

@export 
var explosion_damage: int = 50

@export 
var explosion_radius: float = 5.0

@onready 
var mesh: MeshInstance3D = $MeshInstance3D

@onready 
var explosion_particles: GPUParticles3D = $ExplosionParticles

@onready 
var explosion_light: OmniLight3D = $ExplosionLight

var _exploded: bool = false

func take_damage(amount: int) -> void:
	if _exploded:
		return
	_exploded = true
	_explode()

func _explode() -> void:
	var space := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := SphereShape3D.new()
	shape.radius = explosion_radius
	query.shape = shape
	query.transform = global_transform
	var results := space.intersect_shape(query)
	for result in results:
		var body := result.collider as Node3D
		if body.is_in_group("enemy") or body.is_in_group("player"):
			if body.has_method("take_damage"):
				body.take_damage(explosion_damage, global_position, EnemyRosterData.DamageType.FIRE)
			elif body.has_node("HealthComponent"):
				body.get_node("HealthComponent").take_damage(explosion_damage)

	# VFX
	if explosion_particles:
		explosion_particles.emitting = true
	if explosion_light:
		explosion_light.visible = true
		
		var tween := create_tween()
		tween.tween_property(explosion_light, "light_energy", 0.0, 0.5)

	# Hide mesh
	mesh.visible = false
	$CollisionShape3D.disabled = true

	await get_tree().create_timer(2.0).timeout
	queue_free()
