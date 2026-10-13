extends "res://scripts/tools/_rc16_probe_runner.gd"
## Soak and stress runs (tools/qa_sim/soak <mode> <hash> [minutes]; docs/LONG_SESSION_TEST.md, docs/THERMAL_TEST.md, docs/MEMORY_TEST.md, docs/STRESS_TEST.md). One process, windowed:
##   soak    a cycle of about 60 s over and over: a district change as the game makes it, four monsters near the player that are shot dead, the inventory, the map and the pause screen
##           opened and closed, the flashlight on and off, a walk; once a minute one `[soak] minute` line (frame time mean, p95, p99, max and the frames over 50 ms of that minute, the engine's
##           static memory, the object, node and orphan counts, the video and texture memory), once every ten minutes a save and a load. The end prints `[soak] SUMMARY` with the growth of each
##           number from its first five minutes to its last five.
##   stress  120 monsters (--tmonsters=N) in a ring of 10 to 40 m round the player for 45 s, their AI running: the frame time, how many of them moved, and a clean exit.
## The mode and the length are user args (--tmode=, --tminutes=); the hash goes into the log only. A number printed here is a reading, never a verdict: the documents judge.

const CYCLE_SEC: float = 60.0
const MONSTERS_PER_CYCLE: int = 4
const SAVE_EVERY_MIN: int = 10
const STRESS_SEC: float = 45.0
const FIRST_LAST_MIN: int = 5
const MONSTER_SCENES: Array[String] = ["crawler_3d", "shadow_3d", "hound_3d", "rotter_3d"]
const SCREENS: Array[StringName] = [&"inventory", &"city_map", &"pause"]

var _mode: String = "soak"
var _minutes: int = 120
var _monsters: int = 120
var _deltas: Array[float] = []
var _rows: Array[Dictionary] = []
var _sampling: bool = false
var _sampled_at_ms: int = 0

## The frame times of the run, and one reading a minute once the soak has begun.
func _process(delta: float) -> void:
	super._process(delta)
	_deltas.append(delta * 1000.0)
	if _sampling and Time.get_ticks_msec() - _sampled_at_ms >= 60000:
		_sampled_at_ms += 60000
		_sample(_rows.size() + 1)

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("[soak] SKIP headless - frames need a real display")
		get_tree().quit(3)
		return
	for a in OS.get_cmdline_user_args():
		var s := String(a)
		if s.begins_with("--tmode="):
			_mode = s.substr(8)
		elif s.begins_with("--tminutes="):
			_minutes = int(s.substr(11))
		elif s.begins_with("--tmonsters="):
			_monsters = int(s.substr(12))
		elif s.begins_with("--thash="):
			_hash = s.substr(8)
	var ads := get_node_or_null("/root/AdService")
	if ads:
		ads.enabled = false
	QualityManager.enabled = false  # a measurement reads one tier: the quality manager steps it under 30 FPS (CORRECTION_LOG 241)
	if not await _boot():
		return
	print("[soak] start mode=%s minutes=%d hash=%s tier=%d cap=%d %s" % [_mode, _minutes, _hash, int(SettingsManager.get_setting("graphics_tier", -1)), Engine.max_fps, _mem()])
	if _mode == "stress":
		await _stress()
	else:
		await _soak()
	get_tree().quit(0)

## To the first frame of play, as the probe does.
func _boot() -> bool:
	var menu_up := func() -> bool:
		var cs := get_tree().current_scene
		return cs != null and cs.scene_file_path == Routes.MENU
	if not await _wait_until(menu_up, 15.0):
		Routes.goto(Routes.MENU)
		if not await _wait_until(menu_up, 10.0):
			_fail("main menu never came up")
			return false
	get_window().size = WINDOW_SIZE
	await get_tree().create_timer(1.0).timeout
	SaveSystem.mark_onboard_done()
	Routes.start_game()
	var playing := func() -> bool: return GameManager.is_playing() and get_tree().get_first_node_in_group("player") != null
	if not await _wait_until(playing, 20.0):
		_fail("never reached gameplay")
		return false
	LocalizationManager.set_language("en")
	TutorialSystem.call("_skip_tutorial")
	await get_tree().create_timer(3.0).timeout
	return true

func _soak() -> void:
	var started: int = Time.get_ticks_msec()
	var cycle: int = 0
	var saved_at: int = 0
	_deltas.clear()
	_sampled_at_ms = started
	_sampling = true
	while _rows.size() < _minutes:
		var begun: int = Time.get_ticks_msec()
		await _transition(ORDER[cycle % ORDER.size()], "soak")
		await _activity()
		cycle += 1
		if _rows.size() >= saved_at + SAVE_EVERY_MIN:
			saved_at = _rows.size()
			SaveSystem.save_all()
			SaveSystem.load_all()
		var rest: float = CYCLE_SEC - float(Time.get_ticks_msec() - begun) / 1000.0
		if rest > 0.0:
			await get_tree().create_timer(rest).timeout
	_sampling = false
	_summary()

## About 40 s of play: monsters shot, screens opened, the light switched, a walk.
func _activity() -> void:
	var player := _player_node()
	if player == null:
		return
	player.heal(1000.0)
	var bodies: Array[Node3D] = []
	for i in MONSTERS_PER_CYCLE:
		var scene := load("res://scenes/enemies/%s.tscn" % MONSTER_SCENES[i % MONSTER_SCENES.size()]) as PackedScene
		var m := scene.instantiate() as Node3D
		(_runtime().get("_district_root") as Node).add_child(m)  # where the game keeps its monsters: the district frees them and their drops
		m.set("player_ref", player)
		m.global_position = player.global_position + Vector3(6.0 + 2.0 * float(i), 0.0, 4.0)
		bodies.append(m)
	await get_tree().create_timer(4.0).timeout
	for m in bodies:
		if is_instance_valid(m) and m.has_method("take_damage"):
			m.take_damage(9999.0, player.global_position, EnemyRosterData.DamageType.BULLET)
	await get_tree().create_timer(2.0).timeout
	for screen in SCREENS:
		UIManager.open(screen)
		await get_tree().create_timer(1.5).timeout
		UIManager.close(screen)
		await get_tree().create_timer(0.4).timeout
	UIManager.close_all_blocking()
	_flashlight_toggle(player)
	InputService.set_joy_active(true)
	InputService.set_joy_move_dir(Vector2(0.0, -1.0))
	await get_tree().create_timer(6.0).timeout
	InputService.set_joy_move_dir(Vector2.ZERO)
	InputService.set_joy_active(false)
	_flashlight_toggle(player)
	for m in bodies:
		if is_instance_valid(m):
			m.queue_free()

func _flashlight_toggle(player: Node3D) -> void:
	if player.has_method("toggle_flashlight"):
		player.toggle_flashlight()

func _percentile(sorted_ms: Array[float], q: float) -> float:
	return sorted_ms[mini(int(float(sorted_ms.size()) * q), sorted_ms.size() - 1)] if not sorted_ms.is_empty() else 0.0

## One reading: the frame times since the last one, and the engine's memory and counts.
func _sample(minute: int) -> void:
	var ms: Array[float] = _deltas.duplicate()
	_deltas.clear()
	ms.sort()
	var mean: float = 0.0
	var over: int = 0
	for v in ms:
		mean += v
		over += 1 if v > 50.0 else 0
	mean /= maxf(1.0, float(ms.size()))
	var row := {
		"minute": minute, "mean_ms": mean, "p95_ms": _percentile(ms, 0.95), "p99_ms": _percentile(ms, 0.99), "max_ms": ms[-1] if not ms.is_empty() else 0.0, "over50": over, "frames": ms.size(),
		"static_mib": float(OS.get_static_memory_usage()) / MIB, "objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)), "nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"orphans": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), "video_mib": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / MIB,
		"texture_mib": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / MIB,
	}
	_rows.append(row)
	print("[soak] minute=%d frames=%d mean_ms=%.2f p95_ms=%.2f p99_ms=%.2f max_ms=%.1f over50=%d static_mib=%.1f objects=%d nodes=%d orphans=%d video_mib=%.1f texture_mib=%.1f" % [minute, row["frames"], row["mean_ms"], row["p95_ms"],
		row["p99_ms"], row["max_ms"], row["over50"], row["static_mib"], row["objects"], row["nodes"], row["orphans"], row["video_mib"], row["texture_mib"]])

func _median(key: String, from: int, to: int) -> float:
	var values: Array[float] = []
	for i in range(from, to):
		values.append(float(_rows[i][key]))
	values.sort()
	return values[values.size() / 2] if not values.is_empty() else 0.0

## The growth of each number from the median of the first five minutes to the median of the last five.
func _summary() -> void:
	var n: int = _rows.size()
	if n < 2 * FIRST_LAST_MIN:
		print("[soak] SUMMARY too short: %d minute(s), %d needed" % [n, 2 * FIRST_LAST_MIN])
		return
	var parts: Array[String] = []
	for key: String in ["static_mib", "objects", "nodes", "orphans", "video_mib", "texture_mib", "p95_ms", "mean_ms"]:
		var first: float = _median(key, 0, FIRST_LAST_MIN)
		var last: float = _median(key, n - FIRST_LAST_MIN, n)
		parts.append("%s=%.2f->%.2f(%+.2f)" % [key, first, last, last - first])
	var worst: float = 0.0
	var slow: int = 0
	for row in _rows:
		worst = maxf(worst, float(row["max_ms"]))
		slow += int(row["over50"])
	print("[soak] SUMMARY minutes=%d %s worst_frame_ms=%.1f frames_over_50ms=%d" % [n, " ".join(parts), worst, slow])

func _stress() -> void:
	var player := _player_node()
	player.heal(100000.0)
	var made: Array[Node3D] = []
	var start: Array[Vector3] = []
	for i in _monsters:
		var scene := load("res://scenes/enemies/%s.tscn" % MONSTER_SCENES[i % MONSTER_SCENES.size()]) as PackedScene
		var m := scene.instantiate() as Node3D
		get_tree().current_scene.add_child(m)
		m.set("player_ref", player)
		var angle: float = TAU * float(i) / float(_monsters)
		m.global_position = player.global_position + Vector3(cos(angle), 0.0, sin(angle)) * (10.0 + 30.0 * float(i % 7) / 6.0)
		made.append(m)
		start.append(m.global_position)
	_deltas.clear()
	await get_tree().create_timer(STRESS_SEC).timeout
	var ms: Array[float] = _deltas.duplicate()
	ms.sort()
	var mean: float = 0.0
	for v in ms:
		mean += v
	mean /= maxf(1.0, float(ms.size()))
	var moved: int = 0
	for i in made.size():
		if is_instance_valid(made[i]) and made[i].global_position.distance_to(start[i]) > 0.5:
			moved += 1
	print("[stress] monsters=%d alive=%d moved=%d frames=%d mean_ms=%.2f p95_ms=%.2f p99_ms=%.2f max_ms=%.1f fps_mean=%.1f over50=%d %s" % [made.size(), made.filter(func(m: Node3D) -> bool: return is_instance_valid(m)).size(), moved,
		ms.size(), mean, _percentile(ms, 0.95), _percentile(ms, 0.99), ms[-1] if not ms.is_empty() else 0.0, 1000.0 / maxf(mean, 0.001), ms.filter(func(v: float) -> bool: return v > 50.0).size(), _mem()])
	for m in made:
		if is_instance_valid(m):
			m.queue_free()
	await get_tree().create_timer(2.0).timeout
	print("[stress] DONE clean exit follows %s" % _mem())
