extends Node
## Check: footstep_system.gd resolves surface x speed to real files in
## assets/audio/sfx/footsteps/ (RESCUE WAVE P1, TZ A03). The helpers live here,
## not in the shipped system. Scene: scenes/tools/footstep_check_scene.tscn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run()

func _run() -> void:
	var fs := FootstepSystem.new()
	add_child(fs)
	var fails := _check_mapping(fs) + _check_surface_speeds(fs)
	print("[footstep-check] DONE fails=%d" % fails)
	get_tree().quit(0 if fails == 0 else 1)

## Surface table sanity; crouch/stealth constants must mirror the player enum.
func _check_mapping(fs: FootstepSystem) -> int:
	var fails := 0
	if not fs.MATERIALS.has("default"):
		fails += 1
		print("[footstep] FAIL no default surface")
	for key in ["asphalt_dry", "puddle", "metal", "glass"]:
		var m: Dictionary = fs.MATERIALS.get(key, {})
		var r: Array = m.get("pitch_range", [1.0, 0.0])
		if m.is_empty() or float(r[0]) > float(r[1]) or String(m.get("sample", "")) == "":
			fails += 1
			print("[footstep] FAIL surface %s" % key)
	if fs.STATE_CROUCH != 4 or fs.STATE_STEALTH != 3:
		fails += 1
		print("[footstep] FAIL state constants must mirror the player enum")
	return fails

## A03 regression: every GDD surface must give 3 distinct (sample, pitch) steps
## across STEALTH/WALK/RUN, each backed by a real loaded file.
func _check_surface_speeds(fs: FootstepSystem) -> int:
	var fails := 0
	for surface in ["asphalt_dry", "asphalt_wet", "concrete", "wood", "metal", "puddle", "glass"]:
		var seen := {}
		for state in fs.AUDIBLE_STATES:
			var sample_name: String = fs._step_sample(surface, state)
			var pitch: float = fs._step_pitch(surface, state)[0]
			var key := "%s@%0.2f" % [sample_name, pitch]
			var loaded: bool = fs._streams.has(sample_name)
			if not loaded or seen.has(key):
				fails += 1
			seen[key] = true
			print("[footstep] %s/%d -> %s pitch %0.2f %s" % [surface, state, sample_name, pitch, "OK" if loaded else "MISSING"])
		if seen.size() != fs.AUDIBLE_STATES.size():
			print("[footstep] FAIL %s: only %d distinct steps" % [surface, seen.size()])
	return fails
