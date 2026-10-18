extends RefCounted
## StoryProps (Session 28, W1): up to three small scenes in every district that say what happened there, each 2.6 m from one of the district's three hiding places (someone hid here, so something was left).
## They are built of what the dressing already draws, the crates, the barrels, the bins and the litter, and added to the same MultiMeshes at the end of their arrays: no new draw call, no collision, no
## navigation (the dressing is visual only), and a seeded stream of their own, so nothing else the dressing places moves. The hiding places are the anchors because they stay where they are (a note
## or a part is picked up and gone). Three kinds, in an order that starts at a different one in every district, each with a line of its own that the player reads on coming near (STORY_<KIND>):
##   camp        three crates round a blackened barrel and a blanket: someone lived here
##   barricade   a wall of crates with a barrel at each end and two bins in front: they held the street
##   evacuation  a scatter of cases and a crate: they left in a hurry
## A scene stands into the block (away from the road) and is dropped when it would stand within 2.2 m of another thing the player can use or hide in.

## The kinds of scene and the line of each, spelled out: the i18n audit finds a key that is a literal and not one that is put together.
const LINE_KEYS: Dictionary = {"camp": "STORY_CAMP", "barricade": "STORY_BARRICADE", "evacuation": "STORY_EVACUATION"}
const FROM_ANCHOR_M: float = 2.6
const KEEP_FROM_OTHERS_M: float = 2.2
const MAX_SCENES: int = 3
## A scene's line is read on coming within this many metres of it.
const HOOK_M: float = 3.4
const GROUND_Y: float = 0.06
const BLANKET := Color(0.22, 0.27, 0.30)
const BLACKENED := Color(0.09, 0.09, 0.10)
const CASES: Array[Color] = [Color(0.22, 0.17, 0.11), Color(0.20, 0.21, 0.19), Color(0.28, 0.24, 0.17), Color(0.15, 0.17, 0.21)]

## The lists to add to the dressing's own, keyed "crates", "barrels", "bins", "litter" (transforms) and "barrel_colors", "litter_colors" (colours), and "spots" (a Vector3 for each scene) and "kinds" (its kind).
static func place(district_id: StringName, anchors: Array[Vector3], clear: Array[Vector2], grid: float) -> Dictionary:
	var crates: Array[Transform3D] = []
	var barrels: Array[Transform3D] = []
	var bins: Array[Transform3D] = []
	var litter: Array[Transform3D] = []
	var barrel_colors: Array[Color] = []
	var litter_colors: Array[Color] = []
	var spots: Array[Vector3] = []
	var kinds: Array[String] = []
	var out: Dictionary = {"crates": crates, "barrels": barrels, "bins": bins, "litter": litter, "barrel_colors": barrel_colors, "litter_colors": litter_colors, "spots": spots, "kinds": kinds}
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("story_" + String(district_id))
	var first: int = absi(hash(String(district_id))) % LINE_KEYS.size()
	for anchor: Vector3 in anchors:
		if spots.size() >= MAX_SCENES:
			break
		var centre := Vector3(clampf(roundf(anchor.x / grid), -1.0, 1.0) * grid, 0.0, clampf(roundf(anchor.z / grid), -1.0, 1.0) * grid)
		var into: Vector3 = (centre - anchor).normalized() if centre.distance_to(anchor) > 3.0 else Vector3.RIGHT.rotated(Vector3.UP, rng.randf() * TAU)
		var at := Vector3.INF
		for sign_value: float in [1.0, -1.0]:
			var tried: Vector3 = anchor + into * FROM_ANCHOR_M * sign_value
			if _free(tried, anchor, clear):
				at = tried
				break
		if at == Vector3.INF:
			continue
		var kind: String = LINE_KEYS.keys()[(first + spots.size()) % LINE_KEYS.size()]
		_scene(out, kind, at, rng)
		spots.append(at)
		kinds.append(kind)
	return out

static func _free(at: Vector3, anchor: Vector3, clear: Array[Vector2]) -> bool:
	for other: Vector2 in clear:
		if Vector2(anchor.x, anchor.z).distance_to(other) < 0.2:
			continue  # the anchor itself
		if other.distance_to(Vector2(at.x, at.z)) < KEEP_FROM_OTHERS_M:
			return false
	return true

static func _scene(out: Dictionary, kind: String, at: Vector3, rng: RandomNumberGenerator) -> void:
	var turn := Basis(Vector3.UP, rng.randf() * TAU)
	match kind:
		"camp":
			for offset: Vector3 in [Vector3(-0.9, 0.0, 0.4), Vector3(0.9, 0.0, 0.5), Vector3(0.0, 0.0, -1.0)]:
				_crate(out, at, turn, offset, rng.randf_range(0.8, 1.0), rng)
			(out["barrels"] as Array[Transform3D]).append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU), at + turn * Vector3(0.0, GROUND_Y + 0.45, 0.1)))
			(out["barrel_colors"] as Array[Color]).append(BLACKENED)
			_litter(out, at + turn * Vector3(0.1, GROUND_Y + 0.02, 1.1), turn, Vector3(3.0, 1.0, 5.5), BLANKET)
			for n in 3:
				_litter(out, at + turn * Vector3(rng.randf_range(-1.6, 1.6), GROUND_Y + 0.02, rng.randf_range(-1.6, 1.6)), turn, Vector3(0.6, 1.0, 0.6), CASES[rng.randi() % CASES.size()])
		"barricade":
			for x: float in [-1.2, -0.4, 0.4, 1.2]:
				_crate(out, at, turn, Vector3(x, 0.0, 0.0), 1.0, rng, true)
			for x: float in [-0.8, 0.0, 0.8]:
				_crate(out, at, turn, Vector3(x, 0.7, 0.0), 0.9, rng, true)
			for x: float in [-2.1, 2.1]:
				(out["barrels"] as Array[Transform3D]).append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU), at + turn * Vector3(x, GROUND_Y + 0.45, 0.1)))
				(out["barrel_colors"] as Array[Color]).append(Color(0.27, 0.15, 0.10) if x < 0.0 else Color(0.16, 0.17, 0.19))
			for x: float in [-0.9, 0.9]:
				(out["bins"] as Array[Transform3D]).append(Transform3D(turn, at + turn * Vector3(x, GROUND_Y, 1.3)))
		_:
			for n in 6:  # the dressing's litter box is 0.38 m by 0.012 m by 0.26 m: this scales it to a suitcase of 0.7 to 1 m, 0.2 to 0.3 m thick, standing on the ground
				var size := Vector3(rng.randf_range(1.8, 2.6), rng.randf_range(16.0, 24.0), rng.randf_range(1.6, 2.2))
				_litter(out, at + turn * Vector3(rng.randf_range(-1.5, 1.5), GROUND_Y + size.y * 0.006, rng.randf_range(-1.5, 1.5)), Basis(Vector3.UP, rng.randf() * TAU), size, CASES[rng.randi() % CASES.size()])
			_crate(out, at, turn, Vector3(1.6, 0.0, -0.8), 0.9, rng)

## `tidy` squares a crate to the scene's own direction (a wall of crates turned every way is a heap, not a barricade).
static func _crate(out: Dictionary, at: Vector3, turn: Basis, offset: Vector3, size: float, rng: RandomNumberGenerator, tidy: bool = false) -> void:
	var spot: Vector3 = at + turn * Vector3(offset.x, offset.y + GROUND_Y + 0.35 * size, offset.z)
	var spin: Basis = turn * Basis(Vector3.UP, rng.randf_range(-0.12, 0.12)) if tidy else Basis(Vector3.UP, rng.randf() * TAU)
	(out["crates"] as Array[Transform3D]).append(Transform3D(spin.scaled(Vector3.ONE * size), spot))

static func _litter(out: Dictionary, at: Vector3, turn: Basis, scale_by: Vector3, color: Color) -> void:
	(out["litter"] as Array[Transform3D]).append(Transform3D(turn * Basis.from_scale(scale_by), at))
	(out["litter_colors"] as Array[Color]).append(color)

## Where the hiding places of the district are, in the order they were placed: the anchors of the scenes.
static func hiding_spots(tree: SceneTree) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for node in tree.get_nodes_in_group(&"hiding_spot"):
		var spot := node as Node3D
		if spot != null:
			out.append(spot.global_position)
	return out

## The line of a scene, read once on coming near (a notice, not a pickup): the trigger ends with the visit.
static func hook(parent: Node3D, at: Vector3, kind: String) -> void:
	var area := Area3D.new()
	area.name = "StoryHook_" + kind
	area.collision_layer = 0
	area.collision_mask = 1
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = HOOK_M
	shape.shape = sphere
	area.add_child(shape)
	parent.add_child(area)
	area.global_position = Vector3(at.x, 1.0, at.z)
	area.body_entered.connect(func(body: Node3D) -> void:
		if body.is_in_group("player"):
			EventBus.inventory_notice.emit(LocalizationManager.t(LINE_KEYS[kind]))
			area.queue_free())
