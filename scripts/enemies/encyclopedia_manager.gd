extends Node
const _DATA: Array = [
	preload("res://data/monsters/monster_shadow.tres"),
	preload("res://data/monsters/monster_crawler.tres"),
	preload("res://data/monsters/monster_watcher.tres"),
	preload("res://data/monsters/monster_hunter.tres"),
	preload("res://data/monsters/monster_destroyer.tres"),
	preload("res://data/monsters/monster_boss.tres"),
	preload("res://data/monsters/monster_sharpshooter.tres"),
	preload("res://data/monsters/monster_brute.tres"),
	preload("res://data/monsters/monster_burner.tres"),
	preload("res://data/monsters/monster_rotter.tres"),
	preload("res://data/monsters/monster_hound.tres"),
	preload("res://data/monsters/monster_tvar.tres"),
]
var _by_id: Dictionary = {}
var _unlocked: Dictionary = {}
func _ready() -> void:
	for d in _DATA:
		if d is MonsterData:
			_by_id[(d as MonsterData).id] = d
	EventBus.player_detected.connect(_on_spotted)
func _on_spotted(id: StringName) -> void:
	unlock(id)
func unlock(id: StringName) -> void:
	if _unlocked.get(id, false):
		return
	_unlocked[id] = true
	EventBus.encyclopedia_unlocked.emit(id)
func is_unlocked(id: StringName) -> bool:
	return _unlocked.get(id, false)
func get_data(id: StringName) -> MonsterData:
	return _by_id.get(id, null)
func all_ids() -> Array:
	return _by_id.keys()
func to_dict() -> Dictionary:
	return {"unlocked": _unlocked.keys().map(func(k): return String(k))}
func from_dict(d: Dictionary) -> void:
	_unlocked.clear()
	for k in d.get("unlocked", []):
		_unlocked[StringName(k)] = true