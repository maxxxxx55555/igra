# AudioManager — autoload 18. ПРОЦЕДУРНЫЙ звук (дождь/гром/шаги/гул/щелчки/рык),
# без внешних аудиофайлов. Громкость через бусы SFX/Master.
extends Node

const MIX: int = 22050
const POOL: int = 4

var _ambient: AudioStreamPlayer
var _wind: AudioStreamPlayer
var _rain: AudioStreamPlayer
var _threat: AudioStreamPlayer
var _action: AudioStreamPlayer
var _pool: Array = []
var _last_state: int = 0
var _step_timer: float = 0.0
var _thunder_timer: float = 0.0
var _threat_timer: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ambient = _make_player()
	_rain = _make_player()
	_threat = _make_player()
	_threat.name = "ThreatLayer"
	_action = _make_player()
	_action.name = "ActionLayer"
	for i in POOL:
		_pool.append(_make_player())
	_ambient.stream = _gen_drone(2.0)
	_ambient.volume_db = -18.0
	_ambient.play()
	# Ветер — реальный зацикленный сэмпл поверх процедурного дрона.
	_wind = _make_player()
	_wind.name = "WindLayer"
	_wind.stream = WIND_SFX
	_wind.volume_db = -26.0
	_wind.play()
	_rain.stream = _gen_rain(2.0)
	_rain.volume_db = -40.0
	_rain.play()
	# Слой threat: тихий пульсирующий гул, громкость ведёт близость монстров (_update_threat).
	_threat.stream = _gen_threat_drone(2.0)
	_threat.volume_db = -80.0
	_threat.play()
	_action.volume_db = -80.0
	EventBus.weather_changed.connect(_on_weather)
	EventBus.player_state_changed.connect(func(s: int) -> void: _last_state = s)
	EventBus.flashlight_state_changed.connect(_on_flashlight_toggled)
	EventBus.light_disrupted.connect(func() -> void: _one_shot(_gen_glitch(), -8.0))
	EventBus.monster_spotted.connect(func(_id: StringName) -> void: _one_shot(_gen_growl(), -12.0))
	EventBus.enemy_attack.connect(func(_dmg: int) -> void: _one_shot(_gen_growl(), -8.0))
	# Озвучка игровых событий (раньше были немыми).
	EventBus.item_picked_up.connect(func(_id: StringName) -> void: _one_shot(_gen_pickup(), -10.0))
	EventBus.purchase_success.connect(func(_id: StringName) -> void: _one_shot(_gen_coin(), -8.0))
	EventBus.purchase_failed.connect(func(_id: String, _r: String) -> void: _one_shot(_gen_error(), -12.0))
	EventBus.puzzle_solved.connect(func(_p: StringName, _d: StringName) -> void: _one_shot(_gen_success(), -6.0))
	EventBus.district_restored.connect(func(_a: StringName, _b: int) -> void: _one_shot(_gen_powerup(), -4.0))
	EventBus.achievement_unlocked.connect(func(_id: StringName) -> void: _one_shot(_gen_fanfare(), -6.0))
	EventBus.quest_completed.connect(func(_id: StringName) -> void: _one_shot(_gen_fanfare(), -8.0))
	EventBus.secret_found.connect(func(_id: StringName) -> void: _one_shot(_gen_chime(), -8.0))
	EventBus.enemy_killed.connect(func(_id: StringName) -> void: _one_shot(_gen_thud(), -10.0))
	EventBus.boss_defeated.connect(func() -> void: _one_shot(_gen_boom(), -3.0))
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.ui_screen_opened.connect(func(_id: StringName) -> void: _one_shot(_gen_click(), -16.0))

const HURT_SFX := preload("res://assets/audio/sfx/sfx_hurt.wav")
const WIND_SFX := preload("res://assets/audio/sfx/amb_wind.wav")
const FLASHLIGHT_ON_SFX := preload("res://assets/audio/sfx/sfx_flashlight_on.wav")
const FLASHLIGHT_OFF_SFX := preload("res://assets/audio/sfx/sfx_flashlight_off.wav")

## Щелчок фонаря: реальные сэмплы вместо процедурного клика.
func _on_flashlight_toggled(enabled: bool) -> void:
	_one_shot(FLASHLIGHT_ON_SFX if enabled else FLASHLIGHT_OFF_SFX, -10.0)

func _on_player_damaged(_amount: int) -> void:
	_one_shot(HURT_SFX, -8.0)

const SFX_DIR := "res://assets/audio/sfx/"

func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream:
		_one_shot(stream, volume_db)

func play_sound_3d(stream: AudioStream, position: Vector3, volume_db: float = 0.0) -> void:
	if not stream:
		return
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = volume_db
	player.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
	player.finished.connect(player.queue_free)
	add_child(player)
	player.global_position = position
	player.play()

func play_music(stream: AudioStream) -> void:
	if not stream:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Music" if AudioServer.get_bus_index("Music") >= 0 else "Master"
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

func set_threat_level(level: float) -> void:
	_threat.volume_db = lerpf(-80.0, -10.0, clampf(level, 0.0, 1.0))

func set_action_active(active: bool) -> void:
	_action.volume_db = -10.0 if active else -80.0

func set_threat_stream(stream: AudioStream) -> void:
	_threat.stream = stream
	if stream and not _threat.playing:
		_threat.play()

func set_action_stream(stream: AudioStream) -> void:
	_action.stream = stream
	if stream and not _action.playing:
		_action.play()

func _make_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
	add_child(p)
	return p

func _process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	var moving := (_last_state == 1 or _last_state == 2)
	if moving:
		_step_timer -= delta
		if _step_timer <= 0.0:
			_step_timer = 0.32 if _last_state == 1 else 0.22
			_one_shot(_gen_step(), -14.0)
	if _thunder_timer > 0.0:
		_thunder_timer -= delta
		if _thunder_timer <= 0.0:
			_one_shot(_gen_thunder(), -6.0)
			_thunder_timer = randf_range(6.0, 14.0)
	_threat_timer -= delta
	if _threat_timer <= 0.0:
		_threat_timer = 0.25
		_update_threat()

## Громкость слоя напряжения = близость ближайшего монстра (18 м -> 0, вплотную -> 1).
func _update_threat() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		set_threat_level(0.0)
		return
	var nearest: float = 1e9
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node3D and is_instance_valid(e):
			nearest = minf(nearest, (e as Node3D).global_position.distance_to(player.global_position))
	if nearest > 18.0:
		set_threat_level(0.0)
		return
	set_threat_level(clampf(1.0 - nearest / 18.0, 0.0, 1.0) * 0.85)

func _on_weather(_w: int, _name: String, _fog: float, rain: float) -> void:
	_rain.volume_db = linear_to_db(clampf(rain, 0.0, 1.0)) - 12.0
	if _w == 3:
		_thunder_timer = randf_range(2.0, 6.0)
	else:
		_thunder_timer = 0.0

func _one_shot(stream: AudioStream, vol: float) -> void:
	for p in _pool:
		if not p.playing:
			p.stream = stream
			p.volume_db = vol
			p.play()
			return

func _buf(seconds: float) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(int(seconds * MIX))
	return b

func _wrap(b: PackedByteArray) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_8_BITS
	s.mix_rate = MIX
	s.stereo = false
	s.data = b
	return s

func _wrap_loop(b: PackedByteArray) -> AudioStreamWAV:
	var s := _wrap(b)
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = b.size()
	return s

func _gen_rain(seconds: float) -> AudioStreamWAV:
	var b := _buf(seconds)
	var prev := 128
	for i in b.size():
		var n := randi() % 256
		prev = (prev * 3 + n) / 4
		b[i] = clampi(prev, 0, 255)
	return _wrap_loop(b)

func _gen_drone(seconds: float) -> AudioStreamWAV:
	var b := _buf(seconds)
	for i in b.size():
		var t := float(i) / float(MIX)
		var v := sin(t * 55.0 * TAU) * 0.4 + sin(t * 82.5 * TAU) * 0.2
		v += (float(randi() % 100) / 100.0 - 0.5) * 0.1
		b[i] = clampi(int(128.0 + v * 90.0), 0, 255)
	return _wrap_loop(b)

func _gen_step() -> AudioStreamWAV:
	var b := _buf(0.08)
	for i in b.size():
		var env := 1.0 - float(i) / float(b.size())
		var v := (float(randi() % 256) / 255.0 - 0.5) * env
		b[i] = clampi(int(128.0 + v * 140.0), 0, 255)
	return _wrap(b)

func _gen_click() -> AudioStreamWAV:
	var b := _buf(0.05)
	for i in b.size():
		var t := float(i) / float(MIX)
		var env := 1.0 - float(i) / float(b.size())
		var v := sin(t * 1800.0 * TAU) * env
		b[i] = clampi(int(128.0 + v * 120.0), 0, 255)
	return _wrap(b)

func _gen_thunder() -> AudioStreamWAV:
	var b := _buf(1.2)
	var prev := 128
	for i in b.size():
		var env := exp(-float(i) / float(MIX) * 2.5)
		var n := randi() % 256
		prev = (prev * 2 + n) / 3
		var v := (float(prev) / 255.0 - 0.5) * env
		v += sin(float(i) / float(MIX) * 40.0 * TAU) * 0.3 * env
		b[i] = clampi(int(128.0 + v * 150.0), 0, 255)
	return _wrap(b)

func _gen_growl() -> AudioStreamWAV:
	var b := _buf(0.5)
	for i in b.size():
		var t := float(i) / float(MIX)
		var env := 1.0 - float(i) / float(b.size())
		var v := sin(t * (70.0 + sin(t * 8.0) * 20.0) * TAU) * env
		v += (float(randi() % 100) / 100.0 - 0.5) * 0.3 * env
		b[i] = clampi(int(128.0 + v * 120.0), 0, 255)
	return _wrap(b)

func _gen_glitch() -> AudioStreamWAV:
	var b := _buf(0.15)
	for i in b.size():
		var v := float(randi() % 256) / 255.0 - 0.5
		b[i] = clampi(int(128.0 + v * 160.0), 0, 255)
	return _wrap(b)

## Последовательность тонов с затуханием каждой ноты (для UI/событий).
func _gen_notes(freqs: Array, note_dur: float = 0.09, amp: float = 110.0) -> AudioStreamWAV:
	var per: int = int(note_dur * MIX)
	var b := PackedByteArray()
	b.resize(per * freqs.size())
	var idx: int = 0
	for f_v in freqs:
		var f: float = float(f_v)
		for i in per:
			var t := float(i) / float(MIX)
			var env := 1.0 - float(i) / float(per)
			var v := sin(t * f * TAU) * env * env
			b[idx] = clampi(int(128.0 + v * amp), 0, 255)
			idx += 1
	return _wrap(b)

func _gen_pickup() -> AudioStreamWAV:
	return _gen_notes([880.0, 1320.0], 0.06)

func _gen_coin() -> AudioStreamWAV:
	return _gen_notes([1568.0, 2093.0], 0.07)

func _gen_success() -> AudioStreamWAV:
	return _gen_notes([523.0, 659.0, 784.0], 0.10)

func _gen_fanfare() -> AudioStreamWAV:
	return _gen_notes([523.0, 659.0, 784.0, 1047.0], 0.12)

func _gen_chime() -> AudioStreamWAV:
	return _gen_notes([1047.0, 1568.0], 0.18, 90.0)

func _gen_powerup() -> AudioStreamWAV:
	return _gen_notes([392.0, 523.0, 659.0, 880.0], 0.14)

func _gen_error() -> AudioStreamWAV:
	return _gen_notes([196.0, 165.0], 0.13, 95.0)

func _gen_thud() -> AudioStreamWAV:
	var b := _buf(0.22)
	for i in b.size():
		var t := float(i) / float(MIX)
		var env := exp(-t * 18.0)
		var v := sin(t * 90.0 * TAU) * env
		v += (float(randi() % 100) / 100.0 - 0.5) * 0.45 * env
		b[i] = clampi(int(128.0 + v * 130.0), 0, 255)
	return _wrap(b)

func _gen_boom() -> AudioStreamWAV:
	var b := _buf(1.4)
	var prev := 128
	for i in b.size():
		var t := float(i) / float(MIX)
		var env := exp(-t * 2.0)
		var n := randi() % 256
		prev = (prev * 2 + n) / 3
		var v := sin(t * (46.0 - t * 8.0) * TAU) * env
		v += (float(prev) / 255.0 - 0.5) * 0.5 * env
		b[i] = clampi(int(128.0 + v * 150.0), 0, 255)
	return _wrap(b)

## Пульсирующий гул напряжения (луп) — громкостью управляет _update_threat().
func _gen_threat_drone(seconds: float) -> AudioStreamWAV:
	var b := _buf(seconds)
	for i in b.size():
		var t := float(i) / float(MIX)
		var pulse := 0.55 + 0.45 * sin(t * 1.6 * TAU)
		var v := sin(t * 42.0 * TAU) * 0.5 * pulse
		v += sin(t * 63.0 * TAU) * 0.22 * pulse
		v += (float(randi() % 100) / 100.0 - 0.5) * 0.08
		b[i] = clampi(int(128.0 + v * 95.0), 0, 255)
	return _wrap_loop(b)