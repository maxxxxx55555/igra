extends Node

signal upgrade_purchased(branch: String, level: int)
signal stats_changed()

enum Branch { BRIGHTNESS, RANGE, STABILITY, ANGLE, BATTERY }

const BRANCH_NAMES: Array = ["brightness", "range", "stability", "angle", "battery"]
## Названия и описания веток лежали здесь готовыми русскими строками, из-за
## чего на остальных 12 языках экран улучшений был русским. Теперь — ключи,
## а перевод берётся в get_branch_display()/get_branch_desc().
const BRANCH_DISPLAY: Dictionary = {
	"brightness": "SCR_YARKOST",
	"range": "SCR_DALNOST",
	"stability": "SCR_STABILNOST",
	"angle": "SCR_UGOL_SVETA",
	"battery": "ITEM_BATTERY",
}
const BRANCH_DESC: Dictionary = {
	"brightness": "UPG_BRIGHTNESS_DESC",
	"range": "UPG_RANGE_DESC",
	"stability": "UPG_STABILITY_DESC",
	"angle": "UPG_ANGLE_DESC",
	"battery": "UPG_BATTERY_DESC",
}

## GDD §3.3: one shared cost column for all 5 branches (100/250/500/1000/
## 2000, sum 3850 each -> 19250 to max everything). stability/battery had
## their own higher table (sum 4550 each, 20650 total) - a 1400-coin/7%
## deviation from the documented economy figure.
const BASE_COSTS: Dictionary = {
	"brightness": [100, 250, 500, 1000, 2000],
	"range": [100, 250, 500, 1000, 2000],
	"stability": [100, 250, 500, 1000, 2000],
	"angle": [100, 250, 500, 1000, 2000],
	"battery": [100, 250, 500, 1000, 2000]
}

const LEVEL_BONUSES: Dictionary = {
	"brightness": [0.2, 0.4, 0.6, 0.8, 1.0],
	"range": [1.0, 2.0, 3.0, 4.0, 5.0],
	"stability": [0.1, 0.2, 0.3, 0.4, 0.5],
	"angle": [10.0, 20.0, 30.0, 40.0, 50.0],
	"battery": [0.2, 0.4, 0.6, 0.8, 1.0]
}

var _levels: Dictionary = {
	"brightness": 0,
	"range": 0,
	"stability": 0,
	"angle": 0,
	"battery": 0
}

var _pref_path: String = "user://flashlight_upgrades.cfg"

func _ready() -> void:
	_load()

func get_level(branch: String) -> int:
	return _levels.get(branch, 0)

func get_max_level() -> int:
	return 5

func get_cost(branch: String, level: int) -> int:
	var costs: Array = BASE_COSTS.get(branch, [])
	if level - 1 < costs.size():
		return costs[level - 1]
	return -1

func get_bonus(branch: String) -> float:
	var lvl: int = _levels.get(branch, 0)
	if lvl == 0:
		return 0.0
	var bonuses: Array = LEVEL_BONUSES.get(branch, [])
	if lvl - 1 < bonuses.size():
		return bonuses[lvl - 1]
	return bonuses[-1]

func can_purchase(branch: String) -> bool:
	var lvl: int = _levels.get(branch, 0)
	return lvl < 5

func try_purchase(branch: String) -> bool:
	if not can_purchase(branch):
		return false
	var cost: int = get_cost(branch, _levels[branch] + 1)
	var wallet: Node = get_node_or_null("/root/CoinWallet")
	if not wallet or not wallet.has_method("try_spend"):
		return false
	if not wallet.try_spend(cost):
		return false
	_levels[branch] += 1
	_save()
	upgrade_purchased.emit(branch, _levels[branch])
	stats_changed.emit()
	_apply_to_flashlight()
	return true

func get_branch_display(branch: String) -> String:
	return LocalizationManager.t(String(BRANCH_DISPLAY.get(branch, branch)))

func get_branch_desc(branch: String) -> String:
	var key: String = String(BRANCH_DESC.get(branch, ""))
	return LocalizationManager.t(key) if not key.is_empty() else ""

func get_all_data() -> Array:
	var result: Array = []
	for b in BRANCH_NAMES:
		result.append({
			"id": b,
			"name": get_branch_display(b),
			"desc": get_branch_desc(b),
			"level": _levels[b],
			"max": 5,
			"cost": get_cost(b, _levels[b] + 1),
			"bonus": get_bonus(b),
			"can_buy": can_purchase(b)
		})
	return result

func _apply_to_flashlight() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return
	if player.has_method("apply_flashlight_upgrades"):
		player.apply_flashlight_upgrades(_levels.duplicate())

func _save() -> void:
	var f: FileAccess = FileAccess.open(_pref_path, FileAccess.WRITE)
	if f:
		var data: Dictionary = {}
		for b in BRANCH_NAMES:
			data[b] = _levels[b]
		f.store_string(JSON.stringify(data))

func _load() -> void:
	if not FileAccess.file_exists(_pref_path):
		return
	var f: FileAccess = FileAccess.open(_pref_path, FileAccess.READ)
	if f:
		var data: Dictionary = JSON.parse_string(f.get_as_text())
		if data is Dictionary:
			for b in BRANCH_NAMES:
				_levels[b] = data.get(b, 0)