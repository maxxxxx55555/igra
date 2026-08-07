extends CharacterBody3D
class_name EnemyLightAI
## Light-aware enemy. Bolder in dark, cautious in light, runs from flashlight.

@export var move_speed: float = 2.5
@export var patrol_speed: float = 1.2
@export var flee_speed: float = 4.5
@export var detection_range: float = 12.0
@export var dark_boost: float = 1.5
@export var catch_distance: float = 1.2

enum State { PATROL, CHASE, FLEE }

var _state: int = State.PATROL
var _player: Node3D
var _patrol: Array = []
var _patrol_i: int = 0
var _light_grid: Node

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_collect_patrol()
	_light_grid = get_node_or_null("/root/LightGrid")
	set_physics_process(true)

func _collect_patrol() -> void:
	_patrol.clear()
	for n in get_tree().get_nodes_in_group("patrol"):
		_patrol.append((n as Node3D).global_position)
	if _patrol.is_empty():
		_patrol.append(global_position)

func _physics_process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var to_p: Vector3 = _player.global_position - global_position
	var dist: float = to_p.length()
	var lit: bool = _grid_is_lit(global_position, 0.25)
	var br: float = _grid_brightness(global_position)
	var det: float = detection_range * (dark_boost if not lit else 1.0)
	var flash_pos := Vector3.ZERO
	var flash_dist := -1.0
	var nearest = _grid_nearest_flashlight(global_position)
	if nearest is Array and nearest.size() >= 2:
		flash_pos = nearest[0]
		flash_dist = float(nearest[1])

	var near_flash := flash_dist >= 0.0 and flash_dist < 6.0
	if near_flash:
		_set_state(State.FLEE)
	elif dist < det and not lit:
		_set_state(State.CHASE)
	elif dist < det * 0.5 and lit:
		_set_state(State.CHASE)
	else:
		_set_state(State.PATROL)

	match _state:
		State.PATROL:
			_tick_patrol()
		State.CHASE:
			_tick_chase(br)
		State.FLEE:
			_tick_flee(flash_pos, to_p)

func _set_state(s: int) -> void:
	if s == _state:
		return
	_state = s

func _tick_patrol() -> void:
	if _patrol.is_empty():
		return
	var t: Vector3 = _patrol[_patrol_i]
	_move(t, patrol_speed)
	if global_position.distance_to(t) < 1.5:
		_patrol_i = (_patrol_i + 1) % _patrol.size()

func _tick_chase(br: float) -> void:
	var sp: float = move_speed * (1.4 if br < 0.2 else 0.6)
	_move(_player.global_position, sp)

func _tick_flee(flash_pos: Vector3, to_p: Vector3) -> void:
	var away: Vector3 = global_position - flash_pos
	if away.length() < 0.1:
		away = -to_p
	_move(global_position + away.normalized() * 5.0, flee_speed)

func _move(target: Vector3, speed: float) -> void:
	var dir: Vector3 = target - global_position
	dir.y = 0.0
	if dir.length() < 0.01:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	velocity = dir.normalized() * speed
	move_and_slide()

func state_name() -> StringName:
	match _state:
		State.PATROL:
			return &"PATROL"
		State.CHASE:
			return &"CHASE"
		State.FLEE:
			return &"FLEE"
	return &"?"

func caught_player() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	return global_position.distance_to(_player.global_position) < catch_distance

func _grid_is_lit(p: Vector3, radius: float) -> bool:
	if _light_grid == null:
		return false
	if _light_grid.has_method("is_lit"):
		return bool(_light_grid.is_lit(p, radius))
	return false

func _grid_brightness(p: Vector3) -> float:
	if _light_grid == null:
		return 0.0
	if _light_grid.has_method("cell_brightness"):
		return float(_light_grid.cell_brightness(p))
	return 0.0

func _grid_nearest_flashlight(p: Vector3):
	if _light_grid == null:
		return null
	if _light_grid.has_method("nearest_flashlight"):
		return _light_grid.nearest_flashlight(p)
	return null