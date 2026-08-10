extends "res://legacy_quarantine/enemies2d/enemy_base.gd"
var _alarm_timer: float = 0.0
func _ready() -> void:
    super._ready()
    state = State.IDLE
func _tick_special(delta: float) -> void:
    if _can_see_player():
        _alarm_timer -= delta
        if _alarm_timer <= 0.0:
            _alarm_timer = 1.0
            EventBus.noise_emitted.emit(global_position, 300.0)
            if not _spotted:
                _spotted = true
                EventBus.monster_spotted.emit(monster_id)