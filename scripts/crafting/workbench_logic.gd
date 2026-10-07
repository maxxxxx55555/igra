extends RefCounted
## The workbench's one recipe table (GDD §9, §20) and its rules, shared by the screen (ui/workbench.gd), the
## world station and the tests. A recipe with a "blueprint" needs that blueprint learned (ProgressTracker; the
## pickup is spent on learning). One with a "flag" gives an ability, once; the others give `count` of `result`.

const RECIPES: Array[Dictionary] = [
	{"id":"medkit","name_key":"ITEM_MEDKIT","result":"medkit","count":1,"components":[["fabric",2],["alcohol",1]]},
	{"id":"battery","name_key":"ITEM_BATTERY","result":"battery","count":1,"components":[["cable",1],["fuse",1]]},
	{"id":"noise_bomb","name_key":"ITEM_NOISE_BOMB","result":"noise_bomb","count":1,"components":[["gunpowder",2],["case",1]]},
	{"id":"lockpick","name_key":"ITEM_LOCKPICK","result":"lockpick","count":1,"components":[["metal",2]]},
	{"id":"repair_kit","name_key":"ITEM_REPAIR_KIT","result":"repair_kit","count":1,"components":[["fabric",3],["tool",1]]},
	{"id":"firework","name_key":"ITEM_FIREWORK","result":"firework","count":1,"components":[["gunpowder",1],["paper",1]]},
	{"id":"molotov","name_key":"ITEM_MOLOTOV","result":"molotov","count":1,"components":[["bottle",1],["fabric",1],["alcohol",1]]},
	{"id":"makeshift_lamp","name_key":"ITEM_MAKESHIFT_LAMP","result":"makeshift_lamp","count":1,"components":[["metal",2],["battery",1]]},
	# GDD §9: the five blueprints, found in D2, D4, D7, D8 and D9 (DistrictLoot.WORKBENCH_BLUEPRINTS).
	{"id":"enhanced_battery","name_key":"ITEM_ENHANCED_BATTERY","result":"enhanced_battery","count":1,"components":[["battery",2],["cable",1]],"blueprint":"enhanced_battery"},
	{"id":"uv_flashlight","name_key":"ITEM_UV_FLASHLIGHT","result":"","flag":"uv_flashlight","components":[["cable",3],["fuse",1],["battery",2]],"blueprint":"uv_flashlight"},
	{"id":"strobe_flashlight","name_key":"ITEM_STROBE_FLASHLIGHT","result":"","flag":"strobe_flashlight","components":[["fuse",2],["transformer",1]],"blueprint":"strobe_flashlight"},
	{"id":"portable_workbench","name_key":"ITEM_PORTABLE_WORKBENCH","result":"","flag":"portable_workbench","components":[["plank",5],["metal",2],["tool",1]],"blueprint":"portable_workbench"},
	{"id":"battery_l2","name_key":"ITEM_BATTERY_L2","result":"battery_l2","count":1,"components":[["enhanced_battery",1],["cable",2],["transformer",1]],"blueprint":"battery_l2"},
]

static func is_available(recipe: Dictionary) -> bool:
	return not recipe.has("blueprint") or ProgressTracker.knows_blueprint(String(recipe["blueprint"]))

## An ability recipe is crafted once.
static func is_done(recipe: Dictionary) -> bool:
	return recipe.has("flag") and ProgressTracker.has_crafted(String(recipe["flag"]))

static func can_craft(recipe: Dictionary, qty: int = 1) -> bool:
	if qty <= 0 or not is_available(recipe) or is_done(recipe) or (recipe.has("flag") and qty > 1):
		return false
	for comp in recipe["components"]:
		if InventoryManager.count_of(StringName(comp[0])) < int(comp[1]) * qty:
			return false
	return true

## Spends the materials and gives the result; a pack with no room for it gets the materials back.
static func craft(recipe: Dictionary, qty: int = 1) -> bool:
	if not can_craft(recipe, qty):
		return false
	for comp in recipe["components"]:
		InventoryManager.remove(StringName(comp[0]), int(comp[1]) * qty)
	if recipe.has("flag"):
		ProgressTracker.mark_crafted(String(recipe["flag"]))
		ProgressTracker.crafted += 1
		return true
	if InventoryManager.try_add(StringName(recipe["result"]), int(recipe["count"]) * qty):
		ProgressTracker.crafted += 1
		return true
	for comp in recipe["components"]:
		InventoryManager.try_add(StringName(comp[0]), int(comp[1]) * qty, false)
	return false

static func find(id: String) -> Dictionary:
	for recipe in RECIPES:
		if recipe["id"] == id:
			return recipe
	return {}
