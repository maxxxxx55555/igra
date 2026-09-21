extends Node
## P0 truth gate: RUNTIME proof that music actually plays, not just that a
## bus with the right name exists (tools/flow_check.py already covers that
## statically - reads default_bus_layout.tres and game_manager.gd as text,
## never runs the engine). A district's music_manager.gd routing could be
## silently broken (wrong bus name, volume clamped to -80dB, .play() never
## called) and the static check would still pass. Needs real audio output,
## so --headless (dummy driver, always-zero peaks) would make this
## trivially pass for the wrong reason - run windowed only.
##
## Run: godot --path . --rendering-method gl_compatibility
##        scenes/tools/audio_truth_gate_scene.tscn
## Hard timeout: wrap in `timeout 60s` (well under the 120s default; boot
## takes ~15s per shot_tool.gd's own measured timing).

const SILENCE_DB := -60.0  ## digital silence reads ~-80dB or lower; music at
## any real volume reads well above -60dB even quiet ambient tracks.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if DisplayServer.get_name() == "headless":
		print("[audio-truth] SKIP -- headless has no real audio device, would always read silence")
		get_tree().quit(0)
		return
	call_deferred("_run")

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
	await get_tree().create_timer(8.0).timeout

	var bus_idx := AudioServer.get_bus_index("Music")
	if bus_idx < 0:
		print("[audio-truth] FAIL -- no 'Music' bus")
		get_tree().quit(1)
		return

	var peak_db := -80.0
	for i in 20:  # sample across ~1s, a single instant can catch a wave trough
		var l := AudioServer.get_bus_peak_volume_left_db(bus_idx, 0)
		var r := AudioServer.get_bus_peak_volume_right_db(bus_idx, 0)
		peak_db = maxf(peak_db, maxf(l, r))
		await get_tree().create_timer(0.05).timeout

	var ok := peak_db > SILENCE_DB
	print("[audio-truth] %s -- Music bus peak=%.1fdB (threshold >%.1fdB)" % [
		"PASS" if ok else "FAIL", peak_db, SILENCE_DB])
	get_tree().quit(0 if ok else 1)
