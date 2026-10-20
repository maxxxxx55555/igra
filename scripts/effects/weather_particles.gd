extends Node3D
## W7 of docs/VISUAL_PASS.md section 8: the weather you see. One rain emitter (scenes/vfx/vfx_rain.tscn, a box of falling streaks) HEIGHT_M over the camera and one of drifting drops (scenes/vfx/vfx_dust.tscn, the droplets of fog)
## around it, both following the camera, switched by the weather of WeatherSystem: rain while it rains (the share of the emitter follows the strength of the rain, a storm is the whole of it), the drops while it is foggy.
## The amount of each emitter is scaled by the graphics tier on its own (SettingsManager, particle_ratio). The dust of a room stays with the districts.

const RAIN := preload("res://scenes/vfx/vfx_rain.tscn")
const DROPS := preload("res://scenes/vfx/vfx_dust.tscn")
const HEIGHT_M: float = 12.0
const MIN_RAIN: float = 0.05
const MIN_SHARE: float = 0.3

var _rain: GPUParticles3D = RAIN.instantiate() as GPUParticles3D
var _drops: GPUParticles3D = DROPS.instantiate() as GPUParticles3D

func _ready() -> void:
	name = "WeatherParticles"
	_rain.name = "Rain"
	_drops.name = "FogDrops"
	add_child(_rain)
	add_child(_drops)
	EventBus.weather_changed.connect(_on_weather_changed)
	_apply()

func _on_weather_changed(_weather: int, _name: String, _fog: float, _rain_strength: float) -> void:
	_apply()

func _apply() -> void:
	var rain: float = WeatherSystem.rain_strength()
	_rain.emitting = rain > MIN_RAIN
	_rain.amount_ratio = clampf(rain, MIN_SHARE, 1.0)
	_drops.emitting = WeatherSystem.current == WeatherSystem.Weather.FOG

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var at: Vector3 = camera.global_position
	_rain.global_position = Vector3(at.x, at.y + HEIGHT_M, at.z)
	_drops.global_position = at
