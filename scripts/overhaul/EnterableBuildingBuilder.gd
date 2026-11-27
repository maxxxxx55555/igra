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
	# The doorway faces local +Z.
	var w: float = clampf(width_m, 5.2, 11.0)
	var d: float = clampf(depth_m, 5.2, 10.0)

	var root: Node3D = Node3D.new()
	root.name = "Enterable_%s" % room_name
	root.position = origin
	root.rotation.y = yaw_rad
	root.add_to_group("enterable_buildings")
	parent.add_child(root)

	# 1. Floor & Ceiling
	_add_solid_box(root, "Floor", Vector3(0.0, -0.05, 0.0), Vector3(w, 0.12, d), floor_mat, 0.0)
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

	# A plinth and drip course break the front into weathered masonry bands.
	for side in [-1.0, 1.0]:
		var x := (DOOR_WIDTH * 0.5 + side_w * 0.5) * float(side)
		_add_visual_box(root, "Plinth", Vector3(x, 0.24, front_z + 0.12), Vector3(side_w, 0.46, 0.21), wall_mat, 0)
		_add_visual_box(root, "SillBand", Vector3(x, 1.22, front_z + 0.15), Vector3(side_w, 0.08, 0.25), wall_mat, 0)
	_add_visual_box(root, "DripCourse", Vector3(0, ROOM_HEIGHT - 0.08, front_z + 0.15), Vector3(w + 0.22, 0.15, 0.26), wall_mat, 0)

	# 4. Architectural door frame & warm dim threshold beacon (emissive only -> 0 extra dynamic lights!)
	var frame_mat: StandardMaterial3D = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.14, 0.16, 0.17, 1.0)
	frame_mat.roughness = 0.72
	frame_mat.metallic = 0.25
	_add_visual_box(root, "FrameLeft", Vector3(-DOOR_WIDTH * 0.5, DOOR_HEIGHT * 0.5, front_z + 0.04), Vector3(0.10, DOOR_HEIGHT, 0.34), frame_mat, INTERIOR_CULL_DIST)
	_add_visual_box(root, "FrameRight", Vector3(DOOR_WIDTH * 0.5, DOOR_HEIGHT * 0.5, front_z + 0.04), Vector3(0.10, DOOR_HEIGHT, 0.34), frame_mat, INTERIOR_CULL_DIST)
	_add_visual_box(root, "FrameTop", Vector3(0.0, DOOR_HEIGHT, front_z + 0.04), Vector3(DOOR_WIDTH + 0.20, 0.12, 0.34), frame_mat, INTERIOR_CULL_DIST)

	# Warm interior fixture (emissive bulb + gentle shade, zero dynamic light bloat)
	var bulb_mat: StandardMaterial3D = _bulb()
	_add_visual_box(root, "PorchLamp", Vector3(0.0, DOOR_HEIGHT + 0.22, front_z + 0.22), Vector3(0.24, 0.10, 0.14), bulb_mat, INTERIOR_CULL_DIST)
	_add_visual_box(root, "InteriorCeilingFixture", Vector3(0.0, ROOM_HEIGHT - 0.18, -0.4), Vector3(0.45, 0.08, 0.18), bulb_mat, INTERIOR_CULL_DIST)

	# 5. Grounded interior furniture (culled at 38m to keep mobile draw calls <= 140)
	var loot_local: Array[Vector3] = []
	var desk_pos: Vector3 = Vector3(-w * 0.24, 0.48, -d * 0.22)
	_add_solid_box(root, "CounterDesk", desk_pos, Vector3(1.85, 0.84, 0.78), prop_mat, INTERIOR_CULL_DIST)
	loot_local.append(desk_pos + Vector3(0.0, 0.49, 0.28))

	var shelf_pos: Vector3 = Vector3(w * 0.32, 1.05, -d * 0.32)
	_add_solid_box(root, "WallShelf", shelf_pos, Vector3(1.55, 1.98, 0.52), prop_mat, INTERIOR_CULL_DIST)
	loot_local.append(Vector3(w * 0.14, 0.55, 0.15))

	# Optional cover divider inside larger rooms (great stealth hiding spot!)
	if w >= 7.0:
		_add_solid_box(root, "CoverPartition", Vector3(1.62, 0.95, 0.15), Vector3(1.60, 1.78, 0.22), prop_mat, INTERIOR_CULL_DIST)

	# 6. Interior Area3D trigger for warm shelter acoustics / stealth bonus / HUD hint
	var area: Area3D = Area3D.new()
	area.name = "InteriorZone"
	area.add_to_group("district_interiors")
	area.collision_layer = 0
	area.collision_mask = 1
	area.set_meta("theme_id", theme_id)
	area.set_meta("is_interior", true)
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var box_sh: BoxShape3D = BoxShape3D.new()
	box_sh.size = Vector3(w - 0.5, ROOM_HEIGHT - 0.3, d - 0.5)
	shape_node.name = "CollisionShape3D"
	shape_node.shape = box_sh
	shape_node.position = Vector3(0.0, ROOM_HEIGHT * 0.5, 0.0)
	area.add_child(shape_node)
	root.add_child(area)
	area.body_entered.connect(func(body: Node3D) -> void:
		if body.is_in_group("player"):
			body.set_meta("inside_district_building", true))
	area.body_exited.connect(func(body: Node3D) -> void:
		if body.is_in_group("player"):
			body.set_meta("inside_district_building", false))

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

static func batch_visuals(parent: Node3D, rooms: Array[Dictionary]) -> void:
	# Batch by material, but keep the furniture's 38 m visibility threshold.
	var surfaces := {}
	var casters := SurfaceTool.new()
	casters.begin(Mesh.PRIMITIVE_TRIANGLES)
	for room in rooms:
		var root: Node3D = room.root
		for mesh: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
			var material: Material = mesh.material_override
			var cull := mesh.visibility_range_end
			var anchor := root if cull > 0.0 else parent
			var key := Vector2i(material.get_instance_id() % 2147483647, anchor.get_instance_id() % 2147483647)
			if not surfaces.has(key):
				surfaces[key] = [SurfaceTool.new(), material, cull, anchor]
				surfaces[key][0].begin(Mesh.PRIMITIVE_TRIANGLES)
			var frame := anchor.global_transform.affine_inverse() * mesh.global_transform
			surfaces[key][0].append_from(mesh.mesh, 0, frame)
			if mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON:
				casters.append_from(mesh.mesh, 0, parent.global_transform.affine_inverse() * mesh.global_transform)
			mesh.queue_free()
	var shadow := casters.commit()
	if shadow != null and shadow.get_surface_count() > 0:
		var proxy := MeshInstance3D.new()
		proxy.name = "InteriorShadowCasters"
		proxy.mesh = shadow
		proxy.layers |= ShadowAndRestorationRig.WORLD_CASTER_LAYER
		proxy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		parent.add_child(proxy)
	for data: Array in surfaces.values():
		var mesh := MeshInstance3D.new()
		mesh.mesh = data[0].commit()
		mesh.material_override = data[1]
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.layers |= ShadowAndRestorationRig.LOCAL_RECEIVER_LAYER
		if float(data[2]) <= 0.0:
			mesh.layers |= ShadowAndRestorationRig.MOON_RECEIVER_LAYER
		mesh.visibility_range_end = data[2]
		data[3].add_child(mesh)

static var _shared_fixture: StandardMaterial3D

static func _bulb() -> StandardMaterial3D:
	if _shared_fixture == null:
		_shared_fixture = StandardMaterial3D.new()
		_shared_fixture.albedo_color = Color("#ad905f")
		_shared_fixture.emission_enabled = true
		_shared_fixture.emission = Color("#d4a94e")
		_shared_fixture.emission_energy_multiplier = 0.18
	return _shared_fixture
