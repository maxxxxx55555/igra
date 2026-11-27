class_name ShadowAndRestorationRig
extends RefCounted

## Configures crisp, grounded real-time shadows within mobile limits (<= 4 dynamic lights)
## and implements the 4-Stage District Restoration lighting curve from the concept board:
##   Stage 0 (0%):   Full Darkness — only minimal cold moonlight + player flashlight.
##   Stage 1 (33%):  Partial Light — 35% of district streetlamps ignite.
##   Stage 2 (75%):  Lit Streets   — 75% of streetlamps active, fog recedes slightly.
##   Stage 3 (100%): Restored      — 100% warm amber streetlamps + safe exit beacon.


# Keep shadowed light passes on the road, walls and playable silhouettes.
# The decorative meshes still receive the ambient grade and emissive light.
const WORLD_CASTER_LAYER := 1 << 15
const LOCAL_RECEIVER_LAYER := 1 << 14
const MOON_RECEIVER_LAYER := 1 << 13


static func configure_mobile_shadows(flashlight: SpotLight3D, key_moon: DirectionalLight3D, primary_lamp: Light3D = null) -> void:
	if flashlight != null and is_instance_valid(flashlight):
		flashlight.shadow_enabled = true
		flashlight.shadow_caster_mask = WORLD_CASTER_LAYER
		flashlight.light_cull_mask = LOCAL_RECEIVER_LAYER
		flashlight.shadow_bias = 0.035
		flashlight.shadow_normal_bias = 1.4
		flashlight.shadow_blur = 1.5
		flashlight.spot_attenuation = 1.15
	if key_moon != null and is_instance_valid(key_moon):
		key_moon.shadow_enabled = true
		key_moon.shadow_caster_mask = WORLD_CASTER_LAYER
		key_moon.light_cull_mask = MOON_RECEIVER_LAYER
		key_moon.shadow_bias = 0.05
		key_moon.shadow_normal_bias = 1.6
		key_moon.shadow_blur = 2.0
		key_moon.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		key_moon.directional_shadow_max_distance = 13.0
		key_moon.shadow_opacity = 0.74
	if primary_lamp != null and is_instance_valid(primary_lamp):
		primary_lamp.shadow_enabled = true
		primary_lamp.shadow_caster_mask = WORLD_CASTER_LAYER
		primary_lamp.light_cull_mask = LOCAL_RECEIVER_LAYER
		primary_lamp.shadow_bias = 0.045
		primary_lamp.shadow_normal_bias = 1.5
		primary_lamp.shadow_blur = 1.8


static func apply_restoration_stage(stage_0_to_3: int, streetlamps: Array, world_env: WorldEnvironment) -> float:
	var s: int = clampi(stage_0_to_3, 0, 3)
	var lit_fraction: float = [0.0, 0.42, 0.76, 1.0][s]
	var total: int = streetlamps.size()
	var active_count: int = int(roundf(float(total) * lit_fraction)) if total > 0 else 0
	for i in range(total):
		var lamp: Node = streetlamps[i]
		if not is_instance_valid(lamp):
			continue
		var on: bool = (i < active_count)
		if lamp.has_method("set_restoration_preview"):
			lamp.call("set_restoration_preview", s, on)
		elif lamp is Light3D:
			(lamp as Light3D).visible = on
	if world_env != null and world_env.environment != null:
		var env: Environment = world_env.environment
		env.ambient_light_energy = [0.36, 0.44, 0.52, 0.60][s]
		env.fog_density = [0.022, 0.019, 0.015, 0.012][s]
	return lit_fraction * 100.0
