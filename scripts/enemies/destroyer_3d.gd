class_name DestroyerMonster
extends "res://scripts/enemies/base_monster.gd"

var _combo_step: int = 0
var _combo_timer: float = 0.0

func _init() -> void:
	monster_id = &"destroyer"

func _ready() -> void:
	super._ready()
	stun_duration = 2.0
	flee_duration = 0.0
	add_to_group("destroyers")
	# S9.3: machinery hum, audible at 12 m.
	_set_cues({
		&"chase": {"file": "mon_destroyer_hum", "db": -6.0},
		&"investigate": {"file": "mon_destroyer_hum", "db": -10.0},
	})

func _handle_light_reaction(_delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _combo_timer > 0.0:
		_combo_timer -= delta
	else:
		_combo_step = 0

func _state_patrol(delta: float) -> void:
	super._state_patrol(delta)
	_try_break_nearby_lights()

func _state_investigate(delta: float) -> void:
	super._state_investigate(delta)
	_try_break_nearby_lights()

func _state_chase(delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		_change_state(State.PATROL)
		return
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
		_perform_combo_attack()
		attack_timer = attack_cooldown

func _perform_combo_attack() -> void:
	if not player_ref or not is_instance_valid(player_ref):
		return
	_combo_step = mini(_combo_step + 1, 3)
	_combo_timer = 2.0
	var dmg: float = attack_damage * (0.7 + float(_combo_step) * 0.3)
	player_ref.take_damage(dmg)
	EventBus.enemy_attack.emit(dmg)

func _try_break_nearby_lights() -> void:
	var lights := get_tree().get_nodes_in_group("streetlights")
	for l in lights:
		if l.has_method("force_lit") and l.get("is_lit"):
			if global_position.distance_to(l.global_position) < 2.5:
				l.force_lit(false)

				return

func take_damage(amount: float, _src_pos: Vector3 = Vector3.ZERO) -> void:
	super.take_damage(amount, _src_pos)
	if _combo_step >= 3 and _combo_timer > 0.0:
		stun(stun_duration)

	_combo_step = 0
	_combo_timer = 0.0