extends Node
## P0/R2 truth gate: RUNTIME proof that audio actually plays within budget,
## not just that a bus with the right name exists (tools/flow_check.py
## already covers that statically - reads default_bus_layout.tres and
## game_manager.gd as text, never runs the engine). A district's
## music_manager.gd routing could be silently broken (wrong bus name, volume
## clamped to -80dB, .play() never called) and the static check would still
## pass. Needs real audio output, so --headless (dummy driver, always-zero
## peaks) would make this trivially pass for the wrong reason - run windowed
## only: tools/qa_sim/guarded_windowed res://scenes/tools/audio_truth_gate_scene.tscn
##
## R2 hardening (docs/REDTEAM_CHALLENGE.md TG-HEAR, arena finding): the
## original version only checked the Music bus wasn't silent. Hardened to
## also check a true-peak ceiling on every bus (catches clipping, not just
## "is something happening") and to inject movement so footstep SFX has a
## chance to fire, not just menu/district ambience.
##
## Run: godot --path . --rendering-method gl_compatibility
##        scenes/tools/audio_truth_gate_scene.tscn
## Hard timeout: wrap in `timeout 60s` (well under the 120s default; boot
## takes ~15s per shot_tool.gd's own measured timing).

const MUSIC_SILENCE_DB := -45.0  ## arena TG-HEAR spec: post-unlock Music peak >= -45dB
const TRUE_PEAK_CEILING_DB := -1.5  ## arena TG-HEAR spec / docs/STYLE_GUIDE.md audio budget
const BUSES_TO_CHECK := ["Master", "Music", "SFX", "Ambient"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if DisplayServer.get_name() == "headless":
		print("[audio-truth] SKIP DUMMY_AUDIO -- headless has no real audio device, would always read silence")
		# check.sh's run_gate() maps exit 3 to a printed SKIP, distinct from
		# the exit-0 "ok" a real windowed pass reports - quit(0) here used to
		# make check.sh print this gate green on every standard headless run
		# while testing nothing at all (SLOP_REPORT item 2).
		get_tree().quit(3)
		return
	call_deferred("_run")

## What the music was doing: the mood name, the combat hold, the nearest monster in metres. A peak is only explainable next to it:
## the same code read -12 dB in one run and +0.5 dB in the next (CORRECTION_LOG 102).
func _music_context() -> String:
	return "mood=%s in_combat=%s nearest_monster_m=%.1f" % [MusicManager.Mood.keys()[MusicManager.mood], MusicManager.is_in_combat(), MusicManager.call("_nearest_enemy_distance")]

func _peak_over(bus_idx: int, seconds: float) -> float:
	var peak_db := -80.0
	var samples := maxi(1, int(seconds / 0.05))
	for i in samples:
		var l := AudioServer.get_bus_peak_volume_left_db(bus_idx, 0)
		var r := AudioServer.get_bus_peak_volume_right_db(bus_idx, 0)
		peak_db = maxf(peak_db, maxf(l, r))
		await get_tree().create_timer(0.05).timeout
	return peak_db

## Session 28 (A1): the stems of the three states under a hunted level of 0, 0.4 and 1 (the detection meter set by hand, the monsters out of the count): the peak of the music bus at each level stays under the
## ceiling, and the stems cross over (the tense stem is up at 0.4 and the combat stems at 1, the bed gives way).
func _threat_sweep() -> bool:
	var ok := true
	var music_bus := AudioServer.get_bus_index("Music")
	var layers: Dictionary = MusicManager.get("_layers")
	var hunters: Array[Node] = []
	for monster: Node in get_tree().get_nodes_in_group("enemies"):
		hunters.append(monster)
		monster.remove_from_group("enemies")
	var levels: Dictionary = {}
	for meter: float in [0.0, 0.4, 1.0]:
		var until: int = Time.get_ticks_msec() + 5000
		while Time.get_ticks_msec() < until:
			MusicManager.set("_combat_hold", MusicManager.CALM_DELAY * meter)
			await get_tree().create_timer(0.1).timeout
		var peak: float = await _peak_over(music_bus, 1.0)
		var stems: Dictionary = {}
		for key: String in ["ambient_dark", "ambient_lit", "threat_low", "threat_high", "action"]:
			stems[key] = snappedf((layers[key] as AudioStreamPlayer).volume_db, 0.1)
		levels[meter] = stems
		print("[audio-truth] threat meter=%.1f music_peak=%.1fdB stems=%s" % [meter, peak, stems])
		ok = ok and peak <= TRUE_PEAK_CEILING_DB
	MusicManager.set("_combat_hold", 0.0)
	for monster: Node in hunters:
		if is_instance_valid(monster):
			monster.add_to_group("enemies")
	var calm: Dictionary = levels[0.0]
	var tense: Dictionary = levels[0.4]
	var combat: Dictionary = levels[1.0]
	var crossed: bool = float(tense["threat_low"]) > float(tense["threat_high"]) + 20.0 and float(combat["threat_high"]) > float(combat["threat_low"]) + 20.0 and float(calm["threat_high"]) < -45.0
	print("[audio-truth] %s -- the stems cross over with the hunted level (calm %s, tense %s, combat %s)" % ["PASS" if crossed else "FAIL", calm, tense, combat])
	return ok and crossed

func _run() -> void:
	print("[audio-truth] driver=%s output_device=%s devices=%s" % [
		AudioServer.get_driver_name(), AudioServer.get_output_device(),
		AudioServer.get_output_device_list()])
	var ads := get_node_or_null("/root/AdService")
	if ads:
		ads.enabled = false
	# Same boot timing shot_tool.gd's _apply_scenario already proved out:
	# splash+boot_loading take ~6.5s before Routes.start_game() is safe to
	# call without racing an in-flight transition.
	await get_tree().create_timer(8.0).timeout
	var routes := get_node_or_null("/root/Routes")
	if routes and routes.has_method("start_game"):
		routes.start_game()
	# music_manager.gd deliberately holds every layer muted until the
	# player's first real input (_unlock_audio(), gated on _input()'s own
	# event.is_pressed() check) - a documented anti-boot-hum measure this
	# project already gates on (tools/check.sh's audio_hum_check_scene.tscn,
	# "тишина до первого ввода"). A real player's first click/key satisfies
	# this for free; this probe has to inject one itself or every run would
	# read permanent silence for a reason that has nothing to do with music
	# actually being broken - found by reading _input()/_unlock_audio(),
	# not guessed after the first FAIL.
	var unlock := InputEventKey.new()
	unlock.keycode = KEY_SPACE
	unlock.pressed = true
	Input.parse_input_event(unlock)
	# Let music_manager.gd's district_entered handler fire and any fade-in
	# ramp up to real volume.
	await get_tree().create_timer(6.0).timeout

	# R2 addition: walk the player for a couple seconds so footstep SFX (and,
	# if spawn happens to be in range, a streetlight hum) has a real chance
	# to fire before the SFX/Ambient buses are sampled - best-effort, not a
	# guarantee of a specific sound (spawn point/collision are out of this
	# probe's control), so those two buses are reported but not blocking.
	Input.action_press("move_up")
	await get_tree().create_timer(2.0).timeout
	Input.action_release("move_up")

	var results := {}
	var all_ok := true
	for bus_name in BUSES_TO_CHECK:
		var idx := AudioServer.get_bus_index(bus_name)
		if idx < 0:
			print("[audio-truth] FAIL -- no '%s' bus" % bus_name)
			all_ok = false
			continue
		var before := _music_context() if bus_name == "Music" else ""
		var peak := await _peak_over(idx, 1.0)
		if bus_name == "Music":
			print("[audio-truth] music context before: %s, after: %s" % [before, _music_context()])
		results[bus_name] = peak
		var over_ceiling := peak > TRUE_PEAK_CEILING_DB
		if over_ceiling:
			all_ok = false
		# QA runs mute Master (qa_launch_guard.gd, owner request): its meter reads
		# silence then, so its ceiling is only covered through the child buses.
		var verdict := "CLIP-FAIL" if over_ceiling else ("muted for QA" if AudioServer.is_bus_mute(idx) else "ok")
		print("[audio-truth] %s bus peak=%.1fdB (ceiling <=%.1fdB) %s" % [
			bus_name, peak, TRUE_PEAK_CEILING_DB, verdict])

	var music_peak: float = results.get("Music", -80.0)
	var music_ok := music_peak > MUSIC_SILENCE_DB
	all_ok = all_ok and music_ok
	print("[audio-truth] %s -- Music bus peak=%.1fdB (threshold >%.1fdB)" % [
		"PASS" if music_ok else "FAIL", music_peak, MUSIC_SILENCE_DB])
	print("[audio-truth] SFX peak=%.1fdB Ambient peak=%.1fdB (reported, not blocking -- best-effort footstep/hum trigger, see class comment)" % [
		results.get("SFX", -80.0), results.get("Ambient", -80.0)])

	var sweep_ok: bool = await _threat_sweep()
	all_ok = all_ok and sweep_ok
	print("[audio-truth] %s overall" % ("PASS" if all_ok else "FAIL"))
	get_tree().quit(0 if all_ok else 1)
