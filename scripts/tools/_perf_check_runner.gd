extends Node
## Runner spawned under get_tree().root by _perf_check.gd (same bootstrap
## pattern as _boot_check.gd / _gameplay_shot.gd - a runner living inside
## the scene Routes.goto() replaces gets freed mid-coroutine).

const BUDGET_D1: int = 200   ## GDD/Production Bible asset budget, district 1
const BUDGET_D11: int = 350  ## same, district 11 (busiest)
const BUDGET_P95_MS: float = 33.0  ## frame time, 95th percentile, 30 FPS (the dev iGPU, windowed); read with the vsync and the frame cap off, see _run()
const BUDGET_VRAM_MIB: float = 512.0  ## the mobile video memory budget (PRODUCTION_BIBLE: 400 MiB; the directive's 512)

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
	# a fresh profile opens the onboarding cards on game_started: they pause the tree and dim the frame, and these runs measure the game
	SaveSystem.mark_onboard_done()
	QualityManager.enabled = false  # a measurement reads one tier: the quality manager steps it under 30 FPS (CORRECTION_LOG 241)
	if OS.get_environment("TLS_PERF_TIER") != "":
		SettingsManager.set_graphics_tier(int(OS.get_environment("TLS_PERF_TIER")))  # 0 Low, 1 Medium, 2 High, 3 Ultra: the default is the profile's
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
	var trace: Array[int] = []
	for i in 10:
		await get_tree().process_frame
		trace.append(_calls())
	var draw_calls := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var primitives := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var objects := int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	var district := ""
	var dm := get_node_or_null("/root/DistrictManager")
	if dm != null:
		district = String(dm.current_district)
	print("[perf] district=", district, " draw_calls=", draw_calls,
		" primitives=", primitives, " objects_in_frame=", objects)
	print("[perf] draw calls frame by frame after the player spawned: ", trace)
	# PLAN.md Stage 2: PRODUCTION_BIBLE.md's checklist asks for this to be a
	# real gate, not just a printed number. Godot's headless mode uses a
	# dummy renderer that always reports draw_calls=0 - that's not "under
	# budget", it's "not measured" - hard-failing on 0 would be a false
	# negative, so this specific case is a skip (exit 0, DUMMY-RENDERER
	# note), not a pass. Session 23: D1<200 fails the gate too (142 draw calls measured in
	# Session 22), and so do a p95 frame time over 33 ms and a video memory over 512 MiB.
	if draw_calls == 0:
		print("[perf] SKIP: draw_calls=0 means headless dummy renderer - re-run with --windowed to actually measure")
		# check.sh's run_gate() maps exit 3 to a printed SKIP, distinct from
		# the exit-0 "ok" a real windowed pass reports (SLOP_REPORT item 2).
		get_tree().quit(3)
		return
	await _print_breakdown(district)
	print("[perf] %s steady draw_calls=%d (everything shown again, after the breakdown)" % [district, _calls()])
	# The interval a player sees is the display's vsync and the tier's frame cap (Low and Medium cap at 30 FPS: it reads 33.33 ms whatever the cost, over the 33.0 budget by construction).
	# It is printed once; the budget reads the cost of the frame, so the p95 reads below run with the vsync and the cap off (R2 of the v10 pass, docs/KNOWN_ISSUES.md).
	var d1_interval := await _frame_p95_ms(300)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var d1_p95 := await _median_p95()
	var d1_vram: float = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
	print("[perf] %s frame_p95_ms=%0.2f interval_p95_ms=%0.2f texture_mem_mib=%0.1f video_mem_mib=%0.1f" % [district, d1_p95, d1_interval,
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0, d1_vram])
	var particles := 0
	for node in get_tree().root.find_children("*", "GPUParticles3D", true, false):
		var emitter := node as GPUParticles3D
		if emitter.emitting and emitter.is_visible_in_tree():
			particles += emitter.amount
	print("[perf] %s static_memory_mib=%0.1f particles_emitting=%d (GDD PF2: RAM < 800 MiB, VRAM < 400 MiB, particles < 500)" % [district,
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, particles])
	# D11: jump straight to power_station (QA only; the profile guard restores
	# the save), then measure the busiest district against its own budget.
	var wr := get_tree().root.find_child("WorldRuntime", true, false)
	DistrictManager.current_district = "power_station"
	EventBus.district_entered.emit(&"power_station")
	var d11_loaded := func() -> bool: return wr != null and wr._current_id == &"power_station" and not wr._loading
	if not await _wait_until(d11_loaded, 20.0):
		printerr("[perf] power_station never loaded")
		get_tree().quit(1)
		return
	for i in 60:
		await get_tree().process_frame
	var d11_calls := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var d11_prims := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var d11_objects := int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	var d11_p95 := await _median_p95()
	print("[perf] district=power_station draw_calls=%d primitives=%d objects_in_frame=%d frame_p95_ms=%0.2f" % [
		d11_calls, d11_prims, d11_objects, d11_p95])
	var broke: Array[String] = failures(draw_calls, d11_calls, d1_p95, d11_p95, d1_vram)
	print("[perf] budget D1<%d: %d; D11<%d: %d; p95<=%.0f ms: %.2f and %.2f; video memory<=%.0f MiB: %.1f; over budget: %s" % [BUDGET_D1, draw_calls,
		BUDGET_D11, d11_calls, BUDGET_P95_MS, d1_p95, d11_p95, BUDGET_VRAM_MIB, d1_vram, broke])
	print("[perf] DONE fails=", broke.size())
	get_tree().quit(1 if not broke.is_empty() else 0)

## The budgets a run broke, by name (empty when all are met). Static, so a check can try the edges of each.
static func failures(d1_calls: int, d11_calls: int, d1_p95: float, d11_p95: float, vram_mib: float) -> Array[String]:
	var broke: Array[String] = []
	if d1_calls >= BUDGET_D1:
		broke.append("D1 draw calls")
	if d11_calls >= BUDGET_D11:
		broke.append("D11 draw calls")
	if d1_p95 > BUDGET_P95_MS or d11_p95 > BUDGET_P95_MS:
		broke.append("p95 frame time")
	if vram_mib > BUDGET_VRAM_MIB:
		broke.append("video memory")
	return broke

## What the draw calls of the first district are made of: every direct child of the main scene and of the district root is
## hidden in turn and the frame's draw calls are counted again (the biggest savers first). A 3D node and a UI layer hide
## the same way; the sum is not the total (shadow passes and batching overlap) but the ranking is what a fix is chosen by.
func _print_breakdown(district: String) -> void:
	var base := _calls()
	var base_prims := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var rows: Array = []
	var main := get_tree().current_scene
	var roots: Array[Node] = [main]
	var world := main.find_child("district_" + district, true, false)
	if world != null:
		roots.append(world)
	for root in roots:
		for child in root.get_children():
			if not (child is CanvasItem or child is Node3D or child is CanvasLayer):
				continue
			var was: bool = child.visible
			if not was:
				continue
			child.visible = false
			for i in 3:
				await get_tree().process_frame
			rows.append([base - _calls(), "%s/%s (%s) %d primitives" % [root.name, child.name, child.get_class(), base_prims - int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))]])
			child.visible = true
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var lines: PackedStringArray = []
	for row in rows.slice(0, 14):
		lines.append("%d %s" % [row[0], row[1]])
	print("[perf] breakdown of %d draw calls in %s, calls saved by hiding each node: %s" % [base, district, " | ".join(lines)])
	for i in 3:
		await get_tree().process_frame

func _calls() -> int:
	return int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))

## The median of three 300-frame p95 reads: one read moves by up to 16 ms with the load of the machine (docs/PERF_PASS.md, rc16 before and after).
func _median_p95() -> float:
	var reads: Array[float] = []
	for i in 3:
		reads.append(await _frame_p95_ms(300))
	reads.sort()
	return reads[1]

## 95th-percentile frame time over the next n frames, in ms. Also prints the
## mean GPU and CPU render time and script/physics time over the same frames,
## so a slow p95 says which side is the bottleneck.
func _frame_p95_ms(n: int) -> float:
	var vp := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	var ms: Array[float] = []
	var gpu := 0.0
	var cpu := 0.0
	var script := 0.0
	var phys := 0.0
	for i in n:
		await get_tree().process_frame
		ms.append(get_process_delta_time() * 1000.0)
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(vp)
		script += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		phys += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	print("[perf] mean over %d frames: gpu_ms=%0.2f render_cpu_ms=%0.2f process_ms=%0.2f physics_ms=%0.2f" % [n, gpu / n, cpu / n, script / n, phys / n])
	# process_ms and physics_ms are the engine's WORST frame of the last second (Performance.TIME_PROCESS is a per-second maximum), so they read hitches, not the mean: the slow frames are listed here by index.
	var order := PackedFloat64Array(ms)
	ms.sort()
	var median: float = ms[ms.size() / 2]
	var slow: PackedStringArray = []
	for i in order.size():
		if order[i] > maxf(3.0 * median, 25.0) and slow.size() < 14:
			slow.append("%d:%.0f" % [i, order[i]])
	print("[perf] median %.2f ms, worst %.1f ms, slow frames (index:ms, over max(3 x median, 25 ms)): %s" % [median, ms.back(), ", ".join(slow) if not slow.is_empty() else "none"])
	return ms[int(ms.size() * 0.95)]

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
