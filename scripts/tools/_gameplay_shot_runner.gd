extends Node
## Actual runner, spawned under get_tree().root by _gameplay_shot.gd so it
## survives the Routes.goto() scene swaps it triggers/watches.

const OUT_DEFAULT := "res://docs/shots/gameplay_shot.png"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")

func _out_path() -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			return a.substr(6)
	return OUT_DEFAULT

func _run() -> void:
	var ads := get_node_or_null("/root/AdService")
	if ads:
		ads.enabled = false
	# Same race-avoidance as _boot_check_runner.gd: wait a beat so
	# _bootstrap.gd's own current_scene check resolves first, then nudge
	# only if still stuck (calling goto() immediately races it).
	await get_tree().create_timer(1.0).timeout
	if not _menu_reachable():
		Routes.goto(Routes.MENU)
	if not await _wait_until(_menu_reachable, 12.0):
		printerr("SHOT_FAIL: menu never reachable")
		get_tree().quit(1)
		return
	Routes.start_game()
	if not await _wait_until(func() -> bool: return GameManager.is_playing(), 10.0):
		printerr("SHOT_FAIL: never entered PLAYING")
		get_tree().quit(1)
		return
	if not await _wait_until(func() -> bool: return get_tree().get_first_node_in_group("player") != null, 10.0):
		printerr("SHOT_FAIL: player never spawned")
		get_tree().quit(1)
		return
	await get_tree().create_timer(1.5).timeout
	var img := get_tree().root.get_texture().get_image()
	var path := _out_path()
	var abs_path := ProjectSettings.globalize_path(path) if path.begins_with("res://") else path
	var err := img.save_png(abs_path)
	if err == OK:
		print("SHOT_OK: ", abs_path, " ", img.get_width(), "x", img.get_height())
	else:
		printerr("SHOT_FAIL: ", abs_path, " code ", err)
	get_tree().quit(0 if err == OK else 1)

func _menu_reachable() -> bool:
	var cs := get_tree().current_scene
	return cs != null and cs.scene_file_path == Routes.MENU

func _wait_until(pred: Callable, timeout_sec: float) -> bool:
	var t := 0.0
	while t < timeout_sec:
		if pred.call():
			return true
		await get_tree().create_timer(0.2).timeout
		t += 0.2
	return pred.call()
