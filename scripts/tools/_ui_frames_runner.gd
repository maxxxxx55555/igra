extends "res://scripts/tools/_monster_frames_runner.gd"
## UI screens (session 37, the owner's canon): every screen of UIManager open over the street of the suburbs, one frame each, to be put beside the sheets of docs/art/style_reference.
## Windowed: TLS_FRAMES_HASH=<label> tools/qa_sim/guarded_windowed res://scenes/tools/ui_frames_scene.tscn 300
## Frames -> .qa_logs/frames/ui_<screen>_<label>_<UTC>.png (full size of the window). A saved frame proves nothing until it is read.

const SCREENS: Array[StringName] = [&"inventory", &"city_map", &"skill_tree", &"workbench", &"pause", &"settings", &"death", &"win", &"new_game_plus"]
const CODEX: Array[StringName] = [&"journal", &"quests", &"achievements", &"stats", &"bestiary", &"help", &"collection"]
const PACK: Array = [[&"battery", 2], [&"medkit", 1], [&"serum", 1], [&"fuse", 2], [&"circuit", 2], [&"cable", 3], [&"scrap", 6], [&"alcohol", 1]]

func _run() -> void:
	if not await _enter_game():
		return
	get_window().size = Vector2i(1600, 900)
	for stack: Array in PACK:  # a pack with stacks of several rarities and free slots left: the populated state of the grid
		InventoryManager.try_add(stack[0], stack[1])
	await get_tree().create_timer(1.0).timeout
	for id in SCREENS:
		UIManager.open(id)
		await get_tree().create_timer(0.8).timeout
		await _frame("ui_" + String(id))
		UIManager.close(id)
		await get_tree().create_timer(0.4).timeout
	for tab in CODEX:
		UIManager.open_codex(tab)
		await get_tree().create_timer(0.8).timeout
		await _frame("ui_codex_" + String(tab))
		UIManager.close(&"codex")
		await get_tree().create_timer(0.4).timeout
	print("[lframes] DONE hash=%s" % _hash)
	get_tree().quit(0)
