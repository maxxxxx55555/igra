class_name CrawlerMonster
extends "res://scripts/enemies/base_monster.gd"

const LEAP_SPEED: float = 8.0
const LEAP_WINDUP: float = 0.5

var _leap_windup: float = 0.0
var _leaping: bool = false

func _init() -> void:
	monster_id = &"crawler"

func _ready() -> void:
	super._ready()
	attack_cooldown = 2.0
	vision_angle = 120.0
	peripheral_range = 2.0
	peripheral_angle = 60.0
	chase_speed = LEAP_SPEED * 0.6
	light_flee = false
	vision_range = 6.0  # WAVE 6 P1: GDD §6.2, was unset (base_monster.gd default 10.0)
	add_to_group("crawlers")
	# S9.3: scraping on asphalt, audible at 10 m.
	_set_cues({
		&"chase": {"file": "monster_crawler_scrape", "db": -8.0},
		&"investigate": {"file": "monster_crawler_scrape", "db": -12.0},
	})

func _tick_ai(delta: float) -> void:
	if ai_state == State.STUN or ai_state == State.DEAD:
		return
	if _leaping:
		_tick_leap(delta)
		return
	match ai_state:
		State.PATROL:
			if _nav_agent and _nav_agent.is_navigation_finished():
				_idle_timer = randf_range(1.0, 3.0)
				_change_state(State.IDLE)
			_move_to(_base_speed)

		State.CHASE:
			if not player_ref or not is_instance_valid(player_ref):
				_change_state(State.PATROL)
				return
			set_nav_target(player_ref.global_position)
			var dist := global_position.distance_to(player_ref.global_position)
			if dist <= attack_range and attack_timer <= 0.0:
				_leap_windup = LEAP_WINDUP
				_leaping = true
			_move_to(chase_speed)

		State.FLEE:
			if _flee_timer > 0.0:
				var flee_dir := Vector3.ZERO
				if player_ref and is_instance_valid(player_ref):
					flee_dir = (global_position - player_ref.global_position).normalized()
				else:
					flee_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
				set_nav_target(global_position + flee_dir * 12.0)
				_move_to(_base_speed * 1.5)

func _tick_leap(delta: float) -> void:
	if _leap_windup > 0.0:
		_leap_windup -= delta
		if _leap_windup <= 0.0:
			_leaping = true
			_perform_leap()
		return
	velocity.y -= 9.8 * delta
	move_and_slide()
	if is_on_floor():
		_leaping = false
		attack_timer = attack_cooldown
		if player_ref and is_instance_valid(player_ref):
			var dist := global_position.distance_to(player_ref.global_position)
			if dist < 2.0:
				player_ref.take_damage(attack_damage)
				EventBus.enemy_attack.emit(attack_damage)

		_change_state(State.CHASE)

func _perform_leap() -> void:
	if not player_ref or not is_instance_valid(player_ref):
		_leaping = false
		_change_state(State.PATROL)
		return
	var dir := (player_ref.global_position - global_position).normalized()
	dir.y = 0.3
	velocity = dir * LEAP_SPEED

func _on_light_tick(_delta: float) -> void:
	if not _is_in_light():
		_vision_lost_timer = maxf(0.0, _vision_lost_timer - _delta)
		return
	if ai_state == State.CHASE:
		_vision_lost_timer = 1.0
		pass

func _can_see_player() -> bool:
	if _vision_lost_timer > 0.0:
		return false
	return super._can_see_player()