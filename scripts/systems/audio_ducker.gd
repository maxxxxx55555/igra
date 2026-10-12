extends Node
## Ducking (docs/AUDIO_CONSISTENCY.md): when a cue the player must hear arrives (a boss roar or a new phase, a broadcast, the final night, the
## ending), the Music and Ambient buses drop 12 dB for 2 s: down in 0.15 s, held, back in 0.6 s. An Amplify effect on each bus does it, so the
## volume sliders keep their own say. A second cue inside the hold starts the dip again from where it is.

const BUSES: Array[StringName] = [&"Music", &"Ambient"]
const DUCK_DB: float = -12.0
const HOLD_SEC: float = 2.0
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

func duck() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_db, _db, DUCK_DB, DOWN_SEC)
	_tween.tween_interval(HOLD_SEC)
	_tween.tween_method(_set_db, DUCK_DB, 0.0, UP_SEC)

func _set_db(value: float) -> void:
	_db = value
	for amp: AudioEffectAmplify in _amps:
		amp.volume_db = value
