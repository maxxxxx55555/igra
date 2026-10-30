extends "res://scripts/tools/_monster_frames_runner.gd"
## UI screens (session 37, the owner's canon): every screen of UIManager open over the street of the suburbs, one frame each, to be put beside the sheets of docs/art/style_reference.
## Windowed: TLS_FRAMES_HASH=<label> tools/qa_sim/guarded_windowed res://scenes/tools/ui_frames_scene.tscn 300
## TLS_FRAMES_SIZE=1280x720 sets the window (1600x900 by default); TLS_FRAMES_LANG=de (any of the six) shoots the pack screen and its states in that language alone.
## Frames -> .qa_logs/frames/ui_<screen>_<label>_<UTC>.png (full size of the window). A saved frame proves nothing until it is read.

const SCREENS: Array[StringName] = [&"inventory", &"city_map", &"skill_tree", &"workbench", &"pause", &"settings", &"death", &"win", &"new_game_plus"]
const CODEX: Array[StringName] = [&"journal", &"quests", &"achievements", &"stats", &"bestiary", &"help", &"collection"]
const FILL: Array[StringName] = [&"plank", &"gear", &"transistor", &"wiring"]
const PACK: Array = [[&"battery", 2], [&"medkit", 1], [&"serum", 1], [&"fuse", 2], [&"circuit", 2], [&"cable", 3], [&"scrap", 6], [&"alcohol", 1]]

func _run() -> void:
	if not await _enter_game():
		return
	var lang := OS.get_environment("TLS_FRAMES_LANG")
	if lang != "":
		LocalizationManager.set_language(lang)
	var wanted := OS.get_environment("TLS_FRAMES_SIZE").split("x")
	get_window().size = Vector2i(int(wanted[0]), int(wanted[1])) if wanted.size() == 2 else Vector2i(1600, 900)
	for stack: Array in PACK:  # a pack with stacks of several rarities and free slots left: the populated state of the grid
		InventoryManager.try_add(stack[0], stack[1])
	await get_tree().create_timer(1.0).timeout
	for id in (SCREENS if lang == "" else SCREENS.slice(0, 1)):
		UIManager.open(id)
		await get_tree().create_timer(0.8).timeout
		await _frame("ui_" + String(id))
		UIManager.close(id)
		await get_tree().create_timer(0.4).timeout
	await _inventory_states()
	for tab in (CODEX if lang == "" else []):
		UIManager.open_codex(tab)
		await get_tree().create_timer(0.8).timeout
		await _frame("ui_codex_" + String(tab))
		UIManager.close(&"codex")
		await get_tree().create_timer(0.4).timeout
	print("[lframes] DONE hash=%s" % _hash)
	get_tree().quit(0)

## The states of the pack the recovery brief asks to see (C1): a filter with nothing in it, a pack with one slot free, a pack with nothing in it.
func _inventory_states() -> void:
	UIManager.open(&"inventory")
	await get_tree().create_timer(0.6).timeout
	var ui: Control = UIManager._get_screen(&"inventory")
	ui._on_filter(4)
	await get_tree().create_timer(0.5).timeout
	await _frame("ui_inventory_filtered_empty")
	ui._on_filter(0)
	for id in FILL:
		InventoryManager.try_add(id, 1)
	await get_tree().create_timer(0.5).timeout
	await _frame("ui_inventory_near_capacity")
	InventoryManager.from_dict({})
	await get_tree().create_timer(0.5).timeout
	await _frame("ui_inventory_empty")
	UIManager.close(&"inventory")
	await get_tree().create_timer(0.4).timeout
