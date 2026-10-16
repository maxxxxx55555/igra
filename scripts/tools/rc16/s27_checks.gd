extends RefCounted
## Session 27 (V1, the Soviet visual pass): SOV1, the lane marking is a dash of paint and not a whole tile, and the street tiles use the road shader (the cream slab, decision SLAB-27); SOV2, the skyline's blocks use the
## facade shader, carry roof boxes and balconies, and the weathering follows the graphics tier; SOV3, the halo behind a landmark is a pool of light and not a third of the sky (HALO-27); SOV4, every district has
## sign words and every letter of them is in the engine's own font (the bundled fonts hold no Cyrillic: a missing glyph is a box on a wall); SOV5, the dead grass of the courtyards shows 0, 72 and 144 tufts at the three
## graphics tiers; SOV6, the glow of the blocks and the paint of the signs rises with the power stage and the restored district is not dim (the pixel proof is the wall line of `tools/qa_sim/density_frames`);
## SOV7 (V2), the main menu draws fog and grain between its hero art and its title, none at the Low tier, and the title is stencilled; MUS1 (M1), the Architect announces its second and third phase (the signal was
## declared and listened to and never emitted) and the music takes the theme of the phase it is told.
## Wired into _closeout_check_runner.gd as `await Rc27.run(self)`; CLOSEOUT_ONLY=s27 runs it alone, which tools/qa_sim/s26_mutations.py uses (its third set).

const _ROAD := "res://assets/shaders/soviet_road.gdshader"
const _FACADE := "res://assets/shaders/soviet_facade.gdshader"
const _LANDMARK := preload("res://scripts/world/district_landmark.gd")
const _SIGNS := preload("res://scripts/world/soviet_signs.gd")
const _GRASS := preload("res://scripts/world/dead_grass.gd")

static func run(r: Node) -> void:
	await _streets(r)
	_skyline(r)
	_halo(r)
	_signs(r)
	_grass(r)
	_glow(r)
	await _menu(r)
	_boss(r)

## The placement is asked, not the multimesh: headless the rendering server keeps no instance transforms, but the mesh and its material are resources.
static func _streets(r: Node) -> void:
	var builder := StreetBuilder.new()
	builder.district_id = &"suburbs"
	r.add_child(builder)
	await builder.streets_ready
	var dash := ((builder.get("_marking_mm") as MultiMeshInstance3D).multimesh.mesh as BoxMesh)
	var road := ((builder.get("_road_mm") as MultiMeshInstance3D).multimesh.mesh as BoxMesh).material as ShaderMaterial
	var walk := ((builder.get("_sidewalk_mm") as MultiMeshInstance3D).multimesh.mesh as BoxMesh).material as ShaderMaterial
	var paint := dash.material as ShaderMaterial
	var shaded: bool = road != null and walk != null and paint != null and road.shader.resource_path == _ROAD and walk.shader.resource_path == _ROAD and paint.shader.resource_path == _ROAD
	r._ok(dash.size.x <= 1.5 and dash.size.z <= 0.3 and shaded, "SOV1 the lane marking is a dash of %.2f m by %.2f m and the road, the sidewalk and the paint use the road shader (shaded %s)" % [dash.size.x, dash.size.z, shaded])
	builder.queue_free()

static func _skyline(r: Node) -> void:
	var tier_before: int = int(SettingsManager.get_setting("graphics_tier", 2))
	var sky := CitySkyline.new()
	r.add_child(sky)
	sky.build(&"residential", 24.0, true)
	var blocks := sky.get_node("Blocks") as MultiMeshInstance3D
	var mat := blocks.material_override as ShaderMaterial
	SettingsManager.set_graphics_tier(0)
	var low: float = float(mat.get_shader_parameter("detail"))
	SettingsManager.set_graphics_tier(2)
	var high: float = float(mat.get_shader_parameter("detail"))
	SettingsManager.set_graphics_tier(tier_before)
	# a block of 10 m by 15 m by 10 m with a balcony under every window: a stairwell and 5 rows of 4 slabs, at least
	var boxes: Array[Transform3D] = []
	var tints: Array[Color] = []
	var rng := RandomNumberGenerator.new()
	sky.call("_dress_block", rng, Transform3D.IDENTITY, Vector3(10.0, 15.0, 10.0), Color(0.1, 0.1, 0.12), 1.0, boxes, tints)
	r._ok(mat != null and mat.shader.resource_path == _FACADE and boxes.size() >= 21 and tints.size() == boxes.size() and low == 0.0 and high == 2.0,
		"SOV2 the blocks use the facade shader, a block gets %d roof boxes and balconies, and the detail follows the graphics tier (Low %.0f, High %.0f)" % [boxes.size(), low, high])
	sky.queue_free()

static func _halo(r: Node) -> void:
	var size: Vector2 = _LANDMARK.HALO_SIZE
	var full: float = _LANDMARK.HALO_BY_STAGE[3]
	r._ok(size.x <= 70.0 and size.y <= 60.0 and full <= 0.2, "SOV3 the halo of a landmark is %.0f m by %.0f m at an opacity of %.2f when the district is FULL" % [size.x, size.y, full])

static func _signs(r: Node) -> void:
	var font: Font = ThemeDB.fallback_font
	var words: int = 0
	var missing: Array[String] = []
	for id: StringName in DistrictSceneFactory.DISTRICTS:
		for word: String in _SIGNS.words_of(id):
			words += 1
			for letter: String in word:
				if letter != " " and not font.has_char(letter.unicode_at(0)):
					missing.append("%s in %s" % [letter, id])
	r._ok(words >= 22 and missing.is_empty(), "SOV4 the districts have %d sign words and every letter is in the engine's font (missing: %s)" % [words, ", ".join(missing) if not missing.is_empty() else "none"])

static func _grass(r: Node) -> void:
	var tier_before: int = int(SettingsManager.get_setting("graphics_tier", 2))
	var grass := _GRASS.new()
	grass.district_id = &"suburbs"
	r.add_child(grass)
	var shown: Array[int] = []
	for tier in 3:
		SettingsManager.set_graphics_tier(tier)
		shown.append(grass.multimesh.visible_instance_count)
	SettingsManager.set_graphics_tier(tier_before)
	r._ok(grass.multimesh.instance_count == 144 and shown == [0, 72, 144], "SOV5 the dead grass holds %d tufts and shows %s of them at Low, Medium and High" % [grass.multimesh.instance_count, shown])
	grass.queue_free()

static func _glow(r: Node) -> void:
	var gain: Array[float] = CitySkyline.FACADE_GAIN
	var lit: Array[float] = _SIGNS.LIT_BY_STAGE
	var rises: bool = true
	for stage in 3:
		rises = rises and gain[stage] < gain[stage + 1] and lit[stage] < lit[stage + 1]
	r._ok(rises and gain[0] > 0.0 and gain[3] >= 1.5 * gain[0] and lit[0] <= 0.5 and lit[3] == 1.0, "SOV6 the blocks glow at %.2f (DARK) to %.2f (FULL) and the sign paint at %.2f to %.2f: a restored district reads lighter, a dark one an outline" % [gain[0], gain[3], lit[0], lit[3]])

static func _menu(r: Node) -> void:
	var tier_before: int = int(SettingsManager.get_setting("graphics_tier", 2))
	var menu := (load("res://scenes/ui/main_menu.tscn") as PackedScene).instantiate() as Control
	r.add_child(menu)
	await r.get_tree().process_frame
	var fog := menu.get_node_or_null("MenuFog") as ColorRect
	var hero := menu.get_node_or_null("MenuHeroV2")
	var title := menu.get_node("VBox/Title") as Label
	var between: bool = fog != null and hero != null and fog.get_index() > hero.get_index() and fog.get_index() < menu.get_node("VBox").get_index()
	var stencilled: bool = title.material is ShaderMaterial and (title.material as ShaderMaterial).shader.resource_path == "res://assets/shaders/stencil_title.gdshader"
	var high: bool = fog != null and fog.visible
	SettingsManager.set_graphics_tier(0)
	var low: bool = fog != null and fog.visible
	SettingsManager.set_graphics_tier(tier_before)
	r._ok(between and stencilled and high and not low, "SOV7 the menu draws fog and grain between its hero art and its title (High %s, Low %s) and the title is stencilled (%s)" % [high, low, stencilled])
	menu.queue_free()

static func _boss(r: Node) -> void:
	var boss: Node = load("res://scripts/enemies/boss_3d.gd").new()
	var seen: Array[int] = []
	var listen := func(phase: int) -> void: seen.append(phase)
	EventBus.boss_phase_changed.connect(listen)
	boss.call("_switch_to_p2")
	boss.call("_switch_to_p3")
	EventBus.boss_phase_changed.disconnect(listen)
	boss.free()
	MusicManager.call("_on_boss_phase_changed", 3)
	var third: int = int(MusicManager.get("_boss_phase"))
	MusicManager.call("enter_boss")
	var first: int = int(MusicManager.get("_boss_phase"))
	MusicManager.call("_on_boss_defeated")
	r._ok(seen == [2, 3] and third == 3 and first == 1, "MUS1 the Architect announces its phases %s and the music takes the theme of the phase it is told (3 then %d, a new fight starts at %d)" % [seen, third, first])
