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

## STATIC_AUDIT #31: this table used to carry one entry per district and
## every content pack's item_spawns.json cited its row as "puzzle canon" —
## but the only interactable that ever calls start_puzzle() is
## cable_box_interactable.gd (PUZZLE_ID = "fuse_substation", placed only in
## substation.tscn), so the other 10 rows were unreachable dead data.
## District restoration DARK->FULL is fully live for all 11 districts via
## power_switch.gd's own independent item-cost repair loop, unaffected by
## this table. Trimmed to the one reachable puzzle rather than wiring 9
## more (would double-count puzzle_solved for progress/XP and change the
## reward economy — a GDD §3.3/§8 balance call, see PLAN.md 2026-09-10) or
## keeping data that lies about being canon. _grant_reward() stays general
## so a future real per-district puzzle interactable can add its row back.
func _load_puzzle_data() -> void:
	_puzzle_data = {
		"fuse_substation": {"reward": "coins", "amount": 200, "power_stage": 2},
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

## WAVE 6 P3: screens.gd's PuzzleCables screen hardcoded "cables_suburb"
## on solve regardless of which puzzle was actually started - every
## district's cable puzzle silently reported as suburb's.
func get_active_puzzle() -> String:
	return _active_puzzle

func mark_solved(id: String) -> void:
	_solved[id] = true
	_active_puzzle = ""
	EventBus.puzzle_solved.emit(StringName(id), _district_of(id))
	_grant_reward(id)
	_check_all_solved()
	# ProgressTracker сам считает пазлы по сигналу puzzle_solved выше;
	# здесь был вызов несуществующего increment_stat() — ошибка в рантайме.

## Идентификатор пазла = "<механизм>_<район>", поэтому район вытаскивается
## как остаток после первого подчёркивания (gas_station/power_station — с ним же).
func _district_of(id: String) -> StringName:
	var parts := id.split("_", true, 1)
	return StringName(parts[1]) if parts.size() > 1 else &""

func _grant_reward(id: String) -> void:
	if not _puzzle_data.has(id):
		return
	var data: Dictionary = _puzzle_data[id]
	match data["reward"]:
		"coins":
			CoinWallet.add(int(data["amount"]))
			EventBus.toast_requested.emit(
				LocalizationManager.tf("TOAST_COINS_GAINED", [data["amount"]]), "finding")
		"battery":
			EventBus.item_picked_up.emit(&"battery")
			EventBus.toast_requested.emit(
				LocalizationManager.tf("TOAST_ITEM_FOUND", [LocalizationManager.t("ITEM_BATTERY")]), "finding")
		"medkit":
			EventBus.item_picked_up.emit(&"medkit")
			EventBus.toast_requested.emit(
				LocalizationManager.tf("TOAST_ITEM_FOUND", [LocalizationManager.t("ITEM_MEDKIT")]), "finding")
		"ending":
			EventBus.toast_requested.emit(LocalizationManager.t("TOAST_REACTOR_ONLINE"), "achievement")

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

func reset() -> void:
	_solved.clear()
	_active_puzzle = ""
