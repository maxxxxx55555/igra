extends Node
## D35: 3 slota + avtosejv

const SAVE_DIR: String = "user://saves/"
const MAX_SLOTS: int = 3

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func save_to_slot(slot: int, data: Dictionary) -> void:
	if slot < 1 or slot > MAX_SLOTS:
		return
	data.timestamp = Time.get_unix_time_from_system()
	data.datetime = Time.get_datetime_string_from_system()
	var path = SAVE_DIR + "slot_%d.json" % slot
	var f = FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func load_from_slot(slot: int) -> Dictionary:
	var path = SAVE_DIR + "slot_%d.json" % slot
	if not FileAccess.file_exists(path):
		return {}
	var f = FileAccess.open(path, FileAccess.READ)
	if not f:
		return {}
	var data = JSON.parse_string(f.get_as_text())
	return data if data is Dictionary else {}

func has_save(slot: int) -> bool:
	return FileAccess.file_exists(SAVE_DIR + "slot_%d.json" % slot)

func delete_slot(slot: int) -> void:
	var path = SAVE_DIR + "slot_%d.json" % slot
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func auto_save(data: Dictionary) -> void:
	data.timestamp = Time.get_unix_time_from_system()
	var path = SAVE_DIR + "autosave.json"
	var f = FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func get_slot_info(slot: int) -> Dictionary:
	var data = load_from_slot(slot)
	if data.is_empty():
		return {"empty": true}
	return {
		"empty": false,
		"datetime": data.get("datetime", "?"),
		"level": data.get("level", "?"),
		"playtime": data.get("playtime", 0)
	}