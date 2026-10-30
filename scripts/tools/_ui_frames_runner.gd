extends "res://scripts/tools/_monster_frames_runner.gd"
## UI screens (session 37, the owner's canon): every screen of UIManager open over the street of the suburbs, one frame each, to be put beside the sheets of docs/art/style_reference.
## Windowed: TLS_FRAMES_HASH=<label> tools/qa_sim/guarded_windowed res://scenes/tools/ui_frames_scene.tscn 300
## Frames -> .qa_logs/frames/ui_<screen>_<label>_<UTC>.png (full size of the window). A saved frame proves nothing until it is read.

const SCREENS: Array[StringName] = [&"inventory", &"city_map", &"skill_tree", &"workbench", &"pause", &"settings", &"death", &"win", &"new_game_plus"]
const CODEX: Array[StringName] = [&"journal", &"quests", &"achievements", &"stats", &"bestiary", &"help", &"collection"]

func _run() -> void:
	if not await _enter_game():
		return
	SettingsManager.set_setting("text_size", 1)
	var frame_width: int = int(OS.get_environment("TLS_FRAME_WIDTH")) if not OS.get_environment("TLS_FRAME_WIDTH").is_empty() else 1280
	var frame_height: int = int(OS.get_environment("TLS_FRAME_HEIGHT")) if not OS.get_environment("TLS_FRAME_HEIGHT").is_empty() else 720
	get_window().size = Vector2i(frame_width, frame_height)
	await get_tree().create_timer(1.0).timeout
	for item_id in [&"fuse", &"battery", &"medkit", &"cable", &"alcohol"]:
		InventoryManager.try_add(item_id, 1, false)
	for id in SCREENS:
		UIManager.open(id)
		await get_tree().create_timer(0.8).timeout
		if id == &"inventory" and OS.get_environment("TLS_OPEN_INVENTORY_INSPECTOR") == "1":
			var inv := UIManager._get_screen(id)
			if inv != null:
				inv.set("_overlay_open", true)
				inv.call("_apply_responsive")
				await get_tree().create_timer(0.3).timeout
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
