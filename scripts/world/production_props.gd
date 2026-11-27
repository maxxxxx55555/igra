extends Node3D
## B9 set dressing upgraded with native triplanar PBR materials (0 extra texture MiB).
## Eliminates flat untextured blue/purple box cars, cabinets, fences, handcarts, and debris
## while preserving deterministic seeded placement and 5-draw-call MultiMesh batching.

const CAR := preload("res://assets/mesh/mesh_car.res")
const CABINET := preload("res://assets/mesh/mesh_cabinet.res")
const FENCE := preload("res://assets/mesh/mesh_fence.res")
const CART := preload("res://assets/mesh/mesh_cart.res")
const DEBRIS := preload("res://assets/mesh/mesh_debris.res")

const GROUND_Y: float = 0.06
const CAR_CLEAR_M: float = 3.2
const PROP_CLEAR_M: float = 2.0
const SPAWN_CLEAR_M: float = 8.5

## Gritty desaturated charcoal/rust/umber period finishes (zero bright blue/purple plastic).
const CAR_COLORS: Array[Color] = [
	Color(0.26, 0.27, 0.26), Color(0.32, 0.28, 0.24),
	Color(0.22, 0.24, 0.25), Color(0.29, 0.25, 0.22),
]

const PBR_DIR: String = "res://assets/textures/pbr/"

var _rng := RandomNumberGenerator.new()
var _clear: Array[Vector2] = []
var _grid: float = 16.0
var _inner: float = 3.5
var _walk: float = 4.25


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
	for cx in [-1, 0, 1]:
		for cz in [-1, 0, 1]:
			var centre := Vector3(cx * grid, 0.0, cz * grid)
			if cx == 0 and cz <= 0:
				var side: int = _rng.randi_range(0, 3)
				var at := centre + _road_spot(side, _walk + 0.55,
						_rng.randf_range(-4.5, 4.5), 0.0)
				if _free(at, CAR_CLEAR_M):
					var yaw: float = 0.0 if side == 0 or side == 2 else PI * 0.5
					cars.append(Transform3D(Basis(Vector3.UP, yaw + (_rng.randf() - 0.5) * 0.10),
							Vector3(at.x, GROUND_Y, at.z)))
					car_colors.append(CAR_COLORS[_rng.randi() % CAR_COLORS.size()])
			if cx != 0 or cz != 0:
				var cs: int = _rng.randi_range(0, 3)
				var cat := centre + _road_spot(cs, _inner - 0.35,
						_rng.randf_range(-_inner + 1.0, _inner - 1.0), 0.0)
				if _free(cat, PROP_CLEAR_M):
					cabinets.append(Transform3D(Basis(Vector3.UP, float(cs) * PI * 0.5),
							Vector3(cat.x, GROUND_Y, cat.z)))
			var fs: int = _rng.randi_range(0, 3)
			var fat := centre + _road_spot(fs, _inner - 0.25,
					_rng.randf_range(-_inner + 1.6, _inner - 1.6), 0.0)
			if _free(fat, PROP_CLEAR_M):
				fences.append(Transform3D(Basis(Vector3.UP, float(fs) * PI * 0.5),
						Vector3(fat.x, GROUND_Y, fat.z)))
			var hat := centre + _spread(_inner - 1.0)
			if _free(hat, PROP_CLEAR_M):
				carts.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU),
						Vector3(hat.x, GROUND_Y, hat.z)))
			for i in 2:
				var dat := centre + _spread(_inner - 0.8)
				if _free(dat, PROP_CLEAR_M):
					var s: float = _rng.randf_range(0.75, 1.30)
					debris.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s, s)),
							Vector3(dat.x, GROUND_Y, dat.z)))
	_batch("B9Cars", CAR, cars, car_colors, _pbr_mat("rusted_metal", Color(0.55, 0.55, 0.55), 0.58, 0.42, true), true)
	_batch("B9Cabinets", CABINET, cabinets, [], _pbr_mat("rusted_metal", Color(0.36, 0.38, 0.39), 0.68, 0.48, false), true)
	_batch("B9Fences", FENCE, fences, [], _pbr_mat("rusted_metal", Color(0.30, 0.32, 0.33), 0.72, 0.56, false), true)
	_batch("B9Carts", CART, carts, [], _pbr_mat("plywood", Color(0.42, 0.34, 0.26), 0.86, 0.06, false), true)
	_batch("B9Debris", DEBRIS, debris, [], _pbr_mat("cracked_concrete", Color(0.34, 0.34, 0.32), 0.92, 0.0, false), false)


func _pbr_mat(set_name: String, color: Color, roughness: float, metallic: float, tinted: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	mat.vertex_color_use_as_albedo = tinted
	var alb := PBR_DIR + set_name + "_albedo.webp"
	var nrm := PBR_DIR + set_name + "_normal.webp"
	var rgh := PBR_DIR + set_name + "_rough.webp"
	if ResourceLoader.exists(alb):
		mat.albedo_texture = load(alb) as Texture2D
	if ResourceLoader.exists(nrm):
		mat.normal_enabled = true
		mat.normal_texture = load(nrm) as Texture2D
		mat.normal_scale = 0.85
	if ResourceLoader.exists(rgh):
		mat.roughness = 1.0
		mat.roughness_texture = load(rgh) as Texture2D
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3.ONE * 0.65
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


func _free(at: Vector3, margin: float) -> bool:
	var p := Vector2(at.x, at.z)
	if p.length() < SPAWN_CLEAR_M:
		return false
	for q in _clear:
		if p.distance_to(q) < margin:
			return false
	return true
