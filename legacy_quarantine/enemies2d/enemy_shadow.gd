extends "res://legacy_quarantine/enemies2d/enemy_base.gd"
func _react_to_light(in_light: bool, delta: float) -> void:
    if in_light:
        if state != State.FLEE and state != State.DEAD:
            state = State.FLEE
            _lose_timer = 1.5
        take_damage(data.light_damage_per_sec * delta)