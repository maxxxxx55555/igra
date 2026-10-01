class_name HoundMonster
extends "res://scripts/enemies/base_monster.gd"

## GDD §6.2 Hound: fast swarm chaser, short light-stun; calls allies when it first spots the player (base_monster.gd PACK_CALLERS).

func _init() -> void:
	monster_id = &"hound"

func _ready() -> void:
	super._ready()
	stun_duration = 1.0
	flee_duration = 0.0
	vision_range = 14.0
	vision_angle = 120.0
	add_to_group("hounds")
	_set_cues({
		&"attack": {"file": "mon_hound_attack", "db": -4.0},
		&"hit": {"file": "mon_hound_hit", "db": -6.0},
		&"death": {"file": "mon_hound_death", "db": -2.0},
		&"step": {"file": "mon_hound_step", "db": -12.0},
	})

func _handle_light_reaction(_delta: float) -> void:
	if not _is_in_flashlight:
		return
	if ai_state == State.STUN or ai_state == State.DEAD:
		return
	stun(stun_duration)
