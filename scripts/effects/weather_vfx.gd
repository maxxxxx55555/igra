extends Node3D
class_name WeatherVFX

enum Weather { CLEAR, OVERCAST, RAIN, SNOW, FOG }

@export var district_id: StringName = &""
@export var initial: Weather = Weather.CLEAR
@export var auto: bool = true

var current: Weather = Weather.CLEAR

@onready var _rain: GPUParticles3D = $Rain
@onready var _snow: GPUParticles3D = $Snow
@onready var _fog: GPUParticles3D = $FogDrops
@onready var _env: WorldEnvironment = get_tree().root.get_node_or_null("WorldEnvironment") as WorldEnvironment

func _ready() -> void:
	if auto:
		set_weather(random_for(district_id))
	else:
		set_weather(initial)

func set_weather(w: Weather) -> void:
	if current == w:
		return
	_apply(current, false)
	current = w
	_apply(current, true)

func _process(_delta: float) -> void:
	pass

func _apply(w: Weather, on: bool) -> void:
	match w:
		Weather.RAIN:
			if _rain: _rain.emitting = on
		Weather.SNOW:
			if _snow: _snow.emitting = on
		Weather.FOG:
			if _fog: _fog.emitting = on
	if on and _env and _env.environment:
		_apply_env(w)

func _apply_env(w: Weather) -> void:
	var e := _env.environment
	var theme: Dictionary = DistrictThemes.get_theme(district_id) if DistrictThemes.has(district_id) else {}
	var fog_color: Color = theme.get("fog", Color("#cccccc"))
	match w:
		Weather.CLEAR:
			e.fog_enabled = false
			e.fog_density = 0.0
		Weather.OVERCAST:
			e.fog_enabled = false
		Weather.RAIN:
			e.fog_enabled = true
			e.fog_density = 0.01
			e.fog_light_color = fog_color.darkened(0.1)
		Weather.SNOW:
			e.fog_enabled = true
			e.fog_density = 0.015
			e.fog_light_color = Color("#e8eef4")
		Weather.FOG:
			e.fog_enabled = true
			e.fog_density = 0.04
			e.fog_light_color = fog_color

static func random_for(district_id: StringName) -> Weather:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(district_id)) + Time.get_ticks_msec()
	var roll := rng.randf()
	if roll < 0.5: return Weather.CLEAR
	if roll < 0.7: return Weather.OVERCAST
	if roll < 0.85: return Weather.RAIN
	if roll < 0.95: return Weather.SNOW
	return Weather.FOG
