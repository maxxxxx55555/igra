extends RefCounted
## rc16 closeout checks of perf: wired by the orchestrator into _closeout_check_runner.gd as `await <Preload>.run(self)`

const POOL_PATH: String = "res://scripts/effects/vfx_pool.gd"
const HIT_PATH: String = "res://scenes/vfx/vfx_hit_spark.tscn"
const MAX_STREET_BODIES: int = 40
const POOL_CAP: int = 24
## The lane strips cover -2..46 m along a road and the road axis -3.75..5 m across it. The three samples of a road pair an
## along-distance with an offset across: sidewalk only, road axis, outer road lane (8 roads x 3 = 24 points).
const SAMPLE_ALONG: Array[float] = [-1.5, 22.0, 45.5]
const SAMPLE_ACROSS: Array[float] = [-3.4, 0.0, 4.5]
const BLOCK_CENTRES: Array[Vector3] = [Vector3(-16.0, 0.0, -16.0), Vector3(0.0, 0.0, 0.0), Vector3(16.0, 0.0, 16.0), Vector3(-16.0, 0.0, 16.0)]

static func run(r: Node) -> void:
	r._playing()
	await _street_collision(r)
	await _vfx_pool(r)
	await _district_swap(r)
	await _light_group(r)

## PERF7: a light that enters the tree joins the light limiter's group, so the limiter sorts a short list instead of walking the whole tree
## (about 1800 nodes) four times a second.
static func _light_group(r: Node) -> void:
	var light := OmniLight3D.new()
	r._main.add_child(light)
	await r.get_tree().process_frame
	r._ok(light.is_in_group(&"omni_lights"), "PERF7 an OmniLight3D that enters the tree joins the light limiter's group")
	light.queue_free()

static func _world_runtime(r: Node) -> Node:
	return r._main.get_node_or_null("WorldRuntime")

## The first thing a ray down through `at` meets that is street level: the street body (a child of the builder) or the skyline's
## ground slab. Whatever else stands there (a monster, a locker) is skipped.
static func _ground_hit(space: PhysicsDirectSpaceState3D, builder: Node, at: Vector3) -> Dictionary:
	var skip: Array[RID] = []
	for _try in 6:
		var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 3.0, at + Vector3.DOWN * 3.0, 1)
		query.exclude = skip
		var hit: Dictionary = space.intersect_ray(query)
		if hit.is_empty():
			return hit
		var body: CollisionObject3D = hit["collider"] as CollisionObject3D
		if body.get_parent() == builder or body.name == &"GroundBody":
			return hit
		skip.append(body.get_rid())
	return {}

static func _on_street(hit: Dictionary, builder: Node) -> bool:
	return not hit.is_empty() and (hit["collider"] as Node).get_parent() == builder

## PERF1: the street collision is a few strips on the same surface the tiles had, and nothing is solid between the streets.
static func _street_collision(r: Node) -> void:
	await r.get_tree().physics_frame
	await r.get_tree().physics_frame
	var wr: Node = _world_runtime(r)
	var builder: StreetBuilder = null
	if wr != null and wr.get_child_count() > 0:
		builder = wr.get_child(wr.get_child_count() - 1).get_node_or_null("StreetBuilder") as StreetBuilder
	if builder == null:
		r._ok(false, "PERF1 the start district has a StreetBuilder")
		return
	var bodies: int = builder.find_children("*", "StaticBody3D", true, false).size()
	var space: PhysicsDirectSpaceState3D = (r._main as Node3D).get_world_3d().direct_space_state
	var samples: int = 0
	var off_street: int = 0
	for road in builder.roads:
		for j in SAMPLE_ALONG.size():
			var point: Vector3 = builder.road_pos_at(road, SAMPLE_ALONG[j])
			point += Vector3(0.0, 0.0, SAMPLE_ACROSS[j]) if road.dir == "h" else Vector3(SAMPLE_ACROSS[j], 0.0, 0.0)
			var hit: Dictionary = _ground_hit(space, builder, builder.to_global(point))
			samples += 1
			if not _on_street(hit, builder) or absf(float(hit["position"].y) - 0.06) > 0.01:
				off_street += 1
	var leaks: int = 0
	for centre in BLOCK_CENTRES:
		if _on_street(_ground_hit(space, builder, builder.to_global(centre)), builder):
			leaks += 1
	r._ok(bodies <= MAX_STREET_BODIES and samples == 24 and off_street == 0 and leaks == 0,
		"PERF1 street collision is a few strips on the tile surface (%d StaticBody3D, at most %d; %d of %d road and sidewalk points off the street at y 0.05-0.07; %d of 4 block centres solid)" % [bodies, MAX_STREET_BODIES, off_street, samples, leaks])

static func _burst_count(tree: SceneTree, scene: PackedScene) -> int:
	var n: int = 0
	for node in tree.root.find_children("*", "GPUParticles3D", true, false):
		if node is VFXBurst and node.scene_file_path == scene.resource_path and not node.is_queued_for_deletion():
			n += 1
	return n

## PERF2: 40 hit effects through the pool leave at most the cap alive and replay one. PERF6: a burst that finishes parks itself
## (it is not freed) and the next spawn takes it instead of making a new one.
static func _vfx_pool(r: Node) -> void:
	var tree: SceneTree = r.get_tree()
	var scene: PackedScene = load(HIT_PATH) as PackedScene
	if not ResourceLoader.exists(POOL_PATH):
		r._ok(false, "PERF2 vfx_pool.gd is missing (%s)" % POOL_PATH)
		r._ok(false, "PERF6 vfx_pool.gd is missing, so no finished burst parks itself")
		return
	var pool: Variant = load(POOL_PATH)
	var seen: Dictionary = {}
	var reused: bool = false
	for i in 40:
		var fx: Node3D = pool.spawn(scene, Vector3(0.0, 1.0, 0.0), tree)
		reused = reused or seen.has(fx.get_instance_id())
		seen[fx.get_instance_id()] = fx
	var live: int = _burst_count(tree, scene)
	r._ok(live <= POOL_CAP and reused, "PERF2 40 hit effects through the pool leave at most %d bursts alive and replay one (%d alive, replayed %s)" % [POOL_CAP, live, reused])
	for fx in seen.values():
		fx.queue_free()
	await tree.process_frame
	var first: Node3D = pool.spawn(scene, Vector3.ZERO, tree)
	first.emit_signal("finished")
	await tree.process_frame
	var parked: bool = is_instance_valid(first) and not first.is_queued_for_deletion() and bool(first.get("parked"))
	var before: int = _burst_count(tree, scene)
	var again: Node3D = pool.spawn(scene, Vector3.ZERO, tree)
	r._ok(parked and _burst_count(tree, scene) == before and not bool(again.get("parked")),
		"PERF6 a finished burst parks itself and the next spawn replays it instead of making one (parked %s, bursts %d -> %d)" % [parked, before, _burst_count(tree, scene)])
	for fx in [first, again]:
		if is_instance_valid(fx):
			fx.queue_free()

## PERF3: one district in the tree at a time. PERF4: the load stats. PERF5: the preloader's requests. The player and the district
## are put back afterwards.
static func _district_swap(r: Node) -> void:
	var wr: Node = _world_runtime(r)
	if wr == null:
		r._ok(false, "PERF3 the game has a WorldRuntime")
		return
	var home: StringName = wr.current_district()
	var other: StringName = &"residential" if home == &"suburbs" else &"suburbs"
	var old_root: Node = wr.get_child(wr.get_child_count() - 1)
	var spot: Vector3 = r._player.global_position
	wr.load_district(other)
	var out_at_once: bool = not old_root.is_inside_tree() and wr.get_child_count() == 1
	await r.get_tree().process_frame
	await r.get_tree().process_frame
	r._ok(out_at_once and wr.get_child_count() == 1,
		"PERF3 the old district is out of the tree as load_district returns and one district root is left (%s, %d children)" % [out_at_once, wr.get_child_count()])
	var stats: Dictionary = wr.get_last_load_stats() if wr.has_method("get_last_load_stats") else {}
	r._ok(float(stats.get("total_ms", 0.0)) > 0.0 and String(stats.get("district", "")) == String(other)
		and float(stats.get("streets_ms", 0.0)) > 0.0 and float(stats.get("props_ms", 0.0)) > 0.0,
		"PERF4 the load stats name the district and time the load, the streets and the props (%s)" % [stats])
	var preloader: Variant = wr.get("district_preloader")
	var paths: Array = preloader.requested_paths() if preloader != null else []
	var all_exist: bool = not paths.is_empty()
	for path in paths:
		all_exist = all_exist and ResourceLoader.exists(String(path))
	r._ok(all_exist, "PERF5 the preloader asked the loader for %d paths after the build and every one exists" % paths.size())
	wr.load_district(home)
	await r.get_tree().process_frame
	await r.get_tree().process_frame
	r._player.global_position = spot
