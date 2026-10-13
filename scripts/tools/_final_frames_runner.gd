extends Node
## Runner for _final_frames.gd (lives under /root so scene swaps don't free it).
## Frames, half resolution: 00 boot screen, 01 main menu (and 01_menu_<lang>_s<text size>
## for en, ru, ar at sizes 1 and 2), 02 district "day", 03 district night, 07 skill
## tree, 08 shop (and 08_shop_ar), 04 combat, 05 boss, 06 victory with the NG+ action. The GDD has no daytime
## ("no day", GDD.md:261), so "day" is the restored FULL stage and "night" the
## DARK stage of the spawn district. A saved PNG proves nothing until read.

var out_dir := "res://docs/stills/final/"
## TLS_SWEEP="white:exposure,..." (a decision aid of the shipping pass): after the staged night, day and combat frames the same scene is shot again
## under each tonemap pair, into TLS_SWEEP_OUT, as <frame>_v<n>.png; the pairs are put back. TLS_FRAMES_OUT moves the staged frames away from
## docs/stills/final. Unset, the run is the six-frame run.
var _sweep: Array[Vector2] = []
var _sweep_out: String = "res://.qa_logs/sweep/"
## TLS_HUD_DUMP=<file> (the HUD pass): one line per visible control on a canvas layer, path | class | x,y,w,h | alpha | text or texture, under a
## "## <state>" header per staged state; unset, nothing is written. 10_hud_hurt, 11_hud_prompt and 12_hud_touch are the HUD's states.
var _dump: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")

func _shot(frame: String) -> void:
	await _capture(frame, true)

## `half` false keeps the window's own size (the touch-layout frame is read at its pixels). _rc16_probe_runner.gd overrides _shot(frame) alone.
func _capture(frame: String, half: bool) -> void:
	await RenderingServer.frame_post_draw
	var img := get_tree().root.get_texture().get_image()
	if half:
		img.resize(img.get_width() / 2, img.get_height() / 2, Image.INTERPOLATE_LANCZOS)
	img.save_png(ProjectSettings.globalize_path(out_dir + frame + ".png"))
	print("[final] frame %s.png" % frame)

func _hud_dump(state: String) -> void:
	if OS.get_environment("TLS_HUD_DUMP") == "":
		return
	_dump.append("## " + state)
	var seen: Dictionary = {}
	for layer: Node in get_tree().root.find_children("*", "CanvasLayer", true, false):
		for found: Node in layer.find_children("*", "Control", true, false):
			var ctl := found as Control
			if seen.has(ctl) or not ctl.is_visible_in_tree() or ctl.size.x <= 0.0 or ctl.size.y <= 0.0:
				continue
			seen[ctl] = true
			var alpha: float = 1.0
			var up: Node = ctl
			while up != null and up != layer:
				if up is CanvasItem:
					alpha *= (up as CanvasItem).modulate.a * (up as CanvasItem).self_modulate.a
				up = up.get_parent()
			var rect := ctl.get_global_rect()
			var what: String = ""
			if "text" in ctl:
				what = String(ctl.get("text")).left(30)
			elif ctl is TextureRect and (ctl as TextureRect).texture != null:
				what = (ctl as TextureRect).texture.resource_path.get_file()
			_dump.append("%s|%s|%d,%d,%d,%d|%.2f|%s" % [ctl.get_path(), ctl.get_class(), rect.position.x, rect.position.y, rect.size.x, rect.size.y, alpha, what])

func _write_dump() -> void:
	var path: String = OS.get_environment("TLS_HUD_DUMP")
	if path == "" or _dump.is_empty():
		return
	var file := FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.WRITE)
	if file == null:
		return
	for line: String in _dump:
		file.store_line(line)
	print("[final] hud dump %d lines" % _dump.size())

## The HUD hurt, with an interact prompt, and in the touch layout: states the six release frames do not show.
func _hud_states() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	player.call("take_damage", 45.0)
	await get_tree().create_timer(0.4).timeout
	await _shot("10_hud_hurt")
	player.call("heal", 1000.0)
	EventBus.interact_prompt_changed.emit("Open")
	EventBus.player_interact_available.emit(true)
	await get_tree().create_timer(0.5).timeout
	await _shot("11_hud_prompt")
	EventBus.player_interact_available.emit(false)
	await _touch_frame()

## DisplayServer.is_touchscreen_available() is true while input_devices/pointing/emulate_touch_from_mouse is set, so a HUD built under it
## carries the joystick, the action buttons and the touch-only buttons. The window takes a phone aspect for the shot; every setting comes back.
func _touch_frame() -> void:
	var scene := get_tree().current_scene
	var win := get_window()
	var mode0 := win.mode
	var size0 := win.size
	var calibrated0: Variant = SettingsManager.get_setting("touch_calibration_done", false)
	SettingsManager.set_setting("touch_calibration_done", true)
	ProjectSettings.set_setting("input_devices/pointing/emulate_touch_from_mouse", true)
	Input.emulate_touch_from_mouse = true
	win.mode = Window.MODE_WINDOWED
	win.size = Vector2i(1600, 740)
	await _swap_hud(scene)
	await get_tree().create_timer(1.0).timeout
	await _capture("12_hud_touch", false)
	_hud_dump("touch")
	ProjectSettings.set_setting("input_devices/pointing/emulate_touch_from_mouse", false)
	Input.emulate_touch_from_mouse = false
	win.size = size0
	win.mode = mode0
	SettingsManager.set_setting("touch_calibration_done", calibrated0)
	await _swap_hud(scene)
	await get_tree().create_timer(0.5).timeout

func _swap_hud(scene: Node) -> void:
	var old := scene.get_node_or_null("HUD")
	if old != null:
		scene.remove_child(old)
		old.free()
	var hud := (load("res://scenes/ui/hud_3d.tscn") as PackedScene).instantiate()
	hud.name = "HUD"
	scene.add_child(hud)
	await get_tree().process_frame

func _parse_sweep() -> void:
	for pair: String in OS.get_environment("TLS_SWEEP").split(",", false):
		var wv := pair.split(":")
		if wv.size() == 2:
			_sweep.append(Vector2(float(wv[0]), float(wv[1])))
	if OS.get_environment("TLS_SWEEP_OUT") != "":
		_sweep_out = OS.get_environment("TLS_SWEEP_OUT")
	if OS.get_environment("TLS_FRAMES_OUT") != "":
		out_dir = OS.get_environment("TLS_FRAMES_OUT")

## TLS_MENU_SWEEP="r:g:b,...": the menu's hero art under each modulate colour, as 01_main_menu_v<n>.png (decision aid, like _swept).
func _menu_swept() -> void:
	var hero := get_tree().current_scene.get_node_or_null("MenuHeroV2") as TextureRect
	if hero == null or OS.get_environment("TLS_MENU_SWEEP") == "":
		return
	var kept := hero.modulate
	var normal_out := out_dir
	out_dir = _sweep_out
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var n := 0
	for tint: String in OS.get_environment("TLS_MENU_SWEEP").split(",", false):
		var rgb := tint.split(":")
		if rgb.size() != 3:
			continue
		n += 1
		hero.modulate = Color(float(rgb[0]), float(rgb[1]), float(rgb[2]))
		await get_tree().create_timer(0.3).timeout
		print("[final] sweep 01_main_menu_v%d modulate=%s" % [n, tint])
		await _shot("01_main_menu_v%d" % n)
	out_dir = normal_out
	hero.modulate = kept

func _swept(frame: String, hit: Node3D = null) -> void:
	var worlds := get_tree().root.find_children("*", "WorldEnvironment", true, false)
	if _sweep.is_empty() or worlds.is_empty():
		return
	var env: Environment = (worlds[0] as WorldEnvironment).environment
	var kept := Vector2(env.tonemap_white, env.tonemap_exposure)
	var normal_out := out_dir
	out_dir = _sweep_out
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	for i: int in _sweep.size():
		env.tonemap_white = _sweep[i].x
		env.tonemap_exposure = _sweep[i].y
		if hit != null and is_instance_valid(hit):
			hit.take_damage(1.0)
		await get_tree().create_timer(0.3 if hit == null else 0.02).timeout
		print("[final] sweep %s_v%d white=%s exposure=%s" % [frame, i + 1, _sweep[i].x, _sweep[i].y])
		await _shot("%s_v%d" % [frame, i + 1])
	out_dir = normal_out
	env.tonemap_white = kept.x
	env.tonemap_exposure = kept.y

## Where the rendering camera and the player are: a staged frame is only
## evidence if the camera actually looks at what was staged.
func _where(frame: String) -> void:
	var cam := get_viewport().get_camera_3d()
	var p := get_tree().get_first_node_in_group("player") as Node3D
	print("[final] %s camera %s at %s, player at %s hp=%s, paused=%s" % [frame, cam.get_path() if cam else "none",
		cam.global_position if cam else Vector3.INF, p.global_position if p else Vector3.INF, p.get("hp") if p else -1, get_tree().paused])

## The FPS camera takes the player's yaw (camera_follow_3d.gd _tick_fps).
func _face(p: Node3D, at: Vector3) -> void:
	p.look_at(Vector3(at.x, p.global_position.y, at.z), Vector3.UP)

## Street trees are collision-free MultiMesh instances, so a raycast never sees
## them: a sight line counts as blocked when a canopy (radius 1.2) stands within
## 1.8 m of it on the ground plane.
func _canopies() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for n in get_tree().root.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi := n as MultiMeshInstance3D
		if mmi.multimesh == null or not (mmi.multimesh.mesh is SphereMesh):
			continue
		if (mmi.multimesh.mesh as SphereMesh).radius < 1.0:
			continue
		for i in mmi.multimesh.instance_count:
			var at := mmi.global_transform * mmi.multimesh.get_instance_transform(i).origin
			out.append(Vector2(at.x, at.z))
	return out

func _sight_blocked(canopies: Array[Vector2], a: Vector3, b: Vector3) -> bool:
	var from := Vector2(a.x, a.z)
	var to := Vector2(b.x, b.z)
	for c in canopies:
		if c.distance_to(Geometry2D.get_closest_point_to_segment(c, from, to)) < 1.8:
			return true
	return false

## Turn toward the most street lights (Spot/Omni, not the player's own) 3-40 m
## away inside a +-35 deg view cone, so the DARK and FULL frames show the same
## street with its lamps off and on. A tree 7 m ahead would hide the street.
func _face_lamps(p: Node3D) -> void:
	var canopies := _canopies()
	var lamps: Array[Vector2] = []
	for n in get_tree().root.find_children("*", "Light3D", true, false):
		if not (n is DirectionalLight3D) and not p.is_ancestor_of(n):
			var d := (n as Node3D).global_position - p.global_position
			var flat := Vector2(d.x, d.z)
			if flat.length() > 3.0 and flat.length() < 40.0:
				lamps.append(flat.normalized())
	var best := -1
	for i in 36:
		var yaw := TAU * i / 36.0
		var fwd := Vector2(-sin(yaw), -cos(yaw))
		if _sight_blocked(canopies, p.global_position, p.global_position + Vector3(fwd.x, 0.0, fwd.y) * 7.0):
			continue
		var count := 0
		for d in lamps:
			if d.dot(fwd) > cos(deg_to_rad(35.0)):
				count += 1
		if count > best:
			best = count
			p.rotation.y = yaw
	print("[final] facing %d of %d street lights" % [best, lamps.size()])

func _wait_until(pred: Callable, timeout_sec: float) -> bool:
	var t := 0.0
	while t < timeout_sec:
		if pred.call():
			return true
		await get_tree().create_timer(0.2).timeout
		t += 0.2
	return pred.call()

func _fail(why: String) -> void:
	print("[final] FAIL " + why)
	get_tree().quit(1)

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("[final] SKIP headless - frames need a real display")
		get_tree().quit(3)
		return
	_parse_sweep()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var ads := get_node_or_null("/root/AdService")
	if ads:
		ads.enabled = false
	QualityManager.enabled = false  # a measurement reads one tier: the quality manager steps it under 30 FPS (CORRECTION_LOG 241)
	# The run shows English at text size 1 whatever the profile says; the profile's own values come back at the end.
	var lang0: String = LocalizationManager.current_lang
	var size0: int = int(SettingsManager.get_setting("text_size", 1))
	LocalizationManager.set_language("en")
	SettingsManager.set_text_size(1)
	# The boot screen routes itself to the menu once its bar is full (~6.5 s).
	Routes.goto(Routes.BOOT)
	await get_tree().create_timer(1.2).timeout
	await _shot("00_boot_title")
	var menu_up := func() -> bool:
		var cs := get_tree().current_scene
		return cs != null and cs.scene_file_path == Routes.MENU
	if not await _wait_until(menu_up, 15.0):
		Routes.goto(Routes.MENU)
		if not await _wait_until(menu_up, 10.0):
			_fail("main menu never came up")
			return
	await get_tree().create_timer(1.5).timeout
	await _shot("01_main_menu")
	await _menu_swept()
	# en at text size 1 is 01_main_menu itself (a byte-identical twin fails AF3 rule F6).
	for lang: String in ["en", "ru", "ar"]:
		for size_idx: int in [1, 2]:
			if lang == "en" and size_idx == 1:
				continue
			LocalizationManager.set_language(lang)
			SettingsManager.set_text_size(size_idx)
			await get_tree().create_timer(0.6).timeout
			await _shot("01_menu_%s_s%d" % [lang, size_idx])
	LocalizationManager.set_language("en")
	SettingsManager.set_text_size(1)

	# a fresh profile opens the onboarding cards on game_started: they pause the tree and dim the frame, and these runs measure the game
	SaveSystem.mark_onboard_done()
	Routes.start_game()
	var playing := func() -> bool: return GameManager.is_playing() and get_tree().get_first_node_in_group("player") != null
	if not await _wait_until(playing, 20.0):
		_fail("never reached gameplay")
		return
	await get_tree().create_timer(3.0).timeout
	_face_lamps(get_tree().get_first_node_in_group("player") as Node3D)
	await get_tree().create_timer(0.3).timeout
	_where("03")
	await _shot("03_district_night_dark")
	_hud_dump("calm")
	await _swept("03_district_night_dark")
	await _hud_states()

	PowerGrid.advance_district(StringName(DistrictManager.current_district), DistrictData.Stage.FULL)
	await get_tree().create_timer(1.5).timeout
	await _shot("02_district_day_full")
	await _swept("02_district_day_full")

	UIManager.open(&"skill_tree")
	await get_tree().create_timer(0.6).timeout
	await _shot("07_skill_tree")
	UIManager.close(&"skill_tree")
	var screens: Node = get_tree().current_scene.get_node_or_null("Screens")
	if screens == null:
		_fail("the main scene has no Screens node")
		return
	screens.call("show_screen", "Shop")
	await get_tree().create_timer(0.6).timeout
	await _shot("08_shop")
	LocalizationManager.set_language("ar")
	screens.call("show_screen", "Shop")
	await get_tree().create_timer(0.6).timeout
	await _shot("08_shop_ar")
	LocalizationManager.set_language("en")
	screens.call("hide_all")
	await get_tree().create_timer(0.6).timeout

	# Combat: the nearest monster that is in the world (pooled ones are parked
	# far below), the player 3 m from it and facing it, one hit for the flash.
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var monster: Node3D = null
	for m in get_tree().get_nodes_in_group("monsters"):
		var m3 := m as Node3D
		if m3 == null or not m3.is_visible_in_tree() or m3.global_position.y < -5.0:
			continue
		if monster == null or m3.global_position.distance_to(player.global_position) < monster.global_position.distance_to(player.global_position):
			monster = m3
	if monster == null:
		_fail("no monster in the spawn district")
		return
	var away := player.global_position - monster.global_position
	away.y = 0.0
	away = away.normalized() * 3.0 if away.length() > 0.1 else Vector3(0.0, 0.0, 3.0)
	player.global_position = monster.global_position + away + Vector3(0.0, 0.5, 0.0)
	_face(player, monster.global_position)
	await get_tree().create_timer(0.6).timeout
	if is_instance_valid(monster) and monster.has_method("take_damage"):
		monster.take_damage(1.0)
	await get_tree().process_frame
	_where("04")
	await _shot("04_combat")
	_hud_dump("combat")
	await _swept("04_combat", monster)

	# Boss by the game's own finale flow (finale_director.gd): every district
	# restored starts the final night, entering the power station spawns the
	# Architect at its BossSpawn marker.
	for id in PowerGrid._by_id.keys():
		PowerGrid.advance_district(id, DistrictData.Stage.FULL)
	DistrictManager.current_district = "power_station"
	EventBus.district_entered.emit(&"power_station")
	var boss_up := func() -> bool: return is_instance_valid(FinaleDirector._boss)
	if not await _wait_until(boss_up, 25.0):
		_fail("the Architect never spawned at the power station")
		return
	player = get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		_fail("no player at the power station")
		return
	var boss: Node3D = FinaleDirector._boss
	# Arrive healthy (the staged combat above cost HP; the low-HP vignette would
	# tint the whole frame red) and 5 m from the Architect, facing it.
	if player.has_method("heal"):
		player.heal(1000.0)
	var back := player.global_position - boss.global_position
	back.y = 0.0
	back = back.normalized()
	# The side nearest to where the player arrived, with floor under it and no
	# canopy on the sight line (the Architect spawns 14 m ahead of the arrival).
	var canopies := _canopies()
	var space := player.get_world_3d().direct_space_state
	var spot := boss.global_position + back * 5.0
	for k in 16:
		var turn := ceili(k / 2.0) * TAU / 16.0 * (1.0 if k % 2 == 1 else -1.0)
		var cand := boss.global_position + back.rotated(Vector3.UP, turn) * 5.0
		var floor_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(cand + Vector3(0.0, 4.0, 0.0), cand + Vector3(0.0, -2.0, 0.0)))
		if not floor_hit.is_empty() and not _sight_blocked(canopies, cand, boss.global_position):
			spot = cand
			break
	player.global_position = spot + Vector3(0.0, 0.5, 0.0)
	_face(player, boss.global_position)
	if player.has_method("toggle_flashlight") and not bool(player.get("flashlight_enabled")):
		player.toggle_flashlight()
	# Let P1 run briefly: its brass energy balls (V02) light the fight.
	await get_tree().create_timer(1.0).timeout
	# The Architect moves in P1: aim again right before the shot.
	_face(player, boss.global_position)
	await get_tree().process_frame
	await get_tree().process_frame
	_where("05")
	print("[final] 05 boss at %s" % boss.global_position)
	await _shot("05_boss")

	GameManager.trigger_win()
	await get_tree().create_timer(2.5).timeout
	await _shot("06_victory_ngplus")
	LocalizationManager.set_language(lang0)
	SettingsManager.set_text_size(size0)
	_write_dump()
	print("[final] DONE frames=18")
	get_tree().quit(0)
