class_name MenuCanonAtmosphereDirector
extends RefCounted

## Aligns WorldEnvironment fog, ACES exposure, streetlight color/cones, and facade
## window density to the moody wet-night main menu reference for Last Streetlight.

const FOG_MIST_DEFAULT := Color(0.078, 0.129, 0.149, 1.0)  # #142126 cold slate-teal mist
const SODIUM_KEY_COLOR := Color(0.831, 0.663, 0.306, 1.0)  # #d4a94e
const WINDOW_DIM_COLOR := Color(0.68, 0.52, 0.25, 1.0)

const STAGE_AMBIENT: Dictionary = {
	"DARK": 0.03,
	"PARTIAL": 0.06,
	"STREETS": 0.11,
	"FULL": 0.16,
}

const STAGE_FOG_DENSITY: Dictionary = {
	"DARK": 0.020,
	"PARTIAL": 0.018,
	"STREETS": 0.016,
	"FULL": 0.015,
}

const STAGE_WINDOW_ENERGY: Dictionary = {
	"DARK": 0.02,
	"PARTIAL": 0.30,
	"STREETS": 0.62,
	"FULL": 0.95,
}


static func apply_environment_canon(
	world_env: WorldEnvironment,
	stage: String = "STREETS",
	district_fog_tint: Color = FOG_MIST_DEFAULT
) -> bool:
	if not is_instance_valid(world_env) or world_env.environment == null:
		return false
	var env: Environment = world_env.environment
	var key: String = stage.to_upper()
	var amb_energy: float = float(STAGE_AMBIENT.get(key, 0.11))
	var fog_dens: float = float(STAGE_FOG_DENSITY.get(key, 0.016))

	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.04
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = district_fog_tint.lerp(FOG_MIST_DEFAULT, 0.55)
	env.ambient_light_energy = amb_energy

	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_color = district_fog_tint.lerp(FOG_MIST_DEFAULT, 0.65)
	env.fog_light_energy = 0.72 if key == "DARK" else 0.92
	env.fog_density = fog_dens
	env.fog_sky_affect = 0.85

	env.glow_enabled = false
	env.ssao_enabled = false
	env.ssil_enabled = false
	return true


static func apply_streetlight_canon(light: Light3D, energy: float = 2.6) -> bool:
	if not is_instance_valid(light):
		return false
	light.light_color = SODIUM_KEY_COLOR
	light.light_energy = clampf(energy, 0.0, 4.5)
	return true


static func calm_checkerboard_windows(mat: StandardMaterial3D, stage: String) -> bool:
	if not is_instance_valid(mat):
		return false
	var key: String = stage.to_upper()
	var energy: float = float(STAGE_WINDOW_ENERGY.get(key, 0.28))
	mat.emission_enabled = energy > 0.01
	mat.emission = WINDOW_DIM_COLOR
	mat.emission_energy_multiplier = energy
	mat.roughness = clampf(mat.roughness, 0.72, 0.96)
	return true


static func tune_grade_for_menu_canon(mat: ShaderMaterial, is_mobile: bool = false) -> bool:
	if not is_instance_valid(mat):
		return false
	mat.set_shader_parameter("grade_strength", 0.42 if is_mobile else 0.46)
	mat.set_shader_parameter("halation_strength", 0.16 if is_mobile else 0.20)
	mat.set_shader_parameter("halation_threshold", 0.56)
	mat.set_shader_parameter("vignette_strength", 0.18 if is_mobile else 0.22)
	mat.set_shader_parameter("grain_strength", 0.015 if is_mobile else 0.022)
	mat.set_shader_parameter("contrast_lift", 1.03)
	return true
