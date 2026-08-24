class_name BruteMonster
extends "res://scripts/enemies/base_monster.gd"

## GDD §6.2 Brute: WINDUP (telegraphed delay) -> SLAM (heavy melee hit) ->
## CHARGE (lunge toward last known player position, hunter_3d.gd-style) ->
## self-STUN recovery window. Immune to light.

const WINDUP_TIME: float = 1.0
const SLAM_MULT: float = 1.4
const CHARGE_SPEED: float = 6.0
const SELF_STUN: float = 1.5

var _winding_up: bool = false
var _windup_timer: float = 0.0

func _init() -> void:
	monster_id = &"brute"

func _ready() -> void:
	super._ready()
	stun_duration = 1.5
	flee_duration = 0.0
	light_damage_per_sec = 0.0
	vision_range = 6.0
	vision_angle = 180.0
	add_to_group("brutes")
	_set_cues({
		&"attack": {"file": "mon_brute_attack", "db": -4.0},
		&"hit": {"file": "mon_brute_hit", "db": -6.0},
		&"death": {"file": "mon_brute_death", "db": -2.0},
		&"step": {"file": "mon_brute_step", "db": -12.0},
	})

func _handle_light_reaction(_delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if _winding_up:
		_tick_windup(delta)
		return
	super._physics_process(delta)

func _state_chase(delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		_change_state(State.PATROL)
		return
	_set_nav_target(player_ref.global_position)
	var dist := global_position.distance_to(player_ref.global_position)
	if dist <= attack_range and attack_timer <= 0.0:
		_windup_timer = WINDUP_TIME
		_winding_up = true
		return
	_move_to(chase_speed)

func _tick_windup(delta: float) -> void:
	velocity = Vector3.ZERO
	move_and_slide()
	_windup_timer -= delta
	if _windup_timer <= 0.0:
		_winding_up = false
		_slam_and_charge()

func _slam_and_charge() -> void:
	if player_ref and is_instance_valid(player_ref):
		var dist := global_position.distance_to(player_ref.global_position)
		if dist <= attack_range + 0.5:
			player_ref.take_damage(attack_damage * SLAM_MULT)
			EventBus.enemy_attack.emit(attack_damage * SLAM_MULT)
		var dir := (player_ref.global_position - global_position).normalized()
		dir.y = 0.0
		velocity = dir * CHARGE_SPEED
		velocity.y += get_gravity().y * get_physics_process_delta_time()
		move_and_slide()
	attack_timer = attack_cooldown
	stun(SELF_STUN)
