class_name SharpshooterMonster
extends "res://scripts/enemies/base_monster.gd"

## GDD §6.2 Sniper: AIM (telegraph) -> FIRE (ranged, base _deal_damage already
## instant-at-range) -> REPOSITION (sidestep before it will fire again).
## Retreats instead of meleeing if the player closes to point-blank.

const RETREAT_RANGE: float = 4.0
const REPOSITION_MIN: float = 5.0
const REPOSITION_MAX: float = 8.0
const REPOSITION_TIME: float = 1.0

var _reposition_point: Vector3 = Vector3.ZERO
var _reposition_timer: float = 0.0

func _init() -> void:
	monster_id = &"sharpshooter"

func _ready() -> void:
	super._ready()
	stun_duration = 0.0
	flee_duration = 1.5
	attack_cooldown = 2.0
	vision_range = 25.0
	vision_angle = 30.0
	add_to_group("sharpshooters")
	# Delivered audio uses the GDD's "Sniper" name (mon_sniper_*), not the
	# script's monster_id "sharpshooter" — wiring to the files that exist
	# rather than renaming them.
	_set_cues({
		&"attack": {"file": "mon_sniper_attack", "db": -4.0},
		&"hit": {"file": "mon_sniper_hit", "db": -6.0},
		&"death": {"file": "mon_sniper_death", "db": -2.0},
		&"step": {"file": "mon_sniper_step", "db": -12.0},
	})

## §6.2: "STUN не работает" — Sniper is immune to the STUN status only.
func apply_status(status: int, duration: float, dps: float = 0.0, power: float = 0.0) -> void:
	if status == EnemyRosterData.Status.STUN:
		return
	super.apply_status(status, duration, dps, power)

func _state_chase(delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		_change_state(State.PATROL)
		return
	var dist := global_position.distance_to(player_ref.global_position)
	if dist < RETREAT_RANGE:
		_trigger_flee()
		return
	_set_nav_target(player_ref.global_position)
	if dist <= attack_range and attack_timer <= 0.0:
		_change_state(State.ATTACK)
		return
	_move_to(chase_speed)

func _state_attack(delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		_change_state(State.PATROL)
		return
	if _reposition_timer > 0.0:
		_reposition_timer -= delta
		_set_nav_target(_reposition_point)
		_move_to(chase_speed)
		return
	var dist := global_position.distance_to(player_ref.global_position)
	if dist > attack_range:
		_change_state(State.CHASE)
		return
	if dist < RETREAT_RANGE:
		_trigger_flee()
		return
	if attack_timer <= 0.0:
		_perform_attack()
		attack_timer = attack_cooldown
		_start_reposition()

func _start_reposition() -> void:
	if not player_ref or not is_instance_valid(player_ref):
		return
	var to_player := (player_ref.global_position - global_position).normalized()
	var side := Vector3(-to_player.z, 0.0, to_player.x)
	if randf() < 0.5:
		side = -side
	var dist := randf_range(REPOSITION_MIN, REPOSITION_MAX)
	_reposition_point = global_position + (side - to_player * 0.3) * dist
	_reposition_timer = REPOSITION_TIME
