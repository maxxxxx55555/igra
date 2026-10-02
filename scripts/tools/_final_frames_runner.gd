extends Node
## Runner for _final_frames.gd (lives under /root so scene swaps don't free it).
## Frames, half resolution: 01 main menu, 02 district "day", 03 district night,
## 04 combat, 05 boss, 06 victory with the NG+ action. The GDD has no daytime
## ("no day", GDD.md:261), so "day" is the restored FULL stage and "night" the
## DARK stage of the spawn district. A saved PNG proves nothing until read.

var out_dir := "res://docs/stills/final/"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")

func _shot(frame: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_tree().root.get_texture().get_image()
	img.resize(img.get_width() / 2, img.get_height() / 2, Image.INTERPOLATE_LANCZOS)
	img.save_png(ProjectSettings.globalize_path(out_dir + frame + ".png"))
	print("[final] frame %s.png" % frame)

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
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var ads := get_node_or_null("/root/AdService")
	if ads:
		ads.enabled = false
	# Splash and boot loading take ~6.5 s before the menu is up.
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

	PowerGrid.advance_district(StringName(DistrictManager.current_district), DistrictData.Stage.FULL)
	await get_tree().create_timer(1.5).timeout
	await _shot("02_district_day_full")

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
	print("[final] DONE frames=6")
	get_tree().quit(0)
