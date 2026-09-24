extends Node
## P0/R2 truth gate: RUNTIME proof that audio actually plays within budget,
## not just that a bus with the right name exists (tools/flow_check.py
## already covers that statically - reads default_bus_layout.tres and
## game_manager.gd as text, never runs the engine). A district's
## music_manager.gd routing could be silently broken (wrong bus name, volume
## clamped to -80dB, .play() never called) and the static check would still
## pass. Needs real audio output, so --headless (dummy driver, always-zero
## peaks) would make this trivially pass for the wrong reason - run windowed
## only.
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

func _peak_over(bus_idx: int, seconds: float) -> float:
	var peak_db := -80.0
	var samples := maxi(1, int(seconds / 0.05))
	for i in samples:
		var l := AudioServer.get_bus_peak_volume_left_db(bus_idx, 0)
		var r := AudioServer.get_bus_peak_volume_right_db(bus_idx, 0)
		peak_db = maxf(peak_db, maxf(l, r))
		await get_tree().create_timer(0.05).timeout
	return peak_db

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
		var peak := await _peak_over(idx, 1.0)
		results[bus_name] = peak
		var over_ceiling := peak > TRUE_PEAK_CEILING_DB
		if over_ceiling:
			all_ok = false
		print("[audio-truth] %s bus peak=%.1fdB (ceiling <=%.1fdB) %s" % [
			bus_name, peak, TRUE_PEAK_CEILING_DB, "CLIP-FAIL" if over_ceiling else "ok"])

	var music_peak: float = results.get("Music", -80.0)
	var music_ok := music_peak > MUSIC_SILENCE_DB
	all_ok = all_ok and music_ok
	print("[audio-truth] %s -- Music bus peak=%.1fdB (threshold >%.1fdB)" % [
		"PASS" if music_ok else "FAIL", music_peak, MUSIC_SILENCE_DB])
	print("[audio-truth] SFX peak=%.1fdB Ambient peak=%.1fdB (reported, not blocking -- best-effort footstep/hum trigger, see class comment)" % [
		results.get("SFX", -80.0), results.get("Ambient", -80.0)])

	print("[audio-truth] %s overall" % ("PASS" if all_ok else "FAIL"))
	get_tree().quit(0 if all_ok else 1)
