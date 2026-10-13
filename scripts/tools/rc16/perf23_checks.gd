extends RefCounted
## Session 23 (docs/PERF_PASS.md): dynamic resolution, the quality manager, the shader warm-up, the edges of the perf gate's budgets, the loot a killed monster leaves and the samples of the 3D by tier. Wired into _closeout_check_runner.gd as
## `await Rc23Perf.run(self)`; CLOSEOUT_ONLY=s23 runs it with the others. The viewport's scale and the settings a check touches are put back.

const _Dynamic := preload("res://scripts/systems/dynamic_resolution.gd")
const _Gate := preload("res://scripts/tools/_perf_check_runner.gd")

static func run(r: Node) -> void:
	r._playing()
	_dynamic_resolution(r)
	_quality_manager(r)
	await _warm_up(r)
	_gate_edges(r)
	_loot_stays_with_district(r)
	_msaa_follows_tier(r)

## PERF1: under 30 FPS for 2 s the 3D scale drops to 70 % of Render Scale; in the band between 30 and 45 nothing moves; over 45 FPS for 4 s it comes back.
static func _dynamic_resolution(r: Node) -> void:
	var viewport: Viewport = r.get_viewport()
	var scale0: float = viewport.scaling_3d_scale
	var on0: Variant = SettingsManager.get_setting("dynamic_resolution", false)
	var render0: Variant = SettingsManager.get_setting("render_scale", 1.0)
	SettingsManager.set_setting("dynamic_resolution", true)
	SettingsManager.set_setting("render_scale", 1.0)
	viewport.scaling_3d_scale = 1.0
	var node: Node = _Dynamic.new()
	r.add_child(node)
	for i in 3:
		node.call("step", 25.0, 0.5)
	var early: bool = not bool(node.get("dropped")) and is_equal_approx(viewport.scaling_3d_scale, 1.0)
	node.call("step", 25.0, 0.5)
	var dropped: bool = bool(node.get("dropped")) and is_equal_approx(viewport.scaling_3d_scale, 0.7)
	for i in 10:
		node.call("step", 38.0, 0.5)
	var band: bool = bool(node.get("dropped")) and is_equal_approx(viewport.scaling_3d_scale, 0.7)
	for i in 7:
		node.call("step", 50.0, 0.5)
	var slow: bool = bool(node.get("dropped"))
	node.call("step", 50.0, 0.5)
	var recovered: bool = not bool(node.get("dropped")) and is_equal_approx(viewport.scaling_3d_scale, 1.0)
	for i in 4:
		node.call("step", 25.0, 0.5)
	for i in 6:
		node.call("step", 50.0, 0.5)
	node.call("step", 35.0, 0.5)  # the band: the count towards a recovery starts again
	for i in 7:
		node.call("step", 50.0, 0.5)
	var restarted: bool = bool(node.get("dropped"))
	node.call("step", 50.0, 0.5)
	var again: bool = not bool(node.get("dropped"))
	node.queue_free()
	viewport.scaling_3d_scale = scale0
	SettingsManager.set_setting("dynamic_resolution", on0)
	SettingsManager.set_setting("render_scale", render0)
	r._ok(early and dropped and band and slow and recovered and restarted and again, "PERF1 dynamic resolution: 1.5 s under 30 FPS keeps 1.0 (%s), 2 s drops to 0.7 (%s), the band holds it (%s), 3.5 s over 45 FPS holds (%s) and 4 s restores 1.0 (%s); a dip into the band restarts the count (%s, then %s)" % [early, dropped, band, slow, recovered, restarted, again])

## PERF2: the screen shaders are drawn once as an identity at the start and put back as they were.
static func _warm_up(r: Node) -> void:
	var overlay: Node = r._main.get_node("PostProcessOverlay")
	var names: Array[String] = ["MotionBlurOverlay", "ChromaOverlay", "RainLens"]
	var before: Array[bool] = []
	for layer_name: String in names:
		var layer := _find(overlay, layer_name)
		before.append(layer != null and layer.visible)
	await overlay.call("_warm_shaders")
	var after: Array[bool] = []
	var found: int = 0
	for layer_name: String in names:
		var layer := _find(overlay, layer_name)
		found += 1 if layer != null else 0
		after.append(layer != null and layer.visible)
	r._ok(found == 3 and before == after, "PERF2 shader warm-up: the blur, chroma and rain-lens layers are found (%d) and visible as before (%s then %s)" % [found, before, after])

static func _find(overlay: Node, layer_name: String) -> CanvasItem:
	return overlay.get_node_or_null(layer_name) as CanvasItem

## PERF3: the perf gate fails at every edge: D1 at 200 draw calls (199 passes), D11 at 350, a p95 over 33 ms, a video memory over 512 MiB.
static func _gate_edges(r: Node) -> void:
	var ok: bool = _Gate.failures(199, 349, 33.0, 33.0, 512.0).is_empty()
	var d1: bool = _Gate.failures(200, 349, 20.0, 20.0, 100.0) == ["D1 draw calls"]
	var d11: bool = _Gate.failures(142, 350, 20.0, 20.0, 100.0) == ["D11 draw calls"]
	var p95: bool = _Gate.failures(142, 129, 20.0, 33.1, 100.0) == ["p95 frame time"]
	var vram: bool = _Gate.failures(142, 129, 20.0, 20.0, 512.1) == ["video memory"]
	var measured: bool = _Gate.failures(142, 129, 28.79, 23.61, 155.8).is_empty()  # the numbers of Session 22
	r._ok(ok and d1 and d11 and p95 and vram and measured, "PERF3 perf gate edges: all met at the limits (%s), D1 200 fails (%s), D11 350 fails (%s), p95 33.1 ms fails (%s), 512.1 MiB fails (%s), Session 22's numbers pass (%s)" % [ok, d1, d11, p95, vram, measured])

## LEAK1: what a monster drops lies beside it, so the district that held the monster frees the drop with itself (under the scene root the soak's node count grew by a stale drop per kill, 533 nodes in two hours).
static func _loot_stays_with_district(r: Node) -> void:
	var tree: SceneTree = r.get_tree()
	var before: int = tree.get_nodes_in_group("pickups").size()
	var holder := Node3D.new()
	r.add_child(holder)
	var monster: Node3D = r._monster("crawler_3d")
	monster.reparent(holder)
	for i in 60:
		monster.call("_maybe_drop_loot")
	var beside: int = 0
	for pickup: Node in tree.get_nodes_in_group("pickups"):
		beside += 1 if pickup.get_parent() == holder else 0
	holder.free()
	var left: int = tree.get_nodes_in_group("pickups").size() - before
	r._ok(beside > 0 and left == 0, "LEAK1 loot: %d drops of 60 rolls lie beside the monster, %d are left once its parent is freed" % [beside, left])

## MSAA1: the samples of the 3D follow the tier, off at Low, 2x at Medium and High, 4x at Ultra (the ablation of Session 23 read the 4x at 5.5 to 9 ms of a 19 ms GPU frame of the High tier on the dev iGPU).
static func _msaa_follows_tier(r: Node) -> void:
	var viewport: Viewport = r.get_viewport()
	var tier0: int = int(SettingsManager.get_setting("graphics_tier", 2))
	var modes: Array[int] = []
	for tier in 4:
		SettingsManager.set_graphics_tier(tier)
		modes.append(viewport.msaa_3d)
	SettingsManager.set_graphics_tier(tier0)
	r._ok(modes == [0, 1, 1, 2], "MSAA1 the 3D samples follow the tier: Low, Medium, High, Ultra read %s (off, 2x, 2x, 4x)" % [modes])

static func _tier() -> int:
	return int(SettingsManager.get_setting("graphics_tier", 2))

static func _feed(qm: Node, fps: float, seconds: float) -> void:
	for i in int(seconds * 2.0):
		qm.call("step", fps, 0.5)

## The seconds the readings need to bring the tier to `target`, or -1.0 when it is not there after `limit` seconds.
static func _until(qm: Node, fps: float, limit: float, target: int) -> float:
	var t: float = 0.0
	while _tier() != target and t < limit:
		qm.call("step", fps, 0.5)
		t += 0.5
	return t if _tier() == target else -1.0

## QM1 to QM4 (CORRECTION_LOG 241): the quality manager of T17, stepped with fake readings (the real one's own frames are paused for the check). QM1: 5 s under 30 FPS drops the tier, and under the 30 FPS cap of Low and Medium
## a reading of 29.5, the most that cap gives, neither drops it again nor keeps it down: the tier is raised after the wait, and never above the player's own. QM2: the wait grows with each drop. QM3: the tier the player chose is kept
## apart from the one the manager applied. QM4: and follows the player's own change.
static func _quality_manager(r: Node) -> void:
	var qm: Node = r.get_node("/root/QualityManager")
	var tier0: int = _tier()
	qm.set_process(false)
	SettingsManager.set_graphics_tier(2)
	_feed(qm, 24.0, 4.5)
	var early: bool = _tier() == 2
	_feed(qm, 24.0, 0.5)
	var dropped: bool = _tier() == 1 and Engine.max_fps == 30
	_feed(qm, 29.5, 15.0)
	var held: bool = _tier() == 1
	var first: float = _until(qm, 29.5, 60.0, 2)
	var raised: bool = first > 0.0 and Engine.max_fps == 60
	_feed(qm, 60.0, 60.0)
	var capped: bool = _tier() == 2
	r._ok(early and dropped and held and raised and capped, "QM1 quality manager: 4.5 s at 24 FPS keeps the tier (%s), 5 s drops it to 1 with the 30 FPS cap (%s), 15 s at 29.5 FPS neither drop it again nor raise it (%s), the raise comes (%s) with the 60 FPS cap, and a minute at 60 FPS goes no higher than the player's tier (%s)" % [early, dropped, held, raised, capped])
	SettingsManager.set_graphics_tier(2)
	_feed(qm, 24.0, 5.0)
	var one: float = _until(qm, 29.5, 700.0, 2)
	_feed(qm, 24.0, 5.0)
	var two: float = _until(qm, 29.5, 700.0, 2)
	r._ok(one > 0.0 and two > one, "QM2 quality manager: the wait before a raise is %s s after the first drop and %s s after the second" % [one, two])
	SettingsManager.set_graphics_tier(2)
	SettingsManager.set_setting("graphics_ceiling", -1)
	_feed(qm, 24.0, 5.0)
	var kept: int = int(SettingsManager.get_setting("graphics_ceiling", -1))
	r._ok(kept == 2 and _tier() == 1, "QM3 quality manager: after a drop to tier %d the saved ceiling is %d (the player's 2)" % [_tier(), kept])
	SettingsManager.set_setting("graphics_ceiling", -1)
	SettingsManager.set_graphics_tier(1)
	var chosen: int = int(SettingsManager.get_setting("graphics_ceiling", -1))
	r._ok(chosen == 1, "QM4 quality manager: the player's own change to tier 1 is saved as the ceiling (%d)" % chosen)
	SettingsManager.set_graphics_tier(tier0)
	qm.set_process(true)
