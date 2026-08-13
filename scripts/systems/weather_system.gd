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
@export var change_interval: float = 45.0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_timer = change_interval
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