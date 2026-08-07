extends Node

@export var rain_particles: GPUParticles3D
@export var fog_density_max: float = 0.08
@export var fog_density_min: float = 0.03
var _weather_active: bool = false
var _weather_type: String = "clear"  # clear, rain, fog

func start_rain() -> void:
	_weather_type = "rain"
	if rain_particles:
		rain_particles.emitting = true
	_tween_fog(fog_density_max)

func stop_weather() -> void:
	_weather_type = "clear"
	if rain_particles:
		rain_particles.emitting = false
	_tween_fog(fog_density_min)

func _tween_fog(target: float) -> void:
	var cam := get_viewport().get_camera_3d()
	var env := cam.get_world_3d().environment if cam else null
	if env and env.fog_enabled:
		var tween := create_tween()
		tween.tween_property(env, "fog_density", target, 3.0)
