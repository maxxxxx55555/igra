class_name TvarMonster
extends "res://scripts/enemies/base_monster.gd"

## GDD §6.2 Tvar (mini-boss): light slows it (reuses base _state_chase's
## existing _slow_active x0.5), and 3 incoming hits within a combo window
## self-stun it (destroyer_3d.gd's combo pattern, mirrored on take_damage
## instead of on its own attack).

var _combo_step: int = 0
var _combo_timer: float = 0.0
var _sting_played: bool = false

func _init() -> void:
	monster_id = &"tvar"

func _ready() -> void:
	super._ready()
	stun_duration = 2.0
	flee_duration = 0.0
	vision_range = 16.0
	vision_angle = 360.0
	add_to_group("tvars")
	EventBus.player_detected.connect(_on_any_player_detected)

## Mini-boss intro stinger, once per encounter (RESCUE WAVE P2.5). Guarded
## by monster_id since player_detected is a global broadcast from every
## monster's own detection, not just this one.
func _on_any_player_detected(id: StringName) -> void:
	if id == monster_id and not _sting_played:
		_sting_played = true
		_play_intro_sting("res://assets/audio/sfx/tvar_sting.ogg")

func _handle_light_reaction(_delta: float) -> void:
	if not _is_in_flashlight:
		return
	_slow_active = true

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _combo_timer > 0.0:
		_combo_timer -= delta
	else:
		_combo_step = 0

func take_damage(amount: float, _src_pos: Vector3 = Vector3.ZERO, type: EnemyRosterData.DamageType = EnemyRosterData.DamageType.BULLET) -> void:
	super.take_damage(amount, _src_pos, type)
	if ai_state == State.DEAD:
		return
	_combo_step += 1
	_combo_timer = 2.0
	if _combo_step >= 3:
		_combo_step = 0
		_combo_timer = 0.0
		stun(stun_duration)
