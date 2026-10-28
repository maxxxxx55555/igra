extends RefCounted
## The shapes of the twelve monsters (monster_looks.gd) in place of boxes, cylinders and spheres: every mesh is a stack of elliptical rings. A torso has shoulders, a waist and a forward hunch, a skull a jaw and two dark
## sockets (a vertex colour: the material multiplies it into the albedo, so a hit flash keeps them), a limb an elbow or a knee and a talon, a fist or a foot, the body of a quadruped runs along the spine. Each mesh keeps the
## envelope of the primitive it replaces (same height, width and depth, same pivot), so the rig, the hitboxes and the checks that read the node names are unchanged. The optional "form" row of a look tunes it:
## shoulder, pelvis, depth, waist, belly, hunch, plates (torso); loin, chest, abdomen, arch (quadruped); jaw, eye, boxy (head); arm_bend, leg_bend, claw, fist (limbs); cloak, hem (a funnel body).

const SIDES: int = 10
const LIMB_SIDES: int = 8
const SOCKET: float = 0.1

## spec is a row of monster_looks.gd (shape, a, b, c, ...): "cyl" and "box" are bodies, "sph" and "box" heads, "arm" and "leg" limbs (thickness, length). A body is told from a head by `head`.
static func build(spec: Array, form: Dictionary, head: bool) -> ArrayMesh:
	var a: float = spec[1]
	var b: float = spec[2]
	var c: float = spec[3]
	match String(spec[0]):
		"arm":
			return _limb(false, a, b, form)
		"leg":
			return _limb(true, a, b, form)
		"sph":
			return _skull(a * 0.9, a, a * 2.0, form, 0.0)
		"cyl":
			return _funnel(a, b, c, form) if form.has("cloak") else _torso(a, b, a * float(form.get("depth", 0.7)), b * float(form.get("depth", 0.7)), c, form)
	if head:
		return _muzzle(a, b, c, form) if c > b * 1.15 and c > a else _skull(a * 0.5, c * 0.5, b, form, 1.0)
	if c > b * 1.3 and c > a * 1.2:
		return _quad(a, b, c, form)
	var pelvis: float = form.get("pelvis", 0.62)
	return _torso(a * 0.5, a * 0.5 * pelvis, c * 0.5, c * 0.45, b, form)

static func _bump(t: float, at: float, width: float) -> float:
	return exp(-pow((t - at) / width, 2.0))

## Humanoid torso, hips (t = 0) to shoulders (t = 1), with a neck ring on top that ends inside the head. tx and bx are the half widths of the shoulders and the hips, tf and bf the half depths.
static func _torso(tx: float, bx: float, tf: float, bf: float, h: float, form: Dictionary) -> ArrayMesh:
	var shoulder: float = form.get("shoulder", 1.2)
	var waist: float = form.get("waist", 0.85)
	var belly: float = form.get("belly", 0.0)
	var hunch: float = form.get("hunch", 0.0)
	var plates: float = form.get("plates", 0.0)
	var rings: Array = []
	for i in 9:
		var t: float = i / 7.0
		var pinch: float = 1.0 - (1.0 - waist) * _bump(t, 0.28, 0.22)
		var fat: float = 1.0 + belly * _bump(t, 0.4, 0.22)
		var wx: float = lerpf(bx, tx, t) * (1.0 + (shoulder - 1.0) * pow(minf(t, 1.0), 2.5)) * pinch * fat * (1.0 + 0.18 * plates * _bump(t, 0.88, 0.09))
		var wf: float = lerpf(bf, tf, t) * (1.0 - (1.0 - waist) * 0.5 * _bump(t, 0.28, 0.22)) * fat
		if i == 8:
			t = 1.07
			wx = tx * 0.42
			wf = tf * 0.5
		rings.append([Vector3(0.0, (t - 0.5) * h, -hunch * t * t), wx, wf, 1.0, 0.0])
	return _loft(rings, SIDES)

## A cone that ends at the ground in a ragged hem and rises into a hood: the shadow.
static func _funnel(top: float, bottom: float, h: float, form: Dictionary) -> ArrayMesh:
	var hem: float = form.get("hem", 0.15)
	var rings: Array = []
	for i in 8:
		var t: float = i / 7.0
		var r: float = lerpf(bottom, top, pow(t, 0.6)) + 0.1 * _bump(t, 0.9, 0.09)
		rings.append([Vector3(0.0, (t - 0.5) * h, 0.0), r, r * 0.85, 1.0 - 0.3 * t, hem * (1.0 - t * 2.5) if t < 0.4 else 0.0])
	rings.append([Vector3(0.0, 0.58 * h, 0.0), top * 1.1, top * 1.1, 0.8, 0.0])
	return _loft(rings, SIDES + 2)

## A skull with a brow, a jaw pushed forward and sockets in front. rx and rf are the half width and the half depth, h the height; boxy squares the dome.
static func _skull(rx: float, rf: float, h: float, form: Dictionary, boxy: float) -> ArrayMesh:
	var jaw: float = form.get("jaw", 0.25)
	var rings: Array = []
	for i in 8:
		var t: float = i / 7.0
		var u: float = t * 2.0 - 1.0
		var s: float = maxf(pow(maxf(1.0 - u * u, 0.0), 0.5 - 0.3 * boxy), 0.3)
		var chin: float = clampf((0.45 - t) / 0.45, 0.0, 1.0)
		rings.append([Vector3(0.0, (t - 0.5) * h, -jaw * rf * chin), rx * s * (1.0 - 0.28 * chin), rf * s * (1.0 + 0.12 * _bump(t, 0.62, 0.15)), 1.0, 0.0])
	var one: bool = form.has("eye")
	var blind: bool = form.has("faceless")
	var shade := func(p: Vector3) -> float:
		if blind or p.z > -rf * 0.4:
			return 1.0
		var low: float = h * (-0.12 if one else 0.0)
		var hole: bool = (absf(p.x) < rx * 0.32 and p.y > low and p.y < h * 0.3) if one else (absf(p.x) > rx * 0.18 and absf(p.x) < rx * 0.7 and p.y > h * 0.0 and p.y < h * 0.22)
		return SOCKET if hole or (p.y < -h * 0.2 and absf(p.x) < rx * 0.3) else 1.0
	return _loft(rings, SIDES, shade)

## A long muzzle, back of the skull to the tip of the nose along -Z, for the hound and the crawler.
static func _muzzle(w: float, h: float, d: float, form: Dictionary) -> ArrayMesh:
	var wide := PackedFloat32Array([1.0, 1.0, 0.85, 0.7, 0.58, 0.5])
	var tall := PackedFloat32Array([1.0, 1.1, 0.85, 0.65, 0.58, 0.5])
	var rise := PackedFloat32Array([0.02, 0.05, 0.0, -0.05, -0.07, -0.08])
	var rings: Array = []
	for i in 6:
		var t: float = i / 5.0
		rings.append([Vector3(0.0, rise[i] * h, d * 0.5 - t * d), w * 0.5 * wide[i], h * 0.5 * tall[i], 1.0, 0.0])
	var shade := func(p: Vector3) -> float:
		return SOCKET if absf(p.x) > w * 0.28 and p.y > 0.0 and p.z < d * 0.2 and p.z > -d * 0.1 else 1.0
	return _loft(rings, SIDES, shade)

## A quadruped's body along the spine, rear (z = +d / 2) to chest: a narrow loin between a haunch and a chest, the spine arched.
static func _quad(w: float, h: float, d: float, form: Dictionary) -> ArrayMesh:
	var loin: float = form.get("loin", 0.65)
	var chest: float = form.get("chest", 1.0)
	var abdomen: float = form.get("abdomen", 0.8)
	var arch: float = form.get("arch", 0.0) * h
	var rings: Array = []
	for i in 10:
		var t: float = (i - 1) / 8.0
		var swell: float = maxf(smoothstep(0.4, 0.8, t) * chest, (1.0 - smoothstep(0.12, 0.55, t)) * abdomen)
		var f: float = lerpf(loin, 1.0, minf(swell, 1.0)) * maxf(swell, 1.0)
		if i == 0:  # the rear ends in a rounded tail end, not a flat cap
			t = -0.08
			f *= 0.45
		rings.append([Vector3(0.0, arch * sin(PI * maxf(t, 0.0)), d * 0.5 - t * d), w * 0.5 * f, h * 0.5 * f, 1.0, 0.0])
	return _loft(rings, SIDES)

## An arm hangs from its shoulder (the top of the mesh) to the talons or the fist; a leg runs hip to foot with a knee forward and a hock back. thickness is the width at the shoulder or hip, length the whole limb.
static func _limb(leg: bool, thickness: float, length: float, form: Dictionary) -> ArrayMesh:
	var r: float = thickness * 0.5
	var bend: float = float(form.get("leg_bend" if leg else "arm_bend", 0.0))
	var claw: float = float(form.get("claw", 0.0))
	var fist: float = float(form.get("fist", 1.0))
	# s along the limb from the joint, radius as a share of r, and how far the centre moves forward (-z) in lengths
	var rows: Array = [[0.0, 0.85, 0.0], [0.16, 1.12, -0.02], [0.38, 0.88, -0.14 * bend], [0.5, 0.62, -0.2 * bend], [0.64, 0.8, -0.18 * bend], [0.9, 0.42, 0.12 * bend if leg else -0.1 * bend], [1.0, 0.62 * fist, 0.0]]
	var rings: Array = []
	for row in rows:
		var s: float = row[0]
		rings.append([Vector3(0.0, length * (0.5 - s), length * row[2] * 0.5), r * row[1], r * row[1] * (1.1 if not leg else 1.0), 1.0, 0.0])
	if leg:
		var foot: Array = rings[rings.size() - 1]
		foot[1] = r * 0.8
		foot[2] = r * 2.0
		foot[0] = Vector3(0.0, -length * 0.5, -r * 1.0)
	else:
		rings.append([Vector3(0.0, -length * 0.5 - claw * length * 0.4, -claw * length), r * 0.15, r * 0.15, 1.0, 0.0])
	return _loft(rings, LIMB_SIDES)

## Rings -> a closed mesh with smooth normals and a vertex colour per vertex. A ring is [centre, half width, half depth, shade, ragged]; its frame follows the path (width across x, depth along the other axis).
## Triangles are wound clockwise from outside, as the engine wants them.
static func _loft(rings: Array, sides: int, shade: Callable = Callable()) -> ArrayMesh:
	var n: int = rings.size()
	var verts := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	for i in n:
		var ring: Array = rings[i]
		var c: Vector3 = ring[0]
		var t: Vector3 = ((rings[mini(i + 1, n - 1)][0] as Vector3) - (rings[maxi(i - 1, 0)][0] as Vector3)).normalized()
		var s: Vector3 = (Vector3.RIGHT - t * t.x).normalized()
		var f: Vector3 = s.cross(t)
		for k in sides:
			var a: float = TAU * k / sides
			var jag: float = float(ring[4]) * (1.0 if k % 2 == 0 else -1.0)
			var p: Vector3 = c + (s * cos(a) * float(ring[1]) + f * sin(a) * float(ring[2])) * (1.0 + jag)
			p.y += jag * 0.5
			verts.append(p)
			var v: float = float(ring[3]) * (float(shade.call(p)) if shade.is_valid() else 1.0)
			cols.append(Color(v, v, v))
	for i in n - 1:
		for k in sides:
			var k1: int = (k + 1) % sides
			var a: int = i * sides + k
			var b: int = i * sides + k1
			var c: int = (i + 1) * sides + k1
			var d: int = (i + 1) * sides + k
			idx.append_array([a, b, c, a, c, d])
	for cap in 2:
		var ring: Array = rings[0] if cap == 0 else rings[n - 1]
		var base: int = 0 if cap == 0 else (n - 1) * sides
		var v: float = float(ring[3])
		verts.append(ring[0])
		cols.append(Color(v, v, v))
		var mid: int = verts.size() - 1
		for k in sides:
			var k1: int = (k + 1) % sides
			if cap == 1:
				idx.append_array([mid, base + k, base + k1])
			else:
				idx.append_array([mid, base + k1, base + k])
	var normals := PackedVector3Array()
	normals.resize(verts.size())
	for j in range(0, idx.size(), 3):
		var face: Vector3 = (verts[idx[j + 2]] - verts[idx[j]]).cross(verts[idx[j + 1]] - verts[idx[j]])
		for m in 3:
			normals[idx[j + m]] += face
	for j in normals.size():
		normals[j] = normals[j].normalized()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
