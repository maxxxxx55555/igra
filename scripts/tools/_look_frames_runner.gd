extends "res://scripts/tools/_density_frames_runner.gd"
## Look frames (WORKQUEUE B14, B13): what the wiring of the B block shows, shot in the real game. suburbs dry and in rain (the wet road, the rain), a dark industrial district restored (the ramp of the lamps at 0.35 s and 2 s, then its
## fog cards), the main menu with its backdrop still and dragged, a prop close-up (the contact shadow under a bench), and the 04_block view of five districts for the saturation of the facade band (B13).
## Windowed: TLS_FRAMES_HASH=<hash> tools/qa_sim/guarded_windowed res://scenes/tools/look_frames_scene.tscn 300
## Frames -> .qa_logs/frames/<state>_<hash>_<UTC>.png (the AF3 name). A saved frame proves nothing until it is read.

const STREET := {"at": Vector3(-8.0, 0.1, 21.0), "look": Vector3(-8.0, 1.7, -30.0), "pitch": 0.0, "stage": 3, "light": false}
const BLOCK := {"at": Vector3(0.0, 0.1, 0.0), "look": Vector3(16.0, 1.5, -16.0), "pitch": -0.05, "stage": 3, "light": false}
const FACADE_IDS: Array[StringName] = [&"police", &"hospital", &"residential", &"park", &"school"]

func _frame(state: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_tree().root.get_texture().get_image()
	img.resize(CAPTURE_SIZE.x, CAPTURE_SIZE.y, Image.INTERPOLATE_LANCZOS)
	var file := "%s_%s_%s.png" % [state, _hash, _utc()]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.qa_logs/frames/"))
	img.save_png(ProjectSettings.globalize_path("res://.qa_logs/frames/" + file))
	print("[lframes] frame %s" % file)

## The district raised to a power stage as the game does it: the districts that power it first.
func _raise(id: StringName, stage: int) -> void:
	if PowerGrid.get_stage(id) >= stage:
		return
	for parent in PowerGrid.get_district(id).powered_by:
		PowerGrid.get_district(parent).stage = DistrictData.Stage.FULL
	PowerGrid.advance_district(id, stage as DistrictData.Stage)

func _weather(kind: int) -> void:
	WeatherSystem.current = kind
	WeatherSystem.call("_emit")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("[lframes] SKIP headless - frames need a real display")
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
	var player := _player_node()
	# suburbs, restored: dry, then in rain
	_raise(&"suburbs", 3)
	await _transition(&"suburbs", "look")
	_freeze_monsters()
	_place(STREET)
	_flashlight(player, false)
	await get_tree().create_timer(3.0).timeout
	await _frame("suburbs_dry")
	_weather(WeatherSystem.Weather.RAIN)
	await get_tree().create_timer(3.5).timeout
	await _frame("suburbs_rain")
	_weather(WeatherSystem.Weather.CLEAR)
	# a prop close-up in the same district: a bench, from 2.5 m, a little above
	var props := get_tree().root.find_child("BenchesBatched", true, false) as MultiMeshInstance3D
	if props != null and props.multimesh.instance_count > 0:
		var bench: Vector3 = props.multimesh.get_instance_transform(0).origin
		_place({"at": bench + Vector3(1.6, 0.0, 1.6) - Vector3(0.0, bench.y, 0.0) + Vector3(0.0, 0.1, 0.0), "look": Vector3(bench.x, 0.3, bench.z), "pitch": -0.35, "stage": 3, "light": false})
		await get_tree().create_timer(1.0).timeout
		await _frame("prop_closeup")
	# a dark industrial district restored: the lamps ramp
	await _transition(&"industrial", "look")
	_freeze_monsters()
	_place(STREET)
	_flashlight(player, false)
	await get_tree().create_timer(2.0).timeout
	await _frame("industrial_dark")
	_raise(&"industrial", 2)
	await get_tree().create_timer(0.35).timeout
	await _frame("lamp_ramp_a")
	await get_tree().create_timer(1.65).timeout
	await _frame("lamp_ramp_b")
	_raise(&"industrial", 3)
	await get_tree().create_timer(3.0).timeout
	await _frame("industrial_fog")
	# the 04_block view of five districts: the saturation of the facade band
	for id in FACADE_IDS:
		_raise(id, 3)
		await _transition(id, "look")
		_freeze_monsters()
		_place(BLOCK)
		_flashlight(player, false)
		await get_tree().create_timer(3.0).timeout
		await _frame("facade_%s" % id)
	# the main menu: the backdrop still, then dragged
	Routes.goto(Routes.MENU)
	if not await _wait_until(menu_up, 10.0):
		_fail("main menu did not come back")
		return
	await get_tree().create_timer(2.0).timeout
	await _frame("menu_still")
	var hero := get_tree().current_scene.get_node_or_null("MenuHeroV2")
	if hero != null and hero.get_child_count() > 0:
		hero.get_child(0).set("_drag", Vector2(0.45, 0.25))
		hero.get_child(0).set("_now", Vector2(0.45, 0.25))
	await get_tree().create_timer(0.5).timeout
	await _frame("menu_dragged")
	print("[lframes] DONE hash=%s" % _hash)
	get_tree().quit(0)
