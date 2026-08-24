extends Node
## Runner spawned under get_tree().root by _perf_check.gd (same bootstrap
## pattern as _boot_check.gd / _gameplay_shot.gd - a runner living inside
## the scene Routes.goto() replaces gets freed mid-coroutine).

const BUDGET_D1: int = 200   ## GDD/Production Bible asset budget, district 1
const BUDGET_D11: int = 350  ## same, district 11 (busiest)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")

func _run() -> void:
	await get_tree().create_timer(1.0).timeout
	if not _menu_reachable():
		Routes.goto(Routes.MENU)
	if not await _wait_until(_menu_reachable, 12.0):
		printerr("[perf] menu never reachable")
		get_tree().quit(1)
		return
	Routes.start_game()
	if not await _wait_until(func() -> bool: return GameManager.is_playing(), 10.0):
		printerr("[perf] never entered PLAYING")
		get_tree().quit(1)
		return
	if not await _wait_until(func() -> bool: return get_tree().get_first_node_in_group("player") != null, 10.0):
		printerr("[perf] player never spawned")
		get_tree().quit(1)
		return
	# A few frames to let the renderer settle past the first-frame spike.
	for i in 10:
		await get_tree().process_frame
	var draw_calls := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var primitives := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var objects := int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	var district := ""
	var dm := get_node_or_null("/root/DistrictManager")
	if dm != null:
		district = String(dm.current_district)
	print("[perf] district=", district, " draw_calls=", draw_calls,
		" primitives=", primitives, " objects_in_frame=", objects)
	print("[perf] budget D1<%d D11<%d -> %s" % [BUDGET_D1, BUDGET_D11,
		"OK" if draw_calls < BUDGET_D11 else "OVER BUDGET"])
	print("[perf] DONE")
	get_tree().quit(0)

func _menu_reachable() -> bool:
	var cs := get_tree().current_scene
	return cs != null and cs.scene_file_path == Routes.MENU

func _wait_until(pred: Callable, timeout_sec: float) -> bool:
	var t := 0.0
	while t < timeout_sec:
		if pred.call():
			return true
		await get_tree().create_timer(0.2).timeout
		t += 0.2
	return pred.call()
