# AudioManager — autoload 18. Смесь процедурного звука (шаги/щелчки/рык/
# события) и реальных сэмплов там, где они есть (ветер, дождь по металлу,
# гром, фонарик, урон, низкое HP). Громкость через бусы SFX/Master.
# Every sound is routed to a child of SFX (A01): Footsteps, Combat, UI, Environment.
extends Node

const MIX: int = 22050
const POOL: int = 4
## Distance low-pass of every positional sound: past the unit size the highs fall away (engine defaults: 5000 Hz, -24 dB).
const ATTEN_CUTOFF_HZ: float = 2400.0
const ATTEN_FILTER_DB: float = -14.0
## Positional one-shots share POOL_3D players instead of building one per sound.
const POOL_3D: int = 12
## Reverb by place (A2): the buses that sound in the world share a room that grows with the walls round the head. The tier gate keeps
## Low dry; the four sides and the sky are sensed from the head height every REVERB_SENSE_SEC; REVERB_MASK is the world layer.
const REVERB_BUSES: Array[StringName] = [&"Footsteps", &"Combat", &"Environment"]
const REVERB_MIN_TIER: int = 1
const REVERB_SENSE_SEC: float = 0.25
const REVERB_HEAD_M: float = 1.6
const REVERB_RAY_M: float = 12.0
const REVERB_MASK: int = 1
const REVERB_DIRECTIONS: Array[Vector3] = [Vector3.UP, Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]
const REVERB_WET_OPEN: float = 0.04
const REVERB_WET_CLOSED: float = 0.30
const REVERB_ROOM_OPEN: float = 0.35
const REVERB_ROOM_CLOSED: float = 0.70
const REVERB_FADE_SEC: float = 0.6

var _wind: AudioStreamPlayer
var _rain: AudioStreamPlayer
var _action: AudioStreamPlayer
var _heartbeat: AudioStreamPlayer
var _breath: AudioStreamPlayer
var _pool: Array = []
var _pool_3d: Array[AudioStreamPlayer3D] = []
var _next_3d: int = 0
var _reverbs: Array[AudioEffectReverb] = []
var _reverb_tween: Tween
var _enclosure: float = 0.0
var _last_state: int = 0
var _step_timer: float = 0.0
var _thunder_timer: float = 0.0
var _low_hp: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rain = _make_player(&"Environment")
	_action = _make_player(&"Combat")
	_action.name = "ActionLayer"
	for i in POOL:
		_pool.append(_make_player())
	_setup_reverb()
	_wind = _make_player(&"Environment")
	_wind.name = "WindLayer"
	_wind.stream = WIND_SFX
	_wind.volume_db = -26.0
	# CONTENT UX / FINAL INTEGRATION wave: real mastered rain over metal
	# roofs/cars replaces the procedural white-noise placeholder.
	_rain.stream = _force_loop(RAIN_SFX)
	_rain.volume_db = -40.0
	# Wind and rain wait for the first input like the music: boot stays silent (X17).
	MusicManager.audio_unlocked.connect(func() -> void:
		_wind.play()
		_rain.play())
	_action.volume_db = -80.0
	# Player-state loops (GDD low-HP tension cue): silent until HP<30%,
	# started/stopped once on threshold cross in _on_player_health, not
	# every frame - see _low_hp guard.
	_heartbeat = _make_player(&"Combat")
	_heartbeat.name = "HeartbeatLayer"
	_heartbeat.stream = _force_loop(HEARTBEAT_SFX)
	_heartbeat.volume_db = -6.0
	_breath = _make_player(&"Combat")
	_breath.name = "BreathLayer"
	_breath.stream = _force_loop(BREATH_SFX)
	_breath.volume_db = -6.0
	EventBus.weather_changed.connect(_on_weather)
	EventBus.player_health_changed.connect(_on_player_health)
	EventBus.player_state_changed.connect(func(s: int) -> void: _last_state = s)
	EventBus.flashlight_state_changed.connect(_on_flashlight_toggled)
	EventBus.light_disrupted.connect(func() -> void: _one_shot(_gen_glitch(), -8.0, &"Environment"))
	EventBus.player_detected.connect(func(_id: StringName) -> void: _one_shot(_gen_growl(), -12.0, &"Combat"))
	EventBus.enemy_attack.connect(func(_dmg: int) -> void: _one_shot(_gen_growl(), -8.0, &"Combat"))
	# Озвучка игровых событий (раньше были немыми).
	EventBus.item_picked_up.connect(func(_id: StringName) -> void: _one_shot(_gen_pickup(), -10.0, &"UI"))
	EventBus.purchase_success.connect(func(_id: StringName) -> void: _one_shot(_gen_coin(), -8.0, &"UI"))
	EventBus.purchase_failed.connect(func(_id: String, _r: String) -> void: _one_shot(_gen_error(), -12.0, &"UI"))
	EventBus.puzzle_solved.connect(func(_p: StringName, _d: StringName) -> void: _one_shot(_gen_success(), -6.0, &"UI"))
	EventBus.district_restored.connect(func(_a: StringName, _b: int) -> void: _one_shot(_gen_powerup(), -4.0, &"UI"))
	# Пять событий теперь озвучивает UISFX настоящими стингерами на шине UI
	# (docs/CERT_UIAUDIO.md §4). Процедурный вариант остаётся запасным и молчит,
	# пока файл стингера на месте, иначе на событие звучали бы оба сразу.
	EventBus.achievement_unlocked.connect(func(_id: StringName) -> void:
		if not _has_ui_sting("achievement_sting"): _one_shot(_gen_fanfare(), -6.0, &"UI"))
	EventBus.quest_completed.connect(func(_id: StringName) -> void:
		if not _has_ui_sting("daily_complete_sting"): _one_shot(_gen_fanfare(), -8.0, &"UI"))
	EventBus.secret_found.connect(func(_id: StringName) -> void:
		if not _has_ui_sting("secret_discovery_sting"): _one_shot(_gen_chime(), -8.0, &"UI"))
	EventBus.enemy_killed.connect(func(_id: StringName) -> void: _one_shot(_gen_thud(), -10.0, &"Combat"))
	EventBus.boss_defeated.connect(func() -> void:
		if not _has_ui_sting("boss_sting"): _one_shot(_gen_boom(), -3.0, &"UI"))
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.ui_screen_opened.connect(func(_id: StringName) -> void:
		if not _has_ui_sting("menu_click"): _one_shot(_gen_click(), -16.0, &"UI"))

static func _has_ui_sting(name: String) -> bool:
	return ResourceLoader.exists("res://assets/audio/ui/ui_" + name + ".ogg")

const HURT_SFX := preload("res://assets/audio/sfx/sfx_hurt.wav")
const WIND_SFX := preload("res://assets/audio/sfx/amb_wind.wav")
const FLASHLIGHT_ON_SFX := preload("res://assets/audio/sfx/sfx_flashlight_on.wav")
const FLASHLIGHT_OFF_SFX := preload("res://assets/audio/sfx/sfx_flashlight_off.wav")
const RAIN_SFX := preload("res://assets/audio/one_shots/rain_on_metal_loop.ogg")
const THUNDER_NEAR_SFX := preload("res://assets/audio/one_shots/thunder_near.wav")
const THUNDER_FAR_SFX := preload("res://assets/audio/one_shots/thunder_far.wav")
const HEARTBEAT_SFX := preload("res://assets/audio/one_shots/heartbeat_low_loop.ogg")
const BREATH_SFX := preload("res://assets/audio/one_shots/breath_low_loop.ogg")
const LOW_HP_THRESHOLD: float = 0.30

## .import не в репозитории (см. .gitignore) - loop_mode/loop сбрасывается
## на дефолт на свежем клоне, тот же паттерн, что MusicDirector._force_loop().
static func _force_loop(s: AudioStream) -> AudioStream:
	if s is AudioStreamWAV:
		(s as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true
	return s

func _on_player_health(ratio: float) -> void:
	var low := ratio < LOW_HP_THRESHOLD
	if low == _low_hp:
		return
	_low_hp = low
	if low:
		_heartbeat.play()
		_breath.play()
	else:
		_heartbeat.stop()
		_breath.stop()

## Щелчок фонаря: реальные сэмплы вместо процедурного клика.
func _on_flashlight_toggled(enabled: bool) -> void:
	_one_shot(FLASHLIGHT_ON_SFX if enabled else FLASHLIGHT_OFF_SFX, -10.0, &"Environment")

func _on_player_damaged(_amount: int) -> void:
	_one_shot(HURT_SFX, -8.0, &"Combat")

const SFX_DIR := "res://assets/audio/sfx/"

## bus: an SFX child (Footsteps, Combat, UI, Environment); plain SFX when nothing fits better.
func play_sfx(stream: AudioStream, volume_db: float = 0.0, bus: StringName = &"SFX") -> void:
	if stream:
		_one_shot(stream, volume_db, bus)

## Positional one-shot. Every current caller is a combat sound (weapons, monster
## cues, hits, player hurt), so Combat is the default; pass &"Environment" for props. Returns the pooled player that took it.
func play_sound_3d(stream: AudioStream, position: Vector3, volume_db: float = 0.0, bus: StringName = &"Combat") -> AudioStreamPlayer3D:
	if not stream:
		return null
	var player := _take_player_3d()
	player.stream = stream
	player.volume_db = volume_db
	player.bus = bus
	player.global_position = position
	player.play()
	return player

## A free player of the pool (A3). It grows one player at a time up to POOL_3D; with every one busy the next in turn is cut off.
func _take_player_3d() -> AudioStreamPlayer3D:
	for pooled in _pool_3d:
		if not pooled.playing:
			return pooled
	if _pool_3d.size() < POOL_3D:
		var fresh := AudioStreamPlayer3D.new()
		fresh.attenuation_filter_cutoff_hz = ATTEN_CUTOFF_HZ
		fresh.attenuation_filter_db = ATTEN_FILTER_DB
		add_child(fresh)
		_pool_3d.append(fresh)
		return fresh
	_next_3d = (_next_3d + 1) % POOL_3D
	return _pool_3d[_next_3d]

func _setup_reverb() -> void:
	for bus in REVERB_BUSES:
		_reverbs.append(AudioServer.get_bus_effect(AudioServer.get_bus_index(bus), 0) as AudioEffectReverb)
	_apply_reverb_tier(int(SettingsManager.get_setting("graphics_tier", 2)))
	EventBus.settings_changed.connect(func(key: String, value: Variant) -> void:
		if key == "graphics_tier":
			_apply_reverb_tier(int(value)))
	var timer := Timer.new()
	timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	timer.wait_time = REVERB_SENSE_SEC
	timer.timeout.connect(_sense_reverb)
	add_child(timer)
	timer.start()

func _apply_reverb_tier(tier: int) -> void:
	for bus in REVERB_BUSES:
		AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index(bus), 0, tier >= REVERB_MIN_TIER)

## The share of the five rays (sky and four sides, REVERB_RAY_M long) that meet the world from the player's head. The query needs the
## physics step, hence the physics timer.
func _sense_reverb() -> void:
	var player := get_tree().get_first_node_in_group("player") as CollisionObject3D
	if player == null:
		return
	var head: Vector3 = player.global_position + Vector3.UP * REVERB_HEAD_M
	var space := player.get_world_3d().direct_space_state
	var hits: int = 0
	for direction in REVERB_DIRECTIONS:
		var query := PhysicsRayQueryParameters3D.create(head, head + direction * REVERB_RAY_M, REVERB_MASK)
		query.exclude = [player.get_rid()]
		if not space.intersect_ray(query).is_empty():
			hits += 1
	set_enclosure(float(hits) / REVERB_DIRECTIONS.size())

## 0 is open sky, 1 is walled in: the reverbs follow it over REVERB_FADE_SEC so a doorway does not click. The same amount again keeps the
## running fade: restarting it on every sensing tick would stretch the fade to a crawl.
func set_enclosure(amount: float) -> void:
	var closed: float = clampf(amount, 0.0, 1.0)
	if is_equal_approx(closed, _enclosure):
		return
	_enclosure = closed
	if _reverb_tween != null and _reverb_tween.is_valid():
		_reverb_tween.kill()
	_reverb_tween = create_tween().set_parallel(true)
	for reverb in _reverbs:
		_reverb_tween.tween_property(reverb, "wet", lerpf(REVERB_WET_OPEN, REVERB_WET_CLOSED, closed), REVERB_FADE_SEC)
		_reverb_tween.tween_property(reverb, "room_size", lerpf(REVERB_ROOM_OPEN, REVERB_ROOM_CLOSED, closed), REVERB_FADE_SEC)

func play_music(stream: AudioStream) -> void:
	if not stream:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Music" if AudioServer.get_bus_index("Music") >= 0 else "Master"
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

func set_action_active(active: bool) -> void:
	_action.volume_db = -10.0 if active else -80.0

func set_action_stream(stream: AudioStream) -> void:
	_action.stream = stream
	if stream and not _action.playing:
		_action.play()

func _make_player(bus: StringName = &"SFX") -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
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
			_one_shot(_gen_step(), -14.0, &"Footsteps")
	if _thunder_timer > 0.0:
		_thunder_timer -= delta
		if _thunder_timer <= 0.0:
			# ~40% near / 60% far - a storm reads as mostly distant rolls
			# with the occasional close crack, not every strike overhead.
			var clap: AudioStream = THUNDER_NEAR_SFX if randf() < 0.4 else THUNDER_FAR_SFX
			_one_shot(clap, -6.0, &"Environment")
			_thunder_timer = randf_range(6.0, 14.0)

func _on_weather(_w: int, _name: String, _fog: float, rain: float) -> void:
	_rain.volume_db = linear_to_db(clampf(rain, 0.0, 1.0)) - 12.0
	if _w == 3:
		_thunder_timer = randf_range(2.0, 6.0)
	else:
		_thunder_timer = 0.0

func _one_shot(stream: AudioStream, vol: float, bus: StringName) -> void:
	for p in _pool:
		if not p.playing:
			p.stream = stream
			p.volume_db = vol
			p.bus = bus
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
