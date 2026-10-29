extends RefCounted
## The streetlight of the visual recovery brief, built in code once per process: a concrete plinth, a slender tapered steel pole with collars, a gooseneck arm and a hooded fixture over the lens, in one mesh with
## vertex colours (rust near the foot, dark steel above) and one material, so a district draws every pole in one call. The geometry is laid out around the head offset the lights and the lens share
## (HEAD, the same point street_props.gd and streetlight_3d.tscn use), so the light starts where the lens is. The poles are street_props.gd's; the lens is its emissive sphere, flattened.

const HEAD := Vector3(1.16, 4.2, 0.0)
const CONCRETE := Color("#33322f")
const STEEL := Color("#14171a")
const STEEL_LIGHT := Color("#20252a")
const RUST := Color("#3a2418")
const ARM: Array[Vector3] = [
	Vector3(0.0, 3.95, 0.0), Vector3(0.0, 4.28, 0.0), Vector3(0.07, 4.43, 0.0), Vector3(0.22, 4.51, 0.0),
	Vector3(0.45, 4.55, 0.0), Vector3(0.75, 4.54, 0.0), Vector3(1.0, 4.5, 0.0), Vector3(1.16, 4.44, 0.0),
]
static var _mesh: ArrayMesh = null
static var _material: StandardMaterial3D = null

static func pole_mesh() -> ArrayMesh:
	if _mesh == null:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_frustum(st, Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.62, 0.0), 0.2, 0.15, 8, CONCRETE, CONCRETE.lightened(0.08), true)
		_frustum(st, Vector3(0.0, 0.62, 0.0), Vector3(0.0, 0.7, 0.0), 0.12, 0.1, 10, STEEL_LIGHT, STEEL_LIGHT, true)
		_frustum(st, Vector3(0.0, 0.7, 0.0), Vector3(0.0, 1.5, 0.0), 0.072, 0.0647, 12, RUST, STEEL, false)
		_frustum(st, Vector3(0.0, 1.5, 0.0), Vector3(0.0, 4.0, 0.0), 0.0647, 0.042, 12, STEEL, STEEL, false)
		for collar: Array in [[0.7, 0.09, 0.05], [2.4, 0.058, 0.04], [3.92, 0.056, 0.06]]:
			_frustum(st, Vector3(0.0, float(collar[0]), 0.0), Vector3(0.0, float(collar[0]) + float(collar[2]), 0.0), float(collar[1]), float(collar[1]), 12, STEEL_LIGHT, STEEL_LIGHT, true)
		for i in ARM.size() - 1:
			var radius_a := lerpf(0.036, 0.026, float(i) / float(ARM.size() - 1))
			var radius_b := lerpf(0.036, 0.026, float(i + 1) / float(ARM.size() - 1))
			_frustum(st, ARM[i], ARM[i + 1], radius_a, radius_b, 8, STEEL, STEEL, i == ARM.size() - 2)
		_frustum(st, Vector3(HEAD.x, 4.44, 0.0), Vector3(HEAD.x, 4.36, 0.0), 0.03, 0.03, 8, STEEL, STEEL, true)
		_frustum(st, Vector3(HEAD.x, 4.22, 0.0), Vector3(HEAD.x, 4.38, 0.0), 0.28, 0.09, 8, STEEL_LIGHT, STEEL, true)
		_frustum(st, Vector3(HEAD.x, 4.18, 0.0), Vector3(HEAD.x, 4.22, 0.0), 0.27, 0.28, 8, Color("#0c0d0e"), STEEL, true)
		_mesh = st.commit()
	return _mesh

static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.vertex_color_is_srgb = true
		_material.metallic = 0.4
		_material.roughness = 0.65
		var dir := "res://assets/textures/pbr/rusted_metal_"
		if ResourceLoader.exists(dir + "normal.png"):
			_material.normal_enabled = true
			_material.normal_texture = load(dir + "normal.png")
			_material.normal_scale = 0.5
		if ResourceLoader.exists(dir + "rough.png"):
			_material.roughness = 1.0
			_material.roughness_texture = load(dir + "rough.png")
		_material.uv1_triplanar = true
		_material.uv1_scale = Vector3.ONE * 1.5
	return _material

## A frustum from `a` (radius `ra`, colour `ca`) to `b` (`rb`, `cb`) with `sides` sides, smooth side normals and flat end caps when `caps`; the front face winds clockwise.
static func _frustum(st: SurfaceTool, a: Vector3, b: Vector3, ra: float, rb: float, sides: int, ca: Color, cb: Color, caps: bool) -> void:
	var axis := (b - a).normalized()
	var length := a.distance_to(b)
	var ref := Vector3.UP if absf(axis.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
	var u := axis.cross(ref).normalized()
	var v := u.cross(axis)
	var rim_a: Array[Vector3] = []
	var rim_b: Array[Vector3] = []
	var norms: Array[Vector3] = []
	for i in sides:
		var angle := TAU * float(i) / float(sides)
		var dir := u * cos(angle) + v * sin(angle)
		rim_a.append(a + dir * ra)
		rim_b.append(b + dir * rb)
		norms.append((dir * length - axis * (rb - ra)).normalized())
	for i in sides:
		var j := (i + 1) % sides
		for corner: Array in [[rim_a[i], norms[i], ca], [rim_b[j], norms[j], cb], [rim_b[i], norms[i], cb], [rim_a[i], norms[i], ca], [rim_a[j], norms[j], ca], [rim_b[j], norms[j], cb]]:
			st.set_normal(corner[1])
			st.set_color(corner[2])
			st.add_vertex(corner[0])
	if not caps:
		return
	for end: int in [0, 1]:
		var centre := b if end == 1 else a
		var rim: Array[Vector3] = rim_b if end == 1 else rim_a
		var colour := cb if end == 1 else ca
		var normal := axis if end == 1 else -axis
		for i in sides:
			var j := (i + 1) % sides
			for point: Vector3 in ([centre, rim[i], rim[j]] if end == 1 else [centre, rim[j], rim[i]]):
				st.set_normal(normal)
				st.set_color(colour)
				st.add_vertex(point)
