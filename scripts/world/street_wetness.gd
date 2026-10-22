extends Node
## W5 of docs/VISUAL_PASS.md section 8: in rain the road reads wet. A child of the road tiles (the RoadMM of street_builder.gd): mat_wet_asphalt.tres lays reflective puddles over them as a blended overlay,
## so the textured soviet_road shows between the puddles. The wetness follows the rain of WeatherSystem (0 clear, 0.7 rain, 1 storm), the reflection follows the graphics tier (none on Low: the screen tap is
## skipped and only the mask reads wet), and with no rain the overlay is off and costs nothing.

const MATERIAL: String = "res://assets/env/mat_wet_asphalt.tres"
const REFLECTION_BY_TIER: Array[float] = [0.0, 0.5, 0.85, 0.85]
const MIN_RAIN: float = 0.05

var _road: MultiMeshInstance3D = null
var _mat: ShaderMaterial = null

func _ready() -> void:
	_road = get_parent() as MultiMeshInstance3D
	_mat = (load(MATERIAL) as ShaderMaterial).duplicate() as ShaderMaterial
	EventBus.weather_changed.connect(_on_weather_changed)
	EventBus.settings_changed.connect(_on_setting_changed)
	_apply()

func _on_weather_changed(_weather: int, _name: String, _fog: float, _rain: float) -> void:
	_apply()

func _on_setting_changed(key: String, _value: Variant) -> void:
	if key == "graphics_tier":
		_apply()

func _apply() -> void:
	var rain: float = WeatherSystem.rain_strength()
	_mat.set_shader_parameter("wetness", rain)
	_mat.set_shader_parameter("reflection_strength", REFLECTION_BY_TIER[clampi(int(SettingsManager.get_setting("graphics_tier", 2)), 0, REFLECTION_BY_TIER.size() - 1)])
	_road.material_overlay = _mat if rain > MIN_RAIN else null
