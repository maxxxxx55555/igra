class_name EnemyShadow
extends EnemyBase
func _react_to_light(in_light: bool, delta: float) -> void:
    if in_light:
        if state != State.FLEE and state != State.DEAD:
            state = State.FLEE
            _lose_timer = 1.5
        take_damage(data.light_damage_per_sec * delta)