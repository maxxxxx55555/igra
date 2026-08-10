extends CharacterBody3D

@export var speed: float = 3.5
@export var patrol_points: Array[NodePath]
@export var rotation_speed: float = 5.0

var _index: int = 0
var _points: Array[Vector3] = []
@onready var _nav: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
	for p in patrol_points:
		var node := get_node(p) as Node3D
		if node:
			_points.append(node.global_position)
	if _points.size() > 0:
		_next_point()

func _physics_process(delta: float) -> void:
	if _points.size() == 0:
		return
	if _nav.is_navigation_finished():
		_next_point()
	var next_pos := _nav.get_next_path_position()
	var dir := global_position.direction_to(next_pos)
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	velocity += get_gravity() * delta
	if dir.length() > 0.01:
		var target_rot := atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot, rotation_speed * delta)
	move_and_slide()

func _next_point() -> void:
	_index = (_index + 1) % _points.size()
	_nav.target_position = _points[_index]