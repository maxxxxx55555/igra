extends Node
## Runner for _tz_verify.gd (lives under /root so Routes scene swaps don't free it).

const OUT := "res://docs/stills/tzverify/"
var _fails: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")

func _log(m: String) -> void:
	print("[tzv] ", m)

func _check(cond: bool, m: String) -> void:
	if not cond:
		_fails += 1
	_log(("OK   " if cond else "FAIL ") + m)

func _shot(row: String) -> Image:
	await RenderingServer.frame_post_draw
	var img := get_tree().root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + row + ".png"))
	_log("frame %s.png" % row)
	return img

## Mean (r - b) over a left-edge strip at mid height: where the vignette is
## strong and no HUD widget sits. bg-deep is bluish (< 0), ember is > 0.
func _edge_warmth(img: Image) -> float:
	var w := img.get_width()
	var h := img.get_height()
	var sum := 0.0
	var n := 0
	for y in range(int(h * 0.4), int(h * 0.6), 4):
		for x in range(0, int(w * 0.03), 2):
			var c := img.get_pixel(x, y)
			sum += c.r - c.b
			n += 1
	return sum / maxf(n, 1)

func _save_paths() -> Array[String]:
	var out: Array[String] = ["user://ng_plus_data.json"]
	for base in ["user://tls_savegame.save"] + range(1, SaveSystem.MAX_SLOTS + 1).map(func(i): return "user://tls_savegame_slot%d.save" % i):
		for suffix in ["", ".bak", ".bak2", ".bak3"]:
			out.append(String(base) + suffix)
	return out

func _backup_saves() -> Dictionary:
	var b := {}
	for path in _save_paths():
		if FileAccess.file_exists(path):
			b[path] = FileAccess.get_file_as_bytes(path)
	_log("backed up %d save files" % b.size())
	return b

func _restore_saves(b: Dictionary) -> void:
	for path in _save_paths():
		if b.has(path):
			var f := FileAccess.open(path, FileAccess.WRITE)
			f.store_buffer(b[path])
			f.close()
		elif FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	_log("restored %d save files" % b.size())

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _wait_until(pred: Callable, timeout_sec: float) -> bool:
	var t := 0.0
	while t < timeout_sec:
		if pred.call():
			return true
		await get_tree().create_timer(0.2).timeout
		t += 0.2
	return pred.call()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		_log("SKIP headless - frames need a real display")
		get_tree().quit(3)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var ads := get_node_or_null("/root/AdService")
	if ads:
		ads.enabled = false
	await get_tree().create_timer(1.0).timeout
	Routes.start_game()
	var ready_pred := func() -> bool: return GameManager.is_playing() and get_tree().get_first_node_in_group("player") != null
	if not await _wait_until(ready_pred, 20.0):
		_log("FAIL never reached gameplay")
		get_tree().quit(1)
		return
	await get_tree().create_timer(3.0).timeout
	var p: Node3D = get_tree().get_first_node_in_group("player")
	var cam := get_viewport().get_camera_3d()
	var base_warmth := _edge_warmth(await _shot("baseline"))
	# C06 at load, before any tier change: FogSetup used to reset the density
	# to a fixed 0.015 right after WorldEnvSetup applied the tier.
	var we0 := get_tree().root.find_child("WorldEnvironment", true, false) as WorldEnvironment
	var tier0: int = clampi(int(SettingsManager.get_setting("graphics_tier", 2)), 0, 3)
	var want_fog: float = float(load("res://assets/config/visual_quality.tres").get_meta(["low", "medium", "high", "ultra"][tier0], {}).get("fog_density", -1.0))
	var fog0: float = we0.environment.fog_density if we0 else -1.0
	_check(is_equal_approx(fog0, want_fog), "C06 fog at load (tier %d) = %s, tier preset %s" % [tier0, fog0, want_fog])

	# A02 - audio, numeric only.
	_check(is_equal_approx(MusicManager.FADE_TIME, 2.0), "A02 MusicManager.FADE_TIME=%s (GDD 2.0)" % MusicManager.FADE_TIME)
	# V05 - project setting (desktop value; .mobile override is 1024).
	var atlas := int(ProjectSettings.get_setting("rendering/lights_and_shadows/directional_shadow/size"))
	_check(atlas == 2048, "V05 directional shadow size=%d (GDD 2048)" % atlas)

	# G08 - flashlight colour and cone.
	var fl: SpotLight3D = p.get_node("ModelPivot/FlashlightPivot/Flashlight")
	_check(fl.light_color.to_html(false) == "c9a24a" and is_equal_approx(fl.spot_angle, 45.0),
		"G08 flashlight color=%s angle=%s" % [fl.light_color.to_html(false), fl.spot_angle])
	await _shot("G08_flashlight")

	# G02/G03/G06 - drive RUN for real.
	var fov0 := cam.fov
	Input.action_press("run")
	Input.action_press("move_up")
	await get_tree().create_timer(1.2).timeout
	var fov_run := cam.fov
	var ys: Array[float] = []
	for i in 12:
		await get_tree().process_frame
		ys.append(cam.global_position.y - p.global_position.y)
	await _shot("G03_sprint_fov")
	var vig: ColorRect = get_tree().root.find_child("VignetteOverlay", true, false)
	var vig_r := 0.0
	for i in 60:
		vig_r = vig.color.r if vig else -1.0
		if vig_r > 0.4:
			break
		await get_tree().process_frame
	var run_warmth := _edge_warmth(await _shot("S03_noise_vignette"))
	Input.action_release("run")
	Input.action_release("move_up")
	_check(fov_run - fov0 > 3.0, "G03 sprint FOV %0.1f -> %0.1f (+5 target)" % [fov0, fov_run])
	var span: float = ys.max() - ys.min()
	_check(span > 0.02 and span <= 0.25, "G02 headbob eye-height span while running=%0.3f (amp 0.1)" % span)
	_check(is_equal_approx(p.stats.run_speed, p.stats.walk_speed * 1.6), "G06 run_speed=%s walk=%s" % [p.stats.run_speed, p.stats.walk_speed])
	_check(vig_r > 0.4 and run_warmth - base_warmth > 0.03,
		"S03 ember pulse while running: vignette r=%0.2f, edge warmth %0.3f -> %0.3f" % [vig_r, base_warmth, run_warmth])

	# C06 - fog per tier.
	var we := get_tree().root.find_child("WorldEnvironment", true, false) as WorldEnvironment
	var env: Environment = we.environment if we else cam.get_world_3d().environment
	SettingsManager.set_graphics_tier(0)
	await _frames(3)
	var fog_low: float = env.fog_density if env else -1.0
	await _shot("C06_tier_low")
	SettingsManager.set_graphics_tier(3)
	await _frames(3)
	var fog_ultra: float = env.fog_density if env else -1.0
	await _shot("C06_tier_ultra")
	_check(is_equal_approx(fog_low, 0.012) and is_equal_approx(fog_ultra, 0.015), "C06 fog density low=%s ultra=%s (0.012/0.015)" % [fog_low, fog_ultra])
	var em: Array = get_tree().root.find_children("*", "GPUParticles3D", true, false)
	var scaled := 0
	for e in em:
		if e.has_meta("tier_base_amount") and e.amount == int(round(int(e.get_meta("tier_base_amount")) * 1.5)):
			scaled += 1
	_check(em.size() > 0 and scaled == em.size(), "C06 ultra: %d/%d GPUParticles3D emitters at 150%% amount" % [scaled, em.size()])
	SettingsManager.set_graphics_tier(2)

	# G12b - low-battery flicker.
	p.battery = p.battery_max * 0.1
	var energies: Array[float] = []
	for i in 20:
		await get_tree().process_frame
		energies.append(fl.light_energy)
	await _shot("G12b_low_battery")
	var espread: float = energies.max() - energies.min()
	_check(espread > 0.01, "G12b light_energy spread at 10%% battery=%0.3f" % espread)
	# G12b - max-level Stability clears the flicker (through the real upgrade path).
	var flm := get_node("/root/FlashlightUpgradeManager")
	var st_lvl: int = flm._levels["stability"]
	flm._levels["stability"] = flm.get_max_level()
	p.apply_flashlight_upgrades(flm._levels)
	energies.clear()
	for i in 20:
		await get_tree().process_frame
		energies.append(fl.light_energy)
	var espread_l5: float = energies.max() - energies.min()
	_check(espread_l5 == 0.0, "G12b Stability L5 at 10%% battery: spread=%0.3f (0 = cleared)" % espread_l5)
	flm._levels["stability"] = st_lvl
	p.apply_flashlight_upgrades(flm._levels)
	p.battery = p.battery_max

	# V02 - boss energy ball colour, in front of the camera.
	var ball = BossMonster.EnergyBall.new(Vector3.FORWARD, 0.0)
	get_tree().current_scene.add_child(ball)
	ball.global_position = cam.global_position - cam.global_transform.basis.z * 3.0
	ball.set_process(false)
	ball.set_physics_process(false)
	await _frames(3)
	await _shot("V02_energy_ball")
	ball.queue_free()

	# C04 - arachnophobia name on the real-time spotted label.
	SettingsManager.set_arachnophobia(true)
	var hud: Node = null
	for n in get_tree().root.find_children("*", "CanvasLayer", true, false):
		if n.has_method("_on_monster_spotted"):
			hud = n
			break
	if hud and hud.has_method("_on_monster_spotted"):
		hud._on_monster_spotted(&"crawler")
	await get_tree().create_timer(0.5).timeout
	await _shot("C04_arachnophobia_label")
	var lbl: Label = hud.get("enemy_name_label") if hud else null
	_check(lbl != null and lbl.text == LocalizationManager.t("MONSTER_CRAWLER_ARACHNOPHOBIA"), "C04 spotted label='%s'" % (lbl.text if lbl else "?"))
	SettingsManager.set_arachnophobia(false)

	# C03 - auto-aim bias toward an enemy 8 degrees off-axis.
	var wb := WeaponBase.new()
	add_child(wb)
	wb.set_shooter(p)
	var fwd := -cam.global_transform.basis.z
	var tgt := Node3D.new()
	tgt.add_to_group("enemies")
	get_tree().current_scene.add_child(tgt)
	tgt.global_position = cam.global_position + fwd.rotated(Vector3.UP, deg_to_rad(8.0)) * 10.0
	SettingsManager.set_setting("auto_aim", true)
	var aimed: Vector3 = wb._apply_auto_aim(cam.global_position, fwd)
	SettingsManager.set_setting("auto_aim", false)
	var unaimed: Vector3 = wb._apply_auto_aim(cam.global_position, fwd)
	var to_t := (tgt.global_position - cam.global_position).normalized()
	_check(aimed.dot(to_t) > 0.999 and unaimed.is_equal_approx(fwd), "C03 auto-aim bends toward an 8-degree target only when on")
	tgt.queue_free()
	wb.queue_free()

	# Tutorial hint layout: the box and its Skip button must sit in the bottom
	# half, clear of the HUD bars (they used to collapse onto them).
	var hint := get_tree().root.find_child("TutorialHint", true, false) as Control
	var skip := get_tree().root.find_child("SkipButton", true, false) as Control
	if hint != null and skip != null:
		var lbl_t := hint.find_child("HintText", true, false) as Label
		if lbl_t != null:
			lbl_t.text = LocalizationManager.t("TUT_MOVE")
		hint.visible = true
		await _frames(3)
		await _shot("TUT_hint_layout")
		var vp_h: float = get_viewport().get_visible_rect().size.y
		_check(skip.get_global_rect().position.y > vp_h * 0.5 and lbl_t != null and not lbl_t.text.begins_with("TUT_"),
			"tutorial hint in bottom half (skip y=%d of %d), text='%s'" % [int(skip.get_global_rect().position.y), int(vp_h), lbl_t.text if lbl_t else "?"])
		hint.visible = false
	else:
		_check(false, "tutorial hint/skip nodes not found")

	# G17 - hardcore death wipes the save (last: it ends the run). The wipe is
	# real, so every file it touches is backed up first and restored after -
	# this probe must never cost the machine's owner their actual progress.
	var backup := _backup_saves()
	SaveSystem.save_all()
	# Seed every rotated backup so the check covers the load step-4 fallbacks.
	for suffix in [".bak", ".bak2", ".bak3"]:
		DirAccess.copy_absolute(SaveSystem.SAVE_PATH, SaveSystem.SAVE_PATH + suffix)
	var had_save: bool = SaveSystem.has_save()
	SettingsManager.set_setting("hardcore", true)
	GameManager.trigger_death()
	await get_tree().create_timer(1.0).timeout
	await _shot("G17_hardcore_death")
	var left := _save_paths().filter(func(path: String) -> bool: return path.contains("tls_savegame") and FileAccess.file_exists(path))
	_check(had_save and left.is_empty(), "G17 hardcore death: save before=%s, files left=%s" % [had_save, left])
	SettingsManager.set_setting("hardcore", false)
	_restore_saves(backup)

	_log("DONE fails=%d" % _fails)
	get_tree().quit(0 if _fails == 0 else 1)
