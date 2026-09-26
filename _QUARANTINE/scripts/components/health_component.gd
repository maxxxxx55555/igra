extends Node

signal health_changed(new_health: int)
signal died

@export var max_health: int = 100
var health: int = 100

func _ready() -> void:
	health = max_health

func take_damage(amount: int) -> void:
	health = max(0, health - amount)
	health_changed.emit(health)
	if health <= 0:
		died.emit()

func heal(amount: int) -> void:
	health = min(max_health, health + amount)
	health_changed.emit(health)

func get_health_ratio() -> float:
	return health / max_health if max_health > 0 else 0.0