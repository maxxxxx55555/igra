extends Node
## A9: Sistema shuma - beg/vystrely privlekajut vragov

signal noise_emitted(position: Vector3, radius: float, source: String)

const NOISE_LEVELS: Dictionary = {
    "walk": 3.0,
    "run": 8.0,
    "sprint": 12.0,
    "jump_land": 5.0,
    "pistol_shot": 20.0,
    "shotgun_shot": 25.0,
    "rifle_shot": 22.0,
    "explosion": 40.0,
    "door_open": 4.0,
    "item_drop": 2.0,
    "melee_hit": 6.0,
    "glass_break": 15.0
}

var _stealth_modifier: float = 1.0

func set_stealth_modifier(mod: float) -> void:
    _stealth_modifier = mod

func emit_noise(position: Vector3, noise_type: String) -> void:
    var base_radius = NOISE_LEVELS.get(noise_type, 5.0)
    var radius = base_radius * _stealth_modifier
    noise_emitted.emit(position, radius, noise_type)
    _alert_enemies(position, radius)

func _alert_enemies(position: Vector3, radius: float) -> void:
    for enemy in get_tree().get_nodes_in_group("enemy"):
        if enemy.global_position.distance_to(position) <= radius:
            if enemy.has_method("alert"):
                enemy.alert(position)
            elif enemy.has_method("_update_target"):
                enemy._update_target()

func get_noise_radius(noise_type: String) -> float:
    return NOISE_LEVELS.get(noise_type, 5.0) * _stealth_modifier