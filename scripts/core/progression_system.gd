
extends Node

signal leveled_up(new_level: int)

var xp: int = 0

var level: int = 1

var skill_points: int = 0

func add_xp(amount: int) -> void:
	xp += amount
	
	var threshold := level * 100
	if xp >= threshold:
		xp -= threshold
		level += 1
		skill_points += 1
	leveled_up.emit(level)

func get_xp_needed() -> int:
	return level * 100
