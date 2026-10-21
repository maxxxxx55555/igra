extends RefCounted
## C1 (the v1.0.0-ship pass): what an item lying in the street looks like. mesh_for(item_id) is one procedural mesh of parts (part_mesh.gd) per item, of 400 triangles at most, read by its silhouette against a dark street:
## cells, a medkit with a cross let into its lid, vials, shards of scrap, coils of wire, keys, pages, bottles, a folded blueprint with a curled corner. Every item of data/items has one; what has none is a crate.
## materials_for() gives the body and the accent of the mesh: scrap, metal and paper are matte and give no light, the parts that unlock a district, the cells, the medkit, the keys and the blueprints hold a little emission on
## the accent only. glow_of() is the colour (alpha = strength) of the pool of light a nearby pickup throws on the ground (contact_shadows.gd); spins() is true for the keys, blueprints and guns, the only ones that turn.

const _Parts := preload("res://scripts/art/part_mesh.gd")
const _Weapons := preload("res://scripts/art/weapon_meshes.gd")

const FAMILY: Dictionary = {
	&"battery": &"cell", &"battery_l2": &"cell", &"enhanced_battery": &"cell", &"medkit": &"medkit", &"serum": &"vial",
	&"scrap": &"shard", &"metal": &"plate", &"gear": &"cog", &"plank": &"plank",
	&"cable": &"coil", &"wiring": &"spool", &"fuse": &"fuse", &"transistor": &"transistor", &"circuit": &"board", &"transformer": &"transformer",
	&"key": &"key", &"ancient_key": &"key", &"lockpick": &"pick",
	&"document": &"page", &"paper": &"page", &"photo": &"photo", &"audio_log": &"tape",
	&"bottle": &"bottle", &"alcohol": &"flask", &"gas_canister": &"canister", &"fabric": &"cloth", &"molotov": &"molotov", &"firework": &"rocket",
	&"backpack_l1": &"pack", &"backpack_l2": &"pack", &"case": &"case", &"coin": &"coin", &"motor": &"motor", &"tool": &"wrench",
	&"scope_lens": &"lens", &"radio_part": &"radio", &"repair_kit": &"toolbox", &"noise_bomb": &"bomb", &"gunpowder": &"sack", &"makeshift_lamp": &"lantern",
	&"ammo": &"ammo", &"pistol": &"gun", &"rifle": &"gun", &"shotgun": &"gun",
}
const _STEEL := Color(0.68, 0.71, 0.75)
const _JUNK := [Color(0.36, 0.32, 0.28), Color(0.45, 0.27, 0.17), 0.0, 0.0]
const _GOLD := Color(0.85, 0.68, 0.25)
const _COPPER := Color(0.72, 0.42, 0.20)
const _PAPER := Color(0.85, 0.82, 0.77)
## family -> [body colour, accent colour, emission of the accent, emission of the body]
const LOOK: Dictionary = {
	&"cell": [Color(0.55, 0.42, 0.14), Color(0.95, 0.72, 0.22), 1.3, 0.35], &"medkit": [Color(0.78, 0.78, 0.74), Color(0.78, 0.16, 0.12), 1.1, 0.0],
	&"vial": [Color(0.50, 0.14, 0.12), _STEEL, 0.0, 0.7], &"shard": _JUNK, &"plate": _JUNK, &"cog": _JUNK, &"plank": _JUNK,
	&"coil": [Color(0.18, 0.34, 0.20), _COPPER, 0.5, 0.0], &"spool": [Color(0.20, 0.20, 0.22), _COPPER, 0.5, 0.0], &"fuse": [Color(0.78, 0.72, 0.60), _STEEL, 0.6, 0.0],
	&"transistor": [Color(0.10, 0.12, 0.10), _GOLD, 0.9, 0.0], &"board": [Color(0.12, 0.26, 0.16), _GOLD, 0.9, 0.0], &"transformer": [Color(0.30, 0.31, 0.34), _COPPER, 0.5, 0.0],
	&"key": [Color(0.55, 0.57, 0.60), _STEEL, 0.55, 0.0], &"pick": [Color(0.55, 0.57, 0.60), _STEEL, 0.55, 0.0],
	&"page": [_PAPER, _PAPER, 0.0, 0.0], &"photo": [_PAPER, Color(0.10, 0.12, 0.14), 0.0, 0.0], &"tape": [Color(0.12, 0.12, 0.14), _PAPER, 0.0, 0.0],
	&"bottle": [Color(0.16, 0.34, 0.20), _STEEL, 0.0, 0.0], &"flask": [Color(0.42, 0.28, 0.12), _STEEL, 0.0, 0.0], &"canister": [Color(0.62, 0.22, 0.14), _GOLD, 0.0, 0.0],
	&"cloth": [Color(0.62, 0.58, 0.50), Color(0.62, 0.58, 0.50), 0.0, 0.0], &"molotov": [Color(0.16, 0.34, 0.20), Color(1.0, 0.55, 0.15), 1.2, 0.0], &"rocket": [Color(0.62, 0.16, 0.12), _GOLD, 0.6, 0.0],
	&"blueprint": [Color(0.20, 0.34, 0.60), Color(0.55, 0.70, 0.95), 0.6, 0.0], &"pack": [Color(0.24, 0.26, 0.20), Color(0.16, 0.17, 0.14), 0.0, 0.0],
	&"case": [Color(0.30, 0.24, 0.18), _STEEL, 0.0, 0.0], &"coin": [_GOLD, _GOLD, 0.0, 0.4], &"motor": [Color(0.30, 0.32, 0.34), _STEEL, 0.0, 0.0], &"wrench": _JUNK,
	&"lens": [Color(0.20, 0.21, 0.24), Color(0.60, 0.78, 0.90), 0.5, 0.0], &"radio": [Color(0.26, 0.28, 0.24), _GOLD, 0.0, 0.0], &"toolbox": [Color(0.62, 0.22, 0.14), _STEEL, 0.0, 0.0],
	&"bomb": [Color(0.22, 0.23, 0.25), Color(0.80, 0.30, 0.18), 0.6, 0.0], &"sack": [Color(0.46, 0.38, 0.26), Color(0.30, 0.24, 0.16), 0.0, 0.0], &"lantern": [Color(0.28, 0.27, 0.25), Color(1.0, 0.75, 0.35), 0.9, 0.0],
	&"ammo": [Color(0.30, 0.34, 0.24), _GOLD, 0.0, 0.0], &"gun": [Color(0.20, 0.21, 0.23), Color(0.45, 0.30, 0.18), 0.0, 0.0], &"crate": [Color(0.36, 0.28, 0.20), Color(0.24, 0.19, 0.14), 0.0, 0.0],
}
const _TWO_SIDED: Array[StringName] = [&"page", &"blueprint"]
const _SPINNING: Array[StringName] = [&"key", &"pick", &"blueprint", &"gun"]
## A pickup throws a pool of light on the ground when the emission of its accent reaches this.
const GLOW_FROM: float = 0.5
const SPIN_RAD_PER_SEC: float = 0.25
const SETTLE_SEC: float = 0.35
const SETTLE_DROP_M: float = 0.25

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}

static func family_of(item_id: StringName) -> StringName:
	if String(item_id).begins_with("blueprint_"):
		return &"blueprint"
	return FAMILY.get(item_id, &"crate")

static func spins(item_id: StringName) -> bool:
	return _SPINNING.has(family_of(item_id))

static func glow_of(item_id: StringName) -> Color:
	var look: Array = LOOK[family_of(item_id)]
	var energy: float = look[2]
	var accent: Color = look[1]
	return Color(accent, clampf(energy * 0.35, 0.0, 0.5)) if energy >= GLOW_FROM else Color(accent, 0.0)

## C3: puts the look of `item_id` on `piece`, a MeshInstance3D of `holder` (an item, a gun, a box of rounds, a page): the mesh and its materials, resting on the origin of the holder, dropped in once (SETTLE_SEC, from
## SETTLE_DROP_M up; not with Reduce UI Motion), turning slowly only when it is a key, a blueprint or a gun, and the colour of its pool of light in the meta "glow" of the holder.
static func dress(holder: Node3D, piece: MeshInstance3D, item_id: StringName, settle: bool = true) -> void:
	var mesh := mesh_for(item_id)
	piece.mesh = mesh
	var materials := materials_for(item_id)
	for s in mesh.get_surface_count():
		piece.set_surface_override_material(s, materials[s])
	var rest: float = -mesh.get_aabb().position.y
	piece.position.y = rest
	holder.set_meta(&"glow", glow_of(item_id))
	var old: Variant = piece.get_meta(&"settle", null)
	if old is Tween:
		(old as Tween).kill()
	if not piece.is_inside_tree() or bool(SettingsManager.get_setting("reduce_ui_motion", false)):
		return
	if settle:
		var drop := piece.create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		drop.tween_property(piece, "position:y", rest, SETTLE_SEC).from(rest + SETTLE_DROP_M)
		piece.set_meta(&"settle", drop)
	if spins(item_id):
		piece.create_tween().set_loops().tween_property(piece, "rotation:y", TAU, TAU / SPIN_RAD_PER_SEC).from(0.0)

static func mesh_for(item_id: StringName) -> Mesh:
	if not _meshes.has(item_id):
		_meshes[item_id] = _Weapons.mesh_for(item_id) if family_of(item_id) == &"gun" else _Parts.build(_parts(family_of(item_id), item_id))
	return _meshes[item_id]

## [body, accent] materials of the mesh; the accent's is the same as the body's when the mesh has no accent part.
static func materials_for(item_id: StringName) -> Array[Material]:
	var family: StringName = family_of(item_id)
	if not _materials.has(family):
		var look: Array = LOOK[family]
		var pair: Array[Material] = []
		for i in 2:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = look[i]
			mat.roughness = 0.9
			if _TWO_SIDED.has(family):
				mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			var energy: float = look[3] if i == 0 else look[2]
			mat.emission_enabled = energy > 0.0
			mat.emission = look[i]
			mat.emission_energy_multiplier = energy
			pair.append(mat)
		_materials[family] = pair
	return _materials[family]

static func _p(kind: StringName, size: Vector3, at: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO, accent: bool = false) -> Array:
	return _Parts.part(kind, size, at, rot, 1 if accent else 0)

static func _parts(family: StringName, id: StringName) -> Array:
	var out: Array = []
	match family:
		&"cell":
			var bands: int = 1 + int(id == &"battery_l2") + 2 * int(id == &"enhanced_battery")
			var tall: float = 0.2 + 0.03 * bands
			out = [_p(&"cyl", Vector3(0.075, tall, 0.075), Vector3(0, tall / 2, 0)), _p(&"cyl", Vector3(0.035, 0.03, 0.035), Vector3(0, tall + 0.015, 0), Vector3.ZERO, true)]
			for i in bands:
				out.append(_p(&"tor", Vector3(0.07, 0.09, 0), Vector3(0, tall * (i + 1) / (bands + 1), 0), Vector3.ZERO, true))
		&"medkit":
			out = [_p(&"box", Vector3(0.30, 0.10, 0.20), Vector3(0, 0.05, 0)), _p(&"box", Vector3(0.24, 0.004, 0.06), Vector3(0, 0.102, 0), Vector3.ZERO, true), _p(&"box", Vector3(0.06, 0.004, 0.14), Vector3(0, 0.102, 0), Vector3.ZERO, true)]
			for sx in [-1.0, 1.0]:  # the lid is four pads and the ends of the arms: the cross stays let in
				for sz in [-1.0, 1.0]:
					out.append(_p(&"box", Vector3(0.12, 0.02, 0.07), Vector3(0.09 * sx, 0.11, 0.065 * sz)))
				out.append_array([_p(&"box", Vector3(0.03, 0.02, 0.06), Vector3(0.135 * sx, 0.11, 0)), _p(&"box", Vector3(0.06, 0.02, 0.03), Vector3(0, 0.11, 0.085 * sx))])
		&"vial":
			out = [_p(&"cyl", Vector3(0.05, 0.12, 0.05), Vector3(0, 0.06, 0)), _p(&"cyl", Vector3(0.02, 0.05, 0.05), Vector3(0, 0.145, 0)), _p(&"tor", Vector3(0.018, 0.034, 0), Vector3(0, 0.172, 0), Vector3.ZERO, true), _p(&"cyl", Vector3(0.02, 0.03, 0.02), Vector3(0, 0.195, 0), Vector3.ZERO, true)]
		&"shard":
			out = [_p(&"box", Vector3(0.20, 0.04, 0.11), Vector3(0, 0.02, 0), Vector3(0, 20, 0)), _p(&"box", Vector3(0.12, 0.05, 0.07), Vector3(0.05, 0.065, 0.03), Vector3(8, -35, 10)), _p(&"box", Vector3(0.08, 0.04, 0.05), Vector3(-0.07, 0.05, -0.04), Vector3(-12, 50, -15), true)]
		&"plate":
			out = [_p(&"box", Vector3(0.26, 0.025, 0.18), Vector3(0, 0.0125, 0), Vector3(0, 12, 0)), _p(&"box", Vector3(0.20, 0.025, 0.14), Vector3(0.02, 0.0375, -0.01), Vector3(0, -8, 0)), _p(&"box", Vector3(0.10, 0.025, 0.14), Vector3(0.09, 0.07, 0.02), Vector3(0, 0, 14), true)]
		&"cog":
			out = [_p(&"cyl", Vector3(0.085, 0.04, 0.085), Vector3(0, 0.02, 0)), _p(&"cyl", Vector3(0.03, 0.06, 0.03), Vector3(0, 0.03, 0), Vector3.ZERO, true)]
			for i in 8:
				var a: float = TAU * i / 8.0
				out.append(_p(&"box", Vector3(0.04, 0.04, 0.035), Vector3(cos(a) * 0.1, 0.02, sin(a) * 0.1), Vector3(0, -rad_to_deg(a), 0)))
		&"plank":
			out = [_p(&"box", Vector3(0.52, 0.035, 0.10), Vector3(0, 0.0175, 0), Vector3(0, 10, 0)), _p(&"box", Vector3(0.34, 0.03, 0.08), Vector3(0.02, 0.05, 0.03), Vector3(0, -22, 2)), _p(&"cyl", Vector3(0.006, 0.04, 0.006), Vector3(0.18, 0.075, 0.01), Vector3.ZERO, true)]
		&"coil":
			out = [_p(&"coil", Vector3(0.085, 0.07, 0.014)), _p(&"cyl", Vector3(0.012, 0.03, 0.012), Vector3(0.085, 0.014, -0.02), Vector3(90, 0, 0), true), _p(&"cyl", Vector3(0.012, 0.03, 0.012), Vector3(-0.085, 0.084, 0.02), Vector3(90, 0, 0), true)]
		&"spool":
			out = [_p(&"cyl", Vector3(0.1, 0.015, 0.1), Vector3(0, 0.0075, 0)), _p(&"cyl", Vector3(0.1, 0.015, 0.1), Vector3(0, 0.1, 0)), _p(&"cyl", Vector3(0.045, 0.1, 0.045), Vector3(0, 0.0575, 0)), _p(&"cyl", Vector3(0.062, 0.07, 0.062), Vector3(0, 0.0575, 0), Vector3.ZERO, true)]
		&"fuse":
			out = [_p(&"cyl", Vector3(0.03, 0.12, 0.03), Vector3(0, 0.036, 0), Vector3(0, 0, 90)), _p(&"cyl", Vector3(0.036, 0.03, 0.036), Vector3(-0.06, 0.036, 0), Vector3(0, 0, 90), true), _p(&"cyl", Vector3(0.036, 0.03, 0.036), Vector3(0.06, 0.036, 0), Vector3(0, 0, 90), true)]
		&"transistor":
			out = [_p(&"box", Vector3(0.09, 0.03, 0.07), Vector3(0, 0.015, 0))]
			for i in 3:
				out.append(_p(&"box", Vector3(0.012, 0.012, 0.04), Vector3(-0.025 + 0.025 * i, 0.036, 0), Vector3.ZERO, true))
		&"board":
			out = [_p(&"box", Vector3(0.22, 0.016, 0.15), Vector3(0, 0.008, 0)), _p(&"box", Vector3(0.06, 0.02, 0.06), Vector3(-0.04, 0.026, 0.01))]
			for i in 4:
				out.append(_p(&"box", Vector3(0.02, 0.012, 0.014), Vector3(0.05, 0.022, -0.045 + 0.03 * i), Vector3.ZERO, true))
		&"transformer":
			out = [_p(&"box", Vector3(0.14, 0.12, 0.10), Vector3(0, 0.06, 0)), _p(&"tor", Vector3(0.035, 0.065, 0), Vector3(-0.085, 0.066, 0), Vector3(0, 0, 90), true), _p(&"tor", Vector3(0.035, 0.065, 0), Vector3(0.085, 0.066, 0), Vector3(0, 0, 90), true)]
		&"key":
			var s: float = 1.4 if id == &"ancient_key" else 1.0
			out = [_p(&"tor", Vector3(0.035, 0.06, 0) * s, Vector3(0, 0.0125 * s, 0), Vector3.ZERO, true), _p(&"cyl", Vector3(0.012, 0.16, 0.012) * s, Vector3(0.13 * s, 0.012 * s, 0), Vector3(0, 0, 90))]
			for x in ([0.16, 0.19, 0.21] if id == &"ancient_key" else [0.16, 0.19]):
				out.append(_p(&"box", Vector3(0.018, 0.014, 0.035) * s, Vector3(x * s, 0.012 * s, 0.022 * s)))
		&"pick":
			out = [_p(&"box", Vector3(0.20, 0.008, 0.012), Vector3(0.02, 0.004, 0)), _p(&"box", Vector3(0.03, 0.008, 0.012), Vector3(0.125, 0.004, 0.012), Vector3(0, 40, 0)), _p(&"cyl", Vector3(0.016, 0.06, 0.016), Vector3(-0.12, 0.016, 0), Vector3(0, 0, 90), true)]
		&"page":
			var small: float = 0.75 if id == &"paper" else 1.0
			out = [_p(&"page", Vector3(0.20, 0.03, 0.28) * small), _p(&"page", Vector3(0.19, 0.02, 0.27) * small, Vector3(0.012, 0.012, 0.01), Vector3(0, 9, 0))]
		&"photo":
			out = [_p(&"box", Vector3(0.14, 0.006, 0.11), Vector3(0, 0.003, 0), Vector3(0, 12, 0)), _p(&"box", Vector3(0.11, 0.007, 0.08), Vector3(0, 0.0035, 0), Vector3(0, 12, 0), true)]
		&"tape":
			out = [_p(&"box", Vector3(0.13, 0.025, 0.085), Vector3(0, 0.0125, 0)), _p(&"cyl", Vector3(0.018, 0.004, 0.018), Vector3(-0.03, 0.027, 0), Vector3.ZERO, true), _p(&"cyl", Vector3(0.018, 0.004, 0.018), Vector3(0.03, 0.027, 0), Vector3.ZERO, true)]
		&"bottle", &"molotov":
			out = [_p(&"cyl", Vector3(0.035, 0.14, 0.035), Vector3(0, 0.07, 0)), _p(&"cyl", Vector3(0.014, 0.06, 0.032), Vector3(0, 0.17, 0)), _p(&"cyl", Vector3(0.016, 0.02, 0.016), Vector3(0, 0.21, 0), Vector3.ZERO, family == &"molotov")]
			if family == &"molotov":
				out.append(_p(&"cyl", Vector3(0.008, 0.07, 0.014), Vector3(0.02, 0.24, 0), Vector3(0, 0, -20), true))
		&"flask":
			out = [_p(&"box", Vector3(0.10, 0.13, 0.05), Vector3(0, 0.065, 0)), _p(&"cyl", Vector3(0.016, 0.05, 0.02), Vector3(0, 0.155, 0)), _p(&"cyl", Vector3(0.02, 0.03, 0.02), Vector3(0, 0.195, 0), Vector3.ZERO, true), _p(&"box", Vector3(0.102, 0.03, 0.052), Vector3(0, 0.04, 0), Vector3.ZERO, true)]
		&"canister":
			out = [_p(&"cyl", Vector3(0.07, 0.2, 0.07), Vector3(0, 0.1, 0)), _p(&"sph", Vector3(0.14, 0.08, 0.14), Vector3(0, 0.2, 0)), _p(&"cyl", Vector3(0.02, 0.04, 0.02), Vector3(0, 0.255, 0), Vector3.ZERO, true), _p(&"tor", Vector3(0.05, 0.075, 0), Vector3(0, 0.26, 0), Vector3.ZERO, true)]
		&"cloth":
			out = [_p(&"box", Vector3(0.22, 0.022, 0.16), Vector3(0, 0.011, 0), Vector3(0, 6, 0)), _p(&"box", Vector3(0.20, 0.022, 0.15), Vector3(0.01, 0.033, 0.005), Vector3(0, -8, 0)), _p(&"box", Vector3(0.18, 0.022, 0.13), Vector3(-0.005, 0.055, 0), Vector3(0, 14, 0)), _p(&"box", Vector3(0.05, 0.03, 0.17), Vector3(0.05, 0.026, 0), Vector3(0, 0, 0), true)]
		&"rocket":
			out = [_p(&"cyl", Vector3(0.025, 0.16, 0.025), Vector3(0, 0.025, 0), Vector3(0, 0, 90)), _p(&"cyl", Vector3(0.0, 0.05, 0.025), Vector3(0.105, 0.025, 0), Vector3(0, 0, -90), true), _p(&"cyl", Vector3(0.005, 0.24, 0.005), Vector3(-0.2, 0.006, 0), Vector3(0, 0, 90)), _p(&"box", Vector3(0.03, 0.002, 0.07), Vector3(-0.06, 0.012, 0)), _p(&"box", Vector3(0.03, 0.07, 0.002), Vector3(-0.06, 0.025, 0))]
		&"blueprint":
			out = [_p(&"box", Vector3(0.22, 0.006, 0.16), Vector3(0, 0.003, 0)), _p(&"box", Vector3(0.22, 0.014, 0.012), Vector3(0, 0.007, 0), Vector3.ZERO, true), _p(&"page", Vector3(0.05, 0.03, 0.05), Vector3(0.085, 0.006, 0.055), Vector3.ZERO, true)]
		&"pack":
			var k: float = 1.0 if id == &"backpack_l1" else 1.25
			out = [_p(&"box", Vector3(0.20, 0.26, 0.11) * k, Vector3(0, 0.13 * k, 0)), _p(&"box", Vector3(0.20, 0.09, 0.12) * k, Vector3(0, 0.215 * k, 0)), _p(&"box", Vector3(0.14, 0.12, 0.05) * k, Vector3(0, 0.07 * k, 0.075 * k)), _p(&"box", Vector3(0.025, 0.2, 0.004) * k, Vector3(0.05 * k, 0.14 * k, -0.057 * k), Vector3.ZERO, true), _p(&"box", Vector3(0.025, 0.2, 0.004) * k, Vector3(-0.05 * k, 0.14 * k, -0.057 * k), Vector3.ZERO, true)]
			if id == &"backpack_l2":
				out.append(_p(&"box", Vector3(0.05, 0.16, 0.09) * k, Vector3(0.12 * k, 0.1 * k, 0)))
		&"case":
			out = [_p(&"box", Vector3(0.28, 0.17, 0.07), Vector3(0, 0.085, 0)), _p(&"tor", Vector3(0.03, 0.05, 0), Vector3(0, 0.19, 0), Vector3(90, 0, 0), true), _p(&"box", Vector3(0.03, 0.03, 0.01), Vector3(-0.08, 0.14, 0.04), Vector3.ZERO, true), _p(&"box", Vector3(0.03, 0.03, 0.01), Vector3(0.08, 0.14, 0.04), Vector3.ZERO, true)]
		&"coin":
			out = [_p(&"cyl", Vector3(0.03, 0.006, 0.03), Vector3(0, 0.003, 0)), _p(&"cyl", Vector3(0.03, 0.006, 0.03), Vector3(0.012, 0.009, 0.005), Vector3(0, 0, 4)), _p(&"cyl", Vector3(0.03, 0.006, 0.03), Vector3(0.06, 0.003, -0.03))]
		&"motor":
			out = [_p(&"cyl", Vector3(0.06, 0.14, 0.06), Vector3(0, 0.066, 0), Vector3(0, 0, 90)), _p(&"cyl", Vector3(0.012, 0.06, 0.012), Vector3(0.1, 0.066, 0), Vector3(0, 0, 90), true), _p(&"box", Vector3(0.12, 0.012, 0.09), Vector3(0, 0.006, 0)), _p(&"box", Vector3(0.02, 0.05, 0.10), Vector3(-0.04, 0.066, 0)), _p(&"box", Vector3(0.02, 0.05, 0.10), Vector3(0.04, 0.066, 0))]
		&"wrench":
			out = [_p(&"box", Vector3(0.22, 0.016, 0.03), Vector3(0, 0.008, 0), Vector3(0, 15, 0)), _p(&"cyl", Vector3(0.04, 0.016, 0.04), Vector3(0.115, 0.008, -0.03)), _p(&"box", Vector3(0.03, 0.016, 0.03), Vector3(0.14, 0.008, -0.05), Vector3(0, 15, 0), true)]
		&"lens":
			out = [_p(&"tor", Vector3(0.035, 0.052, 0), Vector3(0, 0.0085, 0)), _p(&"sph", Vector3(0.07, 0.024, 0.07), Vector3(0, 0.012, 0), Vector3.ZERO, true)]
		&"radio":
			out = [_p(&"box", Vector3(0.16, 0.10, 0.07), Vector3(0, 0.05, 0)), _p(&"cyl", Vector3(0.004, 0.16, 0.004), Vector3(0.06, 0.16, -0.02), Vector3(0, 0, -20)), _p(&"cyl", Vector3(0.014, 0.014, 0.014), Vector3(0.045, 0.107, 0.02), Vector3.ZERO, true), _p(&"box", Vector3(0.08, 0.05, 0.004), Vector3(-0.03, 0.05, 0.036), Vector3.ZERO, true)]
		&"toolbox":
			out = [_p(&"box", Vector3(0.26, 0.10, 0.12), Vector3(0, 0.05, 0)), _p(&"box", Vector3(0.262, 0.008, 0.122), Vector3(0, 0.07, 0), Vector3.ZERO, true), _p(&"box", Vector3(0.12, 0.02, 0.016), Vector3(0, 0.115, 0), Vector3.ZERO, true), _p(&"box", Vector3(0.016, 0.03, 0.016), Vector3(-0.06, 0.105, 0), Vector3.ZERO, true), _p(&"box", Vector3(0.016, 0.03, 0.016), Vector3(0.06, 0.105, 0), Vector3.ZERO, true)]
		&"bomb":
			out = [_p(&"sph", Vector3(0.12, 0.12, 0.12), Vector3(0, 0.06, 0)), _p(&"tor", Vector3(0.05, 0.065, 0), Vector3(0, 0.06, 0), Vector3.ZERO, true), _p(&"cyl", Vector3(0.012, 0.04, 0.012), Vector3(0, 0.138, 0), Vector3.ZERO, true)]
		&"sack":
			out = [_p(&"sph", Vector3(0.18, 0.16, 0.14), Vector3(0, 0.08, 0)), _p(&"cyl", Vector3(0.02, 0.05, 0.05), Vector3(0, 0.17, 0)), _p(&"tor", Vector3(0.02, 0.03, 0), Vector3(0, 0.15, 0), Vector3.ZERO, true)]
		&"lantern":
			out = [_p(&"cyl", Vector3(0.05, 0.02, 0.05), Vector3(0, 0.01, 0)), _p(&"cyl", Vector3(0.04, 0.09, 0.04), Vector3(0, 0.065, 0), Vector3.ZERO, true), _p(&"cyl", Vector3(0.012, 0.025, 0.05), Vector3(0, 0.1225, 0)), _p(&"tor", Vector3(0.03, 0.04, 0), Vector3(0, 0.14, 0), Vector3(90, 0, 0))]
		&"ammo":
			out = [_p(&"box", Vector3(0.20, 0.09, 0.12), Vector3(0, 0.045, 0)), _p(&"box", Vector3(0.202, 0.012, 0.122), Vector3(0, 0.06, 0), Vector3.ZERO, true)]
			for i in 3:
				out.append(_p(&"cyl", Vector3(0.012, 0.05, 0.012), Vector3(-0.05 + 0.05 * i, 0.115, 0), Vector3.ZERO, true))
		_:
			out = [_p(&"box", Vector3(0.24, 0.20, 0.24), Vector3(0, 0.1, 0)), _p(&"box", Vector3(0.25, 0.03, 0.25), Vector3(0, 0.05, 0), Vector3.ZERO, true), _p(&"box", Vector3(0.25, 0.03, 0.25), Vector3(0, 0.15, 0), Vector3.ZERO, true)]
	return out
