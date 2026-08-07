class_name EnemyHunter
extends EnemyBase
func _on_lost_player() -> void:
    if _noise_pos != Vector2.INF:
        nav.target_position = _noise_pos
        _lose_timer = 1.5
    else:
        state = State.PATROL if not patrol_points.is_empty() else State.IDLE