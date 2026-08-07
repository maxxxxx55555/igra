extends Node
## Autoload "SaveLoad". JSON save/load to user://savegame.json.

const PATH := "user://savegame.json"

func save_data(data: Dictionary) -> bool:
	var f: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data))
	f.close()
	return true

func load_data() -> Variant:
	if not FileAccess.file_exists(PATH):
		return null
	var f: FileAccess = FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return null
	var text: String = f.get_as_text()
	f.close()
	return JSON.parse_string(text)

func delete_save() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))