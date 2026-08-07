extends Node

signal ng_plus_activated(new_level: int)
signal difficulty_scaled(multiplier: float)

const MAX_NG_PLUS = 3
const XP_MULTIPLIER_PER_NG = 0.25
const ENEMY_DAMAGE_MULTIPLIER_PER_NG = 0.15
const ENEMY_HP_MULTIPLIER_PER_NG = 0.2
const PLAYER_DAMAGE_MULTIPLIER_PER_NG = 0.1
const LOOT_CHANCE_MULTIPLIER_PER_NG = 0.1

var _current_ng_plus: int = 0
var _is_ng_plus_active: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_save()

func get_current_ng_plus() -> int:
	return _current_ng_plus

func get_max_ng_plus() -> int:
	return MAX_NG_PLUS

func is_ng_plus_active() -> bool:
	return _is_ng_plus_active

func activate_ng_plus() -> bool:
	if _current_ng_plus >= MAX_NG_PLUS:
		return false
	_current_ng_plus += 1
	_is_ng_plus_active = true
	ng_plus_activated.emit(_current_ng_plus)
	difficulty_scaled.emit(get_difficulty_multiplier())
	_save_save()
	return true

func get_difficulty_multiplier() -> Dictionary:
	var ng = _current_ng_plus
	return {
		"xp_multiplier": 1.0 + ng * XP_MULTIPLIER_PER_NG,
		"enemy_damage_multiplier": 1.0 + ng * ENEMY_DAMAGE_MULTIPLIER_PER_NG,
		"enemy_hp_multiplier": 1.0 + ng * ENEMY_HP_MULTIPLIER_PER_NG,
		"player_damage_multiplier": 1.0 + ng * PLAYER_DAMAGE_MULTIPLIER_PER_NG,
		"loot_chance_multiplier": 1.0 + ng * LOOT_CHANCE_MULTIPLIER_PER_NG,
	}

func get_xp_multiplier() -> float:
	return 1.0 + _current_ng_plus * XP_MULTIPLIER_PER_NG

func get_enemy_damage_multiplier() -> float:
	return 1.0 + _current_ng_plus * ENEMY_DAMAGE_MULTIPLIER_PER_NG

func get_enemy_hp_multiplier() -> float:
	return 1.0 + _current_ng_plus * ENEMY_HP_MULTIPLIER_PER_NG

func get_player_damage_multiplier() -> float:
	return 1.0 + _current_ng_plus * PLAYER_DAMAGE_MULTIPLIER_PER_NG

func get_loot_chance_multiplier() -> float:
	return 1.0 + _current_ng_plus * LOOT_CHANCE_MULTIPLIER_PER_NG

func reset_for_new_game() -> void:
	_current_ng_plus = 0
	_is_ng_plus_active = false
	_save_save()

func _load_save() -> void:
	var path = "user://ng_plus_data.json"
	if not FileAccess.file_exists(path):
		return
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	var txt = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(txt) != OK:
		return
	var data = json.data as Dictionary
	_current_ng_plus = data.get("ng_plus", 0)
	_is_ng_plus_active = data.get("active", false)

func _save_save() -> void:
	var path = "user://ng_plus_data.json"
	var data = {
		"ng_plus": _current_ng_plus,
		"active": _is_ng_plus_active
	}
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()