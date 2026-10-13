extends "res://scripts/tools/_perf_check_runner.gd"
## Where the frame time goes (docs/PERF_PASS.md, Session 23). One windowed run, tools/qa_sim/guarded_windowed res://scenes/tools/perf_ablation_scene.tscn: a view is measured as it stands, then with one
## part of the frame switched off at a time, the baseline between each pair so the drift of a shared machine shows. The suburbs (the spawn view) take every part in PARTS; the power station (the D11
## of the perf gate, a district with ground fog) takes the three in HEAVY. Every line is `[ablate] <district> <part> frame_p95_ms=<p95> gpu_ms=<mean> draw_calls=<n>`; the saving of a part is its
## line against the baselines around it. A reading, never a verdict.

const FRAMES: int = 300
const SETTLE_FRAMES: int = 20
const PARTS: Array[String] = ["dressing hidden", "post-process layers hidden", "HUD hidden", "glow off", "moon shadows off", "flashlight shadows off", "msaa off", "ash hidden", "3d scale 0.7", "window 1280x720"]
const HEAVY: Array[String] = ["fog cards hidden", "dressing hidden", "post-process layers hidden"]

var _baselines: Array[float] = []
var _window: Vector2i = Vector2i.ZERO

func _run() -> void:
	if not await _boot():
		return
	_window = get_window().size
	print("[ablate] window=%s msaa=%d tier=%d" % [_window, get_viewport().msaa_3d, int(SettingsManager.get_setting("graphics_tier", 2))])
	await _sweep("suburbs", PARTS)
	if not await _travel(&"power_station"):
		return
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
		"dressing hidden":
			(get_tree().root.find_child("DistrictDressing", true, false) as Node3D).visible = not off
		"post-process layers hidden":
			(main.get_node("PostProcessOverlay") as CanvasLayer).visible = not off
		"HUD hidden":
			(main.get_node("HUD") as CanvasLayer).visible = not off
		"glow off":
			((main.get_node("WorldEnvironment") as WorldEnvironment).environment).glow_enabled = not off
		"moon shadows off":
			(main.get_node("Moon") as DirectionalLight3D).shadow_enabled = not off
		"flashlight shadows off":
			for node in get_tree().root.find_children("*", "SpotLight3D", true, false):
				(node as SpotLight3D).shadow_enabled = not off
		"msaa off":
			get_viewport().msaa_3d = Viewport.MSAA_DISABLED if off else Viewport.MSAA_4X
		"ash hidden":
			(main.get_node("Ash") as GPUParticles3D).visible = not off
		"3d scale 0.7":
			get_viewport().scaling_3d_scale = 0.7 if off else 1.0
		"window 1280x720":
			get_window().size = Vector2i(1280, 720) if off else _window

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
