extends Node

const LEADERBOARD_PATH: String = "user://leaderboard.json"
var entries: Array[Dictionary] = []

func _ready() -> void:
	_load()

func add_entry(name: String, score: int, level: int, time: float) -> void:
	entries.append({
		"name": name,
		"score": score,
		"level": level,
		"time": time,
		"date": Time.get_datetime_string_from_system()
	})
	entries.sort_custom(func(a, b): return a.score > b.score)
	if entries.size() > 10:
		entries.resize(10)
	_save()

func _save() -> void:
	var file := FileAccess.open(LEADERBOARD_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(entries))

func _load() -> void:
	if not FileAccess.file_exists(LEADERBOARD_PATH):
		return
	var file := FileAccess.open(LEADERBOARD_PATH, FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if data is Array:
			entries = data
