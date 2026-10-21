extends "res://scripts/tools/_density_frames_runner.gd"
## Look frames (WORKQUEUE B14, B13): what the wiring of the B block shows, shot in the real game. suburbs dry and in rain (the wet road, the rain), a dark industrial district restored (the ramp of the lamps at 0.35 s and 2 s, then its
## fog cards), the main menu with its backdrop still and dragged, a prop close-up (the contact shadow under a bench), and the 04_block view of five districts for the saturation of the facade band (B13); for the C block the pickup library in four sheets and seven pickups along a dark street (C1, C2) and the three guns in the hand (C6).
## Windowed: TLS_FRAMES_HASH=<hash> tools/qa_sim/guarded_windowed res://scenes/tools/look_frames_scene.tscn 300
## Frames -> .qa_logs/frames/<state>_<hash>_<UTC>.png (the AF3 name). A saved frame proves nothing until it is read.

const STREET := {"at": Vector3(-8.0, 0.1, 21.0), "look": Vector3(-8.0, 1.7, -30.0), "pitch": 0.0, "stage": 3, "light": false}
const BLOCK := {"at": Vector3(0.0, 0.1, 0.0), "look": Vector3(16.0, 1.5, -16.0), "pitch": -0.05, "stage": 3, "light": false}
const FACADE_IDS: Array[StringName] = [&"police", &"hospital", &"residential", &"park", &"school"]
## The pickups of C1: the library in four sheets of 12 at 2.3 to 4 m (one frame each), then seven of them along the street at 5 to 10 m in the dark.
const SHEETS: Array = [
	[&"battery", &"battery_l2", &"enhanced_battery", &"medkit", &"serum", &"scrap", &"metal", &"gear", &"plank", &"cable", &"wiring", &"fuse"],
	[&"transistor", &"circuit", &"transformer", &"key", &"ancient_key", &"lockpick", &"document", &"paper", &"photo", &"audio_log", &"bottle", &"alcohol"],
	[&"gas_canister", &"fabric", &"molotov", &"firework", &"blueprint_battery_l2", &"blueprint_uv_flashlight", &"backpack_l1", &"backpack_l2", &"case", &"coin", &"motor", &"tool"],
	[&"scope_lens", &"radio_part", &"repair_kit", &"noise_bomb", &"gunpowder", &"makeshift_lamp", &"ammo", &"pistol", &"rifle", &"shotgun"],
]
const ROW: Array[StringName] = [&"battery", &"medkit", &"key", &"fuse", &"scrap", &"blueprint_battery_l2", &"molotov"]

func _frame(state: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_tree().root.get_texture().get_image()
	img.resize(CAPTURE_SIZE.x, CAPTURE_SIZE.y, Image.INTERPOLATE_LANCZOS)
	var file := "%s_%s_%s.png" % [state, _hash, _utc()]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.qa_logs/frames/"))
	img.save_png(ProjectSettings.globalize_path("res://.qa_logs/frames/" + file))
	print("[lframes] frame %s" % file)

## A view with the flashlight off and then on (a lit surface under a light of energy 24 is the case that broke V1, and the frames of launches 3 to 9 of Session 28 were judged with the light off): the second frame has the suffix _lit.
func _both(state: String) -> void:
	var player := _player_node()
	_flashlight(player, false)
	await get_tree().create_timer(0.3).timeout
	await _frame(state)
	_flashlight(player, true)
	await get_tree().create_timer(0.6).timeout
	await _frame(state + "_lit")
	_flashlight(player, false)

## The district raised to a power stage as the game does it: the districts that power it first.
func _raise(id: StringName, stage: int) -> void:
	if PowerGrid.get_stage(id) >= stage:
		return
	for parent in PowerGrid.get_district(id).powered_by:
		PowerGrid.get_district(parent).stage = DistrictData.Stage.FULL
	PowerGrid.advance_district(id, stage as DistrictData.Stage)

## Pickups of `ids` on the street at `spots`, as the game lays them (the scene of a loose item), in the tree until the frame is taken.
func _lay(ids: Array, spots: Array[Vector3]) -> Array[Node]:
	var laid: Array[Node] = []
	var scene := load("res://scenes/pickups/item_pickup_3d.tscn") as PackedScene
	for i in ids.size():
		var item := scene.instantiate() as Node3D
		item.set("item_id", ids[i])
		get_tree().current_scene.add_child(item)
		item.global_position = spots[i]
		laid.append(item)
	return laid

## The contact shadows of the district on or off, for the control frame of the close-up.
func _show_shadows(on: bool) -> void:
	for board in get_tree().root.find_children("ContactShadows", "MultiMeshInstance3D", true, false):
		(board as Node3D).visible = on

## The fog cards of the dressing on or off, for the control frame of the foggy street.
func _show_cards(on: bool) -> void:
	for card in get_tree().root.find_children("FogCard*", "MeshInstance3D", true, false):
		(card as Node3D).visible = on

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
	await _both("suburbs_dry")
	_weather(WeatherSystem.Weather.RAIN)
	await get_tree().create_timer(3.5).timeout
	await _both("suburbs_rain")
	_weather(WeatherSystem.Weather.CLEAR)
	# a prop close-up in the same district: a bench, from 2.5 m, a little above
	var props := get_tree().root.find_child("BenchesBatched", true, false) as MultiMeshInstance3D
	if props != null and props.multimesh.instance_count > 0:
		var bench: Vector3 = props.multimesh.get_instance_transform(0).origin
		_place({"at": bench + Vector3(1.6, 0.0, 1.6) - Vector3(0.0, bench.y, 0.0) + Vector3(0.0, 0.1, 0.0), "look": Vector3(bench.x, 0.3, bench.z), "pitch": -0.35, "stage": 3, "light": false})
		await get_tree().create_timer(1.0).timeout
		await _both("prop_closeup")
		_show_shadows(false)
		await get_tree().create_timer(0.5).timeout
		await _frame("prop_noshadow")
		_show_shadows(true)
	# the pickup library on the street of the suburbs: four sheets of 12, each seen from 2.3 to 4 m, a little above
	for sheet in SHEETS.size():
		var spots: Array[Vector3] = []
		for i in (SHEETS[sheet] as Array).size():
			spots.append(Vector3(-8.0 + (i % 4 - 1.5) * 0.95, 0.05, 18.1 - (i / 4) * 0.85))
		var laid: Array[Node] = _lay(SHEETS[sheet], spots)
		_place({"at": Vector3(-8.0, 0.1, 20.4), "look": Vector3(-8.0, 0.05, 17.25), "pitch": -0.5, "stage": 3, "light": false})
		player.set("_pitch", -0.5)  # the player puts its own pitch on the camera every frame
		_flashlight(player, true)
		await get_tree().create_timer(2.2).timeout
		await _frame("pickups_sheet%d" % (sheet + 1))
		for item in laid:
			item.queue_free()
	# C4: a lore note pinned on a pole, from 2.5 m, the flashlight on
	for note in get_tree().get_nodes_in_group("document"):
		if note.get("mounted") == true:
			var out := Vector3(sin(note.rotation.y), 0.0, cos(note.rotation.y))
			var note_at: Vector3 = (note as Node3D).global_position
			_place({"at": Vector3(note_at.x, 0.1, note_at.z) + out * 2.5, "look": note_at, "pitch": 0.0, "stage": 3, "light": false})
			player.set("_pitch", 0.0)
			_flashlight(player, true)
			await get_tree().create_timer(1.5).timeout
			await _frame("note_on_pole")
			break
	# C6: the three guns in the hand, from the street of the suburbs
	var manager := player.get_node_or_null("WeaponManager")
	_place(STREET)
	for gun in [&"pistol", &"rifle", &"shotgun"]:
		manager.call("unlock", gun)
		manager.call("equip", gun)
		await get_tree().create_timer(0.8).timeout
		await _frame("viewmodel_%s" % gun)
	manager.call("holster")
	# a dark industrial district restored: the lamps ramp
	await _transition(&"industrial", "look")
	_freeze_monsters()
	_place(STREET)
	_flashlight(player, false)
	var along: Array[Vector3] = []
	for i in ROW.size():
		along.append(Vector3(-8.0 + (1.3 if i % 2 == 0 else -1.3), 0.05, 16.0 - i * 1.2))
	var row: Array[Node] = _lay(ROW, along)
	await get_tree().create_timer(2.0).timeout
	await _frame("industrial_dark")
	for item in row:
		item.queue_free()
	_raise(&"industrial", 2)
	await get_tree().create_timer(0.35).timeout
	await _frame("lamp_ramp_a")
	await get_tree().create_timer(1.65).timeout
	await _both("lamp_ramp_b")
	_raise(&"industrial", 3)
	await get_tree().create_timer(3.0).timeout
	await _both("industrial_fog")
	_show_cards(false)
	await get_tree().create_timer(0.5).timeout
	await _frame("industrial_nofog")
	_show_cards(true)
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
