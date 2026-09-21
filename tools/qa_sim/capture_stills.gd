extends Node
## Owner tool: dumps 8 canonical screenshots to docs/stills/ for store/press
## use (menu, options, 3 lit districts, boss arena, win screen, gallery).
## Headless-safe no-op — screenshotting needs a real compositor, which
## --headless never has. Run windowed:
##   godot --path . --windowed res://scenes/tools/capture_stills_scene.tscn
##
## Reuses the proven autoplay driver (_qa_autoplay_runner.gd) to actually
## reach the districts/boss/win states rather than re-implementing movement.

const OUT_DIR := "res://docs/stills/"
const DISTRICTS_NEEDED := 3
const RUN_BUDGET_SEC := 950.0  ## a hair past the bot's own 900s hard timeout

var _t0: int = 0
var _shots_taken: Dictionary = {}
var _district_shots: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_t0 = Time.get_ticks_msec()
	if DisplayServer.get_name() == "headless":
		print("[stills] headless — no display to capture from, no-op")
		get_tree().quit(0)
		return
	# R0 rendering-corruption diagnostic (2026-09-21): log the real adapter
	# and active method/driver on every windowed run so a magenta-corruption
	# report always carries what hardware/backend produced it.
	print("[stills] adapter=%s vendor=%s method=%s driver=%s" % [
		RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_vendor(),
		RenderingServer.get_current_rendering_method(), RenderingServer.get_current_rendering_driver_name()])
	call_deferred("_run")

func _log(msg: String) -> void:
	print("[stills] t=%.1fs %s" % [float(Time.get_ticks_msec() - _t0) / 1000.0, msg])

func _shot(name: String) -> void:
	if _shots_taken.has(name):
		return
	var img := get_tree().root.get_texture().get_image()
	var abs_dir := ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	var path := abs_dir.path_join(name + ".png")
	var err := img.save_png(path)
	_shots_taken[name] = err == OK
	if err == OK:
		_log("shot %s -> %s (%dx%d)" % [name, path, img.get_width(), img.get_height()])
	else:
		_log("SHOT_FAIL %s code %d" % [name, err])

func _run() -> void:
	await get_tree().create_timer(1.0).timeout
	if get_tree().current_scene == null or get_tree().current_scene.scene_file_path != Routes.MENU:
		Routes.goto(Routes.MENU)
	if not await _wait_until(func() -> bool:
		return get_tree().current_scene != null and get_tree().current_scene.scene_file_path == Routes.MENU, 12.0):
		_log("FAIL: menu never reachable")
		get_tree().quit(1)
		return
	await get_tree().create_timer(0.3).timeout
	_shot("01_menu")

	UIManager.open(&"settings")
	await get_tree().create_timer(0.3).timeout
	_shot("02_options")
	UIManager.close(&"settings")
	await get_tree().create_timer(0.2).timeout

	EventBus.district_stage_changed.connect(_on_district_stage)
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.game_won.connect(_on_game_won)

	# BUG FOUND LIVE (2026-09-21, P4 visual pass): this used to call
	# Routes.start_game() + wait for PLAYING itself, THEN spawn
	# _qa_autoplay_runner.gd on top - but the runner's own _start() ALSO
	# navigates to MainMenu and calls Routes.start_game(), since it's
	# designed to be spawned fresh from boot, not mid-game. Redundantly
	# calling both caused the runner's _start() to bounce back toward a
	# menu that was no longer where the game actually was, then fail its
	# own "menu not reached in 14s" check. We're still at MainMenu here
	# (shots 01/02 only opened Settings, never started a game) - just
	# spawn the runner and let its own _start() do the whole boot.
	_log("still at menu — spawning the autoplay driver to boot + reach districts/boss/win")
	var runner := Node.new()
	runner.name = "StillsAutoplayDriver"
	runner.set_script(load("res://scripts/tools/_qa_autoplay_runner.gd"))
	get_tree().root.add_child(runner)

	await get_tree().create_timer(RUN_BUDGET_SEC).timeout
	_finish()

func _on_district_stage(district_id: StringName, stage: int) -> void:
	if stage < DistrictData.Stage.FULL:
		return
	if _district_shots.size() >= DISTRICTS_NEEDED or String(district_id) in _district_shots:
		return
	_district_shots.append(String(district_id))
	_shot("0%d_district_%s" % [2 + _district_shots.size(), district_id])

func _on_boss_spawned() -> void:
	await get_tree().create_timer(1.5).timeout
	_shot("06_boss_arena")

func _on_game_won() -> void:
	await get_tree().create_timer(1.0).timeout
	_shot("07_win_screen")
	_finish()

func _finish() -> void:
	if _shots_taken.has("08_gallery"):
		return
	UIManager.open(&"collection")
	await get_tree().create_timer(0.5).timeout
	_shot("08_gallery")
	var ok: int = 0
	for v in _shots_taken.values():
		if v:
			ok += 1
	_log("DONE — %d/%d shots captured" % [ok, _shots_taken.size()])
	get_tree().quit(0)

func _wait_until(pred: Callable, timeout_sec: float) -> bool:
	var t := 0.0
	while t < timeout_sec:
		if pred.call():
			return true
		await get_tree().create_timer(0.2).timeout
		t += 0.2
	return pred.call()
