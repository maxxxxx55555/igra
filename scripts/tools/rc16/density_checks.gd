extends RefCounted
## Session 23 (docs/DENSITY_PLAN.md): the density audit. Each of the eleven districts is built from its scene (street grid, props, dressing) at the origin where the game builds it, and the
## nine blocks of its grid (16 m cells between the road axes) are counted: solid props (benches, trees, cones, crates, barrels, bins, hydrants), scatter on the ground (litter and leaves,
## wet patches) and streetlamps. A block under the floor of any of them is empty; the same count without the dressing node is printed beside it, so the gain is on the log. Wired into
## _closeout_check_runner.gd as `await Rc23Density.run(self)`; CLOSEOUT_ONLY=s23 runs it with the others.

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
	var districts: Array = DistrictSceneFactory.DISTRICTS
	for id: StringName in districts:
		var root := (load(DistrictSceneFactory.district_scene_path(id)) as PackedScene).instantiate() as Node3D
		var trigger: Node = root.get_node("DistrictTrigger")
		root.remove_child(trigger)  # a trigger box on the player would announce a district that was not entered
		trigger.free()
		r.add_child(root)
		for i in 6:
			await r.get_tree().process_frame
		var props: Node = root.get_node("Props")
		var dressing: Node = props.get_node_or_null("DistrictDressing")
		var with_all: Dictionary = _least_per_block(props, dressing, false)
		var base: Dictionary = _least_per_block(props, dressing, true)
		landmarks += 1 if dressing != null and dressing.get_node_or_null("Landmark") != null else 0
		rests += 1 if dressing != null and dressing.get_node_or_null("RestLantern/RestLight") != null else 0
		print("[dens] district=%s blocks=9 min_solid=%d (without the dressing %d) min_scatter=%d (%d) min_lamps=%d" % [id, with_all["solid"], base["solid"], with_all["scatter"], base["scatter"], with_all["lamps"]])
		if int(with_all["solid"]) < FLOOR_SOLID or int(with_all["scatter"]) < FLOOR_SCATTER or int(with_all["lamps"]) < FLOOR_LAMPS:
			bad.append(String(id))
		root.queue_free()
		await r.get_tree().process_frame
	r._ok(bad.is_empty() and landmarks == districts.size() and rests == districts.size(), "DENS1 density: every block of every district holds %d solid props, %d scattered pieces and %d lamps at least (under the floor: %s), %d of %d districts have a landmark and %d a lit rest spot" % [FLOOR_SOLID, FLOOR_SCATTER, FLOOR_LAMPS, ", ".join(bad) if not bad.is_empty() else "none", landmarks, districts.size(), rests])

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
			if mmi == null or mmi.multimesh == null:
				continue
			var key: String = "solid" if SOLID.has(mmi.name) else ("scatter" if SCATTER.has(mmi.name) else ("lamps" if LAMPS.has(mmi.name) else ""))
			if key.is_empty():
				continue
			for i in mmi.multimesh.instance_count:
				var at: Vector3 = mmi.multimesh.get_instance_transform(i).origin
				var cell: int = clampi(int(floorf((at.x + 1.5 * GRID_M) / GRID_M)), 0, 2) * 3 + clampi(int(floorf((at.z + 1.5 * GRID_M) / GRID_M)), 0, 2)
				(counts[key] as Array)[cell] = int((counts[key] as Array)[cell]) + 1
	return {"solid": (counts["solid"] as Array).min(), "scatter": (counts["scatter"] as Array).min(), "lamps": (counts["lamps"] as Array).min()}
