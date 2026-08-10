class_name WatcherMonster
extends "res://scripts/enemies/base_monster.gd"

const SCREAM_RANGE: float = 15.0
const RAGE_SPEED_MULT: float = 1.25

func _init() -> void:
	monster_id = &"watcher"

func _ready() -> void:
	super._ready()
	stun_duration = 2.0
	flee_duration = 0.0
	vision_angle = 90.0
	peripheral_range = 4.0
	peripheral_angle = 45.0
	add_to_group("watchers")
	# S9.3: heavy breathing at 5 m, scream is a global cue.
	_set_cues({
		&"chase": {"file": "mon_watcher_breath", "db": -10.0},
		&"scream": {"file": "mon_watcher_scream", "db": -2.0},
	})

func _handle_light_reaction(_delta: float) -> void:
	if not _is_in_flashlight:
		return
	if ai_state == State.STUN or ai_state == State.DEAD:
		return
	stun(stun_duration)
	_rage_active = true
	_rage_timer = 5.0

func _state_chase(delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		_change_state(State.PATROL)
		return
	_set_nav_target(player_ref.global_position)
	var dist := global_position.distance_to(player_ref.global_position)
	if dist <= attack_range and attack_timer <= 0.0:
		_change_state(State.ATTACK)
		return
	var spd: float = chase_speed
	if _rage_active:
		spd *= RAGE_SPEED_MULT
	_move_to(spd)

func _state_attack(delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		_change_state(State.PATROL)
		return
	var dist := global_position.distance_to(player_ref.global_position)
	if dist > attack_range:
		_change_state(State.CHASE)
		return
	if attack_timer <= 0.0:
		_scream()
		player_ref.take_damage(attack_damage)
		EventBus.enemy_attack.emit(attack_damage)
		attack_timer = attack_cooldown

func _scream() -> void:
	EventBus.noise_emitted.emit(Vector2(global_position.x, global_position.z), SCREAM_RANGE)
	play_cue(&"scream", 3.0)
