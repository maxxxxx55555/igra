class_name AudioDirectorA32
extends Node

## Mobile-budgeted audio director: 5 locked buses, Master -1dB limiter, adaptive crossfade, anti-3-repeat SFX pool.

const MAX_SFX_VOICES: int = 12
const CROSSFADE_SEC: float = 1.4
const PITCH_MIN: float = 0.95
const PITCH_MAX: float = 1.05

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active_is_a: bool = true
var _music_tween: Tween = null
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_cursor: int = 0
var _last_history: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _muted: bool = false


func _ready() -> void:
	_rng.randomize()
	ensure_bus_layout()
	_music_a = _make_player("MusicA", &"Music")
	_music_b = _make_player("MusicB", &"Music")
	for i in range(MAX_SFX_VOICES):
		_sfx_pool.append(_make_player("SfxPool_%d" % i, &"SFX"))


func _exit_tree() -> void:
	if is_instance_valid(_music_tween):
		_music_tween.kill()
		_music_tween = null


static func ensure_bus_layout() -> void:
	var master_idx: int = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		var has_limiter: bool = false
		for i in range(AudioServer.get_bus_effect_count(master_idx)):
			if AudioServer.get_bus_effect(master_idx, i) is AudioEffectLimiter:
				has_limiter = true
				break
		if not has_limiter:
			var lim: AudioEffectLimiter = AudioEffectLimiter.new()
			lim.ceiling_db = -1.0
			lim.threshold_db = -1.5
			AudioServer.add_bus_effect(master_idx, lim)

	for bus_name in ["Music", "SFX", "UI", "Ambience"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx: int = AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")


func crossfade_music(stream: AudioStream, target_db: float = -2.0) -> void:
	if stream == null:
		return
	var incoming: AudioStreamPlayer = _music_b if _active_is_a else _music_a
	var outgoing: AudioStreamPlayer = _music_a if _active_is_a else _music_b
	if outgoing.playing and outgoing.stream == stream:
		return
	incoming.stream = stream
	incoming.volume_db = -40.0
	incoming.play()
	_active_is_a = not _active_is_a

	if is_instance_valid(_music_tween):
		_music_tween.kill()
	_music_tween = create_tween().set_parallel(true)
	_music_tween.tween_property(incoming, "volume_db", target_db, CROSSFADE_SEC)
	if outgoing.playing:
		_music_tween.tween_property(outgoing, "volume_db", -42.0, CROSSFADE_SEC)
		_music_tween.chain().tween_callback(func() -> void:
			if is_instance_valid(outgoing):
				outgoing.stop()
		)


func play_sfx_variant(group_key: String, streams: Array[AudioStream], bus_name: StringName = &"SFX", volume_db: float = 0.0) -> void:
	if streams.is_empty():
		return
	var chosen_idx: int = _pick_non_repeating_index(group_key, streams.size())
	var s: AudioStream = streams[chosen_idx]
	if s == null:
		return
	var player: AudioStreamPlayer = _sfx_pool[_sfx_cursor]
	_sfx_cursor = (_sfx_cursor + 1) % _sfx_pool.size()
	player.bus = bus_name
	player.stream = s
	player.volume_db = volume_db
	player.pitch_scale = _rng.randf_range(PITCH_MIN, PITCH_MAX)
	player.play()


func toggle_mute() -> bool:
	_muted = not _muted
	var master_idx: int = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_mute(master_idx, _muted)
	return _muted


func _pick_non_repeating_index(group_key: String, count: int) -> int:
	if count <= 1:
		return 0
	var history: Array = _last_history.get(group_key, [])
	var candidates: Array[int] = []
	for i in range(count):
		if history.size() < 2 or not (history[-1] == i and history[-2] == i):
			candidates.append(i)
	if candidates.is_empty():
		candidates.append(_rng.randi_range(0, count - 1))
	var picked: int = candidates[_rng.randi_range(0, candidates.size() - 1)]
	history.append(picked)
	if history.size() > 3:
		history.pop_front()
	_last_history[group_key] = history
	return picked


func _make_player(p_name: String, bus_name: StringName) -> AudioStreamPlayer:
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.name = p_name
	p.bus = bus_name
	add_child(p)
	return p
