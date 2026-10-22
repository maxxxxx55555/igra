extends RefCounted
## The six keys of the quick bar (GDD 24.1 and 9.7) and the item each one uses. The defaults are the bar's own order; the
## player rewires a key by dragging an item from the inventory onto its slot, and SettingsManager keeps the six ids as one
## setting. Whatever it holds is checked on every read: a hand-edited or old file falls back to the defaults.
## C8 (v1.0.0-ship): the bar shows only what the player has (visible_slots): the flashlight, then the guns and items as they are found.

const KEY: String = "quick_slots"
const SLOTS: int = 6
## Weapon x2, battery, medkit, grenade, special item (the flashlight). hud_3d.gd keeps the same list as _SLOT_ITEMS.
const DEFAULTS: Array = [&"pistol", &"rifle", &"battery", &"medkit", &"molotov", &"flashlight"]
## The two weapon slots and the guns each one cycles through (GDD 18: pistol, rifle, shotgun); hud_3d.gd keeps the same list as _WEAPON_SLOTS.
const GUN_GROUPS: Array = [[&"pistol"], [&"rifle", &"shotgun"]]

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

## The guns a weapon id cycles through (GUN_GROUPS); empty for anything that is not a gun.
static func group_of(item_id: StringName) -> Array:
	for group: Array in GUN_GROUPS:
		if group.has(item_id):
			return group
	return []

## The slots the bar shows, as indices of the six: the flashlight always, a gun slot once a gun of its group is owned (ProgressTracker), any other once the player holds one of its item or bound
## it themselves (a binding that is not the default stays when the stack is gone). The key N of the bar is the Nth of these.
static func visible_slots() -> Array[int]:
	var bound: Array = read()
	var bound_by_player: bool = SettingsManager.get_setting(KEY, null) is Array
	var shown: Array[int] = []
	for i in SLOTS:
		var item_id := StringName(bound[i])
		var group: Array = group_of(item_id)
		var has: bool
		if item_id == &"flashlight":
			has = true
		elif not group.is_empty():
			has = group.any(func(id: StringName) -> bool: return ProgressTracker.has_weapon(String(id)))
		else:
			has = item_id != &"" and (InventoryManager.count_of(item_id) > 0 or (bound_by_player and item_id != DEFAULTS[i]))
		if has:
			shown.append(i)
	return shown

## The items of visible_slots, in their order: [flashlight] at the start of a run.
static func visible_defaults() -> Array:
	var bound: Array = read()
	return visible_slots().map(func(i: int) -> StringName: return bound[i])
