extends Node

## Puzzle system — manages puzzle states, completion, and rewards.

signal puzzle_solved(puzzle_id: String)
signal puzzle_failed(puzzle_id: String)
signal all_puzzles_solved()

var _solved: Dictionary = {}
var _active_puzzle: String = ""
var _puzzle_data: Dictionary = {}

func _ready() -> void:
	_load_puzzle_data()
	EventBus.district_restored.connect(_on_district_restored)

func _load_puzzle_data() -> void:
	_puzzle_data = {
		"generator_suburbs": {"reward": "coins", "amount": 50, "power_stage": 2},
		"fuse_residential": {"reward": "coins", "amount": 75, "power_stage": 2},
		"transformer_park": {"reward": "battery", "amount": 1, "power_stage": 2},
		"switch_school": {"reward": "coins", "amount": 100, "power_stage": 2},
		"generator_hospital": {"reward": "medkit", "amount": 1, "power_stage": 2},
		"fuse_gas_station": {"reward": "coins", "amount": 125, "power_stage": 2},
		"transformer_police": {"reward": "battery", "amount": 2, "power_stage": 2},
		"switch_warehouses": {"reward": "coins", "amount": 150, "power_stage": 2},
		"generator_industrial": {"reward": "medkit", "amount": 2, "power_stage": 2},
		"fuse_substation": {"reward": "coins", "amount": 200, "power_stage": 2},
		"reactor_power_station": {"reward": "ending", "amount": 1, "power_stage": 3}
	}

func start_puzzle(id: String) -> bool:
	if _solved.get(id, false):
		return false
	_active_puzzle = id
	EventBus.puzzle_started.emit(StringName(id))
	var screens := get_tree().root.find_child("Screens", true, false)
	if screens and screens.has_method("show_screen"):
		screens.show_screen("PuzzleCables")
	return true

func is_solved(id: String) -> bool:
	return _solved.get(id, false)

func mark_solved(id: String) -> void:
	_solved[id] = true
	_active_puzzle = ""
	EventBus.puzzle_solved.emit(StringName(id))
	_grant_reward(id)
	_check_all_solved()
	ProgressTracker.increment_stat("puzzles_solved")

func _grant_reward(id: String) -> void:
	if not _puzzle_data.has(id):
		return
	var data: Dictionary = _puzzle_data[id]
	match data["reward"]:
		"coins":
			CoinWallet.add_coins(data["amount"])
			EventBus.toast_requested.emit("+" + str(data["amount"]) + " coins", "finding")
		"battery":
			EventBus.item_picked_up.emit(&"battery")
			EventBus.toast_requested.emit("Battery found!", "finding")
		"medkit":
			EventBus.item_picked_up.emit(&"medkit")
			EventBus.toast_requested.emit("Medkit found!", "finding")
		"ending":
			EventBus.toast_requested.emit("Reactor online!", "achievement")

func _check_all_solved() -> void:
	var all_done := true
	for key in _puzzle_data:
		if not _solved.get(key, false):
			all_done = false
			break
	if all_done:
		all_puzzles_solved.emit()

func get_solved_count() -> int:
	return _solved.size()

func get_total_count() -> int:
	return _puzzle_data.size()

func get_progress() -> float:
	if _puzzle_data.is_empty():
		return 0.0
	return float(_solved.size()) / float(_puzzle_data.size())

func _on_district_restored(district_id: StringName) -> void:
	EventBus.toast_requested.emit("District restored!", "achievement")

func reset() -> void:
	_solved.clear()
	_active_puzzle = ""
