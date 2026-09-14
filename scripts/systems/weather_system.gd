extends Node
enum Weather { CLEAR, RAIN, FOG, STORM, WIND }
const WEATHER_COUNT: int = 5
## Названия погоды уходят в сигнал weather_changed и показываются игроку —
## поэтому это ключи локализации, а не русские строки (языков в игре 13).
const NAME_KEYS := ["WEATHER_CLEAR", "WEATHER_RAIN", "WEATHER_FOG", "WEATHER_STORM", "WEATHER_WIND"]
const FOG_STRENGTH := { Weather.CLEAR: 0.0, Weather.RAIN: 0.25, Weather.FOG: 0.7, Weather.STORM: 0.55, Weather.WIND: 0.1 }
const RAIN_STRENGTH := { Weather.CLEAR: 0.0, Weather.RAIN: 0.7, Weather.FOG: 0.0, Weather.STORM: 1.0, Weather.WIND: 0.2 }
var current: int = Weather.CLEAR
var _timer: float = 0.0
var _lang_connected: bool = false
@export var change_interval: float = 45.0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_timer = change_interval
	# Static audit 2026-09-08: WeatherSystem is an earlier autoload than
	# LocalizationManager (project.godot order), so this first _emit()
	# used to run before any language was loaded - t() fell through to
	# the raw key. Harmless today (no listener displays the name), but
	# deferring costs nothing and removes the trap for future listeners.
	call_deferred("_emit")
	# Re-emit on locale switch so any future/mod listener that displays
	# weather_name gets the translated string instead of holding the
	# pre-switch language (edge case: switching language mid-run during
	# a non-CLEAR weather left the HUD label in the old locale until the
	# next random weather change, up to 45s later).
	call_deferred("_connect_lang")

func _connect_lang() -> void:
	if _lang_connected:
		return
	var lm := get_node_or_null("/root/LocalizationManager")
	if lm != null and lm.has_signal("language_changed"):
		if not lm.language_changed.is_connected(_on_language_changed):
			lm.language_changed.connect(_on_language_changed)
		_lang_connected = true

func _on_language_changed(_lang: String) -> void:
	_emit()

func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = change_interval
		current = randi() % WEATHER_COUNT
		_emit()
func _emit() -> void:
	EventBus.weather_changed.emit(current, LocalizationManager.t(NAME_KEYS[current]), FOG_STRENGTH[current], RAIN_STRENGTH[current])
func fog_strength() -> float:
	return FOG_STRENGTH[current]
func rain_strength() -> float:
	return RAIN_STRENGTH[current]