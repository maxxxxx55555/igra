extends Node

signal room_generated(room_position: Vector3, room_size: Vector3)

@export var room_scene: PackedScene
@export var wall_scene: PackedScene
@export var floor_scene: PackedScene
@export var enemy_scene: PackedScene
@export var item_scene: PackedScene
@export var room_count: int = 8
@export var room_min_size: Vector3 = Vector3(6, 4, 6)
@export var room_max_size: Vector3 = Vector3(12, 4, 12)
@export var corridor_width: float = 2.0

var _rooms: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()

func generate() -> void:
	_rng.randomize()
	_rooms.clear()
	_generate_rooms()
	_connect_rooms()
	_spawn_content()

func _generate_rooms() -> void:
	for i in range(room_count):
		var size = Vector3(
			_rng.randf_range(room_min_size.x, room_max_size.x),
			room_min_size.y,
			_rng.randf_range(room_min_size.z, room_max_size.z)
		)
		var pos = _find_valid_position(size)
		if pos == Vector3.ZERO and i > 0:
			continue
		_rooms.append({"position": pos, "size": size})
		_build_room(pos, size)
		room_generated.emit(pos, size)

func _find_valid_position(size: Vector3) -> Vector3:
	for attempt in range(50):
		var pos = Vector3(
			_rng.randi_range(-40, 40),
			0,
			_rng.randi_range(-40, 40)
		)
		if _is_valid_position(pos, size):
			return pos
	return Vector3.ZERO

func _is_valid_position(pos: Vector3, size: Vector3) -> bool:
	for room in _rooms:
		var dist = pos.distance_to(room.position)
		if dist < (size.x + room.size.x) * 0.6:
			return false
	return true

func _build_room(pos: Vector3, size: Vector3) -> void:
	# Pol
	if floor_scene:
		var floor = floor_scene.instantiate()
		floor.position = pos + Vector3(0, 0, 0)
		floor.scale = Vector3(size.x, 1, size.z)
		add_child(floor)
	# Steny
	_build_walls(pos, size)

func _build_walls(pos: Vector3, size: Vector3) -> void:
	if not wall_scene:
		return
	var half = size / 2
	var corners = [
		pos + Vector3(-half.x, 0, -half.z),
		pos + Vector3(half.x, 0, -half.z),
		pos + Vector3(half.x, 0, half.z),
		pos + Vector3(-half.x, 0, half.z)
	]
	for c in corners:
		var wall = wall_scene.instantiate()
		wall.position = c
		add_child(wall)

func _connect_rooms() -> void:
	for i in range(_rooms.size() - 1):
		var a = _rooms[i].position
		var b = _rooms[i + 1].position
		_build_corridor(a, b)

func _build_corridor(a: Vector3, b: Vector3) -> void:
	var mid = (a + b) / 2
	if floor_scene:
		var corr = floor_scene.instantiate()
		corr.position = mid
		corr.scale = Vector3(abs(a.x - b.x) + corridor_width, 0.1, corridor_width)
		add_child(corr)

func _spawn_content() -> void:
	for room in _rooms:
		if enemy_scene and _rng.randf() < 0.6:
			var enemy = enemy_scene.instantiate()
			enemy.position = room.position + Vector3(_rng.randf_range(-2, 2), 1, _rng.randf_range(-2, 2))
			add_child(enemy)
		if item_scene and _rng.randf() < 0.3:
			var item = item_scene.instantiate()
			item.position = room.position + Vector3(_rng.randf_range(-2, 2), 1, _rng.randf_range(-2, 2))
			add_child(item)
