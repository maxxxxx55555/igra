extends "res://scripts/tools/_wave2_showcase_runner.gd"
## Final-tree store gallery + HC-3 credits proof (2026-11-22).
##
## Windowed only. Reuses the Wave 2 staging helpers so the frames are engine
## captures from the same final visual tree, not the older painted store art.
## Output:
##   store/screenshots/shot*_1920x1080_en.png  (8 EN gallery + 3 touch)
##   build/credits_hc3_verification.png        (readable music attribution)
##
## Run:
##   TLS_GODOT_ARGS="--resolution 1920x1080" \
##     tools/qa_sim/guarded_windowed res://scenes/tools/release_store_shots_scene.tscn 600

const STORE_OUT := "res://store/screenshots/"
const CREDITS_OUT := "res://build/"


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("[store] SKIP headless - store frames need a real display")
		get_tree().quit(3)
		return
	if OS.get_environment("TLS_STORE_OUT") != "":
		out_dir = OS.get_environment("TLS_STORE_OUT")
	else:
		out_dir = STORE_OUT
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CREDITS_OUT))
	QualityManager.enabled = false

	_lang0 = LocalizationManager.current_lang
	_size0 = int(SettingsManager.get_setting("text_size", 1))
	_win0 = get_window()
	_size_win0 = _win0.size
	_mode0 = _win0.mode
	_calibrated0 = SettingsManager.get_setting("touch_calibration_done", false)
	_emulate0 = Input.emulate_touch_from_mouse
	LocalizationManager.set_language("en")
	SettingsManager.set_text_size(1)
	_win0.mode = Window.MODE_WINDOWED
	_win0.size = Vector2i(1920, 1080)
	await _await_frames(4)

	Routes.goto(Routes.BOOT)
	await get_tree().create_timer(1.2).timeout
	var menu_up := func() -> bool:
		var cs := get_tree().current_scene
		return cs != null and cs.scene_file_path == Routes.MENU
	if not await _wait_until(menu_up, 15.0):
		Routes.goto(Routes.MENU)
		if not await _wait_until(menu_up, 10.0):
			_fail("main menu never came up")
			return
	SaveSystem.mark_onboard_done()
	Routes.start_game()
	if not await _wait_until(func() -> bool:
		return GameManager.is_playing() and get_tree().get_first_node_in_group("player") != null, 20.0):
		_fail("never reached gameplay")
		return
	TutorialSystem.call("_skip_tutorial")
	WeatherSystem.set("process_mode", Node.PROCESS_MODE_DISABLED)
	WeatherSystem.current = WeatherSystem.Weather.CLEAR
	WeatherSystem.call("_emit")
	RandomEvents.set("process_mode", Node.PROCESS_MODE_DISABLED)
	await get_tree().create_timer(2.0).timeout
	_hud_visible(false)

	# 1 — the hook: suburbs FULL, HUD off.
	await _go_district(&"suburbs", DistrictData.Stage.FULL)
	await _gallery_shot("shot01_light_vs_dark_1920x1080_en")

	# 2 — residential edge toward the park, HUD off.
	await _go_district(&"residential", DistrictData.Stage.FULL)
	_face_east()
	await _gallery_shot("shot02_district_boundary_1920x1080_en")

	# 3 — stealth read: a real monster 6 m out, flashlight pool, HUD off.
	await _go_district(&"residential", DistrictData.Stage.FULL)
	await _stage_combat()
	await _gallery_shot("shot03_stealth_horror_1920x1080_en")

	# 4 — keeper lore / park at FULL, HUD off.
	await _go_district(&"park", DistrictData.Stage.FULL)
	await _gallery_shot("shot04_keeper_lore_1920x1080_en")

	# 5 — restored gas-station forecourt.
	await _go_district(&"gas_station", DistrictData.Stage.FULL)
	await _gallery_shot("shot05_restored_forecourt_1920x1080_en")

	# 6 — industrial interior/workbench read.
	await _go_district(&"industrial", DistrictData.Stage.FULL)
	await _gallery_shot("shot06_mystery_inside_1920x1080_en")

	# 7 — power station with the Architect staged.
	await _stage_boss()
	await _gallery_shot("shot07_last_streetlight_1920x1080_en")

	# 8 — city map overlay. Hide gameplay UI, then re-enable the map's layer.
	_hide_gallery_ui()
	UIManager.open(&"city_map")
	await get_tree().create_timer(0.8).timeout
	_show_ui_layer()
	await _await_frames(2)
	await _capture("shot08_city_map_1920x1080_en", false)
	UIManager.close(&"city_map")
	await get_tree().create_timer(0.3).timeout

	# 9-11 — touch HUD at the target canvas.
	await _set_touch(true, Vector2i(1920, 1080))
	await _go_district(&"suburbs", DistrictData.Stage.FULL)
	await _capture("shot_p1_touch_first_light_1920x1080_en", false)
	await _go_district(&"residential", DistrictData.Stage.FULL)
	await _stage_combat()
	await _capture("shot_p2_touch_crouch_1920x1080_en", false)
	await _go_district(&"residential", DistrictData.Stage.FULL)
	EventBus.interact_prompt_changed.emit("Open")
	EventBus.player_interact_available.emit(true)
	await get_tree().create_timer(0.5).timeout
	await _capture("shot_p3_touch_interact_1920x1080_en", false)
	EventBus.player_interact_available.emit(false)
	await _set_touch(false, Vector2i(1920, 1080))

	# HC-3 — credits with the AI label and Scott Buckley attribution readable.
	out_dir = CREDITS_OUT
	Routes.goto(Routes.CREDITS)
	var credits_up := func() -> bool:
		var cs := get_tree().current_scene
		return cs != null and cs.scene_file_path == Routes.CREDITS
	if not await _wait_until(credits_up, 10.0):
		_fail("credits screen never came up")
		return
	await get_tree().create_timer(1.2).timeout
	var scroll := get_tree().current_scene.get_node_or_null("VBox/MusicLicences") as ScrollContainer
	if scroll != null and scroll.get_child_count() > 0:
		for child in scroll.get_child(0).get_children():
			if child is Label and "Scott Buckley" in (child as Label).text:
				scroll.ensure_control_visible(child)
				break
		await get_tree().create_timer(0.4).timeout
	await _capture("credits_hc3_verification", false)

	LocalizationManager.set_language(_lang0)
	SettingsManager.set_text_size(_size0)
	Input.emulate_touch_from_mouse = _emulate0
	SettingsManager.set_setting("touch_calibration_done", _calibrated0)
	_win0.size = _size_win0
	_win0.mode = _mode0
	print("[store] DONE gallery=11 credits=1")
	get_tree().quit(0)


func _gallery_shot(name: String) -> void:
	_flashlight_on()
	_hide_gallery_ui()
	await _await_frames(3)
	await _capture(name, false)


func _hide_gallery_ui() -> void:
	# Keep the full-screen post-process layer. Hide the HUD, quest tracker and
	# every other UI layer so the gallery shows the world, not gameplay chrome.
	for layer in get_tree().root.find_children("*", "CanvasLayer", true, false):
		if layer.name == "PostProcessOverlay":
			continue
		layer.set("visible", false)


func _show_ui_layer() -> void:
	# UIManager owns its own CanvasLayer at layer 10; the city map lives there.
	for layer in get_tree().root.find_children("*", "CanvasLayer", true, false):
		if layer is CanvasLayer and (layer as CanvasLayer).layer == 10:
			layer.set("visible", true)


func _flashlight_on() -> void:
	var p := get_tree().get_first_node_in_group("player") as Node3D
	if p == null:
		return
	if p.has_method("toggle_flashlight") and not bool(p.get("flashlight_enabled")):
		p.call("toggle_flashlight")


func _hud_visible(on: bool) -> void:
	var hud := get_tree().root.find_child("HUD", true, false)
	if hud != null:
		hud.set("visible", on)


func _face_east() -> void:
	var p := get_tree().get_first_node_in_group("player") as Node3D
	if p == null:
		return
	_face(p, p.global_position + Vector3(40.0, 0.0, 0.0))
	p.set("_pitch", deg_to_rad(-8.0))
