extends RefCounted
## Session 29 (the v1.0.0-ship pass), B block, the look (docs/VISUAL_PASS.md section 8): LOOK1 the boot order of the environment, its preset, its camera attributes and the table of the graphics tier (B1, B2, B12).
## Wired into _closeout_check_runner.gd next to s29_checks.gd; CLOSEOUT_ONLY=s29 runs both.

static func run(r: Node) -> void:
	r._playing()
	_look(r)
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
