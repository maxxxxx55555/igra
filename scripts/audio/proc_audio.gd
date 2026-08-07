extends Node

@export var enable_proc_audio: bool = true
@export var ambient_hum_freq: float = 65.0
@export var ambient_volume: float = 0.08
@export var moan_interval_min: float = 8.0
@export var moan_interval_max: float = 15.0
@export var flashlight_click_volume: float = 0.3
@export var footstep_volume: float = 0.15
@export var ambient_quiet_volume: float = 0.03

var _ambient_player: AudioStreamPlayer
var _gen_ok: bool = false
var _no_missing: bool = true
var _fallback_used: bool = false
var _time: float = 0.0
var _ambient_current_volume: float = 0.08
var _moan_timer: float = 0.0
var _moan_cooldown: float = 12.0
var _footstep_timer: float = 0.0
var _footstep_interval: float = 0.0
var _player_was_moving: bool = false
var _flashlight_on: bool = true

func _ready() -> void:
	if not enable_proc_audio:
		return
	_ambient_current_volume = ambient_volume
	_moan_cooldown = randf_range(moan_interval_min, moan_interval_max)
	var ambient_bus := "Ambient"
	if AudioServer.get_bus_index(ambient_bus) == -1:
		ambient_bus = "Master"
	var try_gen := func() -> bool:
		var gen := AudioStreamGenerator.new()
		gen.mix_rate = 24000
		gen.buffer_length = 0.5
		var player := AudioStreamPlayer.new()
		player.stream = gen
		player.bus = ambient_bus
		add_child(player)
		player.play()
		if player.get_stream_playback() != null:
			_ambient_player = player
			_gen_ok = true
			return true
		return false
	var gen_ok := false
	var fallback_used := false
	var no_missing := true
	if not try_gen.call():
		fallback_used = true
		var silent := AudioStreamPlayer.new()
		silent.bus = ambient_bus
		add_child(silent)
		silent.play()
		_ambient_player = silent
		_gen_ok = false
	_fallback_used = fallback_used
	_no_missing = no_missing
	EventBus.flashlight_state_changed.connect(_on_flashlight_toggled)
	EventBus.player_state_changed.connect(_on_player_state_changed)


func _on_flashlight_toggled(enabled: bool) -> void:
	_flashlight_on = enabled
	var target_vol := ambient_quiet_volume if enabled else ambient_volume
	var tween := create_tween()
	tween.tween_method(func(v: float): _ambient_current_volume = v, _ambient_current_volume, target_vol, 0.5)
	if enabled:
		_play_flashlight_click()

func _play_flashlight_click() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 24000
	gen.buffer_length = 0.1
	var player := AudioStreamPlayer.new()
	player.stream = gen
	var sfx_bus := "SFX"
	if AudioServer.get_bus_index(sfx_bus) == -1:
		sfx_bus = "Master"
	player.bus = sfx_bus
	add_child(player)
	player.play()
	await get_tree().process_frame
	var playback := player.get_stream_playback()
	if playback:
		var frame_count := 600
		var buf := PackedVector2Array()
		buf.resize(frame_count)
		for i in frame_count:
			var v := 1.0 if (i % 20) < 10 else -1.0
			var decay := 1.0 - float(i) / float(frame_count)
			buf[i] = Vector2(v * flashlight_click_volume * decay, v * flashlight_click_volume * decay)
		playback.push_buffer(buf)
	await get_tree().create_timer(0.15).timeout
	player.queue_free()

func _on_player_state_changed(state: int) -> void:
	pass

func _play_footstep() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 12000
	gen.buffer_length = 0.1
	var player := AudioStreamPlayer.new()
	player.stream = gen
	var sfx_bus := "SFX"
	if AudioServer.get_bus_index(sfx_bus) == -1:
		sfx_bus = "Master"
	player.bus = sfx_bus
	add_child(player)
	player.play()
	await get_tree().process_frame
	var playback := player.get_stream_playback()
	if playback:
		var frame_count := 300
		var buf := PackedVector2Array()
		buf.resize(frame_count)
		for i in frame_count:
			var noise_val := randf_range(-1.0, 1.0) * 0.3
			var decay := 1.0 - float(i) / float(frame_count)
			var click := sin(float(i) * 0.5) * 0.7
			var v := (noise_val + click) * footstep_volume * decay
			buf[i] = Vector2(v, v)
		playback.push_buffer(buf)
	await get_tree().create_timer(0.1).timeout
	player.queue_free()

func _play_moan() -> void:
	if not _gen_ok:
		return
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 12000
	gen.buffer_length = 0.5
	var player := AudioStreamPlayer.new()
	player.stream = gen
	var ambient_bus := "Ambient"
	if AudioServer.get_bus_index(ambient_bus) == -1:
		ambient_bus = "Master"
	player.bus = ambient_bus
	player.volume_db = -10.0
	add_child(player)
	player.play()
	await get_tree().process_frame
	var playback := player.get_stream_playback()
	var dur := randf_range(0.8, 2.0)
	if playback:
		var frame_count := int(dur * 12000.0)
		var buf := PackedVector2Array()
		buf.resize(frame_count)
		for i in frame_count:
			var t := float(i) / 12000.0
			var freq := 80.0 + sin(t * 3.0) * 20.0
			var envelope := sin(float(i) / float(frame_count) * PI)
			var v := sin(t * freq * TAU) * envelope * 0.12
			buf[i] = Vector2(v, v)
		playback.push_buffer(buf)
	await get_tree().create_timer(dur + 0.1).timeout
	player.queue_free()

func _process(delta: float) -> void:
	if not enable_proc_audio:
		return
	_time += delta
	if _gen_ok and _ambient_player and _ambient_player.get_stream_playback():
		var playback = _ambient_player.get_stream_playback()
		if playback:
			var frames = playback.get_frames_available()
			if frames > 0:
				var buf := PackedVector2Array()
				buf.resize(frames)
				for i in frames:
					var t := _time + float(i) / 24000.0
					var hum := sin(t * ambient_hum_freq * TAU) * _ambient_current_volume * 0.5
					var mod_slow := sin(t * 0.3) * 0.5 + 0.5
					var v := hum * (0.6 + mod_slow * 0.4)
					buf[i] = Vector2(v, v)
				playback.push_buffer(buf)
	_moan_timer += delta
	if _moan_timer >= _moan_cooldown:
		_moan_timer = 0.0
		_moan_cooldown = randf_range(moan_interval_min, moan_interval_max)
		_play_moan()
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("is_moving"):
		var moving = player.is_moving()
		if moving and not _player_was_moving:
			_footstep_interval = 0.5
			_footstep_timer = 0.0
		_player_was_moving = moving
		if moving:
			_footstep_timer += delta
			var interval := _footstep_interval
			if player.has_method("is_stealth") and player.is_stealth():
				interval = 0.8
			elif player.has_method("is_running") and player.is_running():
				interval = 0.25
			if _footstep_timer >= interval:
				_footstep_timer = 0.0
				_play_footstep()
