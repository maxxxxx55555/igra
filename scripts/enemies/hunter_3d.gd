class_name HunterMonster
extends "res://scripts/enemies/base_monster.gd"

const CHARGE_SPEED: float = 8.0
const CHARGE_WINDUP: float = 1.0
const RAGE_SPEED_MULT: float = 1.3
const RAGE_DURATION: float = 5.0

var _charging: bool = false
var _charge_windup: float = 0.0
var _was_in_light: bool = false

func _ready() -> void:
	detect_range = 12.0
	max_hp = 120.0
	super._ready()
	_base_speed = 3.5
	attack_damage = 35.0
	attack_range = 2.5
	attack_cooldown = 2.5
	vision_range = 10.0
	vision_angle = 60.0
	peripheral_range = 0.0
	peripheral_angle = 0.0
	chase_speed = _base_speed
	stun_duration = 0.0
	flee_duration = 0.0
	add_to_group("hunters")
	# S9.3: roar before charge.
	_set_cues({&"roar": {"file": "mon_hunter_roar", "db": -3.0}})

func _physics_process(delta: float) -> void:
	if _charging:
		_tick_charge(delta)
		return
	super._physics_process(delta)

func _handle_light_reaction(_delta: float) -> void:
	if _is_in_flashlight:
		_was_in_light = true
		_slow_active = true
	else:
		_slow_active = false
		if _was_in_light:
			_was_in_light = false
			_rage_active = true
			_rage_timer = RAGE_DURATION

func _state_chase(delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		_change_state(State.PATROL)
		return
	_set_nav_target(player_ref.global_position)
	var dist := global_position.distance_to(player_ref.global_position)
	if dist <= attack_range and attack_timer <= 0.0:
		_charge_windup = CHARGE_WINDUP
		_charging = true
		play_cue(&"roar", 3.0)
		return
	var spd: float = chase_speed
	if _slow_active:
		spd *= 0.5
	if _rage_active:
		spd *= RAGE_SPEED_MULT
	_move_to(spd)

func _tick_charge(delta: float) -> void:
	if _charge_windup > 0.0:
		_charge_windup -= delta
		velocity = Vector3.ZERO
		if _charge_windup <= 0.0:
			if not player_ref or not is_instance_valid(player_ref):
				_charging = false
				_change_state(State.PATROL)
				return
			var dir := (player_ref.global_position - global_position).normalized()
			dir.y = 0.0
			velocity = dir * CHARGE_SPEED
			move_and_slide()
			var charge_dist := global_position.distance_to(player_ref.global_position)
			if charge_dist < attack_range + 0.5:
				player_ref.take_damage(attack_damage)
				EventBus.enemy_attack.emit(attack_damage)

			_charging = false
			attack_timer = attack_cooldown
			_change_state(State.CHASE)
		return