extends Node

signal quest_started(quest_id: StringName)
signal quest_completed(quest_id: StringName)
signal quest_progress(quest_id: StringName, progress: int, target: int)

const STATUS_NOT_STARTED = 0
const STATUS_ACTIVE = 1
const STATUS_COMPLETED = 2

var _quests: Dictionary = {}
var _active_quest_id: StringName = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_built_in_quests()
	if SaveSystem and SaveSystem.has_method("get_quest_data"):
		var saved = SaveSystem.get_quest_data()
		if saved:
			load_quest_data(saved)

func _load_built_in_quests() -> void:
	register_quest(&"q_main_restore_district", {
		"title": "Restore the District",
		"description": "Repair the power grid in the first district",
		"objectives": [
			{"id": "activate_generator", "description": "Activate the generator", "target": 1},
			{"id": "connect_cables", "description": "Connect all cables", "target": 3},
		],
		"rewards": {"coins": 100, "xp": 50}
	})
	
	register_quest(&"q_secret_hunter", {
		"title": "Secret Hunter",
		"description": "Find 5 secret rooms",
		"objectives": [
			{"id": "find_secrets", "description": "Discover secret rooms", "target": 5},
		],
		"rewards": {"item": "key_master", "xp": 200}
	})
	
	register_quest(&"q_shadow_slayer", {
		"title": "Shadow Slayer",
		"description": "Defeat 10 shadow enemies",
		"objectives": [
			{"id": "kill_shadows", "description": "Kill shadow enemies", "target": 10},
		],
		"rewards": {"coins": 200, "upgrade": "damage_boost"}
	})

func register_quest(quest_id: StringName, data: Dictionary) -> void:
	if not _quests.has(quest_id):
		_quests[quest_id] = {
			"data": data,
			"status": STATUS_NOT_STARTED,
			"progress": {}
		}
		for obj in data["objectives"]:
			_quests[quest_id]["progress"][obj["id"]] = 0

func start_quest(quest_id: StringName) -> void:
	if not _quests.has(quest_id):
		return
	if _quests[quest_id]["status"] != STATUS_NOT_STARTED:
		return
	_quests[quest_id]["status"] = STATUS_ACTIVE
	_active_quest_id = quest_id
	quest_started.emit(quest_id)
	_save_quests()

func complete_objective(quest_id: StringName, objective_id: StringName, amount: int = 1) -> void:
	if not _quests.has(quest_id):
		return
	var quest = _quests[quest_id]
	if quest["status"] != STATUS_ACTIVE:
		return
	if not quest["progress"].has(objective_id):
		return
	
	quest["progress"][objective_id] += amount
	var obj_data = _find_objective(quest["data"], objective_id)
	if obj_data:
		var current = quest["progress"][objective_id]
		var target = obj_data["target"]
		quest_progress.emit(quest_id, current, target)
		if current >= target:
			quest["progress"][objective_id] = target
			_check_completion(quest_id)

func _find_objective(data: Dictionary, objective_id: StringName):
	for obj in data["objectives"]:
		if obj["id"] == objective_id:
			return obj
	return {}

func _check_completion(quest_id: StringName) -> void:
	var quest = _quests[quest_id]
	var all_done = true
	for obj_id in quest["progress"]:
		var obj_data = _find_objective(quest["data"], obj_id)
		if obj_data and quest["progress"][obj_id] < obj_data["target"]:
			all_done = false
			break
	if all_done:
		complete_quest(quest_id)

func complete_quest(quest_id: StringName) -> void:
	if not _quests.has(quest_id):
		return
	if _quests[quest_id]["status"] != STATUS_ACTIVE:
		return
	
	_quests[quest_id]["status"] = STATUS_COMPLETED
	if _active_quest_id == quest_id:
		_active_quest_id = ""
	
	var rewards = _quests[quest_id]["data"].get("rewards", {})
	if rewards.has("coins"):
		CoinWallet.add(rewards["coins"])
	if rewards.has("xp"):
		XpManager.add_xp(int(rewards["xp"]))
	if rewards.has("item"):
		InventoryManager.try_add(rewards["item"], 1)
	if rewards.has("upgrade"):
		UpgradeSystem.apply(rewards["upgrade"])
	
	quest_completed.emit(quest_id)
	_save_quests()

func can_progress() -> bool:
	for quest_id in _quests:
		if _quests[quest_id]["status"] == STATUS_ACTIVE:
			var data = _quests[quest_id]["data"]
			if data.get("blocks_progression", false):
				return false
	return true

func get_quest_status(quest_id: StringName) -> int:
	if not _quests.has(quest_id):
		return STATUS_NOT_STARTED
	return _quests[quest_id]["status"]

func get_progress(quest_id: StringName) -> Dictionary:
	if not _quests.has(quest_id):
		return {}
	return _quests[quest_id]["progress"].duplicate()

func get_active_quest() -> StringName:
	return _active_quest_id

func get_active_quests() -> Array:
	var active := []
	for quest_id in _quests:
		if _quests[quest_id]["status"] == STATUS_ACTIVE:
			active.append(quest_id)
	return active

func is_completed(quest_id: StringName) -> bool:
	return _quests.has(quest_id) and _quests[quest_id]["status"] == STATUS_COMPLETED

func all_completed() -> bool:
	if _quests.is_empty():
		return false
	for quest_id in _quests:
		if _quests[quest_id]["status"] != STATUS_COMPLETED:
			return false
	return true

func _save_quests() -> void:
	var data = {}
	for quest_id in _quests:
		data[String(quest_id)] = {
			"status": _quests[quest_id]["status"],
			"progress": _quests[quest_id]["progress"]
		}
	SaveSystem.set_quest_data(data)

func load_quest_data(data: Dictionary) -> void:
	for key in data:
		var qid = StringName(key)
		if _quests.has(qid):
			_quests[qid]["status"] = data[key].get("status", STATUS_NOT_STARTED)
			var prog = data[key].get("progress", {})
			if prog is Dictionary:
				_quests[qid]["progress"] = prog
			if _quests[qid]["status"] == STATUS_ACTIVE:
				_active_quest_id = qid