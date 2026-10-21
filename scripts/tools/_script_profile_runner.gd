extends "res://scripts/tools/_perf_ablation_runner.gd"
## R2 of the v10 pass: where the script time of a frame goes, per script, in the suburbs and in the power station at FULL power. Every node whose script has a live `_process` (or `_physics_process`) is taken off the tree's own
## calls and called from here instead, each call timed in microseconds, so the cost of a script is its own and not the wait of the frame for the GPU (the TIME_PROCESS monitor is the whole frame, wait included: Session 28 read it
## as script time). The tier is TLS_PERF_TIER (Low by default); the vertical sync and the frame cap are off. Windowed: tools/qa_sim/guarded_windowed res://scenes/tools/script_profile_scene.tscn 300
## Lines: `[profile] <district> <process|physics> mean_us=<mean of the frame> p99_us=<p99> max_us=<worst> nodes=<n> <script>`, then the total and the mean frame time of the same frames.

const SAMPLE_FRAMES: int = 300
const TOP: int = 18

var _entries: Array[Dictionary] = []
var _frames: Dictionary = {}
var _taken: int = 0
var _sampling: bool = false

func _run() -> void:
	if not await _boot():
		return
	SettingsManager.set_graphics_tier(int(OS.get_environment("TLS_PERF_TIER")) if OS.has_environment("TLS_PERF_TIER") else 0)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	await _full(&"suburbs")
	await _profile("suburbs")
	if not await _travel(&"power_station"):
		return
	await _full(&"power_station")
	await _profile("power_station")
	print("[profile] DONE tier=%d" % int(SettingsManager.get_setting("graphics_tier", 2)))
	get_tree().quit(0)

func _profile(district: String) -> void:
	_entries.clear()
	_frames.clear()
	_taken = 0
	for node: Node in get_tree().root.find_children("*", "", true, false):
		if node == self or node.get_script() == null:
			continue
		var path: String = (node.get_script() as Script).resource_path
		if node.is_processing():
			node.set_process(false)
			_entries.append({"node": node, "path": path, "kind": "process"})
		if node.is_physics_processing():
			node.set_physics_process(false)
			_entries.append({"node": node, "path": path, "kind": "physics"})
	var started: int = Time.get_ticks_usec()
	_sampling = true
	while _taken < SAMPLE_FRAMES:
		await get_tree().process_frame
	_sampling = false
	var wall_ms: float = float(Time.get_ticks_usec() - started) / 1000.0 / float(_taken)
	for entry in _entries:
		if is_instance_valid(entry["node"]):
			if entry["kind"] == "process":
				(entry["node"] as Node).set_process(true)
			else:
				(entry["node"] as Node).set_physics_process(true)
	var rows: Array[Dictionary] = []
	var total: float = 0.0
	for key: String in _frames:
		var per_frame: PackedFloat64Array = _frames[key]
		var sorted: Array = Array(per_frame)
		sorted.sort()
		var mean: float = 0.0
		for us in per_frame:
			mean += us
		mean /= float(maxi(per_frame.size(), 1))
		var nodes: int = 0
		for entry in _entries:
			nodes += 1 if "%s|%s" % [entry["kind"], entry["path"]] == key else 0
		rows.append({"key": key, "mean": mean, "p99": sorted[int(float(sorted.size()) * 0.99)] if not sorted.is_empty() else 0.0, "max": sorted.back() if not sorted.is_empty() else 0.0, "nodes": nodes})
		total += mean if key.begins_with("process") else 0.0
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["mean"] > b["mean"])
	for i in mini(TOP, rows.size()):
		var row: Dictionary = rows[i]
		var parts: PackedStringArray = String(row["key"]).split("|")
		print("[profile] %s %s mean_us=%.1f p99_us=%.1f max_us=%.1f nodes=%d %s" % [district, parts[0], row["mean"], row["p99"], row["max"], row["nodes"], parts[1]])
	print("[profile] %s all scripts' _process: %.1f us a frame; the frame took %.2f ms on the wall; %d script nodes handed over" % [district, total, wall_ms, _entries.size()])

func _process(delta: float) -> void:
	if not _sampling:
		return
	_taken += 1
	for entry in _entries:
		if entry["kind"] != "process" or not is_instance_valid(entry["node"]):
			continue
		var t0: int = Time.get_ticks_usec()
		(entry["node"] as Node).call("_process", delta)
		_add("process|" + String(entry["path"]), float(Time.get_ticks_usec() - t0))

func _physics_process(delta: float) -> void:
	if not _sampling:
		return
	for entry in _entries:
		if entry["kind"] != "physics" or not is_instance_valid(entry["node"]):
			continue
		var t0: int = Time.get_ticks_usec()
		(entry["node"] as Node).call("_physics_process", delta)
		_add("physics|" + String(entry["path"]), float(Time.get_ticks_usec() - t0))

## The microseconds a script spent in this frame (the calls of all its nodes added); a frame is one slot of the script's list.
func _add(key: String, us: float) -> void:
	if not _frames.has(key):
		_frames[key] = PackedFloat64Array()
	var list: PackedFloat64Array = _frames[key]
	if list.size() < _taken:
		list.resize(_taken)
		_frames[key] = list
	list[_taken - 1] += us
