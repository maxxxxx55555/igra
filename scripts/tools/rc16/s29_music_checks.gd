extends RefCounted
## Session 29 (the v10.0.0-ship pass), M3 and M4: the layer system of the music manager proved by a probe, not assumed (Session 27 had caught one such lie: the boss phase signal was declared and listened to and never emitted).
## LAY1 a monster at 25, 15, 8 and 3 m drives the stems: calm alone at 25 m, the tense stem up at 15 m, the combat stems and the action stem at 8 and 3 m. LAY2 the hunted level rises to 1 in under a second and falls back in
## four, and the volumes of the stems follow it (the combat stem up by 30 dB or more, the calm one down by 5 to 7). LAY3 the three phases of the Architect play their own theme. LAY4 the combat hold lasts CALM_DELAY, 6 s, and
## the mood goes back to the calm one after it. LAY5 a new mood swaps the A and B players. LAY6 rain and storm raise the rain stem, wind the wind stem, clear weather neither (M3: they were a comment and no code).
## ONE1 to ONE4 (M6): the four one-shots that the recipe named and no take supplied exist (2 s, 8 s, 0.06 s, 0.3 s) and are played at their triggers: the sting of a restored district by UISFX on district_restored, the cue of a death by
## the MusicManager on game_over, the tick of the XP on xp_gained and the soft note when a healing consumable is used (the signal is connected and the call it makes starts a player of the file on the bus).
## The autoload's own process is stopped while the probe drives it by steps of 0.1 s, so the numbers are the manager's own and not the frame times of the machine. Wired into _closeout_check_runner.gd.

const STEP: float = 0.1

static func run(r: Node) -> void:
	r._playing()
	var mm: Node = r.get_tree().root.get_node_or_null("MusicManager")
	var player: Node3D = r.get_tree().get_first_node_in_group("player") as Node3D
	if mm == null or player == null:
		r._ok(false, "LAY1 the MusicManager and a player exist")
		return
	var saved: Dictionary = {"threat": mm.get("_threat"), "hold": mm.get("_combat_hold"), "weather": mm.get("_weather_id"), "mood": mm.get("mood"), "boss": mm.get("_boss_active"), "phase": mm.get("_boss_phase"), "targets": (mm.get("_layer_target") as Dictionary).duplicate()}
	mm.set_process(false)
	var hunters: Array = []  # the monsters of the world leave the count while the probe places its own (the nearest of them, 13 m away in the first run, set the hunted level of every case)
	for monster: Node in r.get_tree().get_nodes_in_group("enemies"):
		hunters.append(monster)
		monster.remove_from_group("enemies")
	_stems(r, mm, player)
	_rise_fall(r, mm, player)
	_boss(r, mm)
	_hold(r, mm)
	_swap(r, mm)
	_weather(r, mm)
	_one_shots(r, mm)
	for monster in hunters:
		if is_instance_valid(monster):
			(monster as Node).add_to_group("enemies")
	mm.set("_threat", saved["threat"])
	mm.set("_combat_hold", saved["hold"])
	mm.set("_weather_id", saved["weather"])
	mm.set("mood", saved["mood"])
	mm.set("_boss_active", saved["boss"])
	mm.set("_boss_phase", saved["phase"])
	mm.set("_layer_target", saved["targets"])
	mm.set_process(true)

static func _monster(r: Node, player: Node3D, meters: float) -> Node3D:
	var monster := Node3D.new()
	r._main.add_child(monster)
	monster.add_to_group("enemies")
	monster.global_position = player.global_position + Vector3(meters, 0.0, 0.0)
	return monster

static func _steps(mm: Node, seconds: float) -> void:
	for _i in int(round(seconds / STEP)):
		mm.call("_tick_layers", STEP)

static func _clear(mm: Node) -> void:
	mm.set("_threat", 0.0)
	mm.set("_combat_hold", 0.0)
	mm.set("_weather_id", 0)

static func _target(mm: Node, stem: String) -> float:
	return float((mm.get("_layer_target") as Dictionary).get(stem, -1.0))

static func _calm(mm: Node) -> float:
	return maxf(_target(mm, "ambient_dark"), _target(mm, "ambient_lit"))

## A monster at 25 m: the calm stem only. At 15 m the tense stem is the strongest and the combat one has hardly begun. At 8 m and at 3 m the combat stems are up (the action stem with them: the mood is BATTLE) and the calm stem has given way by half.
static func _stems(r: Node, mm: Node, player: Node3D) -> void:
	var rows: PackedStringArray = []
	var ok: bool = true
	for meters in [25.0, 15.0, 8.0, 3.0]:
		_clear(mm)
		var monster := _monster(r, player, meters)
		mm.call("_evaluate")
		_steps(mm, 2.0)
		var low: float = _target(mm, "threat_low")
		var high: float = _target(mm, "threat_high")
		var action: float = _target(mm, "action")
		var calm: float = _calm(mm)
		rows.append("%.0f m: calm %.2f tense %.2f combat %.2f action %.2f" % [meters, calm, low, high, action])
		match int(meters):
			25:
				ok = ok and calm >= 0.99 and low <= 0.01 and high <= 0.01 and action <= 0.01
			15:
				ok = ok and low >= 0.5 and high <= 0.2 and action <= 0.01 and calm >= 0.9
			_:
				ok = ok and high >= 0.99 and action >= 0.99 and low <= 0.01 and calm <= 0.55
		monster.free()  # at once: no frame passes between the cases, and a monster waiting to be freed is still in the group
	_clear(mm)
	mm.call("_evaluate")
	r._ok(ok, "LAY1 the stems follow a monster at 25, 15, 8 and 3 m (%s)" % "; ".join(rows))

## From calm, a monster at 3 m: the hunted level is 1 within a second. Without it the level falls to 0 in four seconds (at 3 s it is still over 0.2). The volumes follow: the combat stem comes up by 30 dB or more, the calm stem goes down.
static func _rise_fall(r: Node, mm: Node, player: Node3D) -> void:
	_clear(mm)
	_steps(mm, 4.0)
	var calm_db: float = (mm.get("_layers")["ambient_dark"] as AudioStreamPlayer).volume_db + (mm.get("_layers")["ambient_lit"] as AudioStreamPlayer).volume_db
	var high_db0: float = (mm.get("_layers")["threat_high"] as AudioStreamPlayer).volume_db
	var monster := _monster(r, player, 3.0)
	_steps(mm, 1.0)
	var rose: float = float(mm.get("_threat"))
	_steps(mm, 3.0)
	var high_db1: float = (mm.get("_layers")["threat_high"] as AudioStreamPlayer).volume_db
	var calm_db1: float = (mm.get("_layers")["ambient_dark"] as AudioStreamPlayer).volume_db + (mm.get("_layers")["ambient_lit"] as AudioStreamPlayer).volume_db
	monster.free()
	_steps(mm, 3.0)
	var still: float = float(mm.get("_threat"))
	_steps(mm, 1.1)
	var fell: float = float(mm.get("_threat"))
	r._ok(rose >= 0.99 and still > 0.2 and fell <= 0.01, "LAY2 the hunted level reads %.2f one second after a monster comes to 3 m, %.2f three seconds after it goes and %.2f at four" % [rose, still, fell])
	r._ok(high_db1 - high_db0 >= 30.0 and calm_db1 < calm_db, "LAY2 the combat stem rises %.1f dB and the calm stems fall from %.1f to %.1f dB (sum of both beds)" % [high_db1 - high_db0, calm_db, calm_db1])

## Each phase of the Architect loads its own theme (the three files differ).
static func _boss(r: Node, mm: Node) -> void:
	var phases: Array = mm.get_script().get_script_constant_map()["BOSS_PHASES"]
	var paths: Array[String] = []
	mm.call("enter_boss")
	for phase in [1, 2, 3]:
		mm.call("_on_boss_phase_changed", phase)
		var stream: AudioStream = mm.call("_load", mm.get("mood"))
		paths.append(stream.resource_path if stream != null else "none")
	mm.call("_leave_boss")
	r._ok(paths.size() == 3 and paths[0] == phases[0] and paths[1] == phases[1] and paths[2] == phases[2] and paths[0] != paths[1] and paths[1] != paths[2], "LAY3 the three phases of the Architect play three themes (%s)" % ", ".join(PackedStringArray(paths)))

## A fight (a detection, a hit) holds the combat mood for CALM_DELAY: at 5.5 s it is still there, at 6.5 s the calm mood is back.
static func _hold(r: Node, mm: Node) -> void:
	var delay: float = float(mm.get_script().get_script_constant_map()["CALM_DELAY"])
	_clear(mm)
	mm.set("_combat_hold", delay)
	for _i in 11:
		mm.call("_process", 0.5)
	var held: bool = mm.call("is_in_combat") and int(mm.get("mood")) == int(MusicDirector.Mood.BATTLE)
	for _i in 2:
		mm.call("_process", 0.5)
	var released: bool = not mm.call("is_in_combat") and int(mm.get("mood")) == int(MusicDirector.Mood.AMBIENT)
	r._ok(is_equal_approx(delay, 6.0) and held and released, "LAY4 the combat hold lasts %.1f s: held at 5.5 s %s, released into the calm mood at 6.5 s %s" % [delay, held, released])

## With the audio unlocked a new mood goes to the other of the two players and the crossfade makes it the active one; the unlock is put back.
static func _swap(r: Node, mm: Node) -> void:
	var was: bool = mm.get("_audio_unlocked")
	mm.set("_audio_unlocked", true)
	var before: Object = mm.get("_active")
	mm.call("set_mood", MusicDirector.Mood.TENSION, false, true)
	var after: Object = mm.get("_active")
	mm.call("set_mood", MusicDirector.Mood.BATTLE, false, true)
	var back: Object = mm.get("_active")
	var swapped: bool = before != after and after != back and back == before and (after as AudioStreamPlayer).stream != null
	var fade: Variant = mm.get("_fade")
	if fade != null and (fade as Tween).is_valid():
		(fade as Tween).kill()
	for player: AudioStreamPlayer in [mm.get("_a"), mm.get("_b")]:
		player.stop()
		player.volume_db = -60.0
	mm.set("_audio_unlocked", was)
	r._ok(swapped, "LAY5 a new mood swaps the A and B players (A, B, A: %s)" % swapped)

## Rain and storm raise the rain stem, wind the wind stem, clear weather and fog neither.
static func _weather(r: Node, mm: Node) -> void:
	var seen: PackedStringArray = []
	var ok: bool = true
	for pair in [[WeatherSystem.Weather.RAIN, 1.0, 0.0], [WeatherSystem.Weather.STORM, 1.0, 0.0], [WeatherSystem.Weather.WIND, 0.0, 1.0], [WeatherSystem.Weather.CLEAR, 0.0, 0.0], [WeatherSystem.Weather.FOG, 0.0, 0.0]]:
		mm.set("_weather_id", int(pair[0]))
		mm.call("_update_layer_targets", STEP)
		var rain: float = _target(mm, "rain")
		var wind: float = _target(mm, "wind")
		seen.append("%d: rain %.0f wind %.0f" % [int(pair[0]), rain, wind])
		ok = ok and is_equal_approx(rain, float(pair[1])) and is_equal_approx(wind, float(pair[2]))
	r._ok(ok, "LAY6 the weather raises its stem (%s)" % "; ".join(seen))

## Runs the connections of `object` to a signal with `args`, as the signal would: the trigger itself, not the function it calls. A signal like game_over also changes the state of the game, so none is raised here.
static func _trigger(source: Signal, object: Object, args: Array) -> void:
	for connection: Dictionary in source.get_connections():
		if (connection["callable"] as Callable).get_object() == object:
			(connection["callable"] as Callable).callv(args)

## The files exist with the lengths of the recipe, and each trigger reaches a player of its file on the UI bus (the Music bus for the death): district_restored, xp_gained and item_consumed (a healing one, then a battery) for UISFX,
## game_over for the MusicManager.
static func _one_shots(r: Node, mm: Node) -> void:
	var ui: Node = r.get_tree().root.get_node_or_null("UISFX")
	var files: Dictionary = {"res://assets/audio/ui/ui_district_restored_sting.ogg": 2.0, "res://assets/audio/music/cue_death.ogg": 8.0, "res://assets/audio/sfx/ui_xp_tick.wav": 0.06, "res://assets/audio/sfx/ui_heal_soft.wav": 0.3}
	var lengths: PackedStringArray = []
	var ok: bool = ui != null
	for path: String in files:
		var stream: AudioStream = load(path) as AudioStream if ResourceLoader.exists(path) else null
		var seconds: float = stream.get_length() if stream != null else -1.0
		lengths.append("%s %.2f" % [path.get_file(), seconds])
		ok = ok and stream != null and absf(seconds - float(files[path])) <= 0.12
	r._ok(ok, "ONE1 the four one-shots exist with the lengths of the recipe (%s)" % ", ".join(lengths))
	if ui == null:
		return
	var heard: Dictionary = {}
	var before: Array[Node] = ui.get_children()
	_trigger(EventBus.district_restored, ui, [&"suburbs", 3])
	_listen(ui, before, heard)
	_trigger(EventBus.xp_gained, ui, [1])
	_listen(ui, before, heard)
	_trigger(EventBus.item_consumed, ui, [&"battery", "BATTERY", 35.0])
	var quiet: bool = not _listen(ui, before, {})
	_trigger(EventBus.item_consumed, ui, [&"medkit", "HEAL", 25.0])
	_listen(ui, before, heard)
	var cue: AudioStreamPlayer = mm.get("_wow_cue")
	cue.stream = null
	_trigger(EventBus.game_over, mm, [])
	var cue_file: String = cue.stream.resource_path.get_file() if cue.stream != null else "none"
	var cue_bus: String = String(cue.bus)
	cue.stop()
	r._ok(heard.get("ui_district_restored_sting.ogg", "") == "UI", "ONE2 district_restored plays the sting on the UI bus (%s)" % heard)
	r._ok(cue_file == "cue_death.ogg" and cue_bus == "Music", "ONE3 game_over plays the cue of a death on the Music bus (%s on %s)" % [cue_file, cue_bus])
	r._ok(heard.get("ui_xp_tick.wav", "") == "UI" and heard.get("ui_heal_soft.wav", "") == "UI" and quiet, "ONE4 xp_gained ticks and a healing consumable plays the soft note on the UI bus, a battery does not (%s, battery quiet %s)" % [heard, quiet])

## The players that appeared under `ui` since `before` are recorded in `heard` (file -> bus), stopped and freed; true when there was one.
static func _listen(ui: Node, before: Array[Node], heard: Dictionary) -> bool:
	var found: bool = false
	for node: Node in ui.get_children():
		var player := node as AudioStreamPlayer
		if player != null and not before.has(node) and player.stream != null:
			heard[player.stream.resource_path.get_file()] = String(player.bus)
			found = true
			player.stop()
			player.queue_free()
			before.append(node)
	return found
