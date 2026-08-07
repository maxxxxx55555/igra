# scripts/economy/upgrade_system.gd — владелец: 05 Senior Godot Developer / 15 Economy Designer
# Автозагрузка 11. ФИНАЛ: тернарники -> if/else (нет INCOMPATIBLE_TERNARY), ключи/значения
# приведены к явным типам (нет Variant-нюансов). Поведение не изменено.
extends Node
const UPGRADE_TABLE: Dictionary = {
	&"upgrade_flashlight_brightness": {"target": "flashlight", "field": "energy_on", "delta": 0.25},
	&"upgrade_flashlight_battery":    {"target": "flashlight", "field": "drain_per_sec", "delta": -0.4},
	&"upgrade_backpack_capacity":     {"target": "inventory",  "field": "capacity_kg", "delta": 10.0},
	&"upgrade_backpack_slots":        {"target": "inventory",  "field": "base_slots", "delta": 4.0},
}
const BLUEPRINT_PREFIX: String = "blueprint_"
var _applied: Dictionary = {}
var _base: Dictionary = {}
var _flash_stats: FlashlightStats = preload("res://data/balance/flashlight_stats.tres")
var _inv_stats: InventoryStats = preload("res://data/balance/inventory_stats.tres")
func _ready() -> void:
	_snapshot_base()
	apply_all()
	EventBus.item_picked_up.connect(_on_pickup)
func _snapshot_base() -> void:
	for row in UPGRADE_TABLE.values():
		var target: String = str(row["target"])
		var field: String = str(row["field"])
		var key: String = "%s:%s" % [target, field]
		var res: Resource
		if target == "flashlight":
			res = _flash_stats
		else:
			res = _inv_stats
		_base[key] = res.get(field)
func apply_all() -> void:
	var acc: Dictionary = {}
	for id in _applied.keys():
		var row: Dictionary = UPGRADE_TABLE.get(id, {})
		if row.is_empty():
			continue
		var target: String = str(row["target"])
		var field: String = str(row["field"])
		var key: String = "%s:%s" % [target, field]
		acc[key] = float(acc.get(key, 0.0)) + float(row["delta"])
	for key in _base.keys():
		var skey: String = str(key)
		var parts: PackedStringArray = skey.split(":")
		var res: Resource
		if parts[0] == "flashlight":
			res = _flash_stats
		else:
			res = _inv_stats
		res.set(parts[1], float(_base[skey]) + float(acc.get(skey, 0.0)))
	for fl in get_tree().get_nodes_in_group("flashlight"):
		if fl.has_method("mark_cone_dirty"):
			fl.mark_cone_dirty()
func apply(upgrade_id: StringName) -> bool:
	if _applied.get(upgrade_id, false) or not UPGRADE_TABLE.has(upgrade_id):
		return false
	_applied[upgrade_id] = true
	apply_all()
	return true
func reset() -> void:
	_applied.clear()
	apply_all()
func is_applied(upgrade_id: StringName) -> bool:
	return _applied.get(upgrade_id, false)
func _on_pickup(item_id: StringName) -> void:
	var s := String(item_id)
	if s.begins_with(BLUEPRINT_PREFIX):
		var up_id := StringName(s.substr(BLUEPRINT_PREFIX.length()))
		if apply(up_id):
			EventBus.inventory_notice.emit("Чертёж применён: улучшение получено!")
func to_dict() -> Dictionary:
	return {"applied": _applied.keys().map(func(k): return String(k))}
func from_dict(d: Dictionary) -> void:
	_applied.clear()
	for k in d.get("applied", []):
		_applied[StringName(k)] = true
	apply_all()
