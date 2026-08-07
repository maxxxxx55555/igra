extends Node
## Placeholder prop mesh generator: low-poly procedural props via SurfaceTool.
## Saves binary ArrayMesh .res to assets/mesh/ (Godot cannot export .obj/.glb from script).
## Run: godot --headless --path <proj> res://scenes/tools/gen_meshes_scene.tscn

const OUT: String = "res://assets/mesh/"
const UVS: float = 1.0    ## world metres -> UV units

var _st: SurfaceTool
var _tris: int = 0
var _wind: float = -1.0   ## sign of cross(b-a, c-a) . normal for a front face

func _ready() -> void:
	_probe_winding()
	var err := DirAccess.make_dir_recursive_absolute(OUT)
	if err != OK and err != ERR_ALREADY_EXISTS:
		push_warning("[mesh] mkdir %s -> %d" % [OUT, err])
	var made: int = 0
	made += _streetlight_pole()
	made += _bench()
	made += _house_small()
	made += _trash_can()
	made += _hydrant()
	print("[mesh] DONE generated=", made)
	_verify()
	get_tree().quit()

## Reload each file straight from disk (cache bypassed) to prove it is readable.
func _verify() -> void:
	for base in ["mesh_streetlight_pole", "mesh_bench", "mesh_house_small",
			"mesh_trash_can", "mesh_hydrant"]:
		var path: String = OUT + base + ".res"
		var m: ArrayMesh = ResourceLoader.load(path, "ArrayMesh", ResourceLoader.CACHE_MODE_IGNORE)
		if m == null:
			printerr("[mesh] verify FAIL ", path)
			continue
		var arr: Array = m.surface_get_arrays(0)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var us: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		var bad: int = 0
		for k in ix.size() / 3:
			var a: int = ix[k * 3]
			var b: int = ix[k * 3 + 1]
			var c: int = ix[k * 3 + 2]
			var cr: Vector3 = (vs[b] - vs[a]).cross(vs[c] - vs[a])
			if signf(cr.dot(ns[a] + ns[b] + ns[c])) != _wind:
				bad += 1
		print("[mesh] verify ", base, "  surfaces=", m.get_surface_count(),
				" verts=", vs.size(), " idx_tris=", ix.size() / 3,
				" normals=", ns.size(), " uvs=", us.size(), " bad_winding=", bad)

# ---------------- framework ----------------

## Godot front faces are wound clockwise as seen from outside; probe a BoxMesh
## instead of trusting that, so winding stays correct if the convention differs.
func _probe_winding() -> void:
	var arr: Array = BoxMesh.new().get_mesh_arrays()
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var i0: int = ix[0] if ix.size() >= 3 else 0
	var i1: int = ix[1] if ix.size() >= 3 else 1
	var i2: int = ix[2] if ix.size() >= 3 else 2
	var cr: Vector3 = (vs[i1] - vs[i0]).cross(vs[i2] - vs[i0])
	var s: float = signf(cr.dot(ns[i0]))
	if s != 0.0:
		_wind = s
	print("[mesh] winding probe: cross.normal sign = ", _wind)

func _begin() -> void:
	_st = SurfaceTool.new()
	_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_tris = 0

func _commit(base: String) -> int:
	_st.index()
	_st.generate_tangents()
	var mesh: ArrayMesh = _st.commit()
	mesh.resource_name = base
	var path: String = OUT + base + ".res"
	var err := ResourceSaver.save(mesh, path)
	var box: AABB = mesh.get_aabb()
	print("[mesh] ", "ok  " if err == OK else "FAIL", path,
			"  tris=", _tris, "  size=", box.size.snappedf(0.01), "  origin=", box.position.snappedf(0.01))
	_st = null
	return 1 if err == OK else 0

## One triangle; winding is flipped automatically to match the intended normals.
func _tri(pa: Vector3, pb: Vector3, pc: Vector3,
		na: Vector3, nb: Vector3, nc: Vector3,
		ua: Vector2, ub: Vector2, uc: Vector2) -> void:
	var cr: Vector3 = (pb - pa).cross(pc - pa)
	if cr.length_squared() < 1e-12:
		return
	if signf(cr.dot(na + nb + nc)) != _wind:
		var tp: Vector3 = pb; pb = pc; pc = tp
		var tn: Vector3 = nb; nb = nc; nc = tn
		var tu: Vector2 = ub; ub = uc; uc = tu
	_st.set_normal(na); _st.set_uv(ua); _st.add_vertex(pa)
	_st.set_normal(nb); _st.set_uv(ub); _st.add_vertex(pb)
	_st.set_normal(nc); _st.set_uv(uc); _st.add_vertex(pc)
	_tris += 1

## Quad from a perimeter cycle, explicit per-vertex normals and UVs.
func _quad_n(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3,
		n0: Vector3, n1: Vector3, n2: Vector3, n3: Vector3,
		u0: Vector2, u1: Vector2, u2: Vector2, u3: Vector2) -> void:
	_tri(p0, p1, p2, n0, n1, n2, u0, u1, u2)
	_tri(p0, p2, p3, n0, n2, n3, u0, u2, u3)

## Planar UV projection onto the face plane, keeps texel density uniform.
func _puv(p: Vector3, n: Vector3) -> Vector2:
	var up: Vector3 = Vector3.UP if absf(n.y) < 0.99 else Vector3.FORWARD
	var ax: Vector3 = up.cross(n).normalized()
	var ay: Vector3 = n.cross(ax).normalized()
	return Vector2(p.dot(ax), -p.dot(ay)) * UVS

## Flat quad with a single outward normal and projected UVs.
func _quad(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, n: Vector3) -> void:
	_quad_n(p0, p1, p2, p3, n, n, n, n,
			_puv(p0, n), _puv(p1, n), _puv(p2, n), _puv(p3, n))

## Flat triangle with a single outward normal and projected UVs.
func _tri_flat(p0: Vector3, p1: Vector3, p2: Vector3, n: Vector3) -> void:
	_tri(p0, p1, p2, n, n, n, _puv(p0, n), _puv(p1, n), _puv(p2, n))

## Axis-aligned box, 12 tris.
func _box(c: Vector3, s: Vector3) -> void:
	var h: Vector3 = s * 0.5
	for axis in 3:
		for dir in [1.0, -1.0]:
			var n: Vector3 = Vector3.ZERO
			n[axis] = dir
			var a1: int = (axis + 1) % 3
			var a2: int = (axis + 2) % 3
			var pts: Array[Vector3] = []
			for k in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
				var p: Vector3 = c
				p[axis] += h[axis] * dir
				p[a1] += h[a1] * k.x
				p[a2] += h[a2] * k.y
				pts.append(p)
			_quad(pts[0], pts[1], pts[2], pts[3], n)

## Cylinder / cone / frustum along an arbitrary axis, smooth side normals.
func _tube(base: Vector3, axis: Vector3, r0: float, r1: float, length: float,
		segs: int, cap0: bool = false, cap1: bool = false) -> void:
	var a: Vector3 = axis.normalized()
	var seed: Vector3 = Vector3.UP if absf(a.y) < 0.99 else Vector3.RIGHT
	var t: Vector3 = seed.cross(a).normalized()
	var b: Vector3 = a.cross(t).normalized()
	var top: Vector3 = base + a * length
	var slope: float = (r0 - r1) / maxf(length, 0.0001)
	for i in segs:
		var th0: float = TAU * float(i) / float(segs)
		var th1: float = TAU * float(i + 1) / float(segs)
		var d0: Vector3 = t * cos(th0) + b * sin(th0)
		var d1: Vector3 = t * cos(th1) + b * sin(th1)
		var n0: Vector3 = (d0 + a * slope).normalized()
		var n1: Vector3 = (d1 + a * slope).normalized()
		var u0: float = float(i) / float(segs)
		var u1: float = float(i + 1) / float(segs)
		var p00: Vector3 = base + d0 * r0
		var p10: Vector3 = base + d1 * r0
		var p11: Vector3 = top + d1 * r1
		var p01: Vector3 = top + d0 * r1
		if r0 <= 0.0001:
			_tri(p01, p11, top, n0, n1, (n0 + n1).normalized(),
					Vector2(u0, 1), Vector2(u1, 1), Vector2((u0 + u1) * 0.5, 0))
		elif r1 <= 0.0001:
			_tri(p00, p10, top, n0, n1, (n0 + n1).normalized(),
					Vector2(u0, 0), Vector2(u1, 0), Vector2((u0 + u1) * 0.5, 1))
		else:
			_quad_n(p00, p10, p11, p01, n0, n1, n1, n0,
					Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, 1), Vector2(u0, 1))
	if cap0 and r0 > 0.0001:
		_disc(base, -a, t, b, r0, segs)
	if cap1 and r1 > 0.0001:
		_disc(top, a, t, b, r1, segs)

## Flat disc fan used as a tube cap.
func _disc(c: Vector3, n: Vector3, t: Vector3, b: Vector3, r: float, segs: int) -> void:
	for i in segs:
		var th0: float = TAU * float(i) / float(segs)
		var th1: float = TAU * float(i + 1) / float(segs)
		var p0: Vector3 = c + (t * cos(th0) + b * sin(th0)) * r
		var p1: Vector3 = c + (t * cos(th1) + b * sin(th1)) * r
		_tri_flat(c, p0, p1, n)

## Flat annulus ring between two radii (rim / flange tops).
func _ring(c: Vector3, n: Vector3, ri: float, ro: float, segs: int) -> void:
	var t: Vector3 = Vector3.RIGHT
	var b: Vector3 = Vector3.BACK
	for i in segs:
		var th0: float = TAU * float(i) / float(segs)
		var th1: float = TAU * float(i + 1) / float(segs)
		var d0: Vector3 = t * cos(th0) + b * sin(th0)
		var d1: Vector3 = t * cos(th1) + b * sin(th1)
		_quad(c + d0 * ri, c + d1 * ri, c + d1 * ro, c + d0 * ro, n)

## Half-ellipsoid cap sitting on a base circle, smooth normals.
func _dome(c: Vector3, r: float, h: float, segs: int, rings: int) -> void:
	for j in rings:
		var a0: float = PI * 0.5 * float(j) / float(rings)
		var a1: float = PI * 0.5 * float(j + 1) / float(rings)
		var r0: float = r * cos(a0)
		var r1: float = r * cos(a1)
		var y0: float = h * sin(a0)
		var y1: float = h * sin(a1)
		for i in segs:
			var t0: float = TAU * float(i) / float(segs)
			var t1: float = TAU * float(i + 1) / float(segs)
			var d0: Vector3 = Vector3(cos(t0), 0, sin(t0))
			var d1: Vector3 = Vector3(cos(t1), 0, sin(t1))
			var p00: Vector3 = c + d0 * r0 + Vector3.UP * y0
			var p10: Vector3 = c + d1 * r0 + Vector3.UP * y0
			var p11: Vector3 = c + d1 * r1 + Vector3.UP * y1
			var p01: Vector3 = c + d0 * r1 + Vector3.UP * y1
			var n00: Vector3 = _ellip_n(d0, r0, y0, r, h)
			var n10: Vector3 = _ellip_n(d1, r0, y0, r, h)
			var n11: Vector3 = _ellip_n(d1, r1, y1, r, h)
			var n01: Vector3 = _ellip_n(d0, r1, y1, r, h)
			var u0: float = float(i) / float(segs)
			var u1: float = float(i + 1) / float(segs)
			var v0: float = float(j) / float(rings)
			var v1: float = float(j + 1) / float(rings)
			if r1 <= 0.0001:
				_tri(p00, p10, p01, n00, n10, Vector3.UP,
						Vector2(u0, v0), Vector2(u1, v0), Vector2((u0 + u1) * 0.5, v1))
			else:
				_quad_n(p00, p10, p11, p01, n00, n10, n11, n01,
						Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1))

func _ellip_n(dir: Vector3, rad: float, y: float, r: float, h: float) -> Vector3:
	var n: Vector3 = dir * (rad / maxf(r * r, 0.0001)) + Vector3.UP * (y / maxf(h * h, 0.0001))
	return n.normalized() if n.length_squared() > 1e-9 else Vector3.UP

## Slanted slab: quad extruded by `t` opposite its normal (roof planes).
func _slab(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, n: Vector3, t: float) -> void:
	var o: Vector3 = -n * t
	var q0: Vector3 = p0 + o
	var q1: Vector3 = p1 + o
	var q2: Vector3 = p2 + o
	var q3: Vector3 = p3 + o
	_quad(p0, p1, p2, p3, n)
	_quad(q0, q1, q2, q3, -n)
	_quad(p0, p1, q1, q0, (p1 - p0).cross(n).normalized())
	_quad(p1, p2, q2, q1, (p2 - p1).cross(n).normalized())
	_quad(p2, p3, q3, q2, (p3 - p2).cross(n).normalized())
	_quad(p3, p0, q0, q3, (p0 - p3).cross(n).normalized())

## Wall in the XY plane at `z`, split into quads around rectangular holes.
func _wall_holes(z: float, nz: float, x0: float, x1: float, y0: float, y1: float,
		holes: Array[Rect2]) -> void:
	var n: Vector3 = Vector3(0, 0, nz)
	var ys: Array[float] = [y0, y1]
	for h in holes:
		if not ys.has(h.position.y):
			ys.append(h.position.y)
		if not ys.has(h.end.y):
			ys.append(h.end.y)
	ys.sort()
	for k in ys.size() - 1:
		var ya: float = ys[k]
		var yb: float = ys[k + 1]
		if yb - ya < 0.001:
			continue
		var spans: Array[Vector2] = []
		for h in holes:
			if h.position.y <= ya + 0.001 and h.end.y >= yb - 0.001:
				spans.append(Vector2(h.position.x, h.end.x))
		spans.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
		var cur: float = x0
		for s in spans:
			if s.x - cur > 0.001:
				_wall_quad(z, n, cur, s.x, ya, yb)
			cur = maxf(cur, s.y)
		if x1 - cur > 0.001:
			_wall_quad(z, n, cur, x1, ya, yb)

func _wall_quad(z: float, n: Vector3, xa: float, xb: float, ya: float, yb: float) -> void:
	_quad(Vector3(xa, ya, z), Vector3(xb, ya, z), Vector3(xb, yb, z), Vector3(xa, yb, z), n)

## Inset opening: back face + jambs, normals face out of the cavity.
func _recess(xa: float, xb: float, ya: float, yb: float, z: float, depth: float,
		floor_face: bool) -> void:
	var zi: float = z - depth
	_quad(Vector3(xa, ya, zi), Vector3(xb, ya, zi), Vector3(xb, yb, zi), Vector3(xa, yb, zi),
			Vector3(0, 0, 1))
	_quad(Vector3(xa, ya, zi), Vector3(xa, yb, zi), Vector3(xa, yb, z), Vector3(xa, ya, z),
			Vector3(1, 0, 0))
	_quad(Vector3(xb, ya, zi), Vector3(xb, yb, zi), Vector3(xb, yb, z), Vector3(xb, ya, z),
			Vector3(-1, 0, 0))
	_quad(Vector3(xa, yb, zi), Vector3(xb, yb, zi), Vector3(xb, yb, z), Vector3(xa, yb, z),
			Vector3(0, -1, 0))
	if floor_face:
		_quad(Vector3(xa, ya, zi), Vector3(xb, ya, zi), Vector3(xb, ya, z), Vector3(xa, ya, z),
				Vector3(0, 1, 0))

# ---------------- props ----------------

## Street lamp: plinth + tapered 4.5 m pole + 1.2 m arm + lamp housing.
## Replaces the BoxMesh(0.1, 2.5, 0.1) placeholder. Origin at the base, y = 0.
func _streetlight_pole() -> int:
	_begin()
	_box(Vector3(0, 0.06, 0), Vector3(0.36, 0.12, 0.36))            # plinth
	_box(Vector3(0, 0.20, 0), Vector3(0.26, 0.16, 0.26))            # collar
	_tube(Vector3(0, 0.28, 0), Vector3.UP, 0.10, 0.055, 4.22, 8, false, true)
	_box(Vector3(0.60, 4.46, 0), Vector3(1.26, 0.09, 0.09))         # arm
	_box(Vector3(1.16, 4.34, 0), Vector3(0.34, 0.16, 0.22))         # lamp housing
	_box(Vector3(1.16, 4.24, 0), Vector3(0.26, 0.05, 0.16))         # lens
	return _commit("mesh_streetlight_pole")

## Park bench: slatted 1.8 x 0.45 seat, backrest, two leg frames. Origin at ground centre.
func _bench() -> int:
	_begin()
	for z in [-0.155, 0.0, 0.155]:                                  # seat slats
		_box(Vector3(0, 0.44, z), Vector3(1.80, 0.05, 0.13))
	for y in [0.66, 0.82]:                                          # backrest slats
		_box(Vector3(0, y, -0.20), Vector3(1.80, 0.13, 0.05))
	for sx in [-1.0, 1.0]:
		var x: float = 0.78 * sx
		_box(Vector3(x, 0.21, -0.17), Vector3(0.06, 0.42, 0.06))    # legs
		_box(Vector3(x, 0.21, 0.17), Vector3(0.06, 0.42, 0.06))
		_box(Vector3(x, 0.415, 0), Vector3(0.07, 0.05, 0.46))       # seat rail
		_box(Vector3(x, 0.66, -0.20), Vector3(0.06, 0.44, 0.06))    # back post
	return _commit("mesh_bench")

## Small house: 6 x 4 x 5 body, gable roof, one door and two window recesses.
## Origin at ground centre.
func _house_small() -> int:
	_begin()
	var hx: float = 3.0
	var hz: float = 2.5
	var wy: float = 4.0
	var ridge: float = 5.2
	var door := Rect2(-0.55, 0.0, 1.10, 2.10)
	var win_l := Rect2(-2.35, 1.10, 1.00, 1.00)
	var win_r := Rect2(1.35, 1.10, 1.00, 1.00)
	var holes: Array[Rect2] = [door, win_l, win_r]
	_wall_holes(hz, 1.0, -hx, hx, 0.0, wy, holes)                   # front (+Z)
	_quad(Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz), Vector3(hx, wy, -hz),
			Vector3(-hx, wy, -hz), Vector3(0, 0, -1))               # back
	_quad(Vector3(-hx, 0, -hz), Vector3(-hx, 0, hz), Vector3(-hx, wy, hz),
			Vector3(-hx, wy, -hz), Vector3(-1, 0, 0))               # left
	_quad(Vector3(hx, 0, -hz), Vector3(hx, 0, hz), Vector3(hx, wy, hz),
			Vector3(hx, wy, -hz), Vector3(1, 0, 0))                 # right
	_quad(Vector3(-hx, wy, -hz), Vector3(hx, wy, -hz), Vector3(hx, wy, hz),
			Vector3(-hx, wy, hz), Vector3(0, 1, 0))                 # ceiling slab
	_recess(door.position.x, door.end.x, door.position.y, door.end.y, hz, 0.14, false)
	_recess(win_l.position.x, win_l.end.x, win_l.position.y, win_l.end.y, hz, 0.12, true)
	_recess(win_r.position.x, win_r.end.x, win_r.position.y, win_r.end.y, hz, 0.12, true)
	var ox: float = hx + 0.20                                       # roof overhang
	var oz: float = hz + 0.20
	var eave: float = wy - 0.05
	var nf: Vector3 = Vector3(0, hz + 0.20, ridge - eave).normalized()
	_slab(Vector3(-ox, eave, oz), Vector3(ox, eave, oz), Vector3(ox, ridge, 0),
			Vector3(-ox, ridge, 0), nf, 0.10)
	var nb: Vector3 = Vector3(0, hz + 0.20, -(ridge - eave)).normalized()
	_slab(Vector3(-ox, eave, -oz), Vector3(ox, eave, -oz), Vector3(ox, ridge, 0),
			Vector3(-ox, ridge, 0), nb, 0.10)
	_tri_flat(Vector3(hx, wy, -hz), Vector3(hx, wy, hz), Vector3(hx, ridge, 0),
			Vector3(1, 0, 0))                                       # gables
	_tri_flat(Vector3(-hx, wy, -hz), Vector3(-hx, wy, hz), Vector3(-hx, ridge, 0),
			Vector3(-1, 0, 0))
	_box(Vector3(0, ridge + 0.06, 0), Vector3(6.5, 0.10, 0.20))     # ridge cap
	return _commit("mesh_house_small")

## Trash can: 12-segment tapered body, rim, domed lid. ~1.0 m tall.
func _trash_can() -> int:
	_begin()
	_tube(Vector3.ZERO, Vector3.UP, 0.26, 0.31, 0.80, 12, true, false)
	_tube(Vector3(0, 0.78, 0), Vector3.UP, 0.335, 0.335, 0.08, 12)  # rim band
	_ring(Vector3(0, 0.78, 0), Vector3.DOWN, 0.308, 0.335, 12)
	_ring(Vector3(0, 0.86, 0), Vector3.UP, 0.31, 0.335, 12)
	_dome(Vector3(0, 0.86, 0), 0.31, 0.14, 12, 2)                   # lid
	return _commit("mesh_trash_can")

## Fire hydrant: flange, barrel, bonnet dome, two side nozzles. ~0.75 m tall.
func _hydrant() -> int:
	_begin()
	_tube(Vector3.ZERO, Vector3.UP, 0.19, 0.17, 0.07, 12, true, false)   # base flange
	_tube(Vector3(0, 0.07, 0), Vector3.UP, 0.125, 0.115, 0.43, 12)       # barrel
	_tube(Vector3(0, 0.50, 0), Vector3.UP, 0.155, 0.105, 0.11, 12)       # shoulder
	_ring(Vector3(0, 0.50, 0), Vector3.DOWN, 0.115, 0.155, 12)
	_dome(Vector3(0, 0.61, 0), 0.105, 0.10, 12, 2)                       # bonnet
	_tube(Vector3(0, 0.71, 0), Vector3.UP, 0.038, 0.030, 0.04, 8, false, true)
	for sx in [-1.0, 1.0]:                                               # side nozzles
		var ax: Vector3 = Vector3(sx, 0, 0)
		_tube(Vector3(0.09 * sx, 0.30, 0), ax, 0.055, 0.050, 0.07, 8, false, false)
		_tube(Vector3(0.16 * sx, 0.30, 0), ax, 0.062, 0.062, 0.03, 8, false, true)
	return _commit("mesh_hydrant")
