extends Node3D

@export var spawn_points: Array[Vector3] = []
@export var max_enemies: int = 5
@export var spawn_interval: float = 30.0
@export var enemy_scene: PackedScene = null

var _alive: Array = []
var _timer: float = 0.0

func _ready() -> void:
	if spawn_points.is_empty():
		spawn_points = [Vector3(0, 0, 5), Vector3(10, 0, -3), Vector3(-8, 0, 12), Vector3(5, 0, -10), Vector3(-5, 0, -15)]
	for i in range(min(max_enemies, spawn_points.size())):
		_spawn_at(i)
	print("ENEMY_SPAWNER ready points=", spawn_points.size(), " max=", max_enemies)

func _process(delta: float) -> void:
	_alive = _alive.filter(func(e): return is_instance_valid(e))
	if _alive.size() < max_enemies:
		_timer += delta
		if _timer >= spawn_interval:
			_timer = 0.0
			_spawn_one()

func _spawn_one() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var valid_points := spawn_points.duplicate()
	valid_points.shuffle()
	for pt in valid_points:
		if player and pt.distance_to(player.global_position) < 20.0:
			continue
		_spawn_at_pos(pt)
		return

func _spawn_at(idx: int) -> void:
	if idx < spawn_points.size():
		_spawn_at_pos(spawn_points[idx])

func _spawn_at_pos(pos: Vector3) -> void:
	var enemy := Enemy3D.new()
	enemy.global_position = pos
	enemy.patrol_points = _generate_patrol(pos)
	add_child(enemy)
	_alive.append(enemy)

func _generate_patrol(center: Vector3) -> Array[Vector3]:
	var pts: Array[Vector3] = []
	for i in 4:
		var angle := randf() * TAU
		var dist := 3.0 + randf() * 4.0
		pts.append(center + Vector3(cos(angle) * dist, 0, sin(angle) * dist))
	return pts
