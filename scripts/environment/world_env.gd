extends WorldEnvironment

enum Weather { NIGHT, RAIN, FOG, STORM }

@export var weather: Weather = Weather.NIGHT:
    set(v):
        weather = v
        _apply_weather(v)

@export var base_visibility: float = 1.0

func _ready() -> void:
    _apply_weather(weather)

func _apply_weather(w: Weather) -> void:
    var env := environment
    if not env:
        return
    match w:
        Weather.NIGHT:
            env.fog_density = 0.008
            env.ambient_light_energy = 0.32 * base_visibility
        Weather.RAIN:
            env.fog_density = 0.015
            env.ambient_light_energy = 0.25 * base_visibility
        Weather.FOG:
            env.fog_density = 0.035
            env.ambient_light_energy = 0.18 * base_visibility
        Weather.STORM:
            env.fog_density = 0.025
            env.ambient_light_energy = 0.15 * base_visibility
    _print_light()

func _print_light() -> void:
    var moon := get_tree().root.find_child("Moon", true, false) as DirectionalLight3D
    var player := get_tree().root.find_child("Player", true, false)
    var omni := player.find_child("PlayerGlow", true, false) as OmniLight3D if player else null
    var env := environment

