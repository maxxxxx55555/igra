extends Node
## Run identity, application lifecycle, readable terminals and startup audio.

var _checks: int = 0
var _fails: int = 0
var _capture: bool = false
var _layer: CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_capture = "--capture" in OS.get_cmdline_user_args()
	await get_tree().process_frame
	_check_run()
	_check_lifecycle()
	_check_audio()
	await _check_terminals()
	await _settle()
	print("[release-polish] DONE checks=%d fails=%d" % [_checks, _fails])
	get_tree().quit(0 if _fails == 0 else 1)

func _ok(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_fails += 1
	print("[release-polish] %s %s" % ["OK" if condition else "FAIL", label])

func _check_run() -> void:
	GameManager.play_time = 900.0
	GameManager.enemies_killed = 17
	SaveSystem.reset_all()
	_ok(GameManager.play_time == 0.0 and GameManager.enemies_killed == 0, "new run clears counters")
	GameManager.play_time = 321.5
	GameManager.enemies_killed = 12
	GameManager.run_hardcore = true
	SaveSystem.save_all()
	SettingsManager.set_setting("hardcore", false)
	GameManager.reset_run()
	_ok(SaveSystem.load_all() and GameManager.run_hardcore and GameManager.play_time == 321.5 and GameManager.enemies_killed == 12, "main save preserves run identity independently of settings")
	_ok(SaveSystem.save_slot(97), "slot writes run metadata")
	GameManager.reset_run()
	_ok(SaveSystem.load_slot(97) and GameManager.run_hardcore and GameManager.enemies_killed == 12, "slot restores run metadata")
	GameManager.restore_run({"play_time": "bad", "kills": [], "hardcore": "true"})
	_ok(GameManager.play_time == 0.0 and GameManager.enemies_killed == 0 and not GameManager.run_hardcore, "invalid field types rejected")
	GameManager.restore_run({"play_time": NAN, "kills": INF})
	_ok(GameManager.play_time == 0.0 and GameManager.enemies_killed == 0, "nonfinite counters rejected")
	GameManager.restore_run({"play_time": -20, "kills": -8})
	_ok(GameManager.play_time == 0.0 and GameManager.enemies_killed == 0, "negative counters clamp")
	ProgressTracker.time_played = 81.0
	ProgressTracker.kills = 4
	SettingsManager.set_setting("hardcore", true)
	GameManager.restore_run({})
	_ok(GameManager.play_time == 81.0 and GameManager.enemies_killed == 4 and GameManager.run_hardcore, "legacy defaults restore")
	var old: Dictionary = SaveSystem._read_envelope(SaveSystem.SAVE_PATH)
	old.erase("run")
	old["progress"]["time_played"] = 81.0
	old["progress"]["kills"] = 4
	old["settings"]["hardcore"] = true
	SaveSystem._write_atomic(SaveSystem.SAVE_PATH, old)
	GameManager.reset_run()
	_ok(SaveSystem.load_all() and GameManager.play_time == 81.0 and GameManager.enemies_killed == 4, "legacy envelope migration loads")
	var count: int = AchievementManager._unlocked.size()
	AchievementManager._unlock(&"not_a_real_achievement")
	_ok(AchievementManager._unlocked.size() == count, "unknown achievement grants nothing")

func _check_lifecycle() -> void:
	SaveSystem.reset_all()
	SettingsManager.set_setting("autosave", true)
	GameManager._change_state(GameManager.GameState.PLAYING)
	GameManager.play_time = 420.0
	GameManager.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	var data: Dictionary = SaveSystem._read_envelope(SaveSystem.SAVE_PATH)
	_ok(GameManager.is_paused() and get_tree().paused and data.get("run", {}).get("play_time") == 420.0, "focus loss checkpoints and pauses")
	GameManager.return_to_menu()
	_ok(GameManager.is_menu() and not get_tree().paused, "menu unpauses")
	GameManager._change_state(GameManager.GameState.PLAYING)
	GameManager.play_time = 430.0
	GameManager.return_to_menu()
	data = SaveSystem._read_envelope(SaveSystem.SAVE_PATH)
	_ok(data.get("run", {}).get("play_time") == 430.0, "menu checkpoints active run")
	GameManager._change_state(GameManager.GameState.PLAYING)
	GameManager.play_time = 440.0
	GameManager.checkpoint_run()
	data = SaveSystem._read_envelope(SaveSystem.SAVE_PATH)
	_ok(data.get("run", {}).get("play_time") == 440.0, "close checkpoint writes")
	SettingsManager.set_setting("autosave", false)
	var before: String = FileAccess.get_file_as_string(SaveSystem.SAVE_PATH)
	GameManager.play_time = 450.0
	GameManager.checkpoint_run()
	_ok(FileAccess.get_file_as_string(SaveSystem.SAVE_PATH) == before, "Auto-save off respected")
	GameManager.return_to_menu()
	SettingsManager.set_setting("autosave", true)

func _check_audio() -> void:
	var before: int = UISFX.get_child_count()
	UISFX.play_ui("menu_click")
	_ok(UISFX.get_child_count() == before, "sting silent before input")
	UISFX._play("ui_hover", 700.0, 0.08)
	_ok(UISFX.get_child_count() == before, "sample silent before input")
	UISFX._beep(700.0, 0.08)
	_ok(UISFX.get_child_count() == before, "fallback silent before input")
	var press := InputEventKey.new()
	press.pressed = true
	press.keycode = KEY_ENTER
	MusicManager._input(press)
	UISFX.play_ui("menu_click")
	_ok(MusicManager._audio_unlocked and UISFX.get_child_count() > before, "input enables UI feedback")

func _check_terminals() -> void:
	var filters: CanvasLayer = load("res://scripts/post_process_overlay.gd").new()
	add_child(filters)
	await _settle()
	_ok(filters.layer < 0, "world postprocessing draws below UI")
	filters.queue_free()
	_layer = CanvasLayer.new()
	_layer.layer = 50
	add_child(_layer)
	LocalizationManager.set_language("en")
	SettingsManager.set_setting("text_size", 1)
	var win: Control = load("res://scripts/ui/win_screen.gd").new()
	_layer.add_child(win)
	for id: String in EndingsManager.ENDING_DATA:
		EndingsManager.force_ending(StringName(id))
		await _settle()
		var art := win.get_node("EndingArt") as TextureRect
		_ok(art.texture != null and art.texture.resource_path.ends_with("ending_%s.png" % id), "ending illustration: " + id)
		if _capture:
			await _shot("ending_" + id)
	EndingsManager._on_state_changed(GameManager.GameState.MENU)
	_ok(not EndingsManager._sting_player.playing, "ending music stops on menu")
	win.hide()
	GameManager.play_time = 125.0
	ProgressTracker.last_hit_by = &"crawler"
	var death: Control = load("res://scripts/ui/death_screen.gd").new()
	_layer.add_child(death)
	var summary: Dictionary = death._summary.duplicate()
	SaveSystem.wipe_all_saves()
	LocalizationManager.set_language("de")
	_ok(death._summary == summary and death._d.text.contains("2:05"), "Hardcore summary survives wipe and retranslation")
	death.queue_free()
	win.show()
	get_window().size = Vector2i(800, 360)
	SettingsManager.set_setting("text_size", 2)
	EndingsManager.force_ending(&"truth")
	for lang: String in LocalizationManager.SUPPORTED:
		LocalizationManager.set_language(lang)
		await _settle()
		var scroll := win.get_node("EndingScroll") as ScrollContainer
		var title: Rect2 = win._title.get_global_rect()
		_ok(title.position.x >= 0.0 and title.end.x <= win.size.x + 1.0, "small title fits: " + lang)
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
		await _settle()
		var button: Rect2 = win._menu_btn.get_global_rect()
		_ok(button.position.y >= scroll.position.y - 1.0 and button.end.y <= scroll.get_global_rect().end.y + 1.0, "last action reachable: " + lang)
		if _capture:
			scroll.scroll_vertical = 0
			await _settle()
			await _shot("ending_small_" + lang)
	win.queue_free()
	SettingsManager.set_setting("text_size", 1)

func _settle() -> void:
	for _i: int in 5:
		await get_tree().process_frame

func _shot(label: String) -> void:
	RenderingServer.force_draw.call_deferred()
	await RenderingServer.frame_post_draw
	var hash_: String = OS.get_environment("TLS_CAPTURE_HASH")
	if hash_.is_empty():
		_ok(false, "capture requires committed runtime hash")
		return
	var stamp: String = Time.get_datetime_string_from_system(true).replace("-", "").replace(":", "") + "Z"
	DirAccess.make_dir_recursive_absolute("res://docs/stills/terminal")
	var path: String = "res://docs/stills/terminal/%s_after_%s_%s.png" % [label, hash_, stamp]
	_ok(get_viewport().get_texture().get_image().save_png(path) == OK, "capture " + label)
