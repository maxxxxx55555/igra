extends Node

signal achievement_unlocked(achievement_id: StringName)

const ACHIEVEMENTS: Dictionary = {
	"ach_01": {
		"id": &"ach_01",
		"name": "ACH_01_NAME",
		"description": "ACH_01_DESC",
		"secret": false,
		"condition": "district_1_full"
	},
	"ach_02": {
		"id": &"ach_02",
		"name": "ACH_02_NAME",
		"description": "ACH_02_DESC",
		"secret": false,
		"condition": "any_district_full"
	},
	"ach_03": {
		"id": &"ach_03",
		"name": "ACH_03_NAME",
		"description": "ACH_03_DESC",
		"secret": false,
		"condition": "all_districts_full"
	},
	"ach_04": {
		"id": &"ach_04",
		"name": "ACH_04_NAME",
		"description": "ACH_04_DESC",
		"secret": false,
		"condition": "all_documents_collected"
	},
	"ach_05": {
		"id": &"ach_05",
		"name": "ACH_05_NAME",
		"description": "ACH_05_DESC",
		"secret": false,
		"condition": "kill_shadows_50"
	},
	"ach_06": {
		"id": &"ach_06",
		"name": "ACH_06_NAME",
		"description": "ACH_06_DESC",
		"secret": false,
		"condition": "district3_stealth"
	},
	"ach_07": {
		"id": &"ach_07",
		"name": "ACH_07_NAME",
		"description": "ACH_07_DESC",
		"secret": false,
		"condition": "combo3_x10"
	},
	"ach_08": {
		"id": &"ach_08",
		"name": "ACH_08_NAME",
		"description": "ACH_08_DESC",
		"secret": false,
		"condition": "overload_5min"
	},
	"ach_09": {
		"id": &"ach_09",
		"name": "ACH_09_NAME",
		"description": "ACH_09_DESC",
		"secret": false,
		"condition": "photos_10"
	},
	"ach_10": {
		"id": &"ach_10",
		"name": "ACH_10_NAME",
		"description": "ACH_10_DESC",
		"secret": false,
		"condition": "secrets_10"
	},
	"ach_11": {
		"id": &"ach_11",
		"name": "ACH_11_NAME",
		"description": "ACH_11_DESC",
		"secret": false,
		"condition": "coins_5000"
	},
	"ach_12": {
		"id": &"ach_12",
		"name": "ACH_12_NAME",
		"description": "ACH_12_DESC",
		"secret": false,
		"condition": "district4_no_damage"
	},
	"ach_13": {
		"id": &"ach_13",
		"name": "ACH_13_NAME",
		"description": "ACH_13_DESC",
		"secret": false,
		"condition": "boss_defeated"
	},
	"ach_14": {
		"id": &"ach_14",
		"name": "ACH_14_NAME",
		"description": "ACH_14_DESC",
		"secret": true,
		"condition": "ending_truth"
	},
	"ach_15": {
		"id": &"ach_15",
		"name": "ACH_15_NAME",
		"description": "ACH_15_DESC",
		"secret": true,
		"condition": "ending_dark"
	},
	"ach_16": {
		"id": &"ach_16",
		"name": "ACH_16_NAME",
		"description": "ACH_16_DESC",
		"secret": true,
		"condition": "speedrun_4h"
	},
	"ach_17": {
		"id": &"ach_17",
		"name": "ACH_17_NAME",
		"description": "ACH_17_DESC",
		"secret": true,
		"condition": "all_flashlight_skins"
	},
	"ach_18": {
		"id": &"ach_18",
		"name": "ACH_18_NAME",
		"description": "ACH_18_DESC",
		"secret": true,
		"condition": "hardcore_clear"
	},
	"ach_19": {
		"id": &"ach_19",
		"name": "ACH_19_NAME",
		"description": "ACH_19_DESC",
		"secret": true,
		"condition": "sleep_in_bed"
	},
	"ach_20": {
		"id": &"ach_20",
		"name": "ACH_20_NAME",
		"description": "ACH_20_DESC",
		"secret": true,
		"condition": "hallucinations_5"
	}
}

var _unlocked: Dictionary = {}
var _progress: Dictionary = {}
var _pref_path: String = "user://achievements.cfg"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load()
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.secret_found.connect(_on_secret_found)
	EventBus.district_restored.connect(_on_district_restored)
	EventBus.document_unlocked.connect(_on_document_unlocked)
	EventBus.quest_completed.connect(_on_quest_completed)
	EventBus.game_won.connect(_on_game_won)
	EventBus.item_consumed.connect(_on_item_consumed)

func _load() -> void:
	if not FileAccess.file_exists(_pref_path):
		return
	var f = FileAccess.open(_pref_path, FileAccess.READ)
	if f:
		var data = JSON.parse_string(f.get_as_text())
		if data is Dictionary:
			_unlocked = data.get("unlocked", {})
			_progress = data.get("progress", {})

func _save() -> void:
	var f = FileAccess.open(_pref_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"unlocked": _unlocked, "progress": _progress}))

func is_unlocked(achievement_id: StringName) -> bool:
	return _unlocked.get(String(achievement_id), false)

func get_progress(achievement_id: StringName) -> int:
	return _progress.get(String(achievement_id), 0)

func get_all() -> Array:
	var result: Array = []
	for aid in ACHIEVEMENTS:
		var data = ACHIEVEMENTS[aid].duplicate()
		data["unlocked"] = is_unlocked(aid)
		data["progress"] = get_progress(aid)
		data["name"] = LocalizationManager.t(String(data.get("name", aid)))
		data["description"] = LocalizationManager.t(String(data.get("description", "")))
		result.append(data)
	return result

func _unlock(achievement_id: StringName) -> void:
	if _unlocked.get(String(achievement_id), false):
		return
	_unlocked[String(achievement_id)] = true
	_save()
	achievement_unlocked.emit(achievement_id)

# Public API for external callers
func unlock(short_id: String) -> void:
	var map: Dictionary = {
		"architect": &"ach_13",
		"first_light": &"ach_01",
		"photographer": &"ach_09",
		"electrician": &"ach_02",
		"beacon": &"ach_03",
		"librarian": &"ach_04",
		"shadow_hunter": &"ach_05",
		"silent_mouse": &"ach_06",
		"combo_master": &"ach_07",
		"overload": &"ach_08",
		"seeker": &"ach_10",
		"economist": &"ach_11",
		"unscathed": &"ach_12",
		"truth": &"ach_14",
		"darkness": &"ach_15",
		"speedrunner": &"ach_16",
		"collector": &"ach_17",
		"iron_man": &"ach_18",
		"summer_night": &"ach_19",
		"who_there": &"ach_20",
	}
	var full_id = map.get(short_id, short_id)
	_unlock(full_id)

# Public property for UI
func get_achievements() -> Dictionary:
	var result: Dictionary = {}
	for aid in ACHIEVEMENTS:
		var data = ACHIEVEMENTS[aid].duplicate()
		data["unlocked"] = is_unlocked(aid)
		data["name"] = LocalizationManager.t(String(data.get("name", aid)))
		data["description"] = LocalizationManager.t(String(data.get("description", "")))
		data["title"] = data["name"]
		result[aid] = data
	return result

func _increment_progress(achievement_id: StringName, amount: int = 1) -> void:
	if is_unlocked(achievement_id):
		return
	var current = _progress.get(String(achievement_id), 0) + amount
	_progress[String(achievement_id)] = current
	var data = ACHIEVEMENTS.get(achievement_id, {})
	var target = 1
	if data:
		# Extract target from condition if possible
		pass
	_save()

func _on_enemy_killed(monster_id: StringName) -> void:
	if monster_id == &"shadow":
		_increment_progress(&"ach_05")
		_check_unlock(&"ach_05", 50)
	_increment_progress(&"ach_13")

func _on_secret_found(secret_id: StringName) -> void:
	_increment_progress(&"ach_10")
	_check_unlock(&"ach_10", 10)

func _on_district_restored(district_id: StringName, stage: int) -> void:
	if stage >= 3:
		# ach_01 "first_light" was passed a StringName (&"district_1") that
		# never matched either branch of _check_unlock - it could never
		# unlock. Same trigger as ach_02 "electrician" (this handler only
		# runs on stage>=3, i.e. a district reaching FULL) - "first light"
		# fires on that same real event, not a separate condition to invent.
		_check_unlock(&"ach_01", true)
		_check_unlock(&"ach_02", true)
		_check_unlock(&"ach_03", _all_districts_full())

func _on_document_unlocked(doc_id: StringName) -> void:
	_increment_progress(&"ach_04")
	_check_unlock(&"ach_04", _all_docs_collected())

func _on_quest_completed(quest_id: StringName) -> void:
	_increment_progress(&"ach_13")

func _on_game_won() -> void:
	_check_unlock(&"ach_13", true)

func _on_item_consumed(item_id: StringName, effect: StringName, value: float) -> void:
	if item_id == &"photo":
		_increment_progress(&"ach_09")
		_check_unlock(&"ach_09", 10)

## condition is either a bool (milestone already met/not) or an int target
## (compared against the running _progress counter _increment_progress()
## keeps). Previously any int target >= 1 unlocked immediately on the
## first call regardless of actual progress (e.g. "kill 50 shadows"
## unlocked on the first kill) - the threshold branch below was dead
## (`pass`).
func _check_unlock(achievement_id: StringName, condition: Variant) -> void:
	if condition is bool:
		if condition:
			_unlock(achievement_id)
	elif condition is int:
		var current: int = int(_progress.get(String(achievement_id), 0))
		if current >= int(condition):
			_unlock(achievement_id)

## Раньше стадии спрашивались по выдуманным id вида "district_0".. "district_10",
## которых нет ни в PowerGrid, ни в DistrictManager: get_stage() всегда
## возвращал 0, и достижение «весь город» не открывалось никогда.
## Источник правды один — PowerGrid.
func _all_districts_full() -> bool:
	var pg = get_node_or_null("/root/PowerGrid")
	if not pg:
		return false
	return pg.all_restored()

func _all_docs_collected() -> bool:
	var pt = get_node_or_null("/root/ProgressTracker")
	if not pt:
		return false
	return pt.get_found_documents() >= pt.get_total_documents() and pt.get_total_documents() > 0