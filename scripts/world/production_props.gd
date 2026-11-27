extends Node3D
## B9 set dressing (2026-11-13): the reusable production meshes of
## scripts/tools/_gen_meshes_b9.gd placed in every district. Visual only, like
## the rest of district_dressing.gd: no collision, no navigation, no markers,
## no gameplay state. Its own seeded stream, so no existing prop, pickup or
## hiding spot moves by a single metre when this node is added.
##
## One MultiMesh per kind: five extra draw calls for a parked car, a street
## cabinet, a fence bay, a handcart and a rubble pile in each district.

const CAR := preload("res://assets/mesh/mesh_car.res")
const CABINET := preload("res://assets/mesh/mesh_cabinet.res")
const FENCE := preload("res://assets/mesh/mesh_fence.res")
const CART := preload("res://assets/mesh/mesh_cart.res")
const DEBRIS := preload("res://assets/mesh/mesh_debris.res")

const GROUND_Y: float = 0.06
## Cars need a wider berth than a bin: nothing a player can use may sit inside one.
const CAR_CLEAR_M: float = 2.6
const PROP_CLEAR_M: float = 1.8
const SPAWN_CLEAR_M: float = 3.5
## Desaturated period colours, read against the brass lamps and blue-grey depth
## of the main-menu canon; no bright plastic and no pure white.
const CAR_COLORS: Array[Color] = [
	Color(0.13, 0.15, 0.16), Color(0.18, 0.17, 0.15),
	Color(0.11, 0.13, 0.17), Color(0.22, 0.19, 0.14),
]

var _rng := RandomNumberGenerator.new()
var _clear: Array[Vector2] = []
var _grid: float = 16.0
var _inner: float = 3.5
var _walk: float = 4.25

## The StreetBuilder gives the same grid and road widths district_dressing.gd uses.
func build(district_id: StringName, sb: Node, clear: Array[Vector2], grid: float) -> void:
	_rng.seed = hash("b9_props_" + String(district_id))
	_clear = clear
	_grid = grid
	_inner = grid * 0.5 - sb.road_width * 0.5 - sb.sidewalk_width
	_walk = grid * 0.5 - sb.road_width * 0.5 - sb.sidewalk_width * 0.5
	var cars: Array[Transform3D] = []
	var car_colors: Array[Color] = []
	var cabinets: Array[Transform3D] = []
	var fences: Array[Transform3D] = []
	var carts: Array[Transform3D] = []
	var debris: Array[Transform3D] = []
	var skip_foreground_props: bool = district_id == &"residential" or district_id == &"power_station"
	for cx in [-1, 0, 1]:
		for cz in [-1, 0, 1]:
			var centre := Vector3(cx * grid, 0.0, cz * grid)
			# Two parked cars per district, along a road that actually runs there.
			if cx == 0 and cz <= 0:
				var side: int = _rng.randi_range(0, 3)
				var at := centre + _road_spot(side, _walk + 0.55,
						_rng.randf_range(-4.5, 4.5), 0.0)
				if _free(at, CAR_CLEAR_M):
					var yaw: float = 0.0 if side == 0 or side == 2 else PI * 0.5
					cars.append(Transform3D(Basis(Vector3.UP, yaw + (_rng.randf() - 0.5) * 0.10),
							Vector3(at.x, GROUND_Y, at.z)))
					car_colors.append(CAR_COLORS[_rng.randi() % CAR_COLORS.size()])
			# A cabinet by the block corner, facing the road.
			if cx != 0 or cz != 0:
				var cs: int = _rng.randi_range(0, 3)
				var cat := centre + _road_spot(cs, _inner - 0.35,
						_rng.randf_range(-_inner + 1.0, _inner - 1.0), 0.0)
				if _free(cat, PROP_CLEAR_M):
					cabinets.append(Transform3D(Basis(Vector3.UP, float(cs) * PI * 0.5),
							Vector3(cat.x, GROUND_Y, cat.z)))
			# One fence bay on a block edge, aligned with it.
			var fs: int = _rng.randi_range(0, 3)
			var fat := centre + _road_spot(fs, _inner - 0.25,
					_rng.randf_range(-_inner + 1.6, _inner - 1.6), 0.0)
			if _free(fat, PROP_CLEAR_M):
				fences.append(Transform3D(Basis(Vector3.UP, float(fs) * PI * 0.5),
						Vector3(fat.x, GROUND_Y, fat.z)))
			# A handcart and rubble inside the block, clear of every usable object.
			var hat := centre + _spread(_inner - 1.0)
			if not skip_foreground_props and _free(hat, PROP_CLEAR_M):
				carts.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU),
						Vector3(hat.x, GROUND_Y, hat.z)))
			for i in 2:
				var dat := centre + _spread(_inner - 0.8)
				if not skip_foreground_props and _free(dat, PROP_CLEAR_M):
					var s: float = _rng.randf_range(0.75, 1.30)
					debris.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s, s)),
							Vector3(dat.x, GROUND_Y, dat.z)))
	_batch("B9Cars", CAR, cars, car_colors, _mat(Color.WHITE, 0.62, 0.28, true), true)
	_batch("B9Cabinets", CABINET, cabinets, [], _mat(Color(0.22, 0.23, 0.24), 0.70, 0.45), true)
	_batch("B9Fences", FENCE, fences, [], _mat(Color(0.16, 0.17, 0.18), 0.75, 0.55), true)
	_batch("B9Carts", CART, carts, [], _mat(Color(0.28, 0.22, 0.16), 0.90, 0.05), true)
	_batch("B9Debris", DEBRIS, debris, [], _mat(Color(0.24, 0.23, 0.21), 0.95, 0.0), false)

func _mat(color: Color, roughness: float, metallic: float, tinted: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	mat.vertex_color_use_as_albedo = tinted
	return mat

func _batch(node_name: String, mesh: Mesh, xforms: Array[Transform3D], colors: Array[Color],
		material: Material, shadows: bool) -> void:
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

func _road_spot(side: int, out: float, along: float, across: float) -> Vector3:
	match side:
		0: return Vector3(along, 0.0, -out + across)
		1: return Vector3(out + across, 0.0, along)
		2: return Vector3(along, 0.0, out + across)
	return Vector3(-out + across, 0.0, along)

func _spread(half: float) -> Vector3:
	return Vector3(_rng.randf_range(-half, half), 0.0, _rng.randf_range(-half, half))

func _free(at: Vector3, radius: float) -> bool:
	if absf(at.x) < SPAWN_CLEAR_M and absf(at.z) < SPAWN_CLEAR_M:
		return false
	for other in _clear:
		if other.distance_to(Vector2(at.x, at.z)) < radius:
			return false
	return true
