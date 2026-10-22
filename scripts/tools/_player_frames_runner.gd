extends "res://scripts/tools/_density_frames_runner.gd"
## Player motion frames (WORKQUEUE A9): the first-person view with a pistol in the suburbs, shot standing, in a sprint, crouched, at the peak of a shot's kick, in a reload and just after a turn.
## Windowed: TLS_FRAMES_HASH=<hash> tools/qa_sim/guarded_windowed res://scenes/tools/player_frames_scene.tscn 240
## Frames -> .qa_logs/frames/<state>_<hash>_<UTC>.png (the AF3 name). A saved frame proves nothing until it is read.

func _frame(state: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_tree().root.get_texture().get_image()
	img.resize(CAPTURE_SIZE.x, CAPTURE_SIZE.y, Image.INTERPOLATE_LANCZOS)
	var file := "%s_%s_%s.png" % [state, _hash, _utc()]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.qa_logs/frames/"))
	img.save_png(ProjectSettings.globalize_path("res://.qa_logs/frames/" + file))
	print("[pframes] frame %s" % file)

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("[pframes] SKIP headless - frames need a real display")
		get_tree().quit(3)
		return
	_hash = OS.get_environment("TLS_FRAMES_HASH") if OS.has_environment("TLS_FRAMES_HASH") else "unknown"
	var ads := get_node_or_null("/root/AdService")
	if ads:
		ads.enabled = false
	var menu_up := func() -> bool:
		var cs := get_tree().current_scene
		return cs != null and cs.scene_file_path == Routes.MENU
	if not await _wait_until(menu_up, 15.0):
		Routes.goto(Routes.MENU)
		if not await _wait_until(menu_up, 10.0):
			_fail("main menu never came up")
			return
	get_window().size = WINDOW_SIZE
	await get_tree().create_timer(1.0).timeout
	SaveSystem.mark_onboard_done()
	Routes.start_game()
	var playing := func() -> bool: return GameManager.is_playing() and get_tree().get_first_node_in_group("player") != null
	if not await _wait_until(playing, 20.0):
		_fail("never reached gameplay")
		return
	LocalizationManager.set_language("en")
	SettingsManager.set_setting("trailer_mode", true)
	_pin_world()
	TutorialSystem.call("_skip_tutorial")
	await get_tree().create_timer(3.0).timeout
	var player: Node3D = get_tree().get_first_node_in_group("player") as Node3D
	var manager: Node = player.get_node("WeaponManager")
	manager.call("unlock", &"pistol")
	manager.call("equip", &"pistol")
	ProgressTracker.add_ammo(60)
	await get_tree().create_timer(1.0).timeout
	await _frame("idle")
	Input.action_press("move_up")
	Input.action_press("run")
	await get_tree().create_timer(1.2).timeout
	await _frame("sprint")
	Input.action_release("run")
	Input.action_release("move_up")
	await get_tree().create_timer(0.6).timeout
	manager.call("fire")
	await get_tree().process_frame
	await _frame("kick")
	await get_tree().create_timer(0.5).timeout
	manager.call("reload")
	await get_tree().create_timer(0.3).timeout
	await _frame("reload")
	await get_tree().create_timer(2.5).timeout
	player.rotation.y += 0.6
	await get_tree().process_frame
	await _frame("turn")
	player.set("_crouch_toggled", true)
	await get_tree().create_timer(1.0).timeout
	await _frame("crouch")
	player.set("_crouch_toggled", false)
	print("[pframes] DONE hash=%s" % _hash)
	get_tree().quit(0)
