extends RefCounted
## Session 29 (the v1.0.0-ship pass), B block, the look (docs/VISUAL_PASS.md section 8): LOOK1 the boot order of the environment, its preset, its camera attributes and the table of the graphics tier (B1, B2, B12).
## WET1 the road reads wet in rain: an overlay of mat_wet_asphalt.tres on the road tiles, none in the clear, the wetness of the rain and the reflection of the tier (none on Low) (B3); LAMP1 the lamp heads
## wear mat_lamp_flicker.tres, lit by the power stage with a ramp on a restore, and Reduce Flash stills the shimmer (B4); SHADOW1 a district holds ONE contact-shadow MultiMesh with a blob under every pole, prop and monster, none on the Low tier (B5); WX1 the weather particles follow the weather and the strobe throws sparks (B8); PAR1 the menu backdrop drifts with the pointer (B9); THEME1 the type scale and the option
## button's focus (B10); MOON1 the shadow bias of the moon follows the district (B11); PBR1 the texture hook of the material factory (B6); SAT1 the facade glow of the chromatic districts is capped (B13). Wired into _closeout_check_runner.gd next to s29_checks.gd; CLOSEOUT_ONLY=s29 runs both.

const _Density := preload("res://scripts/tools/rc16/density_checks.gd")
const _LAMP_HEAD: String = "res://scripts/world/lamp_head.gd"

static func run(r: Node) -> void:
	r._playing()
	_look(r)
	await _wet(r)
	await _lamps(r)
	await _shadows(r)
	await _weather(r)
	await _menu_parallax(r)
	_theme(r)
	_moon(r)
	_pbr_and_saturation(r)
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

## SHADOW1 (B5): at the High tier a district holds ONE ContactShadows MultiMesh (one draw call, no MeshInstance3D with the blob shader) with a blob for every pole and every batched prop, a monster is found by its group by one of
## the ContactShadows of the world (the run has one for its own district) and its blob lies 2 cm above the street under its feet (read from the entry the node keeps: a headless run keeps no instance transforms); at the Low tier a district holds none.
static func _shadows(r: Node) -> void:
	var tier0: int = int(SettingsManager.get_setting("graphics_tier", 2))
	SettingsManager.set_graphics_tier(2)
	var root: Node3D = await _Density._build(r, &"suburbs")
	var monster: Node3D = r._monster("crawler_3d", Vector3(0.0, 1.0, 0.0))  # a district holds none of its own in the closeout scene; the group scan finds it within SCAN_SEC
	await r.get_tree().create_timer(0.8).timeout
	var boards: Array[Node] = root.find_children("ContactShadows", "MultiMeshInstance3D", true, false)
	var board := boards[0] as MultiMeshInstance3D if boards.size() == 1 else null
	var has_board: bool = board != null
	var props: int = 0
	for batch in ["StreetlightPolesBatched", "BenchesBatched", "TreeTrunksBatched", "ConesBatched"]:
		var node := root.find_child(batch, true, false) as MultiMeshInstance3D
		props += node.multimesh.instance_count if node != null else 0
	var blobs: int = board.multimesh.visible_instance_count if board != null else 0
	var lift: float = INF
	for found in r.get_tree().root.find_children("ContactShadows", "MultiMeshInstance3D", true, false):
		for entry: Dictionary in found.get("_tracked"):
			if entry["node"] == monster:
				lift = float(entry["lift"])
	var under: bool = absf(lift + ((monster.get_node("CollisionShape3D") as CollisionShape3D).shape as CapsuleShape3D).height * 0.5 - 0.02) < 0.06
	var flat: int = 0
	for mesh in root.find_children("*", "MeshInstance3D", true, false):
		var mat := (mesh as MeshInstance3D).material_override as ShaderMaterial
		flat += 1 if mat != null and mat.shader != null and mat.shader.resource_path.ends_with("contact_shadow.gdshader") else 0
	root.queue_free()
	monster.queue_free()
	SettingsManager.set_graphics_tier(0)
	var low: Node3D = await _Density._build(r, &"suburbs")
	var none_low: bool = low.find_children("ContactShadows", "MultiMeshInstance3D", true, false).is_empty()
	low.queue_free()
	SettingsManager.set_graphics_tier(tier0)
	r._ok(has_board and blobs >= props and props > 0 and under and flat == 0 and none_low, "SHADOW1 one ContactShadows MultiMesh (%s) with %d blobs for %d poles and props, the blob of a monster 2 cm over the street under its feet (%s, lift %.3f), %d separate blob meshes, none on the Low tier (%s)" % [has_board, blobs, props, under, lift, flat, none_low])

## WX1 (B8): WeatherParticles (a child of the world setup) holds the rain emitter, which emits in rain (the share 0.7) and in a storm (1.0) and not in the clear, and the fog drops, which emit only in fog; the rain stands 12 m over
## the camera; the sparks of the strobe appear (a vfx_strobe burst) and do not with Reduce Flash.
static func _weather(r: Node) -> void:
	var main: Node = r.get_node_or_null("Main3D")
	var setup: Node = main.get_node_or_null("WorldEnvSetup") if main != null else null
	var fx: Node = setup.get_node_or_null("WeatherParticles") if setup != null else null
	var rain := fx.get_node_or_null("Rain") as GPUParticles3D if fx != null else null
	var drops := fx.get_node_or_null("FogDrops") as GPUParticles3D if fx != null else null
	var weather0: int = WeatherSystem.current
	var seen: Array[String] = []
	var ok: bool = rain != null and drops != null
	if ok:
		for kind: int in [WeatherSystem.Weather.CLEAR, WeatherSystem.Weather.RAIN, WeatherSystem.Weather.STORM, WeatherSystem.Weather.FOG]:
			WeatherSystem.current = kind
			WeatherSystem.call("_emit")
			seen.append("%s/%.1f/%s" % [rain.emitting, rain.amount_ratio, drops.emitting])
		ok = seen[0].begins_with("false") and seen[0].ends_with("false") and seen[1] == "true/0.7/false" and seen[2] == "true/1.0/false" and seen[3].begins_with("false") and seen[3].ends_with("true")
	WeatherSystem.current = weather0
	WeatherSystem.call("_emit")
	await r.get_tree().process_frame
	var camera: Camera3D = r.get_viewport().get_camera_3d()
	var height: float = rain.global_position.y - camera.global_position.y if rain != null and camera != null else 0.0
	var player: Node = r._player
	var bursts: Array[Node] = r.get_tree().root.find_children("*VFXStrobe*", "GPUParticles3D", true, false)  # a pooled burst is replayed, and a second one is renamed: it is the playing ones that count
	for burst in bursts:
		(burst as GPUParticles3D).emitting = false
	var flash0: Variant = SettingsManager.get_setting("reduce_flash", false)
	SettingsManager.set_setting("reduce_flash", true)
	player.call("_strobe_effects")
	var playing := func() -> int: return r.get_tree().root.find_children("*VFXStrobe*", "GPUParticles3D", true, false).filter(func(n: Node) -> bool: return (n as GPUParticles3D).emitting).size()
	var calm: int = playing.call()
	SettingsManager.set_setting("reduce_flash", false)
	player.call("_strobe_effects")
	var sparks: int = playing.call()
	SettingsManager.set_setting("reduce_flash", flash0)
	r._ok(ok and absf(height - 12.0) < 0.5 and calm == 0 and sparks == 1, "WX1 the rain emits in rain (share 0.7) and in a storm (1.0) and not in the clear, the drops only in fog (%s), the rain stands %.1f m over the camera, the strobe throws sparks (%d burst playing, with Reduce Flash: %d)" % [seen, height, sparks, calm])

## PAR1 (B9): the menu hero wears the parallax shader and a driver: a drag of 0.4 moves the uniform, the Low tier counts 0.4 of it, Motion Comfort holds it and the drift still.
static func _menu_parallax(r: Node) -> void:
	var menu := (load("res://scenes/ui/main_menu.tscn") as PackedScene).instantiate() as Control
	r.add_child(menu)
	await r.get_tree().process_frame
	var hero := menu.get_node_or_null("MenuHeroV2") as TextureRect
	var mat := hero.material as ShaderMaterial if hero != null else null
	var driver: Node = hero.get_child(0) if hero != null and hero.get_child_count() > 0 else null
	var shader_ok: bool = mat != null and mat.shader.resource_path.ends_with("menu_parallax.gdshader") and driver != null
	var moved: float = 0.0
	var low: float = 0.0
	var held: bool = false
	if shader_ok:
		SettingsManager.set_setting("reduce_camera_motion", false)
		driver.set("_drag", Vector2(0.4, 0.0))
		driver.set("_now", Vector2.ZERO)
		driver.call("_process", 1.0)
		moved = absf((mat.get_shader_parameter("parallax") as Vector2).x)
		var tier0: int = int(SettingsManager.get_setting("graphics_tier", 2))
		SettingsManager.set_graphics_tier(0)
		driver.set("_drag", Vector2(0.4, 0.0))
		driver.set("_now", Vector2.ZERO)
		driver.call("_process", 1.0)
		low = absf((mat.get_shader_parameter("parallax") as Vector2).x)
		SettingsManager.set_graphics_tier(tier0)
		SettingsManager.set_setting("reduce_camera_motion", true)
		driver.set("_drag", Vector2(0.4, 0.0))
		driver.call("_process", 1.0)
		held = (mat.get_shader_parameter("parallax") as Vector2).length() < 0.001 and is_equal_approx(float(mat.get_shader_parameter("drift_amount")), 0.0)
		SettingsManager.set_setting("reduce_camera_motion", false)
	menu.queue_free()
	r._ok(shader_ok and moved > 0.05 and low > 0.0 and low < moved * 0.5 and held, "PAR1 the menu hero wears the parallax shader (%s), a drag moves it by %.3f, %.3f on the Low tier (0.4 of it), Motion Comfort holds it still (%s)" % [shader_ok, moved, low, held])

## THEME1 (B10): the type scale is in the theme as label variations (Display 44, Huge 30, Title 22, Small 13, Mono 15), the titles are on the Bebas face, and the option button has the 2 px brass focus ring and a disabled
## box of its own.
static func _theme(r: Node) -> void:
	var theme: Theme = (load("res://scripts/ui/theme_provider.gd") as GDScript).build_theme()
	var sizes: Array[int] = []
	for variation: StringName in [&"DisplayLabel", &"HugeLabel", &"TitleLabel", &"SmallLabel", &"MonoLabel"]:
		sizes.append(theme.get_font_size(&"font_size", variation))
	var title: Font = theme.get_font(&"font", &"TitleLabel")
	var bebas: bool = title is FontVariation and (title as FontVariation).base_font.resource_path.ends_with("BebasNeue-Regular.ttf")
	var focus := theme.get_stylebox("focus", "OptionButton") as StyleBoxFlat
	var ring: bool = focus != null and focus.border_width_left == 2 and focus.border_color.is_equal_approx(Color("#c9a24a"))
	var dimmed: bool = theme.get_stylebox("disabled", "OptionButton") != theme.get_stylebox("normal", "Button")
	r._ok(sizes == [44, 30, 22, 13, 15] and bebas and ring and dimmed, "THEME1 the type scale %s (44 30 22 13 15), the titles on Bebas (%s), the option button's 2 px brass focus ring (%s) and a disabled box of its own (%s)" % [sizes, bebas, ring, dimmed])

## MOON1 (B11): the shadow bias of the moon is 0.06 and 1.2 times the moon_bias_mult of the district (park 0.9), and 1.0 for a district the table does not know.
static func _moon(r: Node) -> void:
	var main: Node = r.get_node_or_null("Main3D")
	var setup: Node = main.get_node_or_null("WorldEnvSetup") if main != null else null
	if setup == null or not setup.has_method("_apply_moon_bias"):
		r._ok(false, "MOON1 the setup applies the bias of the district")
		return
	var light := DirectionalLight3D.new()  # the closeout scene's setup holds no moon of its own: it is handed one, as PERF2 does
	r.add_child(light)
	var moon0: Variant = setup.get("_moon")
	setup.set("_moon", light)
	var got: Array[Vector2] = []
	for id: StringName in [&"park", &"suburbs", &"nowhere"]:
		setup.call("_apply_moon_bias", id)
		got.append(Vector2(light.shadow_bias, light.shadow_normal_bias))
	setup.set("_moon", moon0)
	light.queue_free()
	r._ok(got[0].is_equal_approx(Vector2(0.054, 1.08)) and got[1].is_equal_approx(Vector2(0.06, 1.2)) and got[2].is_equal_approx(Vector2(0.06, 1.2)), "MOON1 the moon's shadow bias follows the district: park %s, suburbs %s, unknown %s" % [got[0], got[1], got[2]])

## PBR1 (B6): the material factory takes a texture set by name (the set's files are not there yet: the material stays as it was); SAT1 (B13): the facade glow of the chromatic districts is capped, the others keep GLOW_HUE.
static func _pbr_and_saturation(r: Node) -> void:
	var sets: GDScript = load("res://scripts/world/pbr_sets.gd")
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.2, 0.1)
	var same: StandardMaterial3D = sets.apply(mat, "no_such_set")
	var untouched: bool = same == mat and mat.albedo_texture == null and mat.albedo_color.is_equal_approx(Color(0.3, 0.2, 0.1))
	var dressing: GDScript = load("res://scripts/world/district_dressing.gd")
	var takes_set: bool = false
	for method: Dictionary in dressing.get_script_method_list():
		if method["name"] == "_plain":
			takes_set = (method["args"] as Array).size() == 5
	r._ok(untouched and takes_set, "PBR1 the factory's _plain takes a texture set (%s) and a set that has no files leaves the material as it was (%s)" % [takes_set, untouched])
	var skyline: GDScript = load("res://scripts/world/skyline.gd")
	var palettes: Dictionary = skyline.PALETTES
	var worst: float = 0.0
	var worst_id: String = ""
	for id: StringName in palettes:
		var glow: Color = palettes[id][1]
		var top: float = maxf(glow.r, maxf(glow.g, glow.b))
		var chroma: float = 1.0 - minf(glow.r, minf(glow.g, glow.b)) / top
		var kept: float = skyline._glow_hue(glow) * chroma
		if kept > worst:
			worst = kept
			worst_id = String(id)
	var police: float = skyline._glow_hue(palettes[&"police"][1])
	var suburbs: float = skyline._glow_hue(palettes[&"suburbs"][1])
	r._ok(worst <= skyline.GLOW_CHROMA_CAP + 0.0001 and police < skyline.GLOW_HUE and is_equal_approx(suburbs, skyline.GLOW_HUE), "SAT1 the share of the glow's hue times its chroma is held at %.2f or less in every district (worst: %s %.3f), the police keep %.2f of it and the suburbs the whole %.2f" % [skyline.GLOW_CHROMA_CAP, worst_id, worst, police, suburbs])
