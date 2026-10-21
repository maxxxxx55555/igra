extends RigidBody3D
## The noise bomb (docs/AI_STEALTH.md): a craftable consumable that did nothing until Session 23. Thrown along the aim it pops at the first thing it
## hits, or FUSE_SEC after the throw, with a bang that monsters hear: every monster inside NOISE_RADIUS that has not seen the player goes to look at
## the spot (base_monster.gd, `_on_noise_emitted`), so a thrown bomb pulls a patrol away from a door.

const NOISE_RADIUS: float = 24.0
const THROW_SPEED: float = 11.0
const THROW_LIFT: float = 3.0
const FUSE_SEC: float = 2.5
const BOMB_RADIUS: float = 0.08
const CASING := Color("#2a3340")
const POP_SOUND := preload("res://assets/audio/sfx/shot_heavy.ogg")
const SPARK := preload("res://scenes/vfx/vfx_hit_spark.tscn")
const _Pool := preload("res://scripts/effects/vfx_pool.gd")

var _popped: bool = false

func _ready() -> void:
	name = "NoiseBomb"
	collision_layer = 0
	collision_mask = 1
	contact_monitor = true
	max_contacts_reported = 2
	var shape := CollisionShape3D.new()
	var ball := SphereShape3D.new()
	ball.radius = BOMB_RADIUS
	shape.shape = ball
	add_child(shape)
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = BOMB_RADIUS
	sphere.height = BOMB_RADIUS * 2.0
	var casing := StandardMaterial3D.new()
	casing.albedo_color = CASING
	casing.metallic = 0.5
	casing.roughness = 0.5
	sphere.material = casing
	mesh.mesh = sphere
	add_child(mesh)
	body_entered.connect(func(_body: Node) -> void: pop())
	get_tree().create_timer(FUSE_SEC).timeout.connect(pop)

## Puts the bomb at `from` and throws it along `aim`.
func launch(from: Vector3, aim: Vector3) -> void:
	global_position = from
	linear_velocity = aim.normalized() * THROW_SPEED + Vector3.UP * THROW_LIFT

func pop() -> void:
	if _popped or not is_inside_tree():
		return
	_popped = true
	EventBus.noise_emitted.emit(Vector2(global_position.x, global_position.z), NOISE_RADIUS)
	AudioManager.play_sound_3d(POP_SOUND, global_position)
	_Pool.spawn(SPARK, global_position, get_tree())
	queue_free()
