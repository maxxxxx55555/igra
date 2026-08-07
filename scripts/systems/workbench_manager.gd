extends Node

signal blueprint_crafted(blueprint_id: StringName)
signal crafting_started(blueprint_id: StringName)
signal crafting_failed(reason: String)

const BLUEPRINTS: Dictionary = {
	"blueprint_uv_flashlight": {
		"name": "Ультрафиолет",
		"description": "Монстры в конусе фонарика получают 5 урона/сек",
		"category": "Flashlight Module",
		"ingredients": {
			"cable": 3,
			"fuse": 1,
			"battery": 2
		},
		"result": "uv_flashlight_module",
		"result_amount": 1,
		"craft_time": 3.0,
		"unlock_location": "District 4, Physics Cabinet"
	},
	"blueprint_strobe_flashlight": {
		"name": "Стробоскоп",
		"description": "Двойной тап по кнопке фонарика = вспышка, STUN всем в конусе 1.5с. КД 10с",
		"category": "Flashlight Module",
		"ingredients": {
			"fuse": 2,
			"transformer": 1
		},
		"result": "strobe_flashlight_module",
		"result_amount": 1,
		"craft_time": 4.0,
		"unlock_location": "District 7, Interrogation Room"
	},
	"blueprint_portable_workbench": {
		"name": "Переносной верстак",
		"description": "Позволяет крафтить в поле",
		"category": "Utility",
		"ingredients": {
			"scrap": 5,
			"tool": 2,
			"circuit": 1
		},
		"result": "portable_workbench",
		"result_amount": 1,
		"craft_time": 5.0,
		"unlock_location": "District 8, Workshop"
	},
	"blueprint_battery_l2": {
		"name": "Усиленная батарея L2",
		"description": "Ёмкость батареи +40% (требует L1)",
		"category": "Battery Upgrade",
		"ingredients": {
			"blueprint_enhanced_battery": 1,
			"cable": 2,
			"transformer": 1
		},
		"result": "blueprint_enhanced_battery_l2",
		"result_amount": 1,
		"craft_time": 4.0,
		"unlock_location": "District 9, Factory Floor"
	},
	"blueprint_enhanced_battery": {
		"name": "Усиленная батарея",
		"description": "Ёмкость батареи +20%",
		"category": "Battery Upgrade",
		"ingredients": {
			"battery": 2,
			"cable": 1
		},
		"result": "blueprint_enhanced_battery",
		"result_amount": 1,
		"craft_time": 2.0,
		"unlock_location": "District 2, Basement"
	}
}

var _known_blueprints: Array = []
var _crafting: bool = false
var _current_blueprint: StringName = ""
var _craft_timer: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_known()

func _load_known() -> void:
	if not FileAccess.file_exists("user://known_blueprints.cfg"):
		return
	var f: FileAccess = FileAccess.open("user://known_blueprints.cfg", FileAccess.READ)
	if f:
		var data: Dictionary = JSON.parse_string(f.get_as_text())
		if data and data.has("known"):
			_known_blueprints = data["known"]

func _save_known() -> void:
	var f: FileAccess = FileAccess.open("user://known_blueprints.cfg", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"known": _known_blueprints}))

func is_known(blueprint_id: StringName) -> bool:
	return _known_blueprints.has(blueprint_id)

func learn_blueprint(blueprint_id: StringName) -> void:
	if not BLUEPRINTS.has(blueprint_id):
		return
	if not _known_blueprints.has(blueprint_id):
		_known_blueprints.append(blueprint_id)
		_save_known()

func get_blueprint_data(blueprint_id: StringName) -> Dictionary:
	if BLUEPRINTS.has(blueprint_id):
		var data: Dictionary = BLUEPRINTS[blueprint_id].duplicate()
		data["id"] = blueprint_id
		data["known"] = _known_blueprints.has(blueprint_id)
		data["can_craft"] = _can_craft(data)
		return data
	return {}

func get_all_blueprints() -> Array:
	var result: Array = []
	for bid in BLUEPRINTS:
		var data: Dictionary = BLUEPRINTS[bid].duplicate()
		data["id"] = bid
		data["known"] = _known_blueprints.has(bid)
		data["can_craft"] = _can_craft(data)
		result.append(data)
	return result

func get_known_blueprints() -> Array:
	var result: Array = []
	for bid in _known_blueprints:
		if BLUEPRINTS.has(bid):
			var data: Dictionary = BLUEPRINTS[bid].duplicate()
			data["id"] = bid
			data["known"] = true
			data["can_craft"] = _can_craft(data)
			result.append(data)
	return result

func _can_craft(data: Dictionary) -> bool:
	var inv: Node = get_node_or_null("/root/InventoryManager")
	if not inv:
		return false
	for item_id: StringName in data["ingredients"]:
		if not inv.has(item_id, int(data["ingredients"][item_id])):
			return false
	return true

func try_craft(blueprint_id: StringName) -> bool:
	if _crafting:
		return false
	if not BLUEPRINTS.has(blueprint_id):
		return false
	if not _known_blueprints.has(blueprint_id):
		crafting_failed.emit("Blueprint not learned")
		return false
	
	var data: Dictionary = BLUEPRINTS[blueprint_id]
	if not _can_craft(data):
		crafting_failed.emit("Insufficient materials")
		return false
	
	_crafting = true
	_current_blueprint = blueprint_id
	_craft_timer = data["craft_time"]
	crafting_started.emit(blueprint_id)
	return true

func _process(delta: float) -> void:
	if not _crafting:
		return
	_craft_timer -= delta
	if _craft_timer <= 0.0:
		_finish_craft()
		
func _finish_craft() -> void:
	var data: Dictionary = BLUEPRINTS[_current_blueprint]
	var inv: Node = get_node_or_null("/root/InventoryManager")
	if not inv:
		crafting_failed.emit("Inventory unavailable")
		_crafting = false
		return
	
	for item_id: StringName in data["ingredients"]:
		inv.remove(item_id, int(data["ingredients"][item_id]))
	
	if inv.try_add(data["result"], int(data.get("result_amount", 1))):
		blueprint_crafted.emit(_current_blueprint)
	else:
		crafting_failed.emit("Inventory full")
	
	_crafting = false
	_current_blueprint = ""
	_craft_timer = 0.0

func is_crafting() -> bool:
	return _crafting

func get_craft_progress() -> float:
	if not _crafting:
		return 0.0
	var data: Dictionary = BLUEPRINTS[_current_blueprint]
	return 1.0 - (_craft_timer / data["craft_time"])

func get_current_blueprint() -> StringName:
	return _current_blueprint