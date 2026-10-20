extends RefCounted
## Session 29 (the v1.0.0-ship pass), B block, the look (docs/VISUAL_PASS.md section 8): LOOK1 the boot order of the environment, its preset, its camera attributes and the table of the graphics tier (B1, B2, B12).
## WET1 the road reads wet in rain: an overlay of mat_wet_asphalt.tres on the road tiles, none in the clear, the wetness of the rain and the reflection of the tier (none on Low) (B3); LAMP1 the lamp heads
## wear mat_lamp_flicker.tres, lit by the power stage with a ramp on a restore, and Reduce Flash stills the shimmer (B4). Wired into _closeout_check_runner.gd next to s29_checks.gd; CLOSEOUT_ONLY=s29 runs both.

const _Density := preload("res://scripts/tools/rc16/density_checks.gd")
const _LAMP_HEAD: String = "res://scripts/world/lamp_head.gd"

static func run(r: Node) -> void:
	r._playing()
	_look(r)
	await _wet(r)
	await _lamps(r)
	r._playing()

## LOOK1 (B1, B2, B12): ONE WorldEnvironment in the main scene (the factory's per-district one is gone with DistrictThemes.apply_to_environment); world_env_setup.gd boots the look in ONE function, and that
## function, run on a fresh environment, copies the keys of the preset of the profile (fog_height 2.0, fog_sun_scatter 0.1 on both), assigns the night camera attributes and leaves the ACES tone mapper; a
## change of the graphics tier applies its table again. (The closeout scene has a harness environment of its own, which the setup finds first there, and the earlier groups may free nodes: the check does not
## rely on the environment the setup manages, it hands it a new one.)
static func _look(r: Node) -> void:
	var main: Node = r.get_node_or_null("Main3D")
	var worlds: Array[Node] = main.find_children("*", "WorldEnvironment", true, false) if main != null else []
	var setup: Node = main.get_node_or_null("WorldEnvSetup") if main != null else null
	var order: bool = setup != null and setup.has_method("_boot_look")
	var scratch := WorldEnvironment.new()
	scratch.environment = Environment.new()
	r.add_child(scratch)
	var keep_we: Variant = setup.get("_we") if order else null
	var keep_env: Variant = setup.get("_env") if order else null
	if order:
		setup.set("_we", scratch)
		setup.set("_env", scratch.environment)
		setup.call("_boot_look")
		setup.set("_we", keep_we if is_instance_valid(keep_we) else null)
		setup.set("_env", keep_env)
	var env: Environment = scratch.environment
	var preset: bool = is_equal_approx(env.fog_height, 2.0) and is_equal_approx(env.fog_sun_scatter, 0.1)
	var attrs: bool = scratch.camera_attributes != null and scratch.camera_attributes.resource_path.ends_with("camera_attributes_night.tres")
	var aces: bool = env.tonemap_mode == Environment.TONE_MAPPER_ACES
	var themes_clean: bool = not DistrictThemes.has_method("apply_to_environment")
	scratch.queue_free()
	r._ok(worlds.size() == 1 and order and preset and attrs and aces and themes_clean, "LOOK1 one WorldEnvironment in the main scene (%d), the boot order in one function (%s) copies the preset's keys (%s), assigns the night camera attributes (%s) and leaves ACES (%s), no per-district environment (%s)" % [worlds.size(), order, preset, attrs, aces, themes_clean])
	if not order or keep_env == null:
		r._ok(false, "LOOK1 the table of the graphics tier is applied again on a change (no setup)")
		return
	var live: Environment = keep_env as Environment
	var tier0: int = int(SettingsManager.get_setting("graphics_tier", 2))
	var density: Array[float] = []
	for tier: int in [0, 3]:
		SettingsManager.set_graphics_tier(tier)
		density.append(live.fog_density)
	SettingsManager.set_graphics_tier(tier0)
	r._ok(is_equal_approx(density[0], 0.012) and is_equal_approx(density[1], 0.015), "LOOK1 the table of the graphics tier is applied again on a change (fog density %.3f at Low, %.3f at Ultra)" % [density[0], density[1]])

## WET1 (B3): the road tiles of a district wear the wet overlay only in rain (the clear and the fog keep none), with the wetness of the rain (0.7) and the reflection of the tier (0.85 at High, none at Low).
static func _wet(r: Node) -> void:
	var tier0: int = int(SettingsManager.get_setting("graphics_tier", 2))
	var weather0: int = WeatherSystem.current
	SettingsManager.set_graphics_tier(2)
	var root: Node3D = await _Density._build(r, &"suburbs")
	var road := root.find_child("RoadMM", true, false) as MultiMeshInstance3D
	var clear: bool = false
	var wet: bool = false
	var low: bool = false
	var storm: bool = false
	if road != null:
		WeatherSystem.current = WeatherSystem.Weather.CLEAR
		WeatherSystem.call("_emit")
		clear = road.material_overlay == null
		WeatherSystem.current = WeatherSystem.Weather.RAIN
		WeatherSystem.call("_emit")
		var overlay := road.material_overlay as ShaderMaterial
		wet = overlay != null and overlay.shader.resource_path.ends_with("wet_asphalt.gdshader") and is_equal_approx(float(overlay.get_shader_parameter("wetness")), 0.7) and is_equal_approx(float(overlay.get_shader_parameter("reflection_strength")), 0.85)
		SettingsManager.set_graphics_tier(0)
		low = overlay != null and is_equal_approx(float(overlay.get_shader_parameter("reflection_strength")), 0.0)
		WeatherSystem.current = WeatherSystem.Weather.STORM
		WeatherSystem.call("_emit")
		storm = road.material_overlay != null and is_equal_approx(float((road.material_overlay as ShaderMaterial).get_shader_parameter("wetness")), 1.0)
	WeatherSystem.current = weather0
	WeatherSystem.call("_emit")
	SettingsManager.set_graphics_tier(tier0)
	root.queue_free()
	r._ok(clear and wet and low and storm, "WET1 the road tiles carry no overlay in the clear (%s), the wet overlay with the rain's wetness 0.7 and the reflection 0.85 at High (%s), no reflection at Low (%s), wetness 1.0 in a storm (%s)" % [clear, wet, low, storm])

## LAMP1 (B4): the batched heads wear mat_lamp_flicker.tres; `lit` follows the power stage (0 dark, 0.45 partial, 1 streets) and a restore ramps it (not 1 at once, 1 after 1.5 s); the head is hotter at full
## (energy 2.0); Reduce Flash gives the head no shimmer and no dropout.
static func _lamps(r: Node) -> void:
	var flash0: Variant = SettingsManager.get_setting("reduce_flash", false)
	SettingsManager.set_setting("reduce_flash", false)
	var root: Node3D = await _Density._build(r, &"suburbs")
	var lamps := root.find_child("StreetlightLampsBatched", true, false) as MultiMeshInstance3D
	var mat: ShaderMaterial = lamps.material_override as ShaderMaterial if lamps != null else null
	var shader_ok: bool = mat != null and mat.shader.resource_path.ends_with("streetlight_flicker.gdshader")
	var stages: Array[float] = []
	var ramp_start: float = -1.0
	var ramp_end: float = -1.0
	var full_energy: float = -1.0
	if shader_ok:
		var props: Node = lamps.get_parent()
		props.call("_apply_lamp_stage", 0)
		stages.append(float(mat.get_shader_parameter("lit")))
		props.call("_apply_lamp_stage", 1)
		await r.get_tree().create_timer(1.4).timeout
		stages.append(float(mat.get_shader_parameter("lit")))
		props.call("_apply_lamp_stage", 0)
		props.call("_apply_lamp_stage", 2)
		ramp_start = float(mat.get_shader_parameter("lit"))
		await r.get_tree().create_timer(1.5).timeout
		ramp_end = float(mat.get_shader_parameter("lit"))
		props.call("_apply_lamp_stage", 3)
		full_energy = float(mat.get_shader_parameter("energy_mult"))
	root.queue_free()
	SettingsManager.set_setting("reduce_flash", true)
	var still: ShaderMaterial = (load(_LAMP_HEAD) as GDScript).make()
	var calm: bool = is_equal_approx(float(still.get_shader_parameter("flicker_depth")), 0.0) and float(still.get_shader_parameter("dropout_threshold")) >= 1.0
	SettingsManager.set_setting("reduce_flash", flash0)
	var staged: bool = shader_ok and stages.size() == 2 and is_equal_approx(stages[0], 0.0) and is_equal_approx(stages[1], 0.45)
	r._ok(shader_ok and staged and ramp_start < 0.5 and is_equal_approx(ramp_end, 1.0) and is_equal_approx(full_energy, 2.0) and calm, "LAMP1 the lamp heads wear the flicker material (%s), lit %s by stage (0, and 0.45 once the ramp of the partial stage is over), a restore ramps it (%.2f at once, %.2f after 1.5 s), 2.0 at full (%.1f), Reduce Flash stills it (%s)" % [shader_ok, stages, ramp_start, ramp_end, full_energy, calm])
