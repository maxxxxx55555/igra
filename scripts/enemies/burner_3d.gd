class_name BurnerMonster
extends "res://scripts/enemies/base_monster.gd"

## GDD §6.2 Burner: ranged spit that inflicts BURN (base _deal_damage already
## does instant-at-range damage + _inflict_statuses, no override needed).
## Light exposure triggers panic-flee (no HP drain, unlike shadow_3d.gd).

func _init() -> void:
	monster_id = &"burner"

func _ready() -> void:
	super._ready()
	stun_duration = 0.0
	flee_duration = 3.0
	vision_range = 8.0
	vision_angle = 90.0
	add_to_group("burners")

func _handle_light_reaction(_delta: float) -> void:
	if not _is_in_flashlight:
		return
	if ai_state == State.FLEE or ai_state == State.DEAD:
		return
	_change_state(State.FLEE)
	_flee_timer = flee_duration
