class_name RotterMonster
extends "res://scripts/enemies/base_monster.gd"

## GDD §6.2 Rotter: slow omnidirectional tank, inflicts POISON on melee hit
## (base _deal_damage + _inflict_statuses already cover this). Ignores light.

func _init() -> void:
	monster_id = &"rotter"

func _ready() -> void:
	super._ready()
	stun_duration = 2.0
	flee_duration = 0.0
	vision_range = 5.0
	vision_angle = 360.0
	add_to_group("rotters")

func _handle_light_reaction(_delta: float) -> void:
	pass
