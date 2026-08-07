extends Node
## Autoload "DayNight". day_duration_sec = full 24h cycle. Updates WorldEnvironment.

@export var day_duration_sec: float = 1440.0
@export var start_hour: float = 20.0

var _t: float = 0.0
var _env: WorldEnvironment

func _ready() -> void:
	_env = get_tree().get_first_node_in_group(&"world_environment") as WorldEnvironment
	if _env == null:
		_env = get_tree().root.get_node_or_null("Main/WorldEnvironment") as WorldEnvironment
	set_process(true)
	_apply(get_hour())

func _process(delta: float) -> void:
	_t += delta
	_apply(get_hour())

func get_hour() -> float:
	return fmod(start_hour + _t / day_duration_sec * 24.0, 24.0)

func _apply(hours: float) -> void:
	if _env == null or _env.environment == null:
		return
	var e: Environment = _env.environment
	var night: float = 1.0 - clamp(1.0 - abs(hours - 12.0) / 6.0, 0.0, 1.0)
	var sky: Color = Color(0.05, 0.07, 0.12).lerp(Color(0.55, 0.70, 0.90), 1.0 - night)
	e.background_mode = Environment.BG_COLOR
	e.background_color = sky
	e.ambient_light_energy = 0.15 + 0.45 * (1.0 - night)
	e.ambient_light_color = Color(1.0, 0.9, 0.7).lerp(Color(0.4, 0.5, 0.8), night)
	e.fog_density = 0.008 + 0.012 * night