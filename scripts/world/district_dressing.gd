extends Node3D
## What a district holds between its streets (docs/DENSITY_PLAN.md): litter, leaves, puddles, bins, hydrants, crates and barrels in every block, the landmark behind
## the skyline ring and a lit bench by the power switch. Visual only like the trees and benches of street_props.gd: no collision and no navigation, a seeded stream
## of its own so no other placement moves. Everything of one kind is one MultiMesh, so the whole is about ten draw calls.

const _BIN := preload("res://assets/mesh/mesh_trash_can.res")
const _HYDRANT := preload("res://assets/mesh/mesh_hydrant.res")
const _BENCH := preload("res://assets/mesh/mesh_bench.res")
const _LANDMARK := preload("res://scripts/world/district_landmark.gd")

## Tops of the ground in the district (street_builder.gd tiles and skyline.gd ground) and of the road markings.
const GROUND_Y: float = 0.06
const MARKING_TOP_Y: float = 0.08
## Solid props keep this far from anything the player can use or hide in.
const KEEP_CLEAR_M: float = 1.8
const HYDRANTS: int = 5
const LAMP_RANGE_M: float = 7.0
const LAMP_ENERGY: float = 0.9
## Where the bench stands from the power switch (the switch is at the corner of the middle block and the next).
const REST_FROM_SWITCH := Vector3(6.0, 0.0, 5.0)
const BRASS := Color("#c9a24a")
const LITTER_COLORS: Array[Color] = [Color(0.34, 0.36, 0.40), Color(0.46, 0.44, 0.40), Color(0.30, 0.25, 0.14), Color(0.12, 0.12, 0.14)]
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
				var size: float = _rng.randf_range(0.7, 1.7)
				var spread := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(size * _rng.randf_range(1.0, 1.8), 1.0, size))
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
	var none: Array[Color] = []
	_batch("Litter", _flat(), litter, litter_colors, _plain(Color.WHITE, 0.95, 0.0, true), false)
	_batch("Puddles", _disc(), puddles, none, _wet(), false)
	_batch("Crates", _box(), crates, none, _plain(CRATE_COLOR, 0.9, 0.0), true)
	_batch("Barrels", _drum(), barrels, barrel_colors, _plain(Color.WHITE, 0.95, 0.0, true), true)
	_batch("Bins", _BIN, bins, none, _plain(Color(0.20, 0.22, 0.25), 0.6, 0.5), true)
	_batch("Hydrants", _HYDRANT, _hydrant_spots(sb), none, _plain(Color(0.34, 0.27, 0.13), 0.55, 0.4), true)
	_add_landmark()
	_add_rest_spot()

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

func _disc() -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.0
	mesh.bottom_radius = 1.0
	mesh.height = 0.008
	mesh.radial_segments = 14
	mesh.rings = 1
	return mesh

func _drum() -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.28
	mesh.bottom_radius = 0.28
	mesh.height = 0.9
	mesh.radial_segments = 10
	mesh.rings = 1
	return mesh

func _plain(color: Color, roughness: float, metallic: float, tinted: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	mat.vertex_color_use_as_albedo = tinted
	return mat

## Wet ground: dark and glossy, so the lamps and the flashlight leave a streak on it.
func _wet() -> StandardMaterial3D:
	var mat := _plain(Color(0.03, 0.04, 0.05), 0.08, 0.0)
	mat.metallic_specular = 1.0
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
	mmi.multimesh = mm
	mmi.material_override = material
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)

func _add_landmark() -> void:
	_landmark = _LANDMARK.build(_district_id, Vector3(0.0, 0.0, -_LANDMARK.NORTH_M))
	add_child(_landmark)
	_LANDMARK.apply_stage(_landmark, PowerGrid.get_stage(_district_id))
	EventBus.district_stage_changed.connect(_on_stage_changed)

func _on_stage_changed(id: StringName, stage: int) -> void:
	if id == _district_id and is_instance_valid(_landmark):
		_LANDMARK.apply_stage(_landmark, stage)

## A bench under a lantern near the power switch, lit in every stage: the place where the Keeper stops to restore a district.
func _add_rest_spot() -> void:
	var switch_node := get_node_or_null("../../PowerSwitch") as Node3D
	var at: Vector3 = (switch_node.position if switch_node != null else Vector3(8.0, 0.0, 8.0)) + REST_FROM_SWITCH
	var bench := MeshInstance3D.new()
	bench.name = "RestBench"
	bench.mesh = _BENCH
	bench.material_override = _plain(Color(0.30, 0.26, 0.22), 0.85, 0.0)
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
	pole.material_override = _plain(Color(0.165, 0.200, 0.251), 0.55, 0.6)
	pole.position = Vector3(0.0, 1.1, 0.0)
	lantern.add_child(pole)
	var bulb := MeshInstance3D.new()
	var globe := SphereMesh.new()
	globe.radius = 0.14
	globe.height = 0.28
	globe.radial_segments = 8
	globe.rings = 4
	bulb.mesh = globe
	var glow := StandardMaterial3D.new()
	glow.albedo_color = BRASS
	glow.emission_enabled = true
	glow.emission = BRASS
	glow.emission_energy_multiplier = 1.6
	bulb.material_override = glow
	bulb.position = Vector3(0.0, 2.35, 0.0)
	lantern.add_child(bulb)
	var lamp := OmniLight3D.new()
	lamp.name = "RestLight"
	lamp.light_color = BRASS
	lamp.light_energy = LAMP_ENERGY
	lamp.omni_range = LAMP_RANGE_M
	lamp.shadow_enabled = false
	lamp.position = bulb.position
	lantern.add_child(lamp)
