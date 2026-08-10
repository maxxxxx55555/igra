extends "res://legacy_quarantine/enemies2d/enemy_base.gd"
var _jam_timer: float = 0.0
func _tick_special(delta: float) -> void:
    if data.can_break_lights and is_instance_valid(_player) and global_position.distance_to(_player.global_position) <= data.melee_range:
        _jam_timer -= delta
        if _jam_timer <= 0.0:
            _jam_timer = 4.0
            EventBus.light_disrupted.emit()