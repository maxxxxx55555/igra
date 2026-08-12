extends Node

const SAVE_PATH: String = "user://tls_savegame.save"
const SAVE_VERSION: int = 3
const AUTOSAVE_INTERVAL: float = 30.0
const MAX_SLOTS: int = 4

var _pending_player_pos: Vector3 = Vector3.INF
var _autosave_timer: float = AUTOSAVE_INTERVAL
var _quest_data: Dictionary = {}
var _photos: Array = []
var _daily_streak: int = 0
var _last_daily_time: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.district_restored.connect(func(_a, _b): _save())
	EventBus.puzzle_solved.connect(func(_a, _b): _save())
	EventBus.purchase_success.connect(func(_a): _save())
	EventBus.secret_found.connect(func(_a): _save())

func _process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	_autosave_timer -= delta
	if _autosave_timer <= 0.0:
		_autosave_timer = AUTOSAVE_INTERVAL
		save_slot(4)  # autosave to slot 4

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func set_checkpoint(_scene_path: String, pos: Vector3) -> void:
	_pending_player_pos = pos
	_save()

func save_all() -> void:
	_save()

func _save() -> void:
	var payload: Dictionary = {
		"version": SAVE_VERSION,
		"wallet": CoinWallet.to_dict(),
		"shop": ShopService.to_dict(),
		"upgrades": UpgradeSystem.to_dict(),
		"inventory": InventoryManager.to_dict(),
		"power": PowerGrid.to_dict(),
		"encyclopedia": Encyclopedia.to_dict(),
		"progress": ProgressTracker.to_dict(),
		"settings": SettingsManager.to_dict(),
		"player_pos": _read_player_pos(),
		"district": _current_district(),
		"quests": _quest_data,
		"xp": XpManager.save_data(),
		"skill_tree": SkillTreeManager.save_data(),
		"photos": _photos,
		"daily_streak": _daily_streak,
		"last_daily_time": _last_daily_time,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		# push_error("SaveSystem: не удалось записать %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(payload))
	file.close()

func load_all() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var txt: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(txt) != OK:
		# push_error("SaveSystem: ошибка парсинга")
		return false
	var d: Variant = json.data
	if not (d is Dictionary):
		return false
	var data: Dictionary = d as Dictionary
	PowerGrid.from_dict(data.get("power", {}))
	CoinWallet.from_dict(data.get("wallet", {}))
	ShopService.from_dict(data.get("shop", {}))
	UpgradeSystem.from_dict(data.get("upgrades", {}))
	InventoryManager.from_dict(data.get("inventory", {}))
	Encyclopedia.from_dict(data.get("encyclopedia", {}))
	ProgressTracker.from_dict(data.get("progress", {}))
	SettingsManager.from_dict(data.get("settings", {}))
	var pp = data.get("player_pos", null)
	_pending_player_pos = Vector3(pp[0], pp[1], pp[2]) if (pp is Array and pp.size() >= 3) else Vector3.INF
	_quest_data = data.get("quests", {})
	# Текущий район раньше хранил только SaveLoad; без него загрузка всегда
	# возвращала игрока в стартовые пригороды.
	var dm := get_node_or_null("/root/DistrictManager")
	var did: String = String(data.get("district", ""))
	if dm != null and not did.is_empty():
		dm.current_district = did
	_photos = data.get("photos", [])
	_daily_streak = int(data.get("daily_streak", 0))
	_last_daily_time = int(data.get("last_daily_time", 0))
	SkillTreeManager.load_data(data.get("skill_tree", {}))
	XpManager.load_data(data.get("xp", {}))
	return true

func reset_all() -> void:
	PowerGrid.reset()
	UpgradeSystem.reset()
	CoinWallet.from_dict({})
	ShopService.from_dict({})
	InventoryManager.from_dict({})
	Encyclopedia.from_dict({})
	_pending_player_pos = Vector3.INF
	_quest_data = {}
	_photos = []
	_daily_streak = 0
	_last_daily_time = 0
	Endings.reset()

func consume_pending_player_pos() -> Vector3:
	var p := _pending_player_pos
	_pending_player_pos = Vector3.INF
	return p

func set_quest_data(data: Dictionary) -> void:
	_quest_data = data

func get_quest_data() -> Dictionary:
	return _quest_data.duplicate()

func add_photo(photo_id: String) -> bool:
	if photo_id in _photos:
		return false
	_photos.append(photo_id)
	_save()
	return true

func get_photos() -> Array:
	return _photos.duplicate()

func get_photo_count() -> int:
	return _photos.size()

func get_daily_streak() -> int:
	return _daily_streak

func increment_daily_streak() -> void:
	var now := Time.get_unix_time_from_system()
	var last := _last_daily_time
	if now - last > 86400 * 2:
		_daily_streak = 0
	_daily_streak += 1
	_last_daily_time = int(now)
	_save()

func _current_district() -> String:
	var dm := get_node_or_null("/root/DistrictManager")
	return String(dm.current_district) if dm != null else ""

func _read_player_pos() -> Array:
	var p := get_tree().get_first_node_in_group("player")
	if is_instance_valid(p):
		return [p.global_position.x, p.global_position.y, p.global_position.z]
	return [0.0, 0.0, 0.0]

func _get_slot_path(slot: int) -> String:
	return "user://tls_savegame_slot%d.save" % slot

func get_slot_info(slot: int) -> Dictionary:
	var path = _get_slot_path(slot)
	if not FileAccess.file_exists(path):
		return {"exists": false}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {"exists": false}
	
	var txt = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(txt) != OK:
		return {"exists": false}
	
	var data = json.data as Dictionary
	var progress = data.get("progress", {})
	
	return {
		"exists": true,
		"level": data.get("current_scene", "").get_file().get_basename().replace("level_", "").to_int() if data.get("current_scene", "") != "" else 1,
		"playtime": progress.get("time_played", 0.0),
		"modified": 0.0,
		"scene": data.get("current_scene", "")
	}

func save_slot(slot: int) -> bool:
	var payload: Dictionary = {
		"version": SAVE_VERSION,
		"wallet": CoinWallet.to_dict(),
		"shop": ShopService.to_dict(),
		"upgrades": UpgradeSystem.to_dict(),
		"inventory": InventoryManager.to_dict(),
		"power": PowerGrid.to_dict(),
		"encyclopedia": Encyclopedia.to_dict(),
		"progress": ProgressTracker.to_dict(),
		"settings": SettingsManager.to_dict(),
		"player_pos": _read_player_pos(),
		"quests": _quest_data,
		"xp": XpManager.save_data(),
		"skill_tree": SkillTreeManager.save_data(),
		"photos": _photos,
		"daily_streak": _daily_streak,
		"last_daily_time": _last_daily_time,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	var file = FileAccess.open(_get_slot_path(slot), FileAccess.WRITE)
	if file == null:
		# push_error("SaveSystem: не удалось записать слот %d" % slot)
		return false
	
	file.store_string(JSON.stringify(payload))
	file.close()
	return true

func load_slot(slot: int) -> bool:
	var path = _get_slot_path(slot)
	if not FileAccess.file_exists(path):
		return false
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	
	var txt = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(txt) != OK:
		# push_error("SaveSystem: ошибка парсинга слота %d" % slot)
		return false
	
	var data = json.data as Dictionary
	PowerGrid.from_dict(data.get("power", {}))
	CoinWallet.from_dict(data.get("wallet", {}))
	ShopService.from_dict(data.get("shop", {}))
	UpgradeSystem.from_dict(data.get("upgrades", {}))
	InventoryManager.from_dict(data.get("inventory", {}))
	Encyclopedia.from_dict(data.get("encyclopedia", {}))
	ProgressTracker.from_dict(data.get("progress", {}))
	SettingsManager.from_dict(data.get("settings", {}))
	var pp = data.get("player_pos", null)
	_pending_player_pos = Vector3(pp[0], pp[1], pp[2]) if (pp is Array and pp.size() >= 3) else Vector3.INF
	_quest_data = data.get("quests", {})
	_photos = data.get("photos", [])
	_daily_streak = int(data.get("daily_streak", 0))
	_last_daily_time = int(data.get("last_daily_time", 0))
	
	# Load skill tree
	if SkillTreeManager:
		SkillTreeManager.load_data(data.get("skill_tree", {}))
	
	# Load XP
	if XpManager:
		XpManager.load_data(data.get("xp", {}))
	
	return true

func delete_slot(slot: int) -> bool:
	var path = _get_slot_path(slot)
	if FileAccess.file_exists(path):
		var err = DirAccess.remove_absolute(path)
		return err == OK
	return false

func get_all_slots_info() -> Array:
	var result: Array = []
	for i in range(1, MAX_SLOTS + 1):
		var info = get_slot_info(i)
		info["slot"] = i
		info["is_autosave"] = (i == MAX_SLOTS)
		result.append(info)
	return result
