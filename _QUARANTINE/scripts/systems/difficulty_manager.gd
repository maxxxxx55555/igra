extends Node
## A3/A16: DifficultyManager - vybor + NG+

var difficulty: int = 1  # 0 easy, 1 normal, 2 hard
var ngplus: bool = false

func _ready() -> void:
	_load()
	ngplus = FileAccess.file_exists("user://ngplus.cfg")

func set_difficulty(d: int) -> void:
	difficulty = d; _save()

func hp_mult() -> float:
	var m = [0.7, 1.0, 1.5][clamp(difficulty, 0, 2)]
	if ngplus: m *= 1.5
	return m

func dmg_mult() -> float:
	var m = [0.7, 1.0, 1.4][clamp(difficulty, 0, 2)]
	if ngplus: m *= 1.5
	return m

func det_mult() -> float:
	return [0.8, 1.0, 1.2][clamp(difficulty, 0, 2)]

func _save() -> void:
	var f = FileAccess.open("user://diff.cfg", FileAccess.WRITE)
	if f: f.store_string(str(difficulty))

func _load() -> void:
	if FileAccess.file_exists("user://diff.cfg"):
		var f = FileAccess.open("user://diff.cfg", FileAccess.READ)
		if f: difficulty = int(f.get_as_text().strip_edges())