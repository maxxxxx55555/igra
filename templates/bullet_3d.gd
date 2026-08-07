extends Area3D

@export var speed: float = 20.0
@export var damage: float = 10.0
@export var lifetime: float = 2.0

var _velocity: Vector3

func _ready() -> void:
	body_entered.connect(_on_hit)
	area_entered.connect(_on_hit)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func shoot(origin: Vector3, dir: Vector3) -> void:
	global_position = origin
	_velocity = dir * speed
	look_at(origin + dir, Vector3.UP)

func _physics_process(delta: float) -> void:
	position += _velocity * delta

func _on_hit(node: Node) -> void:
	if node.has_method("take_damage"):
		node.take_damage(damage)
	queue_free()