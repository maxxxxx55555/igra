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

## T16: сейв-целостность. Раньше JSON писался напрямую в целевой файл —
## обрыв игры/питания посреди записи оставлял битый .save без возможности
## восстановления. Теперь: temp+rename (атомарно), SHA-256 в конверте,
## .bak — копия предыдущего валидного сейва на случай, если новый бит.

func _write_atomic(path: String, payload: Dictionary) -> bool:
	# checksum считаем от ТОЙ ЖЕ строки, что попадёт на диск как data_json —
	# JSON.parse превращает int в float, так что пересчёт чек-суммы после
	# парсинга payload заново в stringify() никогда бы не совпал с исходной.
	var body := JSON.stringify(payload)
	var envelope := {"checksum": body.sha256_text(), "data_json": body}
	var tmp_path := path + ".tmp"
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(envelope))
	f.close()
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(path, path + ".bak")
	var err := DirAccess.rename_absolute(tmp_path, path)
	return err == OK

## Читает и проверяет конверт по указанному пути; {} если файла нет,
## JSON битый, чек-сумма не сошлась или версия сейва новее движка.
## reason выводится через print() у вызывающей стороны — сама функция
## только классифицирует, чтобы не дублировать текст на каждый return.
func _read_envelope(path: String, out_reason: Array = []) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		if not out_reason.is_empty(): out_reason[0] = "не открылся"
		return {}
	var txt := f.get_as_text()
	f.close()
	var outer := JSON.new()
	if outer.parse(txt) != OK or not (outer.data is Dictionary):
		if not out_reason.is_empty(): out_reason[0] = "битый JSON"
		return {}
	var envelope: Dictionary = outer.data
	var body: String = String(envelope.get("data_json", ""))
	if body.is_empty() or body.sha256_text() != String(envelope.get("checksum", "")):
		if not out_reason.is_empty(): out_reason[0] = "не совпала чек-сумма"
		return {}
	var inner := JSON.new()
	if inner.parse(body) != OK or not (inner.data is Dictionary):
		if not out_reason.is_empty(): out_reason[0] = "битый data_json"
		return {}
	var data: Dictionary = inner.data
	if int(data.get("version", 0)) > SAVE_VERSION:
		if not out_reason.is_empty(): out_reason[0] = "версия сейва новее билда"
		return {}
	return data

## Основной файл -> .bak при провале основного (битый/пустой) -> {}.
## TRUTH WAVE P0.2: раньше провал был полностью тихим — залипший битый
## файл никак не давал о себе знать в логах, и следующая загрузка снова
## молча пыталась его прочитать. Теперь: лог о причине, а если и .bak не
## читается — карантин (переименование в .corrupt-<unix>), чтобы файл не
## путался под ногами при следующей попытке и чтобы это было видно на диске.
func _read_validated(path: String) -> Dictionary:
	var main_reason := [""]
	var data := _read_envelope(path, main_reason)
	if not data.is_empty():
		return data
	if main_reason[0] != "":
		print("[SaveSystem] основной сейв не читается (", main_reason[0], "): ", path, " — пробую .bak")
	var bak_reason := [""]
	data = _read_envelope(path + ".bak", bak_reason)
	if not data.is_empty():
		print("[SaveSystem] восстановлено из .bak: ", path)
		return data
	if main_reason[0] != "" and FileAccess.file_exists(path):
		var quarantine := path + ".corrupt-" + str(Time.get_unix_time_from_system())
		DirAccess.rename_absolute(path, quarantine)
		print("[SaveSystem] сейв и .bak не читаются — карантин в ", quarantine, ", старт с чистого состояния")
	return {}

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
		"quests": QuestManager.serialize(),
		"xp": XpManager.save_data(),
		"skill_tree": SkillTreeManager.save_data(),
		"photos": _photos,
		"daily_streak": _daily_streak,
		"last_daily_time": _last_daily_time,
	}
	_write_atomic(SAVE_PATH, payload)

func load_all() -> bool:
	var data := _read_validated(SAVE_PATH)
	if data.is_empty():
		return false
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
	# Прогресс квестов раньше оседал в буфере _quest_data и никому не отдавался:
	# после загрузки все 19 квестов снова были на нуле.
	QuestManager.from_dict(_quest_data)
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
	QuestManager.reset()
	_photos = []
	_daily_streak = 0
	_last_daily_time = 0
	Endings.reset()
	# TRUTH WAVE P0.2: эти двое сохранялись через SaveSystem (см. _save()/
	# load_all()), но reset_all() их не трогал — "новая игра" стартовала
	# с уровнем/скиллами от прошлого забега на этом сейв-профиле.
	XpManager.reset()
	SkillTreeManager.reset()

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
	var data := _read_validated(_get_slot_path(slot))
	if data.is_empty():
		return {"exists": false}
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
		"quests": QuestManager.serialize(),
		"xp": XpManager.save_data(),
		"skill_tree": SkillTreeManager.save_data(),
		"photos": _photos,
		"daily_streak": _daily_streak,
		"last_daily_time": _last_daily_time,
		"timestamp": Time.get_unix_time_from_system()
	}
	return _write_atomic(_get_slot_path(slot), payload)

func load_slot(slot: int) -> bool:
	var data := _read_validated(_get_slot_path(slot))
	if data.is_empty():
		return false
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
	QuestManager.from_dict(_quest_data)
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
	if FileAccess.file_exists(path + ".bak"):
		DirAccess.remove_absolute(path + ".bak")
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

## TRUTH WAVE P0: "Reset progress" (settings_screen.gd) and boot-time
## quarantine of an unreadable/mismatched save both need this — reset_all()
## alone only clears autoload state in memory, it never touched the actual
## save files, so a restart would resurrect the old progress via Continue.
func wipe_all_saves() -> void:
	for p in [SAVE_PATH, SAVE_PATH + ".bak"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
	for i in range(1, MAX_SLOTS + 1):
		delete_slot(i)
	reset_all()
