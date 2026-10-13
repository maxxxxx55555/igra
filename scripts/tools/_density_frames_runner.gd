extends "res://scripts/tools/_rc16_probe_runner.gd"
## Density frames (tools/qa_sim/density_frames <label> <hash> [district ids], docs/DENSITY_PLAN.md): five stills of what the player sees in each district named (all eleven by default),
## shot from fixed places so a before and an after frame of one view can be laid side by side. The power stage only goes up, so the dark views come first:
##   01_dark     the west street at the eye height of the player, power DARK, the flashlight on
##   02_rest     the corner of the power switch toward the middle block, power DARK, the flashlight off (the lit bench, where there is one)
##   03_street   the west street again, power FULL
##   04_block    from the middle block across the street to its neighbour, power FULL
##   05_skyline  up the south street toward the landmark of the district, power FULL
## Frames -> docs/stills/density/<id>_<view>_<label>_<hash>_<UTC>.jpg (the AF3 name: the code tree and the capture time). A saved frame proves nothing until it is read.
## Each district also prints one `[density] perf` line: the draw calls, primitives and objects of the district as it stands.

const VIEWS: Array[Dictionary] = [
	{"name": "01_dark", "at": Vector3(-8.0, 0.1, 21.0), "look": Vector3(-8.0, 1.7, -30.0), "pitch": 0.0, "stage": -1, "light": true},
	{"name": "02_rest", "at": Vector3(5.0, 0.1, 5.0), "look": Vector3(14.0, 0.6, 13.0), "pitch": -0.04, "stage": -1, "light": false},
	{"name": "03_street", "at": Vector3(-8.0, 0.1, 21.0), "look": Vector3(-8.0, 1.7, -30.0), "pitch": 0.0, "stage": 3, "light": false},
	{"name": "04_block", "at": Vector3(0.0, 0.1, 0.0), "look": Vector3(16.0, 1.5, -16.0), "pitch": -0.05, "stage": 3, "light": false},
	{"name": "05_skyline", "at": Vector3(0.0, 0.1, 18.0), "look": Vector3(0.0, 1.7, -60.0), "pitch": 0.22, "stage": 3, "light": false},
]
const JPG_QUALITY: float = 0.88
const SETTLE_SEC: float = 0.9
const PERF_SETTLE_FRAMES: int = 30

var _ids: Array[StringName] = []

## A JPG keeps a set of eleven districts at about one megabyte; the frames are read and measured, not diffed pixel by pixel.
func _shot(frame: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_tree().root.get_texture().get_image()
	img.resize(CAPTURE_SIZE.x, CAPTURE_SIZE.y, Image.INTERPOLATE_LANCZOS)
	img.save_jpg(ProjectSettings.globalize_path(out_dir + frame + ".jpg"), JPG_QUALITY)

func _snap(state: String) -> void:
	out_dir = "res://docs/stills/density/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var file_name := "%s_%s_%s_%s" % [state, _label, _hash, _utc()]
	await _shot(file_name)
	print("[density] frame %s.jpg" % file_name)

func _freeze_monsters() -> void:
	for m in get_tree().get_nodes_in_group("monsters"):
		(m as Node).process_mode = Node.PROCESS_MODE_DISABLED

func _flashlight(player: Node3D, want: bool) -> void:
	if player.has_method("toggle_flashlight") and bool(player.get("flashlight_enabled")) != want:
		player.toggle_flashlight()

func _view(id: StringName, view: Dictionary) -> void:
	var player := _player_node()
	if player == null:
		print("[density] FAIL no player in %s" % id)
		return
	var at: Vector3 = view["at"]
	var look: Vector3 = view["look"]
	player.heal(1000.0)
	player.global_position = at
	player.velocity = Vector3.ZERO
	player.look_at(Vector3(look.x, player.global_position.y, look.z), Vector3.UP)
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		camera.set("_pitch", float(view["pitch"]))
	var stage: int = int(view["stage"])
	if stage >= 0 and PowerGrid.get_stage(id) < stage:
		PowerGrid.advance_district(id, stage as DistrictData.Stage)
	_flashlight(player, bool(view["light"]))
	await get_tree().create_timer(SETTLE_SEC).timeout
	await _snap("%s_%s" % [id, view["name"]])

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("[density] SKIP headless - frames need a real display")
		get_tree().quit(3)
		return
	for a in OS.get_cmdline_user_args():
		var s := String(a)
		if s.begins_with("--tlabel="):
			_label = s.substr(9)
		elif s.begins_with("--thash="):
			_hash = s.substr(8)
		elif s.begins_with("--tids="):
			for id in s.substr(7).split(",", false):
				_ids.append(StringName(id))
	if _ids.is_empty():
		_ids.assign(ORDER)
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
	await get_tree().create_timer(3.0).timeout
	print("[density] start label=%s hash=%s ids=%s %s" % [_label, _hash, _ids, _mem()])
	for id in _ids:
		if not await _transition(id, "density"):
			print("[density] FAIL district %s never loaded" % id)
			continue
		_freeze_monsters()
		for view: Dictionary in VIEWS:
			await _view(id, view)
		await _perf_line(id)
	print("[density] DONE label=%s hash=%s" % [_label, _hash])
	get_tree().quit(0)

func _perf_line(id: StringName) -> void:
	for i in PERF_SETTLE_FRAMES:
		await get_tree().process_frame
	print("[density] perf district=%s draw_calls=%d primitives=%d objects_in_frame=%d" % [String(id),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))])
