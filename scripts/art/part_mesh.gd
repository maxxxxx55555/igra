extends RefCounted
## One small mesh out of parts (C1 of the v1.0.0-ship pass; the pickups and the weapon models of scripts/art build theirs here). A part is [kind, size, position, rotation in degrees, surface]: surface 0 is
## the body, surface 1 the accent (the bit that may glow). Kinds: box (size), cyl (top radius, height, bottom radius), sph (the three diameters), tor (inner radius, outer radius), page (width, bend, depth: a
## sheet whose edges curl up) and coil (coil radius, height, tube radius: a helix of wire). The parts rest on y = 0 where the caller puts them there.

const _SIDES: int = 10
const _TORUS_RINGS: int = 8
const _COIL_STEPS: int = 24
const _COIL_SIDES: int = 5
const _COIL_TURNS: float = 2.5

static func part(kind: StringName, size: Vector3, at: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO, surface: int = 0) -> Array:
	return [kind, size, at, rot, surface]

## `group` moves the whole set (a gun laid on its side).
static func build(parts: Array, group: Transform3D = Transform3D.IDENTITY) -> ArrayMesh:
	var tools: Array[SurfaceTool] = [SurfaceTool.new(), SurfaceTool.new()]
	var used: Array[bool] = [false, false]
	for st in tools:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p: Array in parts:
		var rot: Vector3 = p[3]
		var basis := Basis.from_euler(Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z)))
		if p[0] == &"sph":
			basis = basis * Basis.from_scale(p[1])
		tools[p[4]].append_from(_primitive(p[0], p[1]), 0, group * Transform3D(basis, p[2]))
		used[p[4]] = true
	var mesh := ArrayMesh.new()
	for i in 2:
		if used[i]:
			tools[i].commit(mesh)
	return mesh

## The triangles of every surface of a mesh.
static func triangles(mesh: Mesh) -> int:
	var count: int = 0
	for s in mesh.get_surface_count():
		var arrays: Array = mesh.surface_get_arrays(s)
		var index: Variant = arrays[Mesh.ARRAY_INDEX]
		count += (index as PackedInt32Array).size() / 3 if index != null else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return count

static func _primitive(kind: StringName, size: Vector3) -> Mesh:
	match kind:
		&"box":
			var box := BoxMesh.new()
			box.size = size
			return box
		&"cyl":
			var cyl := CylinderMesh.new()
			cyl.top_radius = size.x
			cyl.height = size.y
			cyl.bottom_radius = size.z
			cyl.radial_segments = _SIDES
			cyl.rings = 1
			return cyl
		&"sph":
			var sph := SphereMesh.new()
			sph.radius = 0.5
			sph.height = 1.0
			sph.radial_segments = _SIDES
			sph.rings = 5
			return sph
		&"tor":
			var tor := TorusMesh.new()
			tor.inner_radius = size.x
			tor.outer_radius = size.y
			tor.rings = _TORUS_RINGS
			tor.ring_segments = 5
			return tor
		&"page":
			return _page(size)
		&"coil":
			return _coil(size)
	var fallback := BoxMesh.new()
	fallback.size = size
	return fallback

## A sheet of width x depth whose two long edges rise by `bend` (a page lying a little curved), in 6 x 2 quads.
static func _page(size: Vector3) -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cols: int = 6
	for c in cols:
		var u0: float = float(c) / cols
		var u1: float = float(c + 1) / cols
		var quad: Array[Vector3] = [_page_point(size, u0, 0.0), _page_point(size, u1, 0.0), _page_point(size, u1, 1.0), _page_point(size, u0, 1.0)]
		for corner in [0, 1, 2, 0, 2, 3]:
			st.set_uv(Vector2(quad[corner].x / maxf(size.x, 0.001) + 0.5, quad[corner].z / maxf(size.z, 0.001) + 0.5))
			st.add_vertex(quad[corner])
	st.generate_normals()
	return st.commit()

static func _page_point(size: Vector3, u: float, v: float) -> Vector3:
	return Vector3((u - 0.5) * size.x, size.y * pow(absf(u - 0.5) * 2.0, 2.0) + 0.002, (v - 0.5) * size.z)

## A helix of wire: _COIL_TURNS turns of radius size.x climbing size.y, the wire a prism of _COIL_SIDES sides and radius size.z.
static func _coil(size: Vector3) -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[Array] = []
	for step in _COIL_STEPS + 1:
		var t: float = float(step) / _COIL_STEPS
		var angle: float = t * _COIL_TURNS * TAU
		var centre := Vector3(cos(angle) * size.x, size.z + t * size.y, sin(angle) * size.x)
		var out := Vector3(cos(angle), 0.0, sin(angle))
		var ring: Array[Vector3] = []
		for k in _COIL_SIDES:
			var a: float = float(k) / _COIL_SIDES * TAU
			ring.append(centre + (out * cos(a) + Vector3.UP * sin(a)) * size.z)
		rings.append(ring)
	for step in _COIL_STEPS:
		for k in _COIL_SIDES:
			var k2: int = (k + 1) % _COIL_SIDES
			var quad: Array[Vector3] = [rings[step][k], rings[step + 1][k], rings[step + 1][k2], rings[step][k2]]
			for corner in [0, 1, 2, 0, 2, 3]:
				st.add_vertex(quad[corner])
	st.generate_normals()
	return st.commit()
