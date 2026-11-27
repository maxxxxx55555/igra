class_name EnterableBuildingBuilder
extends RefCounted

## Builds enterable ground-floor interiors seamlessly integrated into street buildings.
## Uses real split wall colliders (left wall, right wall, upper lintel) so the player walks
## smoothly through open doorways, hides from stalkers, or searches interior tables for relays.
## Respects <= 140 draw calls (shared materials + distance culling) and <= 45 MiB budget (0 textures).

const WALL_THICKNESS: float = 0.28
const DOOR_WIDTH: float = 1.65
const DOOR_HEIGHT: float = 2.45
const ROOM_HEIGHT: float = 3.40
const INTERIOR_CULL_DIST: float = 38.0


static func build_enterable_room(
	parent: Node3D,
	room_name: String,
	origin: Vector3,
	yaw_rad: float,
	width_m: float,
	depth_m: float,
	theme_id: String,
	wall_mat: Material,
	floor_mat: Material,
	prop_mat: Material
) -> Dictionary:
	"""Constructs an enterable room with an open doorway facing local +Z.
	Returns metadata dict with root Node3D, doorway_world_pos, interior_center, and loot_points.
	"""
	var w: float = clampf(width_m, 5.2, 11.0)
	var d: float = clampf(depth_m, 5.2, 10.0)

	var root: Node3D = Node3D.new()
	root.name = "Enterable_%s" % room_name
	root.position = origin
	root.rotation.y = yaw_rad
	root.add_to_group("enterable_buildings")
	parent.add_child(root)

	# 1. Floor & Ceiling
	_add_solid_box(root, "Floor", Vector3(0.0, 0.06, 0.0), Vector3(w, 0.12, d), floor_mat, 0.0)
	_add_solid_box(root, "Ceiling", Vector3(0.0, ROOM_HEIGHT, 0.0), Vector3(w, 0.20, d), wall_mat, 0.0)

	# 2. Back, Left, Right solid walls
	_add_solid_box(root, "WallBack", Vector3(0.0, ROOM_HEIGHT * 0.5, -d * 0.5), Vector3(w, ROOM_HEIGHT, WALL_THICKNESS), wall_mat, 0.0)
	_add_solid_box(root, "WallLeft", Vector3(-w * 0.5, ROOM_HEIGHT * 0.5, 0.0), Vector3(WALL_THICKNESS, ROOM_HEIGHT, d), wall_mat, 0.0)
	_add_solid_box(root, "WallRight", Vector3(w * 0.5, ROOM_HEIGHT * 0.5, 0.0), Vector3(WALL_THICKNESS, ROOM_HEIGHT, d), wall_mat, 0.0)

	# 3. Front wall split around real open doorway (player walks straight in!)
	var side_w: float = maxf(0.6, (w - DOOR_WIDTH) * 0.5)
	var front_z: float = d * 0.5
	_add_solid_box(root, "FrontLeft", Vector3(-(DOOR_WIDTH * 0.5 + side_w * 0.5), ROOM_HEIGHT * 0.5, front_z), Vector3(side_w, ROOM_HEIGHT, WALL_THICKNESS), wall_mat, 0.0)
	_add_solid_box(root, "FrontRight", Vector3(DOOR_WIDTH * 0.5 + side_w * 0.5, ROOM_HEIGHT * 0.5, front_z), Vector3(side_w, ROOM_HEIGHT, WALL_THICKNESS), wall_mat, 0.0)
	var lintel_h: float = maxf(0.45, ROOM_HEIGHT - DOOR_HEIGHT)
	_add_solid_box(root, "DoorLintel", Vector3(0.0, DOOR_HEIGHT + lintel_h * 0.5, front_z), Vector3(DOOR_WIDTH, lintel_h, WALL_THICKNESS), wall_mat, 0.0)

	# 4. Architectural door frame & warm dim threshold beacon (emissive only -> 0 extra dynamic lights!)
	var frame_mat: StandardMaterial3D = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.14, 0.16, 0.17, 1.0)
	frame_mat.roughness = 0.72
	frame_mat.metallic = 0.25
	_add_visual_box(root, "FrameLeft", Vector3(-DOOR_WIDTH * 0.5, DOOR_HEIGHT * 0.5, front_z + 0.04), Vector3(0.10, DOOR_HEIGHT, 0.34), frame_mat, INTERIOR_CULL_DIST)
	_add_visual_box(root, "FrameRight", Vector3(DOOR_WIDTH * 0.5, DOOR_HEIGHT * 0.5, front_z + 0.04), Vector3(0.10, DOOR_HEIGHT, 0.34), frame_mat, INTERIOR_CULL_DIST)
	_add_visual_box(root, "FrameTop", Vector3(0.0, DOOR_HEIGHT, front_z + 0.04), Vector3(DOOR_WIDTH + 0.20, 0.12, 0.34), frame_mat, INTERIOR_CULL_DIST)

	# Warm interior fixture (emissive bulb + gentle shade, zero dynamic light bloat)
	var bulb_mat: StandardMaterial3D = StandardMaterial3D.new()
	bulb_mat.albedo_color = Color(0.95, 0.80, 0.45, 1.0)
	bulb_mat.emission_enabled = true
	bulb_mat.emission = Color(0.85, 0.67, 0.32, 1.0)
	bulb_mat.emission_energy_multiplier = 1.35
	_add_visual_box(root, "PorchLamp", Vector3(0.0, DOOR_HEIGHT + 0.22, front_z + 0.22), Vector3(0.24, 0.10, 0.14), bulb_mat, INTERIOR_CULL_DIST)
	_add_visual_box(root, "InteriorCeilingFixture", Vector3(0.0, ROOM_HEIGHT - 0.18, -0.4), Vector3(0.45, 0.08, 0.18), bulb_mat, INTERIOR_CULL_DIST)

	# 5. Grounded interior furniture (culled at 38m to keep mobile draw calls <= 140)
	var loot_local: Array[Vector3] = []
	var desk_pos: Vector3 = Vector3(-w * 0.24, 0.48, -d * 0.22)
	_add_solid_box(root, "CounterDesk", desk_pos, Vector3(1.85, 0.84, 0.78), prop_mat, INTERIOR_CULL_DIST)
	loot_local.append(desk_pos + Vector3(0.0, 0.52, 0.0))

	var shelf_pos: Vector3 = Vector3(w * 0.32, 1.05, -d * 0.32)
	_add_solid_box(root, "WallShelf", shelf_pos, Vector3(1.55, 1.98, 0.52), prop_mat, INTERIOR_CULL_DIST)
	loot_local.append(Vector3(w * 0.14, 0.55, 0.15))

	# Optional cover divider inside larger rooms (great stealth hiding spot!)
	if w >= 7.0:
		_add_solid_box(root, "CoverPartition", Vector3(0.35, 0.95, 0.45), Vector3(1.60, 1.78, 0.22), prop_mat, INTERIOR_CULL_DIST)

	# 6. Interior Area3D trigger for warm shelter acoustics / stealth bonus / HUD hint
	var area: Area3D = Area3D.new()
	area.name = "InteriorZone"
	area.set_meta("theme_id", theme_id)
	area.set_meta("is_interior", true)
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var box_sh: BoxShape3D = BoxShape3D.new()
	box_sh.size = Vector3(w - 0.5, ROOM_HEIGHT - 0.3, d - 0.5)
	shape_node.shape = box_sh
	shape_node.position = Vector3(0.0, ROOM_HEIGHT * 0.5, 0.0)
	area.add_child(shape_node)
	root.add_child(area)

	var xform: Transform3D = root.global_transform
	var loot_world: Array[Vector3] = []
	for lp in loot_local:
		loot_world.append(xform * lp)

	return {
		"root": root,
		"theme_id": theme_id,
		"doorway_world": xform * Vector3(0.0, 0.1, front_z + 0.9),
		"interior_center": xform * Vector3(0.0, 0.1, -0.3),
		"loot_points": loot_world,
		"footprint_size": Vector2(w, d),
	}


static func _add_solid_box(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, mat: Material, cull_dist: float) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = node_name
	body.position = pos
	var mi: MeshInstance3D = MeshInstance3D.new()
	var bm: BoxMesh = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	if cull_dist > 0.0:
		mi.visibility_range_end = cull_dist
	body.add_child(mi)
	var col: CollisionShape3D = CollisionShape3D.new()
	var sh: BoxShape3D = BoxShape3D.new()
	sh.size = size
	col.shape = sh
	body.add_child(col)
	parent.add_child(body)
	return body


static func _add_visual_box(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, mat: Material, cull_dist: float) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = node_name
	mi.position = pos
	var bm: BoxMesh = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	if cull_dist > 0.0:
		mi.visibility_range_end = cull_dist
	parent.add_child(mi)
	return mi
