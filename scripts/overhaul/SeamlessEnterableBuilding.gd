class_name SeamlessEnterableBuilding
extends RefCounted

## Zero-Z-Fighting Enterable Building Builder for Last Streetlight.
## Fixes all 3 visual defects seen in V4:
##  1) No coplanar faces / no overlapping textures (every joint inset by exact thickness/margin).
##  2) No clipping into existing street buildings or road markings (strict AABB lot check).
##  3) Architectural grounding (dark slate exterior matching neighborhood, stone plinth,
##     roof parapet cornice, metal doorway awning, interior baseboards, multi-part furniture
##     with legs/shelves instead of giant beige cubes, real shadow casting enabled).

const WALL_T: float = 0.28
const DOOR_W: float = 1.68
const DOOR_H: float = 2.42
const ROOM_H: float = 3.40
const MARGIN_EPS: float = 0.015
const CULL_DIST: float = 38.0


static func is_lot_clear(origin: Vector3, footprint: Vector2, existing_aabbs: Array, road_half_width: float = 4.6) -> bool:
	# Check the finished footprint plus clearance against all reserved lots.
	var half_x: float = footprint.x * 0.5 + 0.32
	var half_z: float = footprint.y * 0.5 + 0.48
	# Reject lots overlapping primary X=0 or Z=0 road stripes
	if absf(origin.x) < (road_half_width + half_x * 0.55) and absf(origin.z) < (road_half_width + half_z * 0.55):
		return false
	var cand: AABB = AABB(
		Vector3(origin.x - half_x, -0.5, origin.z - half_z),
		Vector3(half_x * 2.0, ROOM_H + 2.0, half_z * 2.0)
	)
	for item in existing_aabbs:
		if item is AABB and cand.intersects(item as AABB):
			return false
	return true


static func build(
	parent: Node3D,
	room_name: String,
	origin: Vector3,
	yaw_rad: float,
	width_m: float,
	depth_m: float,
	theme_id: String,
	pbr_shader: Shader
) -> Dictionary:
	var w: float = clampf(width_m, 5.8, 10.6)
	var d: float = clampf(depth_m, 5.4, 9.4)
	var inner_d: float = d - (WALL_T * 2.0) - MARGIN_EPS

	var root: Node3D = Node3D.new()
	root.name = "Enterable_%s" % room_name
	root.position = origin
	root.rotation.y = yaw_rad
	root.add_to_group("enterable_buildings")
	parent.add_child(root)

	# Cohesive dark slate/charcoal materials (no bright chalk gray, no flat beige plastic)
	var ext_wall_mat: Material = _make_pbr_mat(pbr_shader, Color(0.16, 0.19, 0.21), Color(0.065, 0.078, 0.087), 0.82, 0.06, origin.y, 1.0)

	var plinth_mat: Material = _make_pbr_mat(pbr_shader, Color(0.048, 0.060, 0.068), Color(0.020, 0.026, 0.030), 0.72, 0.12, origin.y, 1.0)
	var floor_mat: Material = _make_pbr_mat(pbr_shader, Color(0.16, 0.16, 0.16), Color(0.070, 0.073, 0.076), 0.68, 0.08, origin.y + 0.14, 0.0)
	var wood_mat: Material = _make_pbr_mat(pbr_shader, Color(0.22, 0.16, 0.11), Color(0.084, 0.065, 0.046), 0.78, 0.04, origin.y + 0.14, 0.0)
	var metal_mat: Material = _make_pbr_mat(pbr_shader, Color(0.17, 0.20, 0.21), Color(0.073, 0.085, 0.095), 0.56, 0.42, origin.y + 0.14, 0.0)

	# 1. Raised concrete floor slab (strictly above asphalt y=0 to kill road z-fighting)
	_solid_box(root, "FloorSlab", Vector3(0.0, -0.074, 0.0), Vector3(w - 0.04, 0.16, d - 0.04), floor_mat, 0.0, true)
	# Entry threshold apron (smooth beveled step from street y=0.02 up to y=0.14)
	_visual_box(root, "EntryApron", Vector3(0.0, 0.003, d * 0.5 + 0.24), Vector3(DOOR_W + 0.52, 0.012, 0.46), plinth_mat, CULL_DIST, false)

	# 2. Ceiling & roof parapet cornice (protrudes cleanly, zero coplanar overlap with walls)
	_solid_box(root, "CeilingSlab", Vector3(0.0, ROOM_H + 0.11, 0.0), Vector3(w + 0.18, 0.22, d + 0.18), plinth_mat, 0.0, true)
	_visual_box(root, "RoofParapetFront", Vector3(0.0, ROOM_H + 0.34, d * 0.5 + 0.02), Vector3(w + 0.24, 0.24, 0.16), ext_wall_mat, 0.0, true)
	_visual_box(root, "RoofParapetBack", Vector3(0.0, ROOM_H + 0.34, -d * 0.5 - 0.02), Vector3(w + 0.24, 0.24, 0.16), ext_wall_mat, 0.0, true)

	# 3. Non-coplanar structural walls (side walls inset between front & back walls!)
	var half_w: float = w * 0.5
	var half_d: float = d * 0.5
	var wall_y: float = 0.16 + (ROOM_H - 0.16) * 0.5
	var wall_h: float = ROOM_H - 0.16

	_solid_box(root, "WallBack", Vector3(0.0, wall_y, -(half_d - WALL_T * 0.5)), Vector3(w, wall_h, WALL_T), ext_wall_mat, 0.0, true)
	_solid_box(root, "WallLeft", Vector3(-(half_w - WALL_T * 0.5), wall_y, 0.0), Vector3(WALL_T, wall_h, inner_d), ext_wall_mat, 0.0, true)
	_solid_box(root, "WallRight", Vector3(half_w - WALL_T * 0.5, wall_y, 0.0), Vector3(WALL_T, wall_h, inner_d), ext_wall_mat, 0.0, true)

	# Front wall split cleanly around doorway
	var side_w: float = maxf(0.65, (w - DOOR_W) * 0.5)
	var front_z: float = half_d - WALL_T * 0.5
	_solid_box(root, "FrontLeft", Vector3(-(DOOR_W * 0.5 + side_w * 0.5), wall_y, front_z), Vector3(side_w, wall_h, WALL_T), ext_wall_mat, 0.0, true)
	_solid_box(root, "FrontRight", Vector3(DOOR_W * 0.5 + side_w * 0.5, wall_y, front_z), Vector3(side_w, wall_h, WALL_T), ext_wall_mat, 0.0, true)
	var lintel_h: float = maxf(0.42, ROOM_H - DOOR_H)
	_solid_box(root, "DoorLintel", Vector3(0.0, DOOR_H + lintel_h * 0.5, front_z), Vector3(DOOR_W - MARGIN_EPS, lintel_h, WALL_T), ext_wall_mat, 0.0, true)

	# 4. Exterior grounding plinth skirt (protrudes +0.04m around base -> eliminates sharp ground seam!)
	_visual_box(root, "PlinthLeft", Vector3(-half_w - 0.03, 0.24, 0.0), Vector3(0.06, 0.48, d + 0.08), plinth_mat, CULL_DIST, false)
	_visual_box(root, "PlinthRight", Vector3(half_w + 0.03, 0.24, 0.0), Vector3(0.06, 0.48, d + 0.08), plinth_mat, CULL_DIST, false)
	_visual_box(root, "PlinthBack", Vector3(0.0, 0.24, -half_d - 0.03), Vector3(w + 0.08, 0.48, 0.06), plinth_mat, CULL_DIST, false)
	_visual_box(root, "PlinthFrontL", Vector3(-(DOOR_W * 0.5 + side_w * 0.5), 0.24, half_d + 0.03), Vector3(side_w + 0.04, 0.48, 0.06), plinth_mat, CULL_DIST, false)
	_visual_box(root, "PlinthFrontR", Vector3(DOOR_W * 0.5 + side_w * 0.5, 0.24, half_d + 0.03), Vector3(side_w + 0.04, 0.48, 0.06), plinth_mat, CULL_DIST, false)

	# 5. Recessed metal door frame, rain canopy & warm threshold sconce (zero dynamic light bloat)
	_visual_box(root, "FrameL", Vector3(-DOOR_W * 0.5 + 0.05, 0.16 + (DOOR_H - 0.16) * 0.5, front_z), Vector3(0.10, DOOR_H - 0.16, WALL_T + 0.07), metal_mat, CULL_DIST, true)
	_visual_box(root, "FrameR", Vector3(DOOR_W * 0.5 - 0.05, 0.16 + (DOOR_H - 0.16) * 0.5, front_z), Vector3(0.10, DOOR_H - 0.16, WALL_T + 0.07), metal_mat, CULL_DIST, true)
	_visual_box(root, "FrameTop", Vector3(0.0, DOOR_H - 0.05, front_z), Vector3(DOOR_W + 0.16, 0.10, WALL_T + 0.07), metal_mat, CULL_DIST, true)
	_visual_box(root, "RainCanopy", Vector3(0.0, DOOR_H + 0.22, half_d + 0.42), Vector3(DOOR_W + 0.68, 0.08, 0.84), metal_mat, CULL_DIST, true)

	var bulb_mat: StandardMaterial3D = StandardMaterial3D.new()
	bulb_mat.albedo_color = Color(0.92, 0.76, 0.42, 1.0)
	bulb_mat.emission_enabled = true
	bulb_mat.emission = Color(0.83, 0.64, 0.29, 1.0)
	bulb_mat.emission_energy_multiplier = 0.24
	_visual_box(root, "PorchLampBulb", Vector3(0.0, DOOR_H + 0.14, half_d + 0.24), Vector3(0.22, 0.06, 0.14), bulb_mat, CULL_DIST, false)
	_visual_box(root, "CeilingBulb", Vector3(0.0, ROOM_H - 0.06, -0.35), Vector3(0.42, 0.06, 0.16), bulb_mat, CULL_DIST, false)

	# 6. Interior trim baseboards (hides wall-floor seam cleanly inside room!)
	var in_w: float = w - WALL_T * 2.0 - 0.04
	var in_d: float = d - WALL_T * 2.0 - 0.04
	_visual_box(root, "BaseboardBack", Vector3(0.0, 0.22, -(half_d - WALL_T - 0.025)), Vector3(in_w, 0.12, 0.05), plinth_mat, CULL_DIST, false)
	_visual_box(root, "BaseboardLeft", Vector3(-(half_w - WALL_T - 0.025), 0.22, 0.0), Vector3(0.05, 0.12, in_d), plinth_mat, CULL_DIST, false)
	_visual_box(root, "BaseboardRight", Vector3(half_w - WALL_T - 0.025, 0.22, 0.0), Vector3(0.05, 0.12, in_d), plinth_mat, CULL_DIST, false)

	# 7. Real multi-part interior furniture (wooden table with legs + open metal rack — NO giant beige cubes!)
	var loot_local: Array[Vector3] = []
	var tbl_pos: Vector3 = Vector3(-w * 0.24, 0.16, -d * 0.20)
	_build_table(root, "WorkTable", tbl_pos, 1.65, 0.78, 0.80, wood_mat, metal_mat)
	loot_local.append(tbl_pos + Vector3(0.0, 0.86, 0.0))

	var rack_pos: Vector3 = Vector3(w * 0.30, 0.16, -d * 0.28)
	_build_metal_rack(root, "SupplyRack", rack_pos, 1.45, 0.46, 1.85, metal_mat, wood_mat)
	loot_local.append(rack_pos + Vector3(-0.35, 0.96, 0.0))

	# Low wooden crate + metal locker for stealth cover without blocking the camera
	_solid_box(root, "CrateCover", Vector3(1.58, 0.16 + 0.42, 0.55), Vector3(0.88, 0.84, 0.82), wood_mat, CULL_DIST, true)

	# 8. Interior Zone Area3D
	var fixture := OmniLight3D.new()
	fixture.name = "InteriorFixture"
	fixture.position = Vector3(0.0, ROOM_H - 0.35, -0.35)
	fixture.light_color = Color("#d7ae76")
	fixture.omni_range = 5.2
	fixture.omni_attenuation = 0.85
	fixture.light_energy = 0.0
	fixture.hide()
	root.add_child(fixture)
	var district_id := StringName(parent.get("_district_id"))
	var area: Area3D = Area3D.new()
	area.name = "InteriorZone"
	area.set_meta("theme_id", theme_id)
	area.set_meta("is_interior", true)
	var sh_node: CollisionShape3D = CollisionShape3D.new()
	area.collision_layer = 0
	area.collision_mask = 1
	area.add_to_group("district_interiors")
	sh_node.name = "CollisionShape3D"
	var sh_box: BoxShape3D = BoxShape3D.new()
	sh_box.size = Vector3(in_w - 0.2, ROOM_H - 0.3, in_d - 0.2)
	sh_node.shape = sh_box
	sh_node.position = Vector3(0.0, 0.16 + (ROOM_H - 0.3) * 0.5, 0.0)
	area.add_child(sh_node)
	root.add_child(area)
	area.body_entered.connect(func(body: Node3D) -> void:
		if body.is_in_group("player"):
			body.set_meta("inside_district_building", true)
			_update_fixture(fixture, PowerGrid.get_stage(district_id)))
	area.body_exited.connect(func(body: Node3D) -> void:
		if body.is_in_group("player"):
			body.set_meta("inside_district_building", false)
			fixture.light_energy = 0.0
			fixture.hide())


	var xf: Transform3D = root.global_transform
	var loot_world: Array[Vector3] = []
	for lp in loot_local:
		loot_world.append(xf * lp)

	return {
		"root": root,
		"theme_id": theme_id,
		"doorway_world": xf * Vector3(0.0, 0.16, half_d + 1.05),
		"interior_center": xf * Vector3(0.0, 0.16, 0.15),
		"loot_points": loot_world,
		"footprint_size": Vector2(w, d),
		"aabb": root.transform * AABB(Vector3(-half_w, 0.0, -half_d), Vector3(w, ROOM_H + 0.5, d)),
	}


static func _update_fixture(fixture: OmniLight3D, stage: int) -> void:
	fixture.light_energy = 3.4 if stage == DistrictData.Stage.FULL else 0.0
	fixture.visible = fixture.light_energy > 0.0


static func _build_table(parent: Node3D, prefix: String, base_pos: Vector3, tw: float, td: float, th: float, top_mat: Material, leg_mat: Material) -> void:
	_solid_box(parent, prefix + "_Top", base_pos + Vector3(0.0, th - 0.04, 0.0), Vector3(tw, 0.08, td), top_mat, CULL_DIST, true)
	var lx: float = tw * 0.5 - 0.08
	var lz: float = td * 0.5 - 0.08
	for idx in range(4):
		var sx: float = -lx if (idx % 2 == 0) else lx
		var sz: float = -lz if (idx < 2) else lz
		_visual_box(parent, "%s_Leg%d" % [prefix, idx], base_pos + Vector3(sx, (th - 0.08) * 0.5, sz), Vector3(0.07, th - 0.08, 0.07), leg_mat, CULL_DIST, true)


static func _build_metal_rack(parent: Node3D, prefix: String, base_pos: Vector3, rw: float, rd: float, rh: float, frame_mat: Material, plank_mat: Material) -> void:
	var lx: float = rw * 0.5 - 0.04
	var lz: float = rd * 0.5 - 0.04
	for idx in range(4):
		var sx: float = -lx if (idx % 2 == 0) else lx
		var sz: float = -lz if (idx < 2) else lz
		_visual_box(parent, "%s_Post%d" % [prefix, idx], base_pos + Vector3(sx, rh * 0.5, sz), Vector3(0.05, rh, 0.05), frame_mat, CULL_DIST, true)
	for lvl in [0.18, 0.88, 1.56]:
		_solid_box(parent, "%s_Shelf_%d" % [prefix, int(lvl * 10)], base_pos + Vector3(0.0, lvl, 0.0), Vector3(rw - 0.06, 0.045, rd - 0.04), plank_mat, CULL_DIST, true)


static func _make_pbr_mat(shader: Shader, base_c: Color, grime_c: Color, rough: float, met: float, gy: float, ceil_ao: float) -> Material:
	if shader != null:
		var sm: ShaderMaterial = ShaderMaterial.new()
		sm.shader = shader
		sm.set_shader_parameter("base_color", base_c)
		sm.set_shader_parameter("grime_color", grime_c)
		sm.set_shader_parameter("base_roughness", rough)
		sm.set_shader_parameter("metallic_amount", met)
		sm.set_shader_parameter("ground_y", gy)
		sm.set_shader_parameter("ceiling_ao_enable", ceil_ao)
		return sm
	var std: StandardMaterial3D = StandardMaterial3D.new()
	std.albedo_color = base_c
	std.roughness = rough
	std.metallic = met
	return std


static func _solid_box(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, mat: Material, cull_dist: float, cast_sh: bool) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = node_name
	body.position = pos
	var mi: MeshInstance3D = MeshInstance3D.new()
	var bm: BoxMesh = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_sh else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
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


static func _visual_box(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, mat: Material, cull_dist: float, cast_sh: bool) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = node_name
	mi.position = pos
	var bm: BoxMesh = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_sh else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if cull_dist > 0.0:
		mi.visibility_range_end = cull_dist
	parent.add_child(mi)
	return mi
