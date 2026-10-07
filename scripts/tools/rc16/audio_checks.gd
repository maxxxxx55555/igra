extends RefCounted
## rc16 closeout checks of audio: wired by the orchestrator into _closeout_check_runner.gd as `await <Preload>.run(self)`.
## Every call into the audio code is dynamic (call, get, constant map): on the code before the fix a missing function or constant is a
## failed check, not a script that does not compile.

const WORLD_BUSES: Array[StringName] = [&"Footsteps", &"Combat", &"Environment"]
## Far from every district and from the monsters the other checks park at 500, 500.
const SPOT := Vector3(500.0, 0.0, 560.0)
const POOL_SOUNDS: int = 40
const SETTLE_SEC: float = 0.8
const WET_SLACK: float = 0.01
## Offset and size of the five slabs of the room: four walls 4 m from the player and a ceiling 4 m up (the head is at 1.6 m).
const ROOM_SLABS: Array = [
	[Vector3(4.5, 3.0, 0.0), Vector3(1.0, 8.0, 10.0)],
	[Vector3(-4.5, 3.0, 0.0), Vector3(1.0, 8.0, 10.0)],
	[Vector3(0.0, 3.0, 4.5), Vector3(10.0, 8.0, 1.0)],
	[Vector3(0.0, 3.0, -4.5), Vector3(10.0, 8.0, 1.0)],
	[Vector3(0.0, 4.5, 0.0), Vector3(10.0, 1.0, 10.0)],
]
## Neighbours of the park in DistrictSceneFactory.DISTRICTS, the farthest district from it, and the park itself.
const NEXT_TO_PARK: Array[StringName] = [&"residential", &"school"]
const FARTHEST: StringName = &"power_station"
const PARK: StringName = &"park"

static func run(r: Node) -> void:
	await r.get_tree().process_frame
	_distance_filter(r)
	_pool(r)
	_reverb_tier_gate(r)
	await _reverb_by_place(r)
	_preload_and_unload(r)

static func _constant(script_owner: Object, name: String) -> Variant:
	return (script_owner.get_script() as Script).get_script_constant_map().get(name)

static func _players_3d() -> int:
	var count: int = 0
	for child in AudioManager.get_children():
		if child is AudioStreamPlayer3D:
			count += 1
	return count

static func _reverb_of(bus: StringName) -> AudioEffectReverb:
	var index: int = AudioServer.get_bus_index(bus)
	return AudioServer.get_bus_effect(index, 0) as AudioEffectReverb if AudioServer.get_bus_effect_count(index) > 0 else null

## AUD1: a positional sound is low-passed with distance: the player that takes it carries the cutoff and the drop of the constants, and
## so do the footsteps. The old code has neither constant.
static func _distance_filter(r: Node) -> void:
	var cutoff: Variant = _constant(AudioManager, "ATTEN_CUTOFF_HZ")
	var drop: Variant = _constant(AudioManager, "ATTEN_FILTER_DB")
	if cutoff == null or drop == null:
		r._ok(false, "AUD1 the audio manager names no distance low-pass (ATTEN_CUTOFF_HZ, ATTEN_FILTER_DB)")
		return
	var clip: AudioStream = AudioManager.call("_gen_click")
	var player: Variant = AudioManager.call("play_sound_3d", clip, Vector3.ZERO, -80.0)
	r._ok(player is AudioStreamPlayer3D and is_equal_approx(player.attenuation_filter_cutoff_hz, float(cutoff)) and is_equal_approx(player.attenuation_filter_db, float(drop)),
		"AUD1 a positional sound is low-passed at %s Hz with a drop of %s dB (player %s)" % [cutoff, drop, player])
	var steps := FootstepSystem.new()
	r.add_child(steps)
	var feet: AudioStreamPlayer3D = steps.get_node("FootstepAudio") as AudioStreamPlayer3D
	r._ok(feet != null and is_equal_approx(feet.attenuation_filter_cutoff_hz, float(cutoff)) and is_equal_approx(feet.attenuation_filter_db, float(drop)),
		"AUD1 and so are the footsteps (%s)" % [feet.attenuation_filter_cutoff_hz if feet != null else "no player"])
	steps.queue_free()

## AUD4: forty positional sounds in a row leave at most POOL_3D players in the manager, not forty. The old code builds one per sound.
static func _pool(r: Node) -> void:
	var cap: Variant = _constant(AudioManager, "POOL_3D")
	var before: int = _players_3d()
	var clip: AudioStream = AudioManager.call("_gen_click")
	for i in POOL_SOUNDS:
		AudioManager.call("play_sound_3d", clip, Vector3.ZERO, -80.0)
	var grown: int = _players_3d() - before
	r._ok(cap != null and grown <= int(cap) and grown >= 1,
		"AUD4 %d sounds share a pool of at most %s players (%d players were added)" % [POOL_SOUNDS, cap, grown])

## AUD2: every world bus carries a reverb, and it is on from the Medium tier up and off at Low. The old code has no effect on them.
static func _reverb_tier_gate(r: Node) -> void:
	var tier0: int = int(SettingsManager.get_setting("graphics_tier", 2))
	var seen: Array = []
	var good: bool = true
	for tier in 4:
		SettingsManager.set_setting("graphics_tier", tier)
		for bus in WORLD_BUSES:
			var index: int = AudioServer.get_bus_index(bus)
			var on: bool = AudioServer.get_bus_effect_count(index) > 0 and AudioServer.is_bus_effect_enabled(index, 0)
			good = good and on == (tier >= 1)
			seen.append("%d%s=%s" % [tier, String(bus).left(1), on])
	SettingsManager.set_setting("graphics_tier", tier0)
	r._ok(good, "AUD2 the reverb of the Footsteps, Combat and Environment buses is off at Low and on at Medium, High, Ultra (%s)" % [seen])

## The settled wet and room size of the Combat reverb after the sensing ran once.
static func _settled(r: Node) -> Array:
	AudioManager.call("_sense_reverb")
	await r.get_tree().create_timer(SETTLE_SEC).timeout
	var reverb := _reverb_of(&"Combat")
	return [reverb.wet, reverb.room_size] if reverb != null else [-1.0, -1.0]

## AUD3: the reverb follows the place. A physics timer senses it every quarter second; in the open the Combat reverb rests at its
## open values, walled in (four walls and a ceiling round the head) it grows to its closed values.
static func _reverb_by_place(r: Node) -> void:
	if not AudioManager.has_method("_sense_reverb") or _reverb_of(&"Combat") == null:
		r._ok(false, "AUD3 the audio manager senses no place and its Combat bus has no reverb")
		return
	var sensing: Array = AudioManager.get_children().filter(func(n: Node) -> bool: return n is Timer and n.process_callback == Timer.TIMER_PROCESS_PHYSICS)
	var interval: float = float(_constant(AudioManager, "REVERB_SENSE_SEC"))
	r._ok(sensing.size() == 1 and is_equal_approx((sensing[0] as Timer).wait_time, interval) and not (sensing[0] as Timer).is_stopped(),
		"AUD3 one physics timer senses the place every %s s (%d found)" % [interval, sensing.size()])
	var player := r.get_tree().get_first_node_in_group("player") as Node3D
	var home: Vector3 = player.global_position
	var was_physics: bool = player.is_physics_processing()
	player.set_physics_process(false)
	player.global_position = SPOT
	var tier0: int = int(SettingsManager.get_setting("graphics_tier", 2))
	SettingsManager.set_setting("graphics_tier", 2)
	await r.get_tree().physics_frame
	await r.get_tree().physics_frame
	var open: Array = await _settled(r)
	var room := StaticBody3D.new()
	r.add_child(room)
	room.global_position = SPOT
	for slab: Array in ROOM_SLABS:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = slab[1]
		shape.shape = box
		shape.position = slab[0]
		room.add_child(shape)
	await r.get_tree().physics_frame
	await r.get_tree().physics_frame
	var closed: Array = await _settled(r)
	room.queue_free()
	player.global_position = home
	player.set_physics_process(was_physics)
	SettingsManager.set_setting("graphics_tier", tier0)
	AudioManager.call("set_enclosure", 0.0)
	var wet_open: float = float(_constant(AudioManager, "REVERB_WET_OPEN"))
	var wet_closed: float = float(_constant(AudioManager, "REVERB_WET_CLOSED"))
	r._ok(absf(open[0] - wet_open) <= WET_SLACK and absf(closed[0] - wet_closed) <= WET_SLACK,
		"AUD3 the reverb is wet %.3f in the open (rests at %.3f) and %.3f walled in (grows to %.3f)" % [open[0], wet_open, closed[0], wet_closed])
	r._ok(closed[1] > open[1], "AUD3 and the room is bigger walled in (room size %.2f in the open, %.2f walled in)" % [open[1], closed[1]])

## AUD5: entering a district asks the loader thread for the beds of its two neighbours and lets go of the bed of a far district;
## the bed of the district itself stays. A marker stream stands for a bed that was loaded. The old code does neither. The neighbours
## are those of the order of the dark table, which has to be the order of the districts.
static func _preload_and_unload(r: Node) -> void:
	var order: Array = MusicManager.AMBIENCE_DARK_BY_DISTRICT.keys()
	var same: bool = order.size() == DistrictSceneFactory.DISTRICTS.size()
	for i in mini(order.size(), DistrictSceneFactory.DISTRICTS.size()):
		same = same and order[i] == DistrictSceneFactory.DISTRICTS[i]
	r._ok(same, "AUD5 the dark bed table lists the districts in the order of DistrictSceneFactory.DISTRICTS (%s)" % [order])
	var cache: Dictionary = MusicManager.get("_cache")
	var next_paths: Array[String] = []
	for id in NEXT_TO_PARK:
		var path: String = MusicManager.call("_ambience_path_for", id)
		next_paths.append(path)
		cache.erase(path)
	var far_path: String = MusicManager.call("_ambience_path_for", FARTHEST)
	var here_path: String = MusicManager.call("_ambience_path_for", PARK)
	var marker := AudioStreamWAV.new()
	cache[far_path] = marker
	cache[here_path] = marker
	MusicManager.call("_on_district_entered", PARK)
	var asked: Array = next_paths.map(func(path: String) -> int: return ResourceLoader.load_threaded_get_status(path))
	r._ok(not asked.has(ResourceLoader.THREAD_LOAD_INVALID_RESOURCE) and not asked.has(ResourceLoader.THREAD_LOAD_FAILED),
		"AUD5 entering the park asks the loader thread for the beds of %s (status %s)" % [NEXT_TO_PARK, asked])
	r._ok(not cache.has(far_path), "AUD5 and the bed of %s is let go of (cached %s)" % [FARTHEST, cache.has(far_path)])
	r._ok(cache.get(here_path) == marker, "AUD5 while the bed of the park itself stays")
	cache.erase(here_path)
