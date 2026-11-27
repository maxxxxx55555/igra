class_name NativePbrEnterableBuilder
extends RefCounted

## Enterable Building Builder using the repository's native high-res WebP PBR textures
## (assets/textures/pbr/*) -> 0 extra texture MiB!
## Features: AABB lot-clearance against buildings & road markings, non-coplanar walls,
## multiplicative ground/furniture contact shadows, corner pilasters, recessed warm windows,
## metal canopy, wooden floor, ceiling beams, baseboards, and multi-part interior furniture.

const WALL_T: float = 0.30
const DOOR_W: float = 1.72
const DOOR_H: float = 2.44
const ROOM_H: float = 3.55
const EPS: float = 0.018
const CULL_DIST: float = 42.0

const SHADER_TRIPLANAR: String = "res://shaders/overhaul/triplanar_native_pbr.gdshader"
const SHADER_SHADOW: String = "res://shaders/overhaul/soft_contact_shadow_skirt.gdshader"

const TEX_BRICK_ALB: String = "res://assets/textures/pbr/painted_brick_albedo.webp"
const TEX_BRICK_NRM: String = "res://assets/textures/pbr/painted_brick_normal.webp"
const TEX_BRICK_RGH: String = "res://assets/textures/pbr/painted_brick_rough.webp"

const TEX_CONC_ALB: String = "res://assets/textures/pbr/cracked_concrete_albedo.webp"
const TEX_CONC_NRM: String = "res://assets/textures/pbr/cracked_concrete_normal.webp"
const TEX_CONC_RGH: String = "res://assets/textures/pbr/cracked_concrete_rough.webp"

const TEX_WOOD_ALB: String = "res://assets/textures/pbr/plywood_albedo.webp"
const TEX_WOOD_NRM: String = "res://assets/textures/pbr/plywood_normal.webp"
const TEX_WOOD_RGH: String = "res://assets/textures/pbr/plywood_rough.webp"

const TEX_METAL_ALB: String = "res://assets/textures/pbr/rusted_metal_albedo.webp"
const TEX_METAL_NRM: String = "res://assets/textures/pbr/rusted_metal_normal.webp"
const TEX_METAL_RGH: String = "res://assets/textures/pbr/rusted_metal_rough.webp"

const DISTRICT_TINTS: Array[Color] = [
	Color(0.80, 0.84, 0.84),
	Color(0.74, 0.80, 0.84),
	Color(0.88, 0.78, 0.70),
	Color(0.74, 0.84, 0.90),
	Color(0.72, 0.82, 0.80),
	Color(0.88, 0.82, 0.72),
	Color(0.76, 0.80, 0.78),
	Color(0.80, 0.86, 0.88),
	Color(0.74, 0.78, 0.82),
	Color(0.82, 0.78, 0.74),
	Color(0.86, 0.82, 0.76),
]


static func is_lot_clear(origin: Vector3, footprint: Vector2, existing_aabbs: Array, road_half_width: float = 4.9) -> bool:
	var hx: float = footprint.x * 0.5 + 1.25
	var hz: float = footprint.y * 0.5 + 1.25
	if absf(origin.x) < (road_half_width + hx * 0.62) and absf(origin.z) < (road_half_width + hz * 0.62):
		return false
	var cand: AABB = AABB(Vector3(origin.x - hx, -0.5, origin.z - hz), Vector3(hx * 2.0, ROOM_H + 3.0, hz * 2.0))
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
	district_index_1_based: int = 1
) -> Dictionary:
	var w: float = clampf(width_m, 6.2, 10.6)
	var d: float = clampf(depth_m, 5.6, 9.4)
	var inner_d: float = d - WALL_T * 2.0 - EPS
	var hw: float = w * 0.5
	var hd: float = d * 0.5

	var root: Node3D = Node3D.new()
	root.name = "Enterable_%s" % room_name
	root.position = origin
	root.rotation.y = yaw_rad
	root.add_to_group("enterable_buildings")
	parent.add_child(root)

	var di: int = clampi(district_index_1_based - 1, 0, DISTRICT_TINTS.size() - 1)
	var ext_mat: Material = _triplanar(TEX_BRICK_ALB, TEX_BRICK_NRM, TEX_BRICK_RGH, DISTRICT_TINTS[di], 0.34, 1.35, 1.0, 0.04, origin.y, 0.0)
	var int_mat: Material = _triplanar(TEX_CONC_ALB, TEX_CONC_NRM, TEX_CONC_RGH, Color(0.84, 0.82, 0.78), 0.38, 1.15, 1.05, 0.02, origin.y + 0.18, 1.0)
	var floor_wood: Material = _triplanar(TEX_WOOD_ALB, TEX_WOOD_NRM, TEX_WOOD_RGH, Color(0.72, 0.64, 0.56), 0.44, 1.20, 0.95, 0.04, origin.y + 0.18, 0.0)
	var conc_mat: Material = _triplanar(TEX_CONC_ALB, TEX_CONC_NRM, TEX_CONC_RGH, Color(0.74, 0.76, 0.74), 0.42, 1.25, 1.0, 0.05, origin.y, 0.0)
	var metal_mat: Material = _triplanar(TEX_METAL_ALB, TEX_METAL_NRM, TEX_METAL_RGH, Color(0.84, 0.84, 0.82), 0.52, 1.30, 0.90, 0.46, origin.y, 0.0)

	_shadow_skirt(root, "GroundContactShadow", Vector3(0.0, 0.018, 0.0), Vector2(w + 2.6, d + 2.6), 0.76)

	_solid_box(root, "WoodFloorSlab", Vector3(0.0, 0.09, 0.0), Vector3(w - 0.06, 0.18, d - 0.06), floor_wood, 0.0, true)
	_solid_box(root, "StoneEntryStep", Vector3(0.0, 0.05, hd + 0.28), Vector3(DOOR_W + 0.70, 0.10, 0.54), conc_mat, CULL_DIST, true)

	var wy: float = 0.18 + (ROOM_H - 0.18) * 0.5
	var wh: float = ROOM_H - 0.18
	var front_z: float = hd - WALL_T * 0.5
	var side_w: float = maxf(0.85, (w - DOOR_W) * 0.5)

	_solid_box(root, "WallBack", Vector3(0.0, wy, -(hd - WALL_T * 0.5)), Vector3(w, wh, WALL_T), ext_mat, 0.0, true)
	_solid_box(root, "WallLeft", Vector3(-(hw - WALL_T * 0.5), wy, 0.0), Vector3(WALL_T, wh, inner_d), ext_mat, 0.0, true)
	_solid_box(root, "WallRight", Vector3(hw - WALL_T * 0.5, wy, 0.0), Vector3(WALL_T, wh, inner_d), ext_mat, 0.0, true)
	_solid_box(root, "FrontLeft", Vector3(-(DOOR_W * 0.5 + side_w * 0.5), wy, front_z), Vector3(side_w, wh, WALL_T), ext_mat, 0.0, true)
	_solid_box(root, "FrontRight", Vector3(DOOR_W * 0.5 + side_w * 0.5, wy, front_z), Vector3(side_w, wh, WALL_T), ext_mat, 0.0, true)
	var lintel_h: float = maxf(0.42, ROOM_H - DOOR_H)
	_solid_box(root, "DoorLintel", Vector3(0.0, DOOR_H + lintel_h * 0.5, front_z), Vector3(DOOR_W - EPS, lintel_h, WALL_T), ext_mat, 0.0, true)

	var in_w: float = w - WALL_T * 2.0 - 0.04
	var in_d: float = d - WALL_T * 2.0 - 0.04
	_visual_box(root, "IntBack", Vector3(0.0, wy, -(hd - WALL_T - 0.02)), Vector3(in_w, wh - 0.04, 0.03), int_mat, CULL_DIST, false)
	_visual_box(root, "IntLeft", Vector3(-(hw - WALL_T - 0.02), wy, 0.0), Vector3(0.03, wh - 0.04, in_d - 0.04), int_mat, CULL_DIST, false)
	_visual_box(root, "IntRight", Vector3(hw - WALL_T - 0.02, wy, 0.0), Vector3(0.03, wh - 0.04, in_d - 0.04), int_mat, CULL_DIST, false)

	_solid_box(root, "RoofSlab", Vector3(0.0, ROOM_H + 0.12, 0.0), Vector3(w + 0.28, 0.24, d + 0.28), metal_mat, 0.0, true)
	_visual_box(root, "ParapetF", Vector3(0.0, ROOM_H + 0.36, hd + 0.04), Vector3(w + 0.34, 0.26, 0.16), conc_mat, 0.0, true)
	_visual_box(root, "ParapetB", Vector3(0.0, ROOM_H + 0.36, -hd - 0.04), Vector3(w + 0.34, 0.26, 0.16), conc_mat, 0.0, true)

	for cx in [-1.0, 1.0]:
		for cz in [-1.0, 1.0]:
			_visual_box(root, "Pilaster_%d_%d" % [int(cx), int(cz)], Vector3(cx * (hw + 0.05), wy, cz * (hd + 0.05)), Vector3(0.30, wh + 0.18, 0.30), conc_mat, CULL_DIST, true)

	_visual_box(root, "PlinthL", Vector3(-hw - 0.045, 0.28, 0.0), Vector3(0.09, 0.56, d + 0.06), conc_mat, CULL_DIST, false)
	_visual_box(root, "PlinthR", Vector3(hw + 0.045, 0.28, 0.0), Vector3(0.09, 0.56, d + 0.06), conc_mat, CULL_DIST, false)
	_visual_box(root, "PlinthB", Vector3(0.0, 0.28, -hd - 0.045), Vector3(w + 0.06, 0.56, 0.09), conc_mat, CULL_DIST, false)

	var win_mat: StandardMaterial3D = StandardMaterial3D.new()
	win_mat.albedo_color = Color(0.16, 0.15, 0.12, 1.0)
	win_mat.roughness = 0.14
	win_mat.metallic = 0.12
	win_mat.emission_enabled = true
	win_mat.emission = Color(0.55, 0.40, 0.18, 1.0)
	win_mat.emission_energy_multiplier = 0.45
	if side_w >= 1.9:
		for sx in [-1.0, 1.0]:
			var wx: float = sx * (DOOR_W * 0.5 + side_w * 0.52)
			_visual_box(root, "WinFrame_%d" % int(sx), Vector3(wx, 1.74, hd + 0.03), Vector3(1.20, 1.26, 0.11), metal_mat, CULL_DIST, true)
			_visual_box(root, "WinGlass_%d" % int(sx), Vector3(wx, 1.74, hd + 0.058), Vector3(1.00, 1.06, 0.06), win_mat, CULL_DIST, false)
			_visual_box(root, "WinSill_%d" % int(sx), Vector3(wx, 1.09, hd + 0.11), Vector3(1.34, 0.09, 0.22), conc_mat, CULL_DIST, true)

	_visual_box(root, "DoorFrameL", Vector3(-DOOR_W * 0.5 + 0.06, 0.18 + (DOOR_H - 0.18) * 0.5, front_z), Vector3(0.12, DOOR_H - 0.18, WALL_T + 0.10), metal_mat, CULL_DIST, true)
	_visual_box(root, "DoorFrameR", Vector3(DOOR_W * 0.5 - 0.06, 0.18 + (DOOR_H - 0.18) * 0.5, front_z), Vector3(0.12, DOOR_H - 0.18, WALL_T + 0.10), metal_mat, CULL_DIST, true)
	_visual_box(root, "DoorFrameT", Vector3(0.0, DOOR_H - 0.05, front_z), Vector3(DOOR_W + 0.24, 0.12, WALL_T + 0.10), metal_mat, CULL_DIST, true)
	_visual_box(root, "DoorCanopy", Vector3(0.0, DOOR_H + 0.24, hd + 0.48), Vector3(DOOR_W + 0.84, 0.09, 0.96), metal_mat, CULL_DIST, true)

	var bulb_mat: StandardMaterial3D = StandardMaterial3D.new()
	bulb_mat.albedo_color = Color(0.95, 0.78, 0.40, 1.0)
	bulb_mat.emission_enabled = true
	bulb_mat.emission = Color(0.86, 0.64, 0.26, 1.0)
	bulb_mat.emission_energy_multiplier = 1.35
	_visual_box(root, "PorchLamp", Vector3(0.0, DOOR_H + 0.15, hd + 0.30), Vector3(0.24, 0.06, 0.14), bulb_mat, CULL_DIST, false)
	_visual_box(root, "InteriorLamp", Vector3(0.0, ROOM_H - 0.06, -0.25), Vector3(0.44, 0.06, 0.16), bulb_mat, CULL_DIST, false)

	for bz in [-in_d * 0.25, in_d * 0.25]:
		_visual_box(root, "Beam_%d" % int(bz * 10), Vector3(0.0, ROOM_H - 0.09, bz), Vector3(in_w, 0.16, 0.18), floor_wood, CULL_DIST, true)
	_visual_box(root, "TrimB", Vector3(0.0, 0.25, -(hd - WALL_T - 0.05)), Vector3(in_w, 0.14, 0.06), floor_wood, CULL_DIST, false)
	_visual_box(root, "TrimL", Vector3(-(hw - WALL_T - 0.05), 0.25, 0.0), Vector3(0.06, 0.14, in_d), floor_wood, CULL_DIST, false)
	_visual_box(root, "TrimR", Vector3(hw - WALL_T - 0.05, 0.25, 0.0), Vector3(0.06, 0.14, in_d), floor_wood, CULL_DIST, false)

	var loot_local: Array[Vector3] = []
	var tbl_pos: Vector3 = Vector3(-w * 0.24, 0.18, -d * 0.20)
	_build_table(root, "WorkTable", tbl_pos, 1.65, 0.78, 0.80, floor_wood, metal_mat)
	_shadow_skirt(root, "WorkTableShadow", tbl_pos + Vector3(0.0, 0.012, 0.0), Vector2(2.05, 1.15), 0.60)
	loot_local.append(tbl_pos + Vector3(0.0, 0.86, 0.0))

	var rack_pos: Vector3 = Vector3(w * 0.30, 0.18, -d * 0.26)
	_build_rack(root, "SupplyRack", rack_pos, 1.45, 0.46, 1.85, metal_mat, floor_wood)
	_shadow_skirt(root, "SupplyRackShadow", rack_pos + Vector3(0.0, 0.012, 0.0), Vector2(1.75, 0.82), 0.60)
	loot_local.append(rack_pos + Vector3(-0.35, 0.96, 0.0))

	var crate_pos: Vector3 = Vector3(0.50, 0.18 + 0.38, 0.65)
	_solid_box(root, "WoodenCrate", crate_pos, Vector3(0.84, 0.76, 0.78), floor_wood, CULL_DIST, true)
	_shadow_skirt(root, "CrateShadow", Vector3(crate_pos.x, 0.192, crate_pos.z), Vector2(1.20, 1.12), 0.64)

	var area: Area3D = Area3D.new()
	area.name = "InteriorZone"
	area.set_meta("theme_id", theme_id)
	area.set_meta("is_interior", true)
	var sh_node: CollisionShape3D = CollisionShape3D.new()
	var sh_box: BoxShape3D = BoxShape3D.new()
	sh_box.size = Vector3(in_w - 0.2, ROOM_H - 0.3, in_d - 0.2)
	sh_node.shape = sh_box
	sh_node.position = Vector3(0.0, 0.18 + (ROOM_H - 0.3) * 0.5, 0.0)
	area.add_child(sh_node)
	root.add_child(area)

	var xf: Transform3D = root.global_transform
	var loot_world: Array[Vector3] = []
	for lp in loot_local:
		loot_world.append(xf * lp)

	return {
		"root": root,
		"theme_id": theme_id,
		"doorway_world": xf * Vector3(0.0, 0.18, hd + 1.15),
		"interior_center": xf * Vector3(0.0, 0.18, 0.15),
		"loot_points": loot_world,
		"aabb": AABB(origin - Vector3(hw + 0.25, 0.0, hd + 0.25), Vector3(w + 0.5, ROOM_H + 0.6, d + 0.5)),
	}


static func _triplanar(alb_p: String, nrm_p: String, rgh_p: String, tint: Color, uv_s: float, n_depth: float, r_scale: float, met: float, gy: float, ceil_ao: float) -> Material:
	if ResourceLoader.exists(SHADER_TRIPLANAR) and ResourceLoader.exists(alb_p) and ResourceLoader.exists(nrm_p) and ResourceLoader.exists(rgh_p):
		var sh: Shader = load(SHADER_TRIPLANAR) as Shader
		var alb: Texture2D = load(alb_p) as Texture2D
		var nrm: Texture2D = load(nrm_p) as Texture2D
		var rgh: Texture2D = load(rgh_p) as Texture2D
		if sh != null and alb != null and nrm != null and rgh != null:
			var sm: ShaderMaterial = ShaderMaterial.new()
			sm.shader = sh
			sm.set_shader_parameter("albedo_tex", alb)
			sm.set_shader_parameter("normal_tex", nrm)
			sm.set_shader_parameter("roughness_tex", rgh)
			sm.set_shader_parameter("tint_color", tint)
			sm.set_shader_parameter("uv_scale", uv_s)
			sm.set_shader_parameter("normal_depth", n_depth)
			sm.set_shader_parameter("roughness_scale", r_scale)
			sm.set_shader_parameter("metallic_amount", met)
			sm.set_shader_parameter("ground_y", gy)
			sm.set_shader_parameter("ceiling_ao_enable", ceil_ao)
			return sm
	var std: StandardMaterial3D = StandardMaterial3D.new()
	std.albedo_color = tint * 0.18
	std.roughness = 0.80
	std.metallic = met
	return std


static func _shadow_skirt(parent: Node3D, node_name: String, pos: Vector3, size_xz: Vector2, opacity: float) -> void:
	if not ResourceLoader.exists(SHADER_SHADOW):
		return
	var sh: Shader = load(SHADER_SHADOW) as Shader
	if sh == null:
		return
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = node_name
	mi.position = pos
	var pm: PlaneMesh = PlaneMesh.new()
	pm.size = size_xz
	mi.mesh = pm
	var sm: ShaderMaterial = ShaderMaterial.new()
	sm.shader = sh
	sm.set_shader_parameter("shadow_opacity", opacity)
	mi.material_override = sm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = CULL_DIST + 16.0
	parent.add_child(mi)


static func _build_table(parent: Node3D, prefix: String, base_pos: Vector3, tw: float, td: float, th: float, top_mat: Material, leg_mat: Material) -> void:
	_solid_box(parent, prefix + "_Top", base_pos + Vector3(0.0, th - 0.04, 0.0), Vector3(tw, 0.08, td), top_mat, CULL_DIST, true)
	var lx: float = tw * 0.5 - 0.08
	var lz: float = td * 0.5 - 0.08
	for idx in range(4):
		var sx: float = -lx if (idx % 2 == 0) else lx
		var sz: float = -lz if (idx < 2) else lz
		_visual_box(parent, "%s_Leg%d" % [prefix, idx], base_pos + Vector3(sx, (th - 0.08) * 0.5, sz), Vector3(0.07, th - 0.08, 0.07), leg_mat, CULL_DIST, true)


static func _build_rack(parent: Node3D, prefix: String, base_pos: Vector3, rw: float, rd: float, rh: float, frame_mat: Material, plank_mat: Material) -> void:
	var lx: float = rw * 0.5 - 0.04
	var lz: float = rd * 0.5 - 0.04
	for idx in range(4):
		var sx: float = -lx if (idx % 2 == 0) else lx
		var sz: float = -lz if (idx < 2) else lz
		_visual_box(parent, "%s_Post%d" % [prefix, idx], base_pos + Vector3(sx, rh * 0.5, sz), Vector3(0.05, rh, 0.05), frame_mat, CULL_DIST, true)
	for lvl in [0.18, 0.88, 1.56]:
		_solid_box(parent, "%s_Shelf_%d" % [prefix, int(lvl * 10)], base_pos + Vector3(0.0, lvl, 0.0), Vector3(rw - 0.06, 0.045, rd - 0.04), plank_mat, CULL_DIST, true)


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
