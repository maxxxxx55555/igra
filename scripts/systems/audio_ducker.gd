extends Node
## Ducking (docs/AUDIO_CONSISTENCY.md): when a cue the player must hear arrives (a boss roar or a new phase, a broadcast, the final night, the
## ending), the Music and Ambient buses drop 12 dB for 2 s: down in 0.15 s, held, back in 0.6 s. An Amplify effect on each bus does it, so the
## volume sliders keep their own say. A second cue inside the hold starts the dip again from where it is.
## A sting (an achievement, a quest, a secret, a restored district, a boss down) dips them 6 dB for 1.2 s (docs/AUDIO_COVERAGE.md, the mood matrix: stings and dialogue duck the music); it never lifts a deeper dip that is still held.

const BUSES: Array[StringName] = [&"Music", &"Ambient"]
const DUCK_DB: float = -12.0
const HOLD_SEC: float = 2.0
const STING_DB: float = -6.0
const STING_HOLD_SEC: float = 1.2
const DOWN_SEC: float = 0.15
const UP_SEC: float = 0.6

var _amps: Array[AudioEffectAmplify] = []
var _tween: Tween = null
var _db: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus: StringName in BUSES:
		var index: int = AudioServer.get_bus_index(bus)
		if index < 0:
			continue
		var amp := AudioEffectAmplify.new()
		AudioServer.add_bus_effect(index, amp)
		_amps.append(amp)
	EventBus.boss_spawned.connect(duck)
	EventBus.boss_phase_changed.connect(func(_phase: int) -> void: duck())
	EventBus.final_night_started.connect(duck)
	EventBus.game_won.connect(duck)
	EventBus.voice_line.connect(func(_text: String) -> void: duck())
	EventBus.achievement_unlocked.connect(_sting)
	EventBus.quest_completed.connect(_sting)
	EventBus.secret_found.connect(_sting)
	EventBus.district_restored.connect(_sting)
	EventBus.boss_defeated.connect(_sting)

func _sting(_a: Variant = null, _b: Variant = null) -> void:
	duck(STING_DB, STING_HOLD_SEC)

func duck(depth_db: float = DUCK_DB, hold_sec: float = HOLD_SEC) -> void:
	if _tween != null and _tween.is_valid():
		if _db < depth_db:
			return
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_db, _db, depth_db, DOWN_SEC)
	_tween.tween_interval(hold_sec)
	_tween.tween_method(_set_db, depth_db, 0.0, UP_SEC)

func _set_db(value: float) -> void:
	_db = value
	for amp: AudioEffectAmplify in _amps:
		amp.volume_db = value
