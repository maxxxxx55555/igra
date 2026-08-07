class_name HealthResource
extends Resource

@export var max_hp: float = 100.0
@export var current_hp: float = 100.0
@export var armor: float = 0.0
@export var regen_per_sec: float = 0.0

func take_damage(amount: float) -> float:
	var actual := maxf(0.0, amount * (1.0 - armor))
	current_hp = maxf(0.0, current_hp - actual)
	return actual

func heal(amount: float) -> void:
	current_hp = minf(max_hp, current_hp + amount)

func is_dead() -> bool:
	return current_hp <= 0.0

func reset() -> void:
	current_hp = max_hp