class_name Enemy3D
extends CharacterBody3D

enum AIState { IDLE, PATROL, CHASE, ATTACK }

@export var monster_id: StringName = &"enemy_generic"
@export var max_hp: float = 50.0
@export var speed: float = 3.0
@export var detect_range: float = 10.0
@export var attack_range: float = 2.0
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 1.5
@export var patrol_points: Array[Vector3] = []

var hp: float = 50.0
var ai_state: AIState = AIState.IDLE
var _player: Node3D = null
var _nav_agent: NavigationAgent3D = null
var _ai_timer: float = 0.0
var _ai_interval: float = 0.1
var _patrol_index: int = 0
var _idle_timer: float = 0.0
var _attack_timer: float = 0.0
var _lost_timer: float = 0.0
var _player_lost_time: float = 5.0

func _ready() -> void:
	hp = max_hp
	_nav_agent = get_node_or_null("NavigationAgent3D")
	if not _nav_agent:
		_nav_agent = NavigationAgent3D.new()
		_nav_agent.name = "NavigationAgent3D"
		add_child(_nav_agent)
	_nav_agent.path_desired_distance = 1.0
	_nav_agent.target_desired_distance = 1.5
	add_to_group("enemies")
	EventBus.enemy_spawned.emit(self)
	# print("ENEMY3D ready id=", monster_id, " hp=", hp, " state=", ai_state)

func _physics_process(delta: float) -> void:
	_ai_timer += delta
	if _ai_timer < _ai_interval:
		return
	_ai_timer = 0.0
	_update_ai()

func _update_ai() -> void:
	if not _player:
		_player = get_tree().get_first_node_in_group("player")
	if not _player:
		return

	match ai_state:
		AIState.IDLE:
			_idle_timer += _ai_interval
			if _idle_timer >= 2.0 + randf() * 1.0:
				_idle_timer = 0.0
				if patrol_points.size() > 0:
					ai_state = AIState.PATROL
					_patrol_index = 0
					_set_nav_target(patrol_points[_patrol_index])
			if _can_see_player():
				ai_state = AIState.CHASE
				_lost_timer = 0.0
				_set_nav_target(_player.global_position)

		AIState.PATROL:
			if _nav_agent.is_navigation_finished():
				_idle_timer += _ai_interval
				if _idle_timer >= 2.0 + randf() * 1.0:
					_idle_timer = 0.0
					_patrol_index = (_patrol_index + 1) % patrol_points.size()
					_set_nav_target(patrol_points[_patrol_index])
			if _can_see_player():
				ai_state = AIState.CHASE
				_lost_timer = 0.0
				_set_nav_target(_player.global_position)

		AIState.CHASE:
			var dist := global_position.distance_to(_player.global_position)
			if dist < attack_range:
				ai_state = AIState.ATTACK
				_attack_timer = attack_cooldown
			else:
				_set_nav_target(_player.global_position)
				var next_pos := _nav_agent.get_next_path_position()
				var dir := (next_pos - global_position).normalized()
				velocity = dir * speed
				move_and_slide()
			if not _can_see_player():
				_lost_timer += _ai_interval
				if _lost_timer >= _player_lost_time:
					ai_state = AIState.PATROL
					_lost_timer = 0.0
			else:
				_lost_timer = 0.0

		AIState.ATTACK:
			_attack_timer += _ai_interval
			if _attack_timer >= attack_cooldown:
				_attack_timer = 0.0
				var dist := global_position.distance_to(_player.global_position)
				if dist < attack_range:
					EventBus.enemy_attack.emit(int(attack_damage))
					# print("ENEMY3D attack damage=", attack_damage)
				ai_state = AIState.CHASE

func _can_see_player() -> bool:
	if not _player:
		return false
	var dist := global_position.distance_to(_player.global_position)
	if dist > detect_range:
		return false
	var dir_to_player := (_player.global_position - global_position).normalized()
	var forward := -global_transform.basis.z.normalized()
	var angle := acos(clampf(dir_to_player.dot(forward), -1.0, 1.0))
	if angle > deg_to_rad(30.0):
		return false
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 1.0, 0), _player.global_position + Vector3(0, 1.0, 0))
	query.exclude = [self]
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return false
	return result.collider.is_in_group("player")

func _set_nav_target(pos: Vector3) -> void:
	if _nav_agent:
		_nav_agent.target_position = pos

func take_damage(amount: float) -> void:
	hp -= amount
	# print("ENEMY3D hit hp=", hp)
	if hp <= 0:
		_die()

func _die() -> void:
	EventBus.enemy_killed.emit(monster_id)
	EventBus.enemy_died.emit(global_position)
	call_deferred("queue_free")

@rpc("any_peer", "reliable")
func _server_kill(monster_id: StringName) -> void:
	if is_multiplayer_authority():
		EventBus.enemy_killed.emit(monster_id)
