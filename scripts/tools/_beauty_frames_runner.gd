extends "res://scripts/tools/_final_frames_runner.gd"
## Eight look-development frames for the beauty pass: the menu, then the same
## staged view (lamps in the +-35 deg cone, flashlight on in the dark) in six
## districts, dark and restored. Compare BEAUTY_TAG=before with =after.

const VISITS: Array = [
	[&"suburbs", 0], [&"suburbs", 3], [&"residential", 0], [&"park", 0],
	[&"hospital", 0], [&"industrial", 0], [&"power_station", 3],
]

## BEAUTY_HIDE=ash,sky switches those layers off so a look-development A/B can
## name the source of a visual artefact.
func _apply_hide() -> void:
	var hide := OS.get_environment("BEAUTY_HIDE")
	if hide.contains("ash"):
		for n in get_tree().root.find_children("Ash", "GPUParticles3D", true, false):
			(n as Node3D).visible = false
	if hide.contains("sky"):
		for n in get_tree().root.find_children("*", "WorldEnvironment", true, false):
			(n as WorldEnvironment).environment.sky = null

## A district only takes power once its feeders are FULL (the power station
## needs the substation), so restore those first.
func _restore(id: StringName, stage: int) -> void:
	for feeder in PowerGrid.get_district(id).powered_by:
		_restore(feeder, DistrictData.Stage.FULL)
	if PowerGrid.get_stage(id) < stage:
		PowerGrid.advance_district(id, stage)

func _visit(index: int, id: StringName, stage: int) -> bool:
	EventBus.district_entered.emit(id)
	var there := func() -> bool:
		return DistrictManager.current_district == String(id) and get_tree().get_first_node_in_group("player") != null
	if not await _wait_until(there, 15.0):
		_fail("never reached " + String(id))
		return false
	await get_tree().create_timer(3.5).timeout
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player.has_method("heal"):
		player.heal(1000.0)
	if stage > 0:
		_restore(id, stage)
		await get_tree().create_timer(1.5).timeout
	elif player.has_method("toggle_flashlight") and not bool(player.get("flashlight_enabled")):
		player.toggle_flashlight()
	_face_lamps(player)
	_apply_hide()
	await get_tree().create_timer(0.4).timeout
	await _shot("%02d_%s_%s" % [index, String(id), "dark" if stage == 0 else "lit"])
	return true

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("[beauty] SKIP headless - frames need a real display")
		get_tree().quit(3)
		return
	var tag := OS.get_environment("BEAUTY_TAG")
	out_dir = "res://docs/stills/beauty/%s/" % (tag if not tag.is_empty() else "after")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
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
	await get_tree().create_timer(1.5).timeout
	await _shot("00_main_menu")
	Routes.start_game()
	var playing := func() -> bool: return GameManager.is_playing() and get_tree().get_first_node_in_group("player") != null
	if not await _wait_until(playing, 20.0):
		_fail("never reached gameplay")
		return
	await get_tree().create_timer(3.0).timeout
	for i in VISITS.size():
		if not await _visit(i + 1, VISITS[i][0], VISITS[i][1]):
			return
	print("[beauty] DONE frames=%d" % (VISITS.size() + 1))
	get_tree().quit(0)
