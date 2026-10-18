extends "res://scripts/tools/_perf_check_runner.gd"
## Where the frame time goes (docs/PERF_PASS.md, Session 23). One windowed run, tools/qa_sim/guarded_windowed res://scenes/tools/perf_ablation_scene.tscn: a view is measured as it stands, then with one part of the frame switched off at a time, the baseline between each pair so the drift of a shared
## machine shows. The vertical sync and the frame cap are off, so a frame time is the work and not a multiple of the display's interval. The suburbs (the spawn view) take the parts of PARTS, then every visible child of the HUD and of the post-process
## overlay in turn, then the 4x MSAA (last: switched back on it does not return until the window changes size); the power station (the D11 of the perf gate, a district with ground fog) takes the two in HEAVY.
## Every line is `[ablate] <district> <part> frame_p95_ms=<p95> gpu_ms=<mean> draw_calls=<n>`; the saving of a part is its line against the baselines around it. A reading, never a verdict.

const FRAMES: int = 200
const SETTLE_FRAMES: int = 20
const PARTS: Array[String] = ["lamp pools hidden", "lamp cones hidden", "window halos hidden", "post-process layers hidden", "HUD hidden"]
const HEAVY: Array[String] = ["fog cards hidden", "lamp pools hidden", "lamp cones hidden", "window halos hidden"]
const LAYERS: Array[String] = ["HUD", "PostProcessOverlay"]

var _baselines: Array[float] = []

func _run() -> void:
	if not await _boot():
		return
	var vsync: int = DisplayServer.window_get_vsync_mode()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	print("[ablate] window=%s msaa=%d tier=%d vsync_was=%d" % [get_window().size, get_viewport().msaa_3d, int(SettingsManager.get_setting("graphics_tier", 2)), vsync])
	await _full(&"suburbs")
	await _sweep("suburbs", PARTS)
	for layer in LAYERS:
		await _children_sweep("suburbs", layer)
	_apply("msaa off", true)
	await _measure("suburbs", "msaa off")
	if not await _travel(&"power_station"):
		return
	await _full(&"power_station")
	await _sweep("power_station", HEAVY)
	print("[ablate] DONE baselines %s least %.2f ms" % [_baselines, _baselines.min()])
	get_tree().quit(0)

func _sweep(district: String, parts: Array[String]) -> void:
	await _measure(district, "baseline")
	await _shot(district, "baseline")
	for part in parts:
		_apply(part, true)
		await _measure(district, part)
		await _shot(district, part)
		_apply(part, false)
		await _measure(district, "baseline")

## Every child of a main-scene layer that is visible is switched off alone, the baseline after each.
func _children_sweep(district: String, layer: String) -> void:
	for child: Node in get_tree().root.get_node("Main3D").get_node(layer).get_children():
		var item := child as CanvasItem
		if item == null or not item.visible:
			continue
		item.visible = false
		await _measure(district, "%s/%s" % [layer, child.name])
		item.visible = true
		await _measure(district, "baseline")

## One frame for the eye, in .qa_logs (not evidence: the stills of the pass are taken by the frame tools).
func _shot(district: String, part: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://.qa_logs/ablate_%s_%s.png" % [district, part.replace(" ", "_")]))

## Switches one part off (`off` true) or puts it back.
func _apply(part: String, off: bool) -> void:
	var main := get_tree().root.get_node("Main3D")
	match part:
		"fog cards hidden":
			for card in get_tree().root.find_children("FogCard*", "MeshInstance3D", true, false):
				(card as MeshInstance3D).visible = not off
		"lamp pools hidden":
			(get_tree().root.find_child("LampPools", true, false) as Node3D).visible = not off
		"lamp cones hidden":
			(get_tree().root.find_child("LampCones", true, false) as Node3D).visible = not off
		"window halos hidden":
			(get_tree().root.find_child("WindowHalos", true, false) as Node3D).visible = not off
		"post-process layers hidden":
			(main.get_node("PostProcessOverlay") as CanvasLayer).visible = not off
		"HUD hidden":
			(main.get_node("HUD") as CanvasLayer).visible = not off
		"msaa off":
			get_viewport().msaa_3d = Viewport.MSAA_DISABLED if off else Viewport.MSAA_4X

## The district at FULL power, where its lamps, their cones and its lit panes are all drawn (the perf gate measures the stage that a new game spawns in, and a part that a lower stage hides costs nothing there).
func _full(id: StringName) -> void:
	for parent in PowerGrid.get_district(id).powered_by:
		PowerGrid.get_district(parent).stage = DistrictData.Stage.FULL
	PowerGrid.advance_district(id, DistrictData.Stage.FULL)
	for i in 120:
		await get_tree().process_frame
	print("[ablate] %s power stage %d" % [id, PowerGrid.get_stage(id)])

## To the first frame of play, as the perf gate does.
func _boot() -> bool:
	await get_tree().create_timer(1.0).timeout
	if not _menu_reachable():
		Routes.goto(Routes.MENU)
	if not await _wait_until(_menu_reachable, 12.0):
		printerr("[ablate] menu never reachable")
		get_tree().quit(1)
		return false
	SaveSystem.mark_onboard_done()
	QualityManager.enabled = false  # a measurement reads one tier: the quality manager steps it under 30 FPS (CORRECTION_LOG 241)
	Routes.start_game()
	if not await _wait_until(func() -> bool: return GameManager.is_playing() and get_tree().get_first_node_in_group("player") != null, 20.0):
		printerr("[ablate] never reached gameplay")
		get_tree().quit(1)
		return false
	TutorialSystem.call("_skip_tutorial")
	for i in 60:
		await get_tree().process_frame
	return true

## Straight to a district, as the perf gate does for its D11 (QA only; the profile guard restores the save).
func _travel(id: StringName) -> bool:
	var wr := get_tree().root.find_child("WorldRuntime", true, false)
	DistrictManager.current_district = id
	EventBus.district_entered.emit(id)
	if not await _wait_until(func() -> bool: return wr._current_id == id and not wr._loading, 20.0):
		printerr("[ablate] %s never loaded" % id)
		get_tree().quit(1)
		return false
	for i in 60:
		await get_tree().process_frame
	return true

## The p95 of the frame time and the mean GPU time over FRAMES frames, after SETTLE_FRAMES to let the change take hold.
func _measure(district: String, part: String) -> void:
	for i in SETTLE_FRAMES:
		await get_tree().process_frame
	var vp := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	var ms: Array[float] = []
	var gpu: float = 0.0
	for i in FRAMES:
		await get_tree().process_frame
		ms.append(get_process_delta_time() * 1000.0)
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
	ms.sort()
	var p95: float = ms[int(float(ms.size()) * 0.95)]
	if part == "baseline":
		_baselines.append(p95)
	print("[ablate] %s %s frame_p95_ms=%.2f gpu_ms=%.2f draw_calls=%d" % [district, part, p95, gpu / float(FRAMES), _calls()])
