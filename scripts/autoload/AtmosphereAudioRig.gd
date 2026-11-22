extends Node
## Spatial one-shot effects for footsteps, repairs and boss telegraphs.

const RATE: int = 11025
const CUES: Array[StringName] = [&"asphalt", &"metal", &"gravel", &"spark", &"surge"]
## Wave 3: the wet night boot steps of the owner's reference.
const CANON_DIR: String = "res://assets/audio/menu_canon/"
const STEP_FILES: Array[String] = [
	"sfx_step_wet_asphalt_01.wav",
	"sfx_step_wet_asphalt_02.wav",
	"sfx_step_wet_asphalt_03.wav",
]

@export_range(3, 24) var effect_voices: int = 10
@export var ogg_paths: Dictionary[StringName, String] = {}

var _sounds: Dictionary[StringName, AudioStream] = {}
var _steps: Array[AudioStream] = []
var _last_step: int = -1
var _effects: Array[AudioStreamPlayer3D] = []
var _priorities: PackedInt32Array = PackedInt32Array()
var _ages: PackedInt64Array = PackedInt64Array()
var _serial: int = 0
var _director: Node
var _rng := RandomNumberGenerator.new()

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
	for file: String in STEP_FILES:
		var path: String = CANON_DIR + file
		if ResourceLoader.exists(path):
			var stream := load(path) as AudioStream
			if stream != null:
				_steps.append(stream)
	_rng.randomize()
	for i: int in range(effect_voices):
		_effects.append(_new_emitter())
		_priorities.append(0)
		_ages.append(0)
	get_tree().node_added.connect(_on_node_added)
	_sync_director()

func _exit_tree() -> void:
	for player: AudioStreamPlayer3D in _effects:
		player.stop()
		player.stream = null
	_sounds.clear()
	_steps.clear()

func _on_node_added(node: Node) -> void:
	if node.has_signal(&"survival_changed") and node.has_signal(&"boss_telegraph"):
		_sync_director.call_deferred()

func set_bus_gain(bus: StringName, gain: float) -> void:
	if bus not in [&"Master", &"Music", &"SFX"] or not is_finite(gain):
		return
	var index: int = AudioServer.get_bus_index(bus)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(clampf(gain, 0.0001, 1.0)))

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

func _connect_cues(source: Node, enabled: bool) -> void:
	var cues: Dictionary[StringName, Callable] = {
		&"repair_spark": play_repair_spark,
		&"boss_telegraph": play_boss_telegraph,
	}
	for cue: StringName in cues:
		if source.has_signal(cue):
			var callback: Callable = cues[cue]
			if enabled and not source.is_connected(cue, callback):
				source.connect(cue, callback)
			elif not enabled and source.is_connected(cue, callback):
				source.disconnect(cue, callback)

func _new_emitter() -> AudioStreamPlayer3D:
	var emitter: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	emitter.bus = &"SFX"
	emitter.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	emitter.unit_size = 2.5
	emitter.max_distance = 48.0
	add_child(emitter)
	emitter.top_level = true
	return emitter

func play_footstep(at: Vector3, surface: StringName = &"asphalt") -> void:
	# Wave 3: on asphalt the boot steps are the three wet-night files of the
	# owner's reference. The next step is never the same file twice in a row
	# and the pitch wanders inside 0.95..1.05, so a walk never machine-guns.
	if surface == &"asphalt" and _steps.size() >= 2:
		var pick: int = _rng.randi_range(0, _steps.size() - 1)
		if pick == _last_step:
			pick = (pick + 1 + _rng.randi_range(0, _steps.size() - 2)) % _steps.size()
		_last_step = pick
		_play_at(&"asphalt", at, -8.0, _rng.randf_range(0.95, 1.05), 1, _steps[pick])
		return
	var cue: StringName = surface if surface in [&"gravel", &"metal"] else &"asphalt"
	_play_at(cue, at, -8.0, _rng.randf_range(0.88, 1.12), 1)

func play_repair_spark(at: Vector3) -> void:
	_play_at(&"spark", at, -7.0, _rng.randf_range(0.96, 1.08), 2)

func play_boss_telegraph(at: Vector3) -> void:
	_play_at(&"surge", at, -3.0, 1.0, 3)

func _play_at(cue: StringName, at: Vector3, gain_db: float, pitch: float, priority: int, stream_override: AudioStream = null) -> void:
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
		emitter.stream = stream_override if stream_override != null else _sounds[cue]
		emitter.global_position = at
		emitter.volume_db = gain_db
		emitter.pitch_scale = pitch
		_priorities[slot] = priority
		_serial += 1
		_ages[slot] = _serial
		emitter.play()

func _load_sound(cue: StringName) -> AudioStream:
	var path: String = ogg_paths.get(cue, "")
	if not path.is_empty() and ResourceLoader.exists(path):
		var imported: AudioStreamOggVorbis = load(path) as AudioStreamOggVorbis
		if imported != null:
			var copy: AudioStreamOggVorbis = imported.duplicate() as AudioStreamOggVorbis
			copy.loop = false
			return copy
	var length_s: float = 0.30
	if cue == &"surge":
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
		s *= clampf(t * 500.0, 0.0, 1.0) * clampf((length_s - t) * 150.0, 0.0, 1.0)
		data.encode_s16(i * 2, roundi(clampf(s, -1.0, 1.0) * 32767.0))
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.data = data
	return wav
