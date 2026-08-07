extends Node3D

func _ready() -> void:
	var env := WorldEnvironment.new()
	env.name = "NightEnvironment"
	add_child(env)
	var e := Environment.new()
	env.environment = e
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.02, 0.03, 0.07)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.07, 0.09, 0.15)
	e.ambient_light_energy = 0.45
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.fog_enabled = true
	e.fog_light_color = Color(0.05, 0.06, 0.11)
	e.fog_density = 0.012
	var moon := DirectionalLight3D.new()
	moon.name = "MoonLight"
	moon.light_color = Color(0.92, 0.94, 1.0)
	moon.light_energy = 0.35
	moon.shadow_enabled = false
	moon.rotation_degrees = Vector3(-55, -40, 0)
	add_child(moon)