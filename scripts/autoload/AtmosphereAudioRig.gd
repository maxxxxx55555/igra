extends Node
## Attach under the active 3D viewport or install as an autoload.
## Optional imported Ogg paths use the keys in CUES. Register powered lamps
## with set_streetlight_hum() or group lights as streetlamp. A gameplay_director
## supplies cues and vitals automatically. set_survival() accepts fractions.

const RATE: int = 11025
const BLOCK: int = 256
const HUM_VOICES: int = 4
const HUM_RANGE: float = 19.0
const CUES: Array[StringName] = [&"hum", &"asphalt", &"metal", &"gravel", &"spark", &"surge"]
const CRAFT_HUM: String = "res://assets/audio/craft/amb_sodium_hum_loop.wav"

@export_range(3, 24) var effect_voices: int = 10
@export var ogg_paths: Dictionary[StringName, String] = {}
@export var listening_point: Node3D

var _sounds: Dictionary[StringName, AudioStream] = {}
var _effects: Array[AudioStreamPlayer3D] = []
var _priorities: PackedInt32Array = PackedInt32Array()
var _ages: PackedInt64Array = PackedInt64Array()
var _serial: int = 0
var _hums: Array[AudioStreamPlayer3D] = []
var _owners: PackedInt64Array = PackedInt64Array()
var _lamps: Dictionary[int, WeakRef] = {}
var _muted_group_lamps: Dictionary[int, bool] = {}
var _refresh_in: float = 0.0
var _director: Node
var _battery: float = 100.0
var _warmth: float = 100.0
var _distance: float = INF
var _drone: AudioStreamPlayer = AudioStreamPlayer.new()
var _playback: AudioStreamGeneratorPlayback
var _chunk: PackedVector2Array = PackedVector2Array()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _target: float = 0.0
var _tension: float = 0.0
var _phase: float = 0.0
var _beat: float = 0.0
var _edge: float = 0.0
var _filtered: float = 0.0

func _ready() -> void:
	for bus: StringName in [&"Music", &"SFX"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var index: int = AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, &"Master")
	_rng.seed = 916371
	for cue: StringName in CUES:
		_sounds[cue] = _load_sound(cue)
	_rng.randomize()
	for i: int in range(effect_voices):
		_effects.append(_new_emitter())
		_priorities.append(0)
		_ages.append(0)
	for i: int in range(HUM_VOICES):
		var hum: AudioStreamPlayer3D = _new_emitter()
		hum.stream = _sounds[&"hum"]
		hum.max_distance = HUM_RANGE
		hum.volume_db = -16.0
		_hums.append(hum)
		_owners.append(0)
	_drone.bus = &"Music"
	add_child(_drone)
	if AudioServer.get_driver_name() != "Dummy":
		_start_drone()
	get_tree().node_added.connect(_on_node_added)
	_sync_director()

func _start_drone() -> void:
	var generator: AudioStreamGenerator = AudioStreamGenerator.new()
	generator.mix_rate = RATE
	generator.buffer_length = 0.25
	_drone.stream = generator
	_chunk.resize(BLOCK)
	_drone.play()
	_playback = _drone.get_stream_playback() as AudioStreamGeneratorPlayback
	_fill_drone()

func _exit_tree() -> void:
	_drone.stop()
	_playback = null
	_drone.stream = null
	for player: AudioStreamPlayer3D in _effects:
		player.stop()
		player.stream = null
	for player: AudioStreamPlayer3D in _hums:
		player.stop()
		player.stream = null

func _on_node_added(node: Node) -> void:
	if node.has_signal(&"survival_changed") and node.has_signal(&"boss_telegraph"):
		_sync_director.call_deferred()

func set_bus_gain(bus: StringName, gain: float) -> void:
	if bus not in [&"Master", &"Music", &"SFX"] or not is_finite(gain):
		return
	var index: int = AudioServer.get_bus_index(bus)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(clampf(gain, 0.0001, 1.0)))

func set_survival(warmth_01: float, battery_01: float, architect_distance_m: float) -> void:
	if not is_finite(warmth_01) or not is_finite(battery_01) or is_nan(architect_distance_m):
		return
	var distance_m: float = clampf(architect_distance_m, 0.0, 40.0)
	var cold: float = 1.0 - clampf(warmth_01, 0.0, 1.0)
	var dark: float = 1.0 - clampf(battery_01, 0.0, 1.0)
	var near: float = 1.0 - smoothstep(2.0, 40.0, distance_m)
	_target = cold * 0.29 + dark * 0.23 + near * 0.48

func _process(delta: float) -> void:
	_fill_drone()
	_refresh_in -= delta
	if _refresh_in <= 0.0:
		_refresh_in = 0.25
		_sync_director()
		_refresh_hums()

func _sync_director() -> void:
	if not is_inside_tree():
		return
	var next: Node = get_tree().get_first_node_in_group(&"gameplay_director")
	if not is_instance_valid(_director):
		_director = null
	if next != _director:
		if _director != null:
			_connect_cues(_director, false)
		_director = next
		if _director != null:
			_connect_cues(_director, true)
			_battery = float(_director.get(&"battery"))
			_warmth = float(_director.get(&"warmth"))
	if _director == null:
		return
	_distance = INF
	var listener: Node3D = _listener()
	if listener != null and _director.has_method(&"architect_position"):
		var position: Vector3 = _director.call(&"architect_position")
		if position.is_finite():
			_distance = listener.global_position.distance_to(position)
	set_survival(_warmth * 0.01, _battery * 0.01, _distance)

func _connect_cues(source: Node, enabled: bool) -> void:
	var cues: Dictionary[StringName, Callable] = {
		&"survival_changed": _on_survival, &"repair_spark": play_repair_spark,
		&"boss_telegraph": play_boss_telegraph,
	}
	for cue: StringName in cues:
		if source.has_signal(cue):
			var callback: Callable = cues[cue]
			if enabled and not source.is_connected(cue, callback):
				source.connect(cue, callback)
			elif not enabled and source.is_connected(cue, callback):
				source.disconnect(cue, callback)

func _on_survival(battery: float, warmth: float) -> void:
	_battery = battery
	_warmth = warmth
	set_survival(warmth * 0.01, battery * 0.01, _distance)

func _listener() -> Node3D:
	if is_instance_valid(listening_point) and listening_point.is_inside_tree():
		return listening_point
	return get_viewport().get_camera_3d()

func _fill_drone() -> void:
	if _playback == null:
		return
	var available: int = _playback.get_frames_available()
	while available >= BLOCK:
		_tension = lerpf(_tension, _target, 0.025)
		var cutoff: float = lerpf(84.0, 490.0, _tension)
		var pole: float = 1.0 - exp(-TAU * cutoff / RATE)
		var edge_step: float = TAU * lerpf(64.8, 67.2, _tension) / RATE
		for i: int in range(BLOCK):
			_phase = fmod(_phase + TAU * 44.0 / RATE, TAU)
			_beat = fmod(_beat + TAU * 44.21 / RATE, TAU)
			_edge = fmod(_edge + edge_step, TAU)
			var tone: float = 0.083 * sin(_phase) + 0.049 * sin(_beat)
			tone += _tension * (0.048 * sin(_edge) + 0.022 * sin(5.0 * _phase))
			_filtered += pole * (tone - _filtered)
			_chunk[i] = Vector2(_filtered, _filtered)
		if not _playback.push_buffer(_chunk):
			break
		available -= BLOCK

func _new_emitter() -> AudioStreamPlayer3D:
	var emitter: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	emitter.bus = &"SFX"
	emitter.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	emitter.unit_size = 2.5
	emitter.max_distance = 48.0
	add_child(emitter)
	emitter.top_level = true
	return emitter

func set_streetlight_hum(lamp: Node3D, enabled: bool) -> void:
	if is_instance_valid(lamp):
		var id: int = lamp.get_instance_id()
		if enabled:
			_muted_group_lamps.erase(id)
			_lamps[id] = weakref(lamp)
		else:
			_lamps.erase(id)
			if lamp.is_in_group(&"streetlamp"):
				_muted_group_lamps[id] = true
		_refresh_in = 0.0

func _refresh_hums() -> void:
	var listener: Node3D = _listener()
	var candidates: Dictionary[int, Node3D] = {}
	for id: int in _muted_group_lamps.keys():
		if not is_instance_id_valid(id):
			_muted_group_lamps.erase(id)
	for member: Node in get_tree().get_nodes_in_group(&"streetlamp"):
		var light: Light3D = member as Light3D
		if light != null and not _muted_group_lamps.has(light.get_instance_id()):
			candidates[light.get_instance_id()] = light
	for id: int in _lamps.keys():
		var lamp: Node3D = _lamps[id].get_ref() as Node3D
		if not is_instance_valid(lamp) or not lamp.is_inside_tree():
			_lamps.erase(id)
		else:
			candidates[id] = lamp
	var near: Array[Node3D] = []
	for lamp: Node3D in candidates.values():
		var light: Light3D = lamp as Light3D
		if not lamp.is_visible_in_tree() or (light != null and light.light_energy <= 0.0):
			continue
		if listener != null and lamp.global_position.distance_squared_to(listener.global_position) < HUM_RANGE * HUM_RANGE:
			near.append(lamp)
	if not near.is_empty():
		var origin: Vector3 = listener.global_position
		near.sort_custom(func(a: Node3D, b: Node3D) -> bool:
			return a.global_position.distance_squared_to(origin) < b.global_position.distance_squared_to(origin))
	near.resize(mini(near.size(), HUM_VOICES))
	var wanted: Array[int] = []
	for lamp: Node3D in near:
		wanted.append(lamp.get_instance_id())
	for i: int in range(_hums.size()):
		if _owners[i] != 0 and not wanted.has(_owners[i]):
			_hums[i].stop()
			_owners[i] = 0
	for lamp: Node3D in near:
		var slot: int = _owners.find(lamp.get_instance_id())
		if slot < 0:
			slot = _owners.find(0)
			_owners[slot] = lamp.get_instance_id()
		_hums[slot].global_position = lamp.global_position
		if not _hums[slot].playing:
			_hums[slot].play()

func play_footstep(at: Vector3, surface: StringName = &"asphalt") -> void:
	var cue: StringName = surface if surface in [&"gravel", &"metal"] else &"asphalt"
	_play_at(cue, at, -8.0, _rng.randf_range(0.88, 1.12), 1)

func play_repair_spark(at: Vector3) -> void:
	_play_at(&"spark", at, -7.0, _rng.randf_range(0.96, 1.08), 2)

func play_boss_telegraph(at: Vector3) -> void:
	_play_at(&"surge", at, -3.0, 1.0, 3)

func _play_at(cue: StringName, at: Vector3, gain_db: float, pitch: float, priority: int) -> void:
	if not at.is_finite():
		return
	var slot: int = -1
	for i: int in range(_effects.size()):
		if not _effects[i].playing:
			slot = i
			break
		if _priorities[i] > priority:
			continue
		if slot < 0 or _priorities[i] < _priorities[slot] or (_priorities[i] == _priorities[slot] and _ages[i] < _ages[slot]):
			slot = i
	if slot >= 0:
		var emitter: AudioStreamPlayer3D = _effects[slot]
		emitter.stop()
		emitter.stream = _sounds[cue]
		emitter.global_position = at
		emitter.volume_db = gain_db
		emitter.pitch_scale = pitch
		_priorities[slot] = priority
		_serial += 1
		_ages[slot] = _serial
		emitter.play()

func _load_sound(cue: StringName) -> AudioStream:
	if cue == &"hum" and ResourceLoader.exists(CRAFT_HUM):
		var crafted := load(CRAFT_HUM) as AudioStreamWAV
		if crafted != null:
			var copy := crafted.duplicate() as AudioStreamWAV
			copy.loop_mode = AudioStreamWAV.LOOP_FORWARD
			copy.loop_begin = 0
			copy.loop_end = maxi(0, (copy.data.size() / 4) - 1)
			return copy
	var path: String = ogg_paths.get(cue, "")
	if not path.is_empty() and ResourceLoader.exists(path):
		var imported: AudioStreamOggVorbis = load(path) as AudioStreamOggVorbis
		if imported != null:
			var copy: AudioStreamOggVorbis = imported.duplicate() as AudioStreamOggVorbis
			copy.loop = cue == &"hum"
			return copy
	var length_s: float = 0.30
	if cue == &"hum":
		length_s = 1.0
	elif cue == &"surge":
		length_s = 0.86
	var count: int = roundi(length_s * RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	var smooth_noise: float = 0.0
	for i: int in range(count):
		var t: float = float(i) / RATE
		var noise: float = _rng.randf_range(-1.0, 1.0)
		smooth_noise += 0.18 * (noise - smooth_noise)
		var s: float = 0.0
		match cue:
			&"hum":
				s = 0.32 * sin(TAU * 100.0 * t) + 0.10 * sin(TAU * 200.0 * t)
				s *= 0.83 + 0.17 * cos(TAU * 3.0 * t)
			&"metal":
				s = exp(-18.0 * t) * (0.40 * sin(1900.0 * t) + 0.26 * sin(3120.0 * t)) + 0.33 * noise * exp(-70.0 * t)
			&"gravel":
				s = smooth_noise * exp(-13.0 * t) + noise * exp(-18.0 * t) * (0.31 + 0.26 * sin(170.0 * t))
			&"spark":
				s = (noise - smooth_noise) * exp(-17.0 * t) * pow(absf(cos(95.0 * t)), 7.0)
			&"surge":
				s = 0.55 * sin(TAU * (110.0 * t + 94.0 * t * t)) + 0.17 * sin(TAU * 221.0 * t)
				s *= sin(PI * t / length_s)
			_:
				s = 0.55 * exp(-24.0 * t) * sin(TAU * (62.0 * t + 0.32 * (1.0 - exp(-30.0 * t))))
				s += 0.75 * smooth_noise * exp(-21.0 * t)
		if cue != &"hum":
			s *= clampf(t * 500.0, 0.0, 1.0) * clampf((length_s - t) * 150.0, 0.0, 1.0)
		data.encode_s16(i * 2, roundi(clampf(s, -1.0, 1.0) * 32767.0))
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.data = data
	if cue == &"hum":
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = count
	return wav
