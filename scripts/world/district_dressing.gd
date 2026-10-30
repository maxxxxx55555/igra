extends Node3D
## What a district holds between its streets (docs/DENSITY_PLAN.md): litter, leaves, soft wet patches, bins, hydrants, crates and barrels in every block, a pool of
## light under each streetlamp that reaches into the block beside it, the landmark behind the skyline ring and a lit bench by the power switch. Visual only like
## the trees and benches of street_props.gd: no collision and no navigation, a seeded stream of its own so no other placement moves. Everything of one kind is one
## MultiMesh, so the whole is about thirteen draw calls.

const _BIN := preload("res://assets/mesh/mesh_trash_can.res")
const _HYDRANT := preload("res://assets/mesh/mesh_hydrant.res")
const _BENCH := preload("res://assets/mesh/mesh_bench.res")
const _LANDMARK := preload("res://scripts/world/district_landmark.gd")
const _MANHOLE := preload("res://scripts/world/manhole.gd")

## Tops of the ground in the district (street_builder.gd tiles and skyline.gd ground) and of the road markings.
const GROUND_Y: float = 0.06
const MARKING_TOP_Y: float = 0.08
## Solid props keep this far from anything the player can use or hide in.
const KEEP_CLEAR_M: float = 1.8
const HYDRANTS: int = 5
## Iron covers in the roads round the middle block: the footsteps ring on them and a thread of steam rises from each.
const MANHOLES: int = 2
const LAMP_RANGE_M: float = 9.0
const LAMP_ENERGY: float = 1.4
## The pool of light under a streetlamp: its diameter, how far toward the block it is moved from the pole, its opacity per power stage (DARK, PARTIAL, STREETS, FULL).
const POOL_M: float = 6.5
const POOL_TOWARD_BLOCK_M: float = 1.6
const POOL_Y: float = 0.095
const POOL_BY_STAGE: Array[float] = [0.0, 0.05, 0.11, 0.16]
const REST_POOL_ALPHA: float = 0.22
## Ground fog in the four fog districts (the weather of DistrictThemes): three drifting cards over the blocks, off at the Low tier (the depth fog of the environment is enough there).
const FOG_DISTRICTS: Array[StringName] = [&"warehouses", &"industrial", &"substation", &"power_station"]
const FOG_SHADER := preload("res://assets/shaders/height_fog_card.gdshader")
const _LAMP_DETAILS := preload("res://scripts/world/lamp_details.gd")
const _STORY := preload("res://scripts/world/story_props.gd")
const _URBAN := preload("res://scripts/world/urban_set_dressing.gd")
const FOG_CARD_M: float = 46.0
const FOG_Y: float = 0.35
const FOG_BY_STAGE: Array[float] = [0.12, 0.25, 0.35, 0.45]
const FOG_AT: Array[Vector3] = [Vector3(-14.0, 0.0, -10.0), Vector3(12.0, 0.0, 2.0), Vector3(-4.0, 0.0, 16.0)]
## Where the bench stands from the power switch (the switch is at the corner of the middle block and the next).
const REST_FROM_SWITCH := Vector3(6.0, 0.0, 5.0)
const BRASS := Color("#c9a24a")
const LITTER_COLORS: Array[Color] = [Color(0.22, 0.23, 0.26), Color(0.30, 0.29, 0.26), Color(0.20, 0.16, 0.09), Color(0.09, 0.09, 0.10)]
const LEAF_COLORS: Array[Color] = [Color(0.17, 0.15, 0.08), Color(0.12, 0.14, 0.08), Color(0.20, 0.13, 0.07)]
const CRATE_COLOR := Color(0.22, 0.17, 0.11)
const BARREL_COLORS: Array[Color] = [Color(0.16, 0.17, 0.19), Color(0.27, 0.15, 0.10)]
## Per district and block: litter, leaves, puddles, crates, barrels, bins.
const KIT := {
	&"suburbs": {"litter": 6, "leaves": 6, "puddles": 2, "crates": 1, "barrels": 0, "bins": 2},
	&"residential": {"litter": 8, "leaves": 4, "puddles": 2, "crates": 1, "barrels": 0, "bins": 2},
	&"park": {"litter": 3, "leaves": 12, "puddles": 2, "crates": 0, "barrels": 0, "bins": 1},
	&"school": {"litter": 8, "leaves": 3, "puddles": 2, "crates": 2, "barrels": 0, "bins": 2},
	&"hospital": {"litter": 5, "leaves": 0, "puddles": 2, "crates": 1, "barrels": 0, "bins": 3},
	&"gas_station": {"litter": 8, "leaves": 0, "puddles": 3, "crates": 2, "barrels": 2, "bins": 2},
	&"police": {"litter": 6, "leaves": 0, "puddles": 2, "crates": 2, "barrels": 1, "bins": 2},
	&"warehouses": {"litter": 7, "leaves": 0, "puddles": 3, "crates": 4, "barrels": 2, "bins": 1},
	&"industrial": {"litter": 7, "leaves": 0, "puddles": 3, "crates": 2, "barrels": 4, "bins": 1},
	&"substation": {"litter": 4, "leaves": 0, "puddles": 2, "crates": 1, "barrels": 2, "bins": 0},
	&"power_station": {"litter": 5, "leaves": 0, "puddles": 3, "crates": 2, "barrels": 2, "bins": 1},
}

var _rng := RandomNumberGenerator.new()
var _landmark: Node3D = null
var _district_id: StringName = &""
var _clear: Array[Vector2] = []
var _pool_mat: StandardMaterial3D = null
var _fog_mat: ShaderMaterial = null
var _inner: float = 3.5
var _grid: float = 16.0
var _walk: float = 4.25

## `sb` is the district's StreetBuilder: its grid spacing and the widths of its road and sidewalk place everything.
func build(district_id: StringName, sb: Node) -> void:
	_district_id = district_id
	_rng.seed = hash("dressing_" + String(district_id))
	var kit: Dictionary = KIT.get(district_id, KIT[&"suburbs"])
	_grid = sb.grid_spacing
	_inner = _grid * 0.5 - sb.road_width * 0.5 - sb.sidewalk_width
	_walk = _grid * 0.5 - sb.road_width * 0.5 - sb.sidewalk_width * 0.5
	_clear = _keep_clear()
	var litter: Array[Transform3D] = []
	var litter_colors: Array[Color] = []
	var puddles: Array[Transform3D] = []
	var crates: Array[Transform3D] = []
	var barrels: Array[Transform3D] = []
	var barrel_colors: Array[Color] = []
	var bins: Array[Transform3D] = []
	for cx in [-1, 0, 1]:
		for cz in [-1, 0, 1]:
			var centre := Vector3(cx * _grid, 0.0, cz * _grid)
			var pieces: int = int(kit["litter"]) + int(kit["leaves"])
			for i in pieces:
				var at: Vector3 = centre + _spread(_grid * 0.5 - 0.6)
				var turn := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(_rng.randf_range(0.5, 1.4), 1.0, _rng.randf_range(0.5, 1.4)))
				litter.append(Transform3D(turn, Vector3(at.x, GROUND_Y + 0.02, at.z)))
				litter_colors.append(_pick(LEAF_COLORS if i >= int(kit["litter"]) else LITTER_COLORS))
			for i in int(kit["puddles"]):
				var on_road: Vector3 = centre + _road_spot(_rng.randi_range(0, 3), _grid * 0.5, _rng.randf_range(-6.0, 6.0), _rng.randf_range(-2.2, 2.2))
				var size: float = _rng.randf_range(1.0, 2.2)
				var spread := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(size * _rng.randf_range(1.0, 1.6), 1.0, size))
				puddles.append(Transform3D(spread, Vector3(on_road.x, MARKING_TOP_Y + 0.01, on_road.z)))
			for i in int(kit["crates"]):
				var at: Vector3 = _solid_spot(centre + _edge_spot())
				if at == Vector3.INF:
					continue
				var size: float = _rng.randf_range(0.8, 1.15)
				crates.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * size), Vector3(at.x, GROUND_Y + 0.35 * size, at.z)))
				if _rng.randf() < 0.25:
					crates.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * size * 0.8), Vector3(at.x, GROUND_Y + 0.98 * size, at.z)))
			for i in int(kit["barrels"]):
				var at: Vector3 = _solid_spot(centre + _edge_spot())
				if at != Vector3.INF:
					barrels.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU), Vector3(at.x, GROUND_Y + 0.45, at.z)))
					barrel_colors.append(_pick(BARREL_COLORS))
			for i in int(kit["bins"]):
				var at: Vector3 = _solid_spot(centre + _road_spot(_rng.randi_range(0, 3), _grid * 0.5 - _walk, _rng.randf_range(-6.0, 6.0), 0.0))
				if at != Vector3.INF:
					bins.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU), Vector3(at.x, GROUND_Y, at.z)))
	var story: Dictionary = _STORY.place(district_id, _STORY.hiding_spots(get_tree()), _clear, _grid)
	var story_from: Dictionary = {"Crates": crates.size(), "Barrels": barrels.size(), "Bins": bins.size(), "Litter": litter.size()}
	crates.append_array(story["crates"] as Array[Transform3D])
	barrels.append_array(story["barrels"] as Array[Transform3D])
	barrel_colors.append_array(story["barrel_colors"] as Array[Color])
	bins.append_array(story["bins"] as Array[Transform3D])
	litter.append_array(story["litter"] as Array[Transform3D])
	litter_colors.append_array(story["litter_colors"] as Array[Color])
	var none: Array[Color] = []
	_batch("Litter", _flat(), litter, litter_colors, _plain(Color.WHITE, 0.95, 0.0, true), false)
	_batch("Puddles", _patch(), puddles, none, _soft(Color(0.015, 0.02, 0.03, 0.55), false), false)
	_batch("Crates", _box(), crates, none, _plain(CRATE_COLOR, 0.9, 0.0, false, "plywood"), true)
	_batch("Barrels", _drum(), barrels, barrel_colors, _plain(Color.WHITE, 0.95, 0.0, true, "rusted_metal"), true)
	_batch("Bins", _BIN, bins, none, _plain(Color(0.20, 0.22, 0.25), 0.6, 0.5, false, "rusted_metal"), true)
	_batch("Hydrants", _HYDRANT, _hydrant_spots(sb), none, _plain(Color(0.34, 0.27, 0.13), 0.55, 0.4, false, "rusted_metal"), true)
	_pool_mat = _soft(Color(BRASS, 0.0), true)
	_batch("LampPools", _patch(), _lamp_pools(), none, _pool_mat, false)
	var details: Node3D = _LAMP_DETAILS.new()
	details.name = "LampDetails"
	add_child(details)
	details.call("build", district_id, get_parent())
	for node_name: String in story_from:
		var batch := get_node_or_null(node_name)
		if batch != null:
			batch.set_meta("story_from", story_from[node_name])
	var spots: Array[Vector3] = story["spots"]
	var kinds: Array[String] = story["kinds"]
	set_meta("story_spots", spots)
	for i in spots.size():
		_STORY.hook(self, spots[i], kinds[i])
	var urban: Node3D = _URBAN.new()
	urban.name = "UrbanSetDressing"
	add_child(urban)
	urban.call("build", district_id, sb, _clear, _grid, _inner)
	_add_landmark()
	_add_rest_spot()
	_add_fog()
	_add_manholes()
	_apply_stage(PowerGrid.get_stage(_district_id))
	EventBus.district_stage_changed.connect(_on_stage_changed)

## One pool of light for each streetlamp (its pole is a transform of the batched poles of the sibling node), moved toward the block the pole stands beside.
func _lamp_pools() -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	var poles := get_parent().get_node_or_null("StreetlightPolesBatched") as MultiMeshInstance3D
	if poles == null:
		return out
	for i in poles.multimesh.instance_count:
		var pole: Vector3 = poles.multimesh.get_instance_transform(i).origin
		var best := Vector3.ZERO
		var nearest: float = INF
		for cx in [-1, 0, 1]:
			for cz in [-1, 0, 1]:
				var centre := Vector3(cx * _grid, 0.0, cz * _grid)
				if centre.distance_to(pole) < nearest:
					nearest = centre.distance_to(pole)
					best = centre
		var at: Vector3 = pole + (best - pole).normalized() * POOL_TOWARD_BLOCK_M
		out.append(Transform3D(Basis().scaled(Vector3(POOL_M, 1.0, POOL_M)), Vector3(at.x, POOL_Y, at.z)))
	return out

## Hydrants stand on the corners of a few crossings.
func _hydrant_spots(sb: Node) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	for i in HYDRANTS:
		var corner := Vector3((_rng.randi_range(0, 3) - 1.5) * _grid, 0.0, (_rng.randi_range(0, 3) - 1.5) * _grid)
		var reach: float = sb.road_width * 0.5 + 0.4
		var around := Vector3(1.0 if _rng.randf() < 0.5 else -1.0, 0.0, 1.0 if _rng.randf() < 0.5 else -1.0) * reach
		var at: Vector3 = _solid_spot(corner + around)
		if at != Vector3.INF:
			out.append(Transform3D(Basis(), Vector3(at.x, GROUND_Y, at.z)))
	return out

## A point of the square of half-size `half` around the origin.
func _spread(half: float) -> Vector3:
	return Vector3(_rng.randf_range(-half, half), 0.0, _rng.randf_range(-half, half))

func _pick(colors: Array[Color]) -> Color:
	return colors[_rng.randi() % colors.size()]

## A point of the road on side 0..3 of a block (north, east, south, west) `out` metres from the block's centre: `along` runs with the road, `across` is the offset from its axis.
func _road_spot(side: int, out: float, along: float, across: float) -> Vector3:
	match side:
		0:
			return Vector3(along, 0.0, -out + across)
		1:
			return Vector3(out + across, 0.0, along)
		2:
			return Vector3(along, 0.0, out + across)
	return Vector3(-out + across, 0.0, along)

## A point of the open ground of a block, 0.7 m inside its edge: where the lamps of the street reach.
func _edge_spot() -> Vector3:
	return _road_spot(_rng.randi_range(0, 3), _inner - 0.7, _rng.randf_range(-_inner + 0.6, _inner - 0.6), 0.0)

## The point, or INF when it is too close to a pickup, a hiding place or a door.
func _solid_spot(at: Vector3) -> Vector3:
	for other in _clear:
		if other.distance_to(Vector2(at.x, at.z)) < KEEP_CLEAR_M:
			return Vector3.INF
	return at

func _keep_clear() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for group in [&"interactable", &"hiding_spot"]:
		for node in get_tree().get_nodes_in_group(group):
			var spot := node as Node3D
			if spot != null:
				out.append(Vector2(spot.global_position.x, spot.global_position.z))
	return out

func _flat() -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.38, 0.012, 0.26)
	return mesh

func _box() -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.7, 0.7, 0.7)
	return mesh

## A flat one-metre square that lies on the ground and carries a soft round texture.
func _patch() -> PlaneMesh:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2.ONE
	return mesh

func _drum() -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.28
	mesh.bottom_radius = 0.28
	mesh.height = 0.9
	mesh.radial_segments = 10
	mesh.rings = 1
	return mesh

func _plain(color: Color, roughness: float, metallic: float, tinted: bool = false, tex: String = "") -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	mat.vertex_color_use_as_albedo = tinted
	return preload("res://scripts/world/pbr_sets.gd").apply(mat, tex)  # B6: the set `tex` names, if its files exist

## A soft round patch that is not lit by anything: a wet stain (`add` false: darkens what is under it) or a pool of light (`add` true: brightens it).
func _soft(color: Color, add: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if add:
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_texture = _LANDMARK.glow_texture()
	mat.albedo_color = color
	return mat

func _batch(node_name: String, mesh: Mesh, xforms: Array[Transform3D], colors: Array[Color], material: Material, shadows: bool) -> void:
	if xforms.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not colors.is_empty()
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		if mm.use_colors:
			mm.set_instance_color(i, colors[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.set_meta("spots", xforms)
	mmi.multimesh = mm
	mmi.material_override = material
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)

## Last of the placements, so none that the seeded stream made before it moves; a cover is left out where a pickup or a hiding place is near.
func _add_manholes() -> void:
	for i in MANHOLES:
		var at: Vector3 = _solid_spot(_road_spot(_rng.randi_range(0, 3), _grid * 0.5, _rng.randf_range(-5.0, 5.0), _rng.randf_range(-1.6, 1.6)))
		if at == Vector3.INF:
			continue
		var cover: Node3D = _MANHOLE.new()
		cover.name = "Manhole%d" % i
		cover.position = at
		add_child(cover)

func _add_fog() -> void:
	if not FOG_DISTRICTS.has(_district_id) or int(SettingsManager.get_setting("graphics_tier", 2)) < 1:
		return
	_fog_mat = ShaderMaterial.new()
	_fog_mat.shader = FOG_SHADER
	var card := PlaneMesh.new()
	card.size = Vector2(FOG_CARD_M, FOG_CARD_M)
	for i in FOG_AT.size():
		var fog := MeshInstance3D.new()
		fog.name = "FogCard%d" % i
		fog.mesh = card
		fog.material_override = _fog_mat
		fog.position = FOG_AT[i] + Vector3(0.0, FOG_Y, 0.0)
		fog.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(fog)

func _add_landmark() -> void:
	_landmark = _LANDMARK.build(_district_id, Vector3(0.0, 0.0, -_LANDMARK.NORTH_M))
	add_child(_landmark)

func _on_stage_changed(id: StringName, stage: int) -> void:
	if id == _district_id:
		_apply_stage(stage)

## The landmark, the pools of the lamps and the ground fog follow the power of the district.
func _apply_stage(stage: int) -> void:
	if is_instance_valid(_landmark):
		_LANDMARK.apply_stage(_landmark, stage)
	if _fog_mat != null:
		_fog_mat.set_shader_parameter("alpha", FOG_BY_STAGE[clampi(stage, 0, FOG_BY_STAGE.size() - 1)])
	var pool: float = POOL_BY_STAGE[clampi(stage, 0, POOL_BY_STAGE.size() - 1)]
	_pool_mat.albedo_color = Color(BRASS, pool)
	var pools := get_node_or_null("LampPools") as Node3D
	if pools != null:
		pools.visible = pool > 0.0  # a blended quad of opacity 0 still costs its fill

## A bench under a lantern near the power switch, lit in every stage: the place where the Keeper stops to restore a district.
func _add_rest_spot() -> void:
	var switch_node := get_node_or_null("../../PowerSwitch") as Node3D
	var at: Vector3 = (switch_node.position if switch_node != null else Vector3(8.0, 0.0, 8.0)) + REST_FROM_SWITCH
	var bench := MeshInstance3D.new()
	bench.name = "RestBench"
	bench.mesh = _BENCH
	bench.material_override = _plain(Color(0.30, 0.26, 0.22), 0.85, 0.0, false, "plywood")
	add_child(bench)
	bench.position = Vector3(at.x, GROUND_Y, at.z)
	bench.rotation.y = atan2(8.0 - at.x, 8.0 - at.z)  # the seat of the bench faces +Z: toward the power switch
	var lantern := Node3D.new()
	lantern.name = "RestLantern"
	lantern.position = Vector3(at.x - 1.3, GROUND_Y, at.z + 0.2)
	add_child(lantern)
	var pole := MeshInstance3D.new()
	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.05
	shaft.bottom_radius = 0.07
	shaft.height = 2.2
	shaft.radial_segments = 6
	shaft.rings = 1
	pole.mesh = shaft
	pole.material_override = _plain(Color(0.165, 0.200, 0.251), 0.55, 0.6, false, "rusted_metal")
	pole.position = Vector3(0.0, 1.1, 0.0)
	lantern.add_child(pole)
	var bulb := MeshInstance3D.new()
	var globe := SphereMesh.new()
	globe.radius = 0.2
	globe.height = 0.4
	globe.radial_segments = 8
	globe.rings = 4
	bulb.mesh = globe
	var glow := StandardMaterial3D.new()
	glow.albedo_color = BRASS
	glow.emission_enabled = true
	glow.emission = BRASS
	glow.emission_energy_multiplier = 2.5
	bulb.material_override = glow
	bulb.position = Vector3(0.0, 2.35, 0.0)
	lantern.add_child(bulb)
	var bloom := MeshInstance3D.new()
	bloom.name = "RestBloom"
	var flare := QuadMesh.new()
	flare.size = Vector2(2.6, 2.6)
	bloom.mesh = flare
	var flare_mat := _soft(Color(BRASS, 0.7), true)
	flare_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	bloom.material_override = flare_mat
	bloom.position = bulb.position
	lantern.add_child(bloom)
	var rest_pool := MeshInstance3D.new()
	rest_pool.name = "RestPool"
	rest_pool.mesh = _patch()
	rest_pool.material_override = _soft(Color(BRASS, REST_POOL_ALPHA), true)
	rest_pool.scale = Vector3(POOL_M, 1.0, POOL_M)
	rest_pool.position = Vector3(0.0, POOL_Y - GROUND_Y, 0.0)
	lantern.add_child(rest_pool)
	var lamp := OmniLight3D.new()
	lamp.name = "RestLight"
	lamp.light_color = BRASS
	lamp.light_energy = LAMP_ENERGY
	lamp.omni_range = LAMP_RANGE_M
	lamp.shadow_enabled = false
	lamp.position = bulb.position
	lantern.add_child(lamp)
