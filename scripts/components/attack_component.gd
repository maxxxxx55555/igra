extends Node3D

@export var attack_range: float = 2.0
@export var attack_damage: int = 25
@export var attack_cooldown: float = 0.5

var _cooldown_timer: float = 0.0

func _process(delta: float) -> void:
    if _cooldown_timer > 0:
        _cooldown_timer -= delta

func can_attack() -> bool:
    return _cooldown_timer <= 0.0

func attack(target: Node3D) -> bool:
    if not can_attack():
        return false
    if not target:
        return false
    var dist = global_position.distance_to(target.global_position)
    if dist > attack_range:
        return false
    if target.has_method("take_damage"):
        target.take_damage(attack_damage)
    _cooldown_timer = attack_cooldown
    return true