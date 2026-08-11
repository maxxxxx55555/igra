class_name FogSetup
extends Node3D

@onready var fog_volume: FogVolume = get_node_or_null("../FogVolume")
@onready var world_env: WorldEnvironment = get_node_or_null("../WorldEnvironment")


func _ready() -> void:
	_configure_fog()

func _configure_fog() -> void:
	if world_env:
		var env: Environment = world_env.environment
		if env:
			env.fog_enabled = true
			env.fog_density = 0.015
			env.fog_light_color = Color("#1a2133")
			env.fog_sun_scatter = 0.1

