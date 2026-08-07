extends Node

signal achievement_unlocked(id: String)

var achievements: Dictionary = {}
var _unlocked_ids: Array[String] = []

const DATA_PATH: String = "res://data/achievements/achievements.json"

func _ready() -> void:
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f == null:
		# push_error("AchievementManager: не найден " + DATA_PATH)
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		achievements = parsed
		for id in achievements:
			achievements[id]["unlocked"] = false

func unlock(id: String) -> void:
	if not achievements.has(id):
		return
	if achievements[id].unlocked:
		return
	achievements[id].unlocked = true
	_unlocked_ids.append(id)
	achievement_unlocked.emit(id)
	_show_toast(achievements[id].get("title", id))

func is_unlocked(id: String) -> bool:
	return achievements.has(id) and achievements[id].unlocked

func serialize() -> Dictionary:
	return {"unlocked": _unlocked_ids.duplicate()}

func from_dict(data: Dictionary) -> void:
	var unlocked: Array = data.get("unlocked", [])
	for id in unlocked:
		if achievements.has(id):
			achievements[id].unlocked = true
			if id not in _unlocked_ids:
				_unlocked_ids.append(id)

func _show_toast(title: String) -> void:
	var toast := Panel.new()
	var lbl := Label.new()
	lbl.text = "Достижение: %s!" % title
	toast.add_child(lbl)
	get_tree().root.add_child.call_deferred(toast)
	toast.position = Vector2(100, 50)
	
	var tween := create_tween()
	tween.tween_property(toast, "position:y", 100, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_interval(2.5)
	tween.chain().tween_property(toast, "modulate:a", 0.0, 0.5)
	tween.finished.connect(toast.queue_free)
