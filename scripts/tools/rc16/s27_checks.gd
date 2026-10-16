extends RefCounted
## Session 27 (V1, the Soviet visual pass): SOV1, the lane marking is a dash of paint and not a whole tile, and the street tiles use the road shader (the cream slab, decision SLAB-27); SOV2, the skyline's blocks use the
## facade shader, carry roof boxes and balconies, and the weathering follows the graphics tier; SOV3, the halo behind a landmark is a pool of light and not a third of the sky (HALO-27).
## Wired into _closeout_check_runner.gd as `await Rc27.run(self)`; CLOSEOUT_ONLY=s27 runs it alone, which tools/qa_sim/s26_mutations.py uses (its third set).

const _ROAD := "res://assets/shaders/soviet_road.gdshader"
const _FACADE := "res://assets/shaders/soviet_facade.gdshader"
const _LANDMARK := preload("res://scripts/world/district_landmark.gd")

static func run(r: Node) -> void:
	await _streets(r)
	_skyline(r)
	_halo(r)

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
