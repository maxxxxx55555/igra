extends RefCounted
## Session 23 (docs/DENSITY_PLAN.md): the density audit. Each of the eleven districts is built from its scene (street grid, props, dressing) at the origin where the game builds it, and the
## nine blocks of its grid (16 m cells between the road axes) are counted: solid props (benches, trees, cones, crates, barrels, bins, hydrants), scatter on the ground (litter and leaves,
## wet patches) and streetlamps. A block under the floor of any of them is empty; the same count without the dressing node is printed beside it, so the gain is on the log. Wired into
## _closeout_check_runner.gd as `await Rc23Density.run(self)`; CLOSEOUT_ONLY=s23 runs it with the others. FOLIAGE1 and FOG1 hold the atmosphere of the same build: the swaying canopies and the fog cards.
## A headless run keeps no instance data on the rendering server (every transform reads back as the origin), so each batched node carries its spots as the metadata `spots`.

const FLOOR_SOLID: int = 2
const FLOOR_SCATTER: int = 4
const FLOOR_LAMPS: int = 2
const GRID_M: float = 16.0
const SOLID: Array[String] = ["BenchesBatched", "TreeTrunksBatched", "ConesBatched", "Crates", "Barrels", "Bins", "Hydrants"]
const SCATTER: Array[String] = ["Litter", "Puddles"]
const LAMPS: Array[String] = ["StreetlightPolesBatched"]

static func run(r: Node) -> void:
	var bad: Array[String] = []
	var landmarks: int = 0
	var rests: int = 0
	var manholes: int = 0
	var districts: Array = DistrictSceneFactory.DISTRICTS
	for id: StringName in districts:
		var root: Node3D = await _build(r, id)
		var props: Node = root.get_node("Props")
		var dressing: Node = props.get_node_or_null("DistrictDressing")
		var with_all: Dictionary = _least_per_block(props, dressing, false)
		var base: Dictionary = _least_per_block(props, dressing, true)
		landmarks += 1 if dressing != null and dressing.get_node_or_null("Landmark") != null else 0
		rests += 1 if dressing != null and dressing.get_node_or_null("RestLantern/RestLight") != null else 0
		manholes += 1 if dressing != null and (dressing.get_node_or_null("Manhole0/Steam") != null or dressing.get_node_or_null("Manhole1/Steam") != null) else 0
		print("[dens] district=%s blocks=9 min_solid=%d (without the dressing %d) min_scatter=%d (%d) min_lamps=%d" % [id, with_all["solid"], base["solid"], with_all["scatter"], base["scatter"], with_all["lamps"]])
		if int(with_all["solid"]) < FLOOR_SOLID or int(with_all["scatter"]) < FLOOR_SCATTER or int(with_all["lamps"]) < FLOOR_LAMPS:
			bad.append(String(id))
		root.queue_free()
		await r.get_tree().process_frame
	await _atmosphere(r)
	r._ok(bad.is_empty() and landmarks == districts.size() and rests == districts.size(), "DENS1 density: every block of every district holds %d solid props, %d scattered pieces and %d lamps at least (under the floor: %s), %d of %d districts have a landmark and %d a lit rest spot" % [FLOOR_SOLID, FLOOR_SCATTER, FLOOR_LAMPS, ", ".join(bad) if not bad.is_empty() else "none", landmarks, districts.size(), rests])
	r._ok(manholes == districts.size(), "MANH1 manholes: %d of %d districts hold an iron cover in the road with a thread of steam" % [manholes, districts.size()])

## The least of each count over the nine blocks; `skip_dressing` leaves out what the dressing node adds.
static func _least_per_block(props: Node, dressing: Node, skip_dressing: bool) -> Dictionary:
	var counts: Dictionary = {}
	for key: String in ["solid", "scatter", "lamps"]:
		counts[key] = [0, 0, 0, 0, 0, 0, 0, 0, 0]
	for holder: Node in [props, dressing]:
		if holder == null or (skip_dressing and holder == dressing):
			continue
		for child in holder.get_children():
			var mmi := child as MultiMeshInstance3D
			if mmi == null:
				continue
			var node_name: String = String(mmi.name)
			var key: String = "solid" if SOLID.has(node_name) else ("scatter" if SCATTER.has(node_name) else ("lamps" if LAMPS.has(node_name) else ""))
			if key.is_empty():
				continue
			for spot: Variant in mmi.get_meta("spots", []):
				var at: Vector3 = (spot as Transform3D).origin if spot is Transform3D else spot as Vector3
				var cell: int = clampi(int(floorf((at.x + 1.5 * GRID_M) / GRID_M)), 0, 2) * 3 + clampi(int(floorf((at.z + 1.5 * GRID_M) / GRID_M)), 0, 2)
				(counts[key] as Array)[cell] = int((counts[key] as Array)[cell]) + 1
	return {"solid": (counts["solid"] as Array).min(), "scatter": (counts["scatter"] as Array).min(), "lamps": (counts["lamps"] as Array).min()}

## A district from its scene at the origin where the game builds it, with the props and the dressing made.
static func _build(r: Node, id: StringName) -> Node3D:
	var root := (load(DistrictSceneFactory.district_scene_path(id)) as PackedScene).instantiate() as Node3D
	var trigger: Node = root.get_node("DistrictTrigger")
	root.remove_child(trigger)  # a trigger box on the player would announce a district that was not entered
	trigger.free()
	r.add_child(root)
	for i in 6:
		await r.get_tree().process_frame
	return root

static func _cards(root: Node3D) -> int:
	var count: int = 0
	for child in root.get_node("Props/DistrictDressing").get_children():
		count += 1 if String(child.name).begins_with("FogCard") else 0
	return count

## FOLIAGE1: the canopies of the street trees carry the sway shader in the dark teal of the old flat material, and Motion Comfort stops the sway at once.
## FOG1: the four fog districts hold three fog cards, the others none, and no district holds one at the Low tier.
## POOL1: a pool of light or a halo of opacity 0 (the DARK stage) is hidden, not drawn blind.
static func _atmosphere(r: Node) -> void:
	var tier0: Variant = SettingsManager.get_setting("graphics_tier", 2)
	SettingsManager.set_setting("graphics_tier", 2)
	var street: Node3D = await _build(r, &"suburbs")
	var leaves := street.get_node("Props").get_node_or_null("TreeLeavesBatched") as MultiMeshInstance3D
	var mat: ShaderMaterial = leaves.material_override as ShaderMaterial if leaves != null else null
	var swaying: float = float(mat.get_shader_parameter("sway_strength")) if mat != null else -1.0
	var colour: Color = mat.get_shader_parameter("leaf_color") if mat != null else Color.WHITE
	SettingsManager.set_setting("reduce_camera_motion", true)
	var still: float = float(mat.get_shader_parameter("sway_strength")) if mat != null else -1.0
	SettingsManager.set_setting("reduce_camera_motion", false)
	var restored: float = float(mat.get_shader_parameter("sway_strength")) if mat != null else -1.0
	var plain: int = _cards(street)
	var dressing: Node = street.get_node("Props").get_node_or_null("DistrictDressing")
	var pools: Node3D = dressing.get_node_or_null("LampPools") as Node3D if dressing != null else null
	var halo: Node3D = dressing.get_node_or_null("Landmark/Halo") as Node3D if dressing != null else null
	var rests: bool = false
	var wakes: bool = false
	if pools != null and halo != null:
		dressing.call("_apply_stage", 0)
		rests = not pools.visible and not halo.visible
		dressing.call("_apply_stage", 1)
		wakes = pools.visible and halo.visible
	street.queue_free()
	var foggy: Node3D = await _build(r, &"warehouses")
	var fogged: int = _cards(foggy)
	foggy.queue_free()
	SettingsManager.set_setting("graphics_tier", 0)
	var low: Node3D = await _build(r, &"warehouses")
	var at_low: int = _cards(low)
	low.queue_free()
	SettingsManager.set_setting("graphics_tier", tier0)
	await r.get_tree().process_frame
	r._ok(mat != null and swaying > 0.0 and still == 0.0 and restored == swaying and colour.is_equal_approx(Color(0.09, 0.16, 0.15)), "FOLIAGE1 canopies: a sway shader (%s) of %.2f m, %.2f m with Motion Comfort and %.2f m after, in the old dark teal (%s)" % [mat != null, swaying, still, restored, colour.is_equal_approx(Color(0.09, 0.16, 0.15))])
	r._ok(rests and wakes, "POOL1 lamp pools: the pools of the lamps and the halo of the landmark are not drawn at the DARK stage (%s) and are drawn from the next (%s)" % [rests, wakes])
	r._ok(fogged == 3 and plain == 0 and at_low == 0, "FOG1 ground fog: %d cards in a fog district, %d in the suburbs, %d at the Low tier" % [fogged, plain, at_low])
