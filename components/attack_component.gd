

class_name AttackComponent

extends Node
@export 

var damage: int = 25
@export 

var attack_range: float = 2.0
@export 

var attack_cooldown: float = 1.0
var _can_attack: bool = true
func attack(target: Node) -> void:
	if not _can_attack or not target:
		return
	var health = target.get_node_or_null("HealthComponent")
	if health:
		health.take_damage(damage)
	_can_attack = false
	get_tree().create_timer(attack_cooldown).timeout.connect(func(): _can_attack = true)

