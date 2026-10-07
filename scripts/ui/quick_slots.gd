extends RefCounted
## The six keys of the quick bar (GDD 24.1 and 9.7) and the item each one uses. The defaults are the bar's own order; the
## player rewires a key by dragging an item from the inventory onto its slot, and SettingsManager keeps the six ids as one
## setting. Whatever it holds is checked on every read: a hand-edited or old file falls back to the defaults.

const KEY: String = "quick_slots"
const SLOTS: int = 6
## Weapon x2, battery, medkit, grenade, special item (the flashlight). hud_3d.gd keeps the same list as _SLOT_ITEMS.
const DEFAULTS: Array = [&"pistol", &"rifle", &"battery", &"medkit", &"molotov", &"flashlight"]

## The six ids in force: the saved ones when there are six and each is blank or a known item, else the defaults.
static func read() -> Array:
	var saved: Variant = SettingsManager.get_setting(KEY, null)
	if typeof(saved) != TYPE_ARRAY or (saved as Array).size() != SLOTS:
		return DEFAULTS.duplicate()
	var bound: Array = []
	for entry in (saved as Array):
		var item_id := StringName(str(entry))
		if item_id != &"" and not DEFAULTS.has(item_id) and not ItemDatabase.has_item(item_id):
			return DEFAULTS.duplicate()
		bound.append(item_id)
	return bound

## What a key can use: a consumable. The guns and the light keep to their own slots.
static func can_bind(item_id: StringName) -> bool:
	var data := ItemDatabase.get_item(item_id)
	return data != null and data.consumable

static func bind(index: int, item_id: StringName) -> void:
	if index < 0 or index >= SLOTS:
		return
	var bound: Array = read()
	bound[index] = item_id
	SettingsManager.set_setting(KEY, bound)

## Puts a slot back to its default item.
static func clear(index: int) -> void:
	if index >= 0 and index < SLOTS:
		bind(index, DEFAULTS[index])
