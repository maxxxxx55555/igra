class_name StalkerEnemyAI
extends CharacterBody3D

## Active survival-horror Stalker enemy reacting to flashlight visibility, sprint noise, walls, and streetlight safe-zones.

signal alert_state_changed(new_state: int)
signal player_caught(player: Node3D)

enum State { PATROL, INVESTIGATE, HUNT, RETREAT }

@export var patrol_speed: float = 2.1
@export var investigate_speed: float = 3.2
@export var hunt_speed: float = 4.6
@export var sight_range_m: float = 18.0
@export var hearing_range_m: float = 12.0
@export var catch_distance_m: float = 1.45
@export var lose_sight_timeout_sec: float = 4.5
@export var world_collision_mask: int = 1
@export var patrol_points: Array[Vector3] = []

var current_state: State = State.PATROL
var _player_ref: Node3D = null
var _patrol_index: int = 0
var _investigate_target: Vector3 = Vector3.ZERO
var _time_since_seen: float = 99.0
var _player_visibility_01: float = 0.25
var _player_noise_01: float = 0.0
var _safe_zone_centers: Array[Vector3] = []
var _safe_zone_radius_m: float = 6.5
var _gravity: float = 18.0


func _ready() -> void:
	safe_margin = 0.04
	collision_mask |= world_collision_mask
	if patrol_points.is_empty():
		var origin: Vector3 = global_position
		patrol_points = [
			origin + Vector3(8.0, 0.0, 0.0),
			origin + Vector3(8.0, 0.0, 8.0),
			origin + Vector3(-8.0, 0.0, 8.0),
			origin + Vector3(-8.0, 0.0, -4.0),
		]


func set_player_target(player_node: Node3D) -> void:
	_player_ref = player_node


func update_player_stealth_metrics(visibility_01: float, noise_01: float) -> void:
	_player_visibility_01 = clampf(visibility_01, 0.05, 1.0)
	_player_noise_01 = clampf(noise_01, 0.0, 1.0)


func set_safe_zones(centers: Array[Vector3], radius_m: float = 6.5) -> void:
	_safe_zone_centers = centers
	_safe_zone_radius_m = maxf(2.0, radius_m)


func _physics_process(delta: float) -> void:
	var dt: float = clampf(delta, 0.0, 0.05)
	velocity.y = 0.0 if is_on_floor() else (velocity.y - _gravity * dt)

	for sz in _safe_zone_centers:
		if global_position.distance_to(sz) < _safe_zone_radius_m:
			_set_state(State.RETREAT)
			var away: Vector3 = global_position - sz
			away.y = 0.0
			var retreat_pos: Vector3 = global_position + (away.normalized() if away.length_squared() > 0.01 else Vector3.FORWARD) * 10.0
			_steer_and_move(retreat_pos, hunt_speed * 0.9, dt)
			return

	var sees_player: bool = _can_see_player()
	var hears_player: bool = _can_hear_player()

	if sees_player and is_instance_valid(_player_ref):
		_time_since_seen = 0.0
		_investigate_target = _player_ref.global_position
		_set_state(State.HUNT)
	elif hears_player and is_instance_valid(_player_ref):
		_investigate_target = _player_ref.global_position
		if current_state != State.HUNT:
			_set_state(State.INVESTIGATE)
	else:
		_time_since_seen += dt
		if current_state == State.HUNT and _time_since_seen >= lose_sight_timeout_sec:
			_set_state(State.INVESTIGATE)
		elif current_state == State.RETREAT:
			_set_state(State.PATROL)

	var target_pos: Vector3 = global_position
	var move_speed: float = patrol_speed
	match current_state:
		State.HUNT:
			if is_instance_valid(_player_ref):
				target_pos = _player_ref.global_position
				move_speed = hunt_speed
				if global_position.distance_to(_player_ref.global_position) <= catch_distance_m:
					player_caught.emit(_player_ref)
		State.INVESTIGATE:
			target_pos = _investigate_target
			move_speed = investigate_speed
			if _flat_dist(global_position, _investigate_target) < 1.3:
				_set_state(State.PATROL)
		State.PATROL:
			target_pos = patrol_points[_patrol_index % patrol_points.size()]
			move_speed = patrol_speed
			if _flat_dist(global_position, target_pos) < 1.4:
				_patrol_index = (_patrol_index + 1) % patrol_points.size()
		State.RETREAT:
			_set_state(State.PATROL)

	_steer_and_move(target_pos, move_speed, dt)


func _steer_and_move(target_pos: Vector3, speed: float, dt: float) -> void:
	var dir: Vector3 = target_pos - global_position
	dir.y = 0.0
	if dir.length_squared() > 0.04:
		dir = dir.normalized()
		if is_on_wall():
			dir = dir.rotated(Vector3.UP, PI * 0.45)
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), clampf(dt * 7.0, 0.0, 1.0))
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * dt * 4.0)
		velocity.z = move_toward(velocity.z, 0.0, speed * dt * 4.0)
	move_and_slide()


func _can_see_player() -> bool:
	if not is_instance_valid(_player_ref):
		return false
	var eff_range: float = sight_range_m * clampf(0.35 + 0.85 * _player_visibility_01, 0.35, 1.2)
	if global_position.distance_to(_player_ref.global_position) > eff_range:
		return false
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var q: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0.0, 1.4, 0.0),
		_player_ref.global_position + Vector3(0.0, 1.2, 0.0),
		world_collision_mask
	)
	q.exclude = [get_rid()]
	var hit: Dictionary = space.intersect_ray(q)
	return hit.is_empty() or hit.get("collider") == _player_ref


func _can_hear_player() -> bool:
	if not is_instance_valid(_player_ref) or _player_noise_01 <= 0.25:
		return false
	return global_position.distance_to(_player_ref.global_position) <= (hearing_range_m * _player_noise_01)


func _set_state(next_state: State) -> void:
	if current_state != next_state:
		current_state = next_state
		alert_state_changed.emit(int(next_state))


func _flat_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
