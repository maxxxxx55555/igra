extends Node
const _ITEMS: Array = [
	preload("res://data/items/battery.tres"),
	preload("res://data/items/medkit.tres"),
	preload("res://data/items/key.tres"),
	preload("res://data/items/scrap.tres"),
	preload("res://data/items/cable.tres"),
	preload("res://data/items/fuse.tres"),
	preload("res://data/items/blueprint_flashlight_brightness.tres"),
	preload("res://data/items/blueprint_flashlight_battery.tres"),
	preload("res://data/items/blueprint_backpack_capacity.tres"),
	preload("res://data/items/blueprint_backpack_slots.tres"),
	preload("res://data/items/gear.tres"),
	preload("res://data/items/wiring.tres"),
	preload("res://data/items/circuit.tres"),
	preload("res://data/items/transistor.tres"),
	preload("res://data/items/motor.tres"),
	preload("res://data/items/radio_part.tres"),
	preload("res://data/items/scope_lens.tres"),
	preload("res://data/items/serum.tres"),
	preload("res://data/items/gas_canister.tres"),
	preload("res://data/items/ancient_key.tres"),
	preload("res://data/items/transformer.tres"),
	preload("res://data/items/tool.tres"),
	preload("res://data/items/coin.tres"),
	preload("res://data/items/backpack_l1.tres"),
	preload("res://data/items/backpack_l2.tres"),
	preload("res://data/items/document.tres"),
	preload("res://data/items/audio_log.tres"),
	preload("res://data/items/photo.tres"),
	# WAVE 6 P2: workbench.gd's RECIPES needed these 13 - 7 raw materials
	# for the 8 recipes, 6 craft results (medkit/battery already existed
	# above). Icons unset (ASSET_PENDING) - item_database.gd's own
	# fallback below already handles that for every other item too.
	preload("res://data/items/fabric.tres"),
	preload("res://data/items/alcohol.tres"),
	preload("res://data/items/gunpowder.tres"),
	preload("res://data/items/case.tres"),
	preload("res://data/items/metal.tres"),
	preload("res://data/items/paper.tres"),
	preload("res://data/items/bottle.tres"),
	preload("res://data/items/noise_bomb.tres"),
	preload("res://data/items/lockpick.tres"),
	preload("res://data/items/repair_kit.tres"),
	preload("res://data/items/firework.tres"),
	preload("res://data/items/molotov.tres"),
	preload("res://data/items/makeshift_lamp.tres"),
]
const ICON_DIR: String = "res://assets/textures/items/"
var _by_id: Dictionary = {}
func _ready() -> void:
	for data in _ITEMS:
		if data is ItemData:
			var item: ItemData = data as ItemData
			_by_id[item.id] = item
			if item.icon == null:
				var p: String = ICON_DIR + String(item.id) + ".png"
				if ResourceLoader.exists(p):
					item.icon = load(p) as Texture2D
func get_item(id: StringName) -> ItemData:
	return _by_id.get(id, null)
func has_item(id: StringName) -> bool:
	return _by_id.has(id)
func all_ids() -> Array:
	return _by_id.keys()