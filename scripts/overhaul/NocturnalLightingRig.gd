class_name NocturnalLightingRig
extends Node3D

## Fixes crushed black foreground on Mali-G52 while keeping tense nocturnal horror readability.

@export var ambient_sky_color: Color = Color(0.11, 0.17, 0.23, 1.0)
@export var ambient_energy: float = 0.42
@export var fog_color: Color = Color(0.06, 0.095, 0.125, 1.0)
@export var fog_density: float = 0.022
@export var flashlight_color: Color = Color(1.0, 0.82, 0.56, 1.0)
@export var flashlight_energy: float = 4.2
@export var flashlight_range: float = 24.0
@export var flashlight_angle_deg: float = 34.0


func apply_to_world_environment(world_env: WorldEnvironment) -> void:
	if not is_instance_valid(world_env):
		return
	var env: Environment = world_env.environment
	if env == null:
		env = Environment.new()
		world_env.environment = env

	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.035, 0.055, 0.075, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient_sky_color
	env.ambient_light_energy = ambient_energy

	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.12
	env.tonemap_white = 4.0

	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_color = fog_color
	env.fog_density = fog_density
	env.fog_aerial_perspective = 0.25

	env.ssao_enabled = false
	env.ssr_enabled = false
	env.sdfgi_enabled = false
	env.volumetric_fog_enabled = false
	env.glow_enabled = false


func configure_player_flashlight(spot: SpotLight3D) -> void:
	if not is_instance_valid(spot):
		return
	spot.light_color = flashlight_color
	spot.light_energy = flashlight_energy
	spot.spot_range = flashlight_range
	spot.spot_angle = flashlight_angle_deg
	spot.spot_attenuation = 1.35
	spot.spot_angle_attenuation = 0.65
	spot.shadow_enabled = true
	spot.shadow_bias = 0.06
