class_name ShadowMonster
extends "res://scripts/enemies/base_monster.gd"

const CHASE_SPEED: float = 4.0
const PATROL_SPEED: float = 1.5
const TELEPORT_RANGE: float = 6.0
const TELEPORT_COOLDOWN: float = 3.0

var _teleport_cooldown: float = 0.0

func _ready() -> void:
	detect_range = 15.0
	max_hp = 30.0
	super._ready()
	_base_speed = PATROL_SPEED
	attack_damage = 15.0
	attack_range = 1.5
	attack_cooldown = 1.5
	light_damage_per_sec = 0.0
	vision_range = 0.0
	vision_angle = 0.0
	peripheral_range = 15.0
	peripheral_angle = 180.0
	chase_speed = CHASE_SPEED
	stun_duration = 0.0
	flee_duration = 5.0
	add_to_group("shadow")
	# S9.3: Shadow has no footsteps; teleport is an electric snap.
	_set_cues({&"teleport": {"file": "monster_shadow_click", "db": -4.0}})

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_teleport_cooldown = maxf(0.0, _teleport_cooldown - delta)

func _handle_light_reaction(delta: float) -> void:
	if not _is_in_flashlight:
		return
	hp -= 10.0 * delta

	if hp <= 0.0:
		_die()
		return
	if ai_state != State.FLEE and ai_state != State.DEAD:
		_change_state(State.FLEE)
		_flee_timer = flee_duration

func _state_chase(delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		_change_state(State.PATROL)
		return
	if _teleport_cooldown <= 0.0 and global_position.distance_to(player_ref.global_position) > 4.0:
		_teleport_behind_player()
		_teleport_cooldown = TELEPORT_COOLDOWN
	_set_nav_target(player_ref.global_position)
	var dist := global_position.distance_to(player_ref.global_position)
	if dist <= attack_range and attack_timer <= 0.0:
		_change_state(State.ATTACK)
		return
	_move_to(chase_speed)

func _state_attack(delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		_change_state(State.PATROL)
		return
	var dist := global_position.distance_to(player_ref.global_position)
	if dist > attack_range:
		_change_state(State.CHASE)
		return
	if attack_timer <= 0.0:
		_shadow_attack()
		attack_timer = attack_cooldown

func _state_flee(delta: float) -> void:
	if _flee_timer <= 0.0:
		_flee_timer = 0.0
		if player_ref and is_instance_valid(player_ref):
			_investigate_point = player_ref.global_position
			_investigate_timer = 5.0
			_change_state(State.INVESTIGATE)
		else:
			_change_state(State.PATROL)
		return
	if not player_ref or not is_instance_valid(player_ref):
		_change_state(State.PATROL)
		return
	var flee_dir := (global_position - player_ref.global_position).normalized()
	_set_nav_target(global_position + flee_dir * 15.0)
	_move_to(_base_speed * 2.0)

func _teleport_behind_player() -> void:
	if not player_ref or not is_instance_valid(player_ref):
		return
	var behind := player_ref.global_position - player_ref.global_transform.basis.z.normalized() * 2.0
	behind.y = player_ref.global_position.y
	global_position = behind
	velocity = Vector3.ZERO
	play_cue(&"teleport", 0.5)

func _shadow_attack() -> void:
	if not player_ref or not is_instance_valid(player_ref):
		return
	player_ref.take_damage(attack_damage)
	EventBus.enemy_attack.emit(attack_damage)

func take_damage(amount: float, _src_pos: Vector3 = Vector3.ZERO, type: EnemyRosterData.DamageType = EnemyRosterData.DamageType.BULLET) -> void:
	super.take_damage(amount, _src_pos, type)
	if hp <= 0.0:
		queue_free()
