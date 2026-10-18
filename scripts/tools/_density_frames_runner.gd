extends "res://scripts/tools/_rc16_probe_runner.gd"
## Density frames (tools/qa_sim/density_frames <label> <hash> [district ids], docs/DENSITY_PLAN.md): five stills of what the player sees in each district named (all eleven by default),
## shot from fixed places. With the label `pair` every view is shot twice in the same run: first with the district's dressing node hidden (the file label is "before"), then shown
## ("after"), so the two frames differ by the dressing and by nothing else. The power stage only goes up, so the dark views come first:
##   01_dark     the west street at the eye height of the player, power DARK, the flashlight on
##   02_rest     the road beside the power switch toward the bench and its lantern in the next block, power DARK, the flashlight off
##   03_street   the west street again, power FULL
##   04_block    from the middle block across the street to its neighbour, power FULL
##   05_skyline  up the south street toward the landmark of the district, power FULL
##   06_courtyard from inside the middle block across the grid to the south-west corner of the ring, power FULL (Session 27)
##   07_facade    close to the west facade of the ring, looking up its panels, power FULL (Session 27)
##   08_sign      five metres in front of the widest stencilled sign of the district (a long word shows whether its end is cut off), by the flashlight; the place is read from the loaded district, and the baked atlas is counted for ink (Session 27)
## --tviews=<names> shoots only those views (the default is all).
## Frames -> docs/stills/density/<id>_<view>_<label>_<hash>_<UTC>.jpg (the AF3 name: the code tree and the capture time). A saved frame proves nothing until it is read.
## The runs are in English with the HUD and the tutorial hidden (Trailer Mode), so a frame holds the world and nothing else. The weather is pinned to clear and the random events
## are off (`_pin_world`), and each view prints one `[density] state` line (weather, stage, tier, the environment's ambient, glow and exposure), so a frame can be traced to its state.
## Each district also prints one `[density] perf` line: the draw calls, primitives and objects of the district as it stands.
## Store frames (store/SCREENSHOT_RECIPES.md): the user args `--tlang=<locale>` (default en), `--thud=1` (the HUD stays: Trailer Mode off) and `--tpng=1` (a PNG without alpha in
## store/screenshots/recipes/<id>_<view>_<locale>_<hash>_<UTC>.png instead of the JPG of docs/stills/density).

const _Views := preload("res://scripts/tools/_density_views.gd")
const VIEWS: Array[Dictionary] = [
	{"name": "01_dark", "at": Vector3(-8.0, 0.1, 21.0), "look": Vector3(-8.0, 1.7, -30.0), "pitch": 0.0, "stage": -1, "light": true},
	{"name": "02_rest", "at": Vector3(6.0, 0.1, 15.5), "look": Vector3(13.5, 1.5, 13.5), "pitch": 0.0, "stage": -1, "light": false},
	{"name": "03_street", "at": Vector3(-8.0, 0.1, 21.0), "look": Vector3(-8.0, 1.7, -30.0), "pitch": 0.0, "stage": 3, "light": false},
	{"name": "04_block", "at": Vector3(0.0, 0.1, 0.0), "look": Vector3(16.0, 1.5, -16.0), "pitch": -0.05, "stage": 3, "light": false},
	{"name": "05_skyline", "at": Vector3(0.0, 0.1, 18.0), "look": Vector3(0.0, 1.7, -60.0), "pitch": 0.22, "stage": 3, "light": false},
	{"name": "06_courtyard", "at": Vector3(-2.5, 0.1, 2.5), "look": Vector3(-30.0, 1.7, 30.0), "pitch": 0.04, "stage": 3, "light": false},
	{"name": "07_facade", "at": Vector3(-23.0, 0.1, 6.0), "look": Vector3(-32.0, 1.7, 8.0), "pitch": 0.32, "stage": 3, "light": false},
]
const JPG_QUALITY: float = 0.88
const SETTLE_SEC: float = 0.9
const PERF_SETTLE_FRAMES: int = 30
## A restored district's wall stands this many levels (of 255) over the floor of the grade: seen, and still a night.
const WALL_LIFT_MIN: float = 12.0
const WALL_LIFT_MAX: float = 60.0

var _ids: Array[StringName] = []
var _views: PackedStringArray = []
var _lang: String = "en"
var _hud: bool = false
var _png: bool = false

## A JPG keeps a set of eleven districts at about one megabyte; the frames are read and measured, not diffed pixel by pixel.
func _shot(frame: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_tree().root.get_texture().get_image()
	img.resize(CAPTURE_SIZE.x, CAPTURE_SIZE.y, Image.INTERPOLATE_LANCZOS)
	if _png:
		img.convert(Image.FORMAT_RGB8)
		img.save_png(ProjectSettings.globalize_path(out_dir + frame + ".png"))
	else:
		img.save_jpg(ProjectSettings.globalize_path(out_dir + frame + ".jpg"), JPG_QUALITY)

func _snap(state: String, label: String = "") -> void:
	out_dir = "res://store/screenshots/recipes/" if _png else "res://docs/stills/density/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var file_name := "%s_%s_%s_%s" % [state, _lang if _png else (label if not label.is_empty() else _label), _hash, _utc()]
	await _shot(file_name)
	print("[density] frame %s.%s" % [file_name, "png" if _png else "jpg"])

func _freeze_monsters() -> void:
	for m in get_tree().get_nodes_in_group("monsters"):
		(m as Node).process_mode = Node.PROCESS_MODE_DISABLED

## The dressing node of the district that is loaded (district_dressing.gd), or null.
func _dressing() -> Node3D:
	for node in get_tree().root.find_children("*", "Node3D", true, false):
		var script := node.get_script() as Script
		if script != null and script.resource_path.ends_with("district_dressing.gd"):
			return node as Node3D
	return null

## The weather rolls a new state every 45 s and its overlay darkens the screen by up to half, and the random events flash and flicker the light: a frame must depend on neither.
func _pin_world() -> void:
	WeatherSystem.set("process_mode", Node.PROCESS_MODE_DISABLED)
	WeatherSystem.current = WeatherSystem.Weather.CLEAR
	WeatherSystem.call("_emit")
	RandomEvents.set("process_mode", Node.PROCESS_MODE_DISABLED)
	QualityManager.enabled = false  # a measurement reads one tier: the quality manager steps it under 30 FPS (CORRECTION_LOG 241)

func _flashlight(player: Node3D, want: bool) -> void:
	if player.has_method("toggle_flashlight") and bool(player.get("flashlight_enabled")) != want:
		player.toggle_flashlight()

## Puts the player at the place of a view and turns the camera to it; the player, or null when there is none.
func _place(view: Dictionary) -> Node3D:
	var player := _player_node()
	if player == null:
		return null
	var at: Vector3 = view["at"]
	var look: Vector3 = view["look"]
	player.heal(1000.0)
	player.global_position = at
	player.velocity = Vector3.ZERO
	player.look_at(Vector3(look.x, player.global_position.y, look.z), Vector3.UP)
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		camera.set("_pitch", float(view["pitch"]))
	return player

func _view(id: StringName, view: Dictionary) -> void:
	var player := _place(view)
	if player == null:
		print("[density] FAIL no player in %s" % id)
		return
	var camera := get_viewport().get_camera_3d()
	var stage: int = int(view["stage"])
	if stage >= 0 and PowerGrid.get_stage(id) < stage:
		# a district can only be raised once the ones that power it are FULL (PowerGrid.is_unlocked): a subset of districts, the store recipe's, stayed DARK (CORRECTION_LOG 249)
		for parent in PowerGrid.get_district(id).powered_by:
			PowerGrid.get_district(parent).stage = DistrictData.Stage.FULL
		if not PowerGrid.advance_district(id, stage as DistrictData.Stage):
			_fail("%s %s: the power stage is %d and the view wants %d" % [String(id), view["name"], PowerGrid.get_stage(id), stage])
			return
	_flashlight(player, bool(view["light"]))
	if _Views.SWITCHED.has(_label):
		_Views.pin_lamps(get_tree())
	await get_tree().create_timer(SETTLE_SEC).timeout
	var env := get_viewport().world_3d.environment
	print("[density] state district=%s view=%s weather=%d stage=%d tier=%d ambient=%.3f glow=%.3f exposure=%.3f flashlight=%s" % [String(id), view["name"], WeatherSystem.current,
		PowerGrid.get_stage(id), int(SettingsManager.get_setting("graphics_tier", -1)), env.ambient_light_energy, env.glow_intensity, env.tonemap_exposure, player.get("flashlight_enabled")])
	if view["name"] == "07_facade":
		await _wall_check(id)
	var dressing := _dressing()
	if view["name"] == "02_rest" and dressing != null and camera != null:
		var bulb := dressing.get_node_or_null("RestLantern/RestBloom") as Node3D
		if bulb != null:
			print("[density] rest district=%s bloom_world=%s on_screen=%s behind=%s visible=%s camera=%s" % [String(id), bulb.global_position,
				camera.unproject_position(bulb.global_position), camera.is_position_behind(bulb.global_position), bulb.is_visible_in_tree(), camera.global_position])
	if _label == "pair" and dressing != null:
		dressing.visible = false
		await get_tree().process_frame
		await _snap("%s_%s" % [id, view["name"]], "before")
		dressing.visible = true
		await get_tree().process_frame
		await _snap("%s_%s" % [id, view["name"]], "after")
	elif _Views.SWITCHED.has(_label):
		_Views.switch(_label, get_tree(), false)
		await get_tree().process_frame
		await _snap("%s_%s" % [id, view["name"]], "before")
		_Views.switch(_label, get_tree(), true)
		await get_tree().process_frame
		await _snap("%s_%s" % [id, view["name"]], "after")
	else:
		await _snap("%s_%s" % [id, view["name"]])

## The view of 08_sign, or an empty one (a `[density] FAIL` line, the run goes on) when the district hangs no sign or its atlas holds no letters: the frame must not be the proof that the bake worked.
func _sign_view(id: StringName) -> Dictionary:
	var signs := get_tree().root.find_child("Signs", true, false) as MultiMeshInstance3D
	if signs == null or signs.multimesh.instance_count == 0:
		print("[density] FAIL no sign hung in %s" % id)
		return {}
	var widest: int = 0
	for i: int in signs.multimesh.instance_count:
		if signs.multimesh.get_instance_custom_data(i).g > signs.multimesh.get_instance_custom_data(widest).g:
			widest = i
	var spot: Transform3D = signs.global_transform * signs.multimesh.get_instance_transform(widest)
	var atlas: Image = ((signs.material_override as ShaderMaterial).get_shader_parameter("atlas") as Texture2D).get_image()
	var ink: int = 0
	for y: int in range(0, atlas.get_height(), 4):
		for x: int in range(0, atlas.get_width(), 4):
			if atlas.get_pixel(x, y).a > 0.5:
				ink += 1
	print("[density] signs district=%s count=%d atlas=%dx%d ink_samples=%d first=%s facing=%s" % [String(id), signs.multimesh.instance_count, atlas.get_width(), atlas.get_height(), ink, spot.origin, spot.basis.z.normalized()])
	if ink < 200:
		print("[density] FAIL the sign atlas of %s holds no letters (%d ink samples)" % [id, ink])
		return {}
	var normal := spot.basis.z.normalized()
	return {"name": "08_sign", "at": Vector3(spot.origin.x + normal.x * 5.0, 0.1, spot.origin.z + normal.z * 5.0), "look": spot.origin, "pitch": -0.08, "stage": 3, "light": true}

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
		elif s.begins_with("--tviews="):
			_views = s.substr(9).split(",", false)
		elif s.begins_with("--tlang="):
			_lang = s.substr(8)
		elif s == "--thud=1":
			_hud = true
		elif s == "--tpng=1":
			_png = true
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
	LocalizationManager.set_language(_lang)
	SettingsManager.set_setting("trailer_mode", not _hud)
	_pin_world()
	TutorialSystem.call("_skip_tutorial")
	await get_tree().create_timer(3.0).timeout
	print("[density] start label=%s hash=%s ids=%s %s" % [_label, _hash, _ids, _mem()])
	for id in _ids:
		if not await _transition(id, "density"):
			print("[density] FAIL district %s never loaded" % id)
			continue
		_freeze_monsters()
		for view: Dictionary in VIEWS:
			if _views.is_empty() or _views.has(String(view["name"])):
				await _view(id, view)
		if _views.is_empty() or _views.has("08_sign"):
			var sign_view := _sign_view(id)
			if not sign_view.is_empty():
				await _view(id, sign_view)
		if _views.is_empty() or _views.has("09_lamp"):
			var lamp_view := _Views.lamp_view(get_tree(), id)
			if not lamp_view.is_empty():
				await _view(id, lamp_view)
		if _views.is_empty() or _views.has("10_story"):
			var story_view := _Views.story_view(get_tree(), id)
			if not story_view.is_empty():
				await _view(id, story_view)
		for diag: String in ["11_pane", "12_dust", "13_base"]:
			if _views.has(diag):
				var diag_view := _Views.diag_view(get_tree(), id, diag)
				if not diag_view.is_empty():
					await _view(id, diag_view)
		if _views.has("probe"):
			_Views.probe(get_tree(), id)
		var dressing := _dressing()
		if _label == "pair" and dressing != null:
			dressing.visible = false
			await _perf_line(id, "without")
			dressing.visible = true
		elif _Views.SWITCHED.has(_label):
			_Views.switch(_label, get_tree(), false)
			await _perf_line(id, "without")
			_Views.switch(_label, get_tree(), true)
		await _perf_line(id, "with")
	print("[density] DONE label=%s hash=%s" % [_label, _hash])
	get_tree().quit(0)

## What the facade shows (Session 27): in the 07_facade view the median brightness of the band of the frame where the wall is (10 to 70 % of its height, every fourth pixel: windows, gaps and ground are the
## minority of it) at the gain of the stage and with the glow off. The first probe read a patch that held half ground and calibrated the walls to 120 of 255, the sweep of gains behind the numbers of
## `scripts/world/skyline.gd` (0.15 stood the wall at +3 over the floor, 0.26 at +20, 0.34 at +40, 0.48 at +74) is in `s27_v1f_41e1c2d`; the median of the band does not need a sweep to be read.
func _wall_check(id: StringName) -> void:
	var blocks := get_tree().root.find_child("Blocks", true, false) as MultiMeshInstance3D
	var facade: ShaderMaterial = blocks.material_override as ShaderMaterial if blocks != null else null
	if facade == null:
		print("[density] FAIL no facade material to read in %s" % id)
		return
	var gain: float = float(facade.get_shader_parameter("gain"))
	var lit: float = await _wall_level()
	facade.set_shader_parameter("gain", 0.0)
	var dark: float = await _wall_level()
	facade.set_shader_parameter("gain", gain)
	print("[density] wall district=%s gain=%.2f floor=%.1f lit=%.1f lift=%.1f" % [String(id), gain, dark, lit, lit - dark])
	if lit - dark < WALL_LIFT_MIN or lit - dark > WALL_LIFT_MAX:
		print("[density] FAIL the facade of %s shows %.1f levels over the black floor, %.0f to %.0f asked" % [String(id), lit - dark, WALL_LIFT_MIN, WALL_LIFT_MAX])

func _wall_level() -> float:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_tree().root.get_texture().get_image()
	var levels: Array[float] = []
	for y: int in range(int(image.get_height() * 0.1), int(image.get_height() * 0.7), 4):
		for x: int in range(0, image.get_width(), 4):
			var pixel := image.get_pixel(x, y)
			levels.append((pixel.r + pixel.g + pixel.b) / 3.0 * 255.0)
	levels.sort()
	return levels[levels.size() / 2]

func _perf_line(id: StringName, dressing: String) -> void:
	for i in PERF_SETTLE_FRAMES:
		await get_tree().process_frame
	print("[density] perf district=%s dressing=%s draw_calls=%d primitives=%d objects_in_frame=%d" % [String(id), dressing,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))])
