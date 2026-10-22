extends RefCounted
## What a hiding spot looks like (N004 of the v10 nitpick: the six kinds were bare boxes of one flat colour, three in every district). One mesh of parts per kind (part_mesh.gd), resting on y = 0 and inside the box
## its collider keeps (HidingSpot.TYPE_SIZES): surface 0 is the body, in the colour of the kind, surface 1 the accent (doors, lids, glass, tyres, slats, trim). The front of a spot is +z, where the player stands.

const _Parts := preload("res://scripts/art/part_mesh.gd")
const _DUMPSTER_TEXTURE := "res://assets/textures/surfaces/dumpster_metal_512.png"
## The accent colour of each kind.
const ACCENT: Dictionary = {
	"locker": Color(0.28, 0.33, 0.38), "dumpster": Color(0.11, 0.18, 0.14), "car": Color(0.06, 0.07, 0.09),
	"crate": Color(0.20, 0.15, 0.10), "bush": Color(0.14, 0.24, 0.17), "dark_corner": Color(0.12, 0.14, 0.17),
}

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}

static func _p(kind: StringName, size: Vector3, at: Vector3, rot: Vector3 = Vector3.ZERO, accent: bool = false) -> Array:
	return _Parts.part(kind, size, at, rot, 1 if accent else 0)

static func mesh_for(kind: String) -> ArrayMesh:
	if not _meshes.has(kind):
		_meshes[kind] = _Parts.build(_parts(kind))
	return _meshes[kind]

## [body, accent] materials of a kind. The dumpster's body keeps its sheet-metal texture.
static func materials_for(kind: String, body: Color) -> Array[Material]:
	if not _materials.has(kind):
		var pair: Array[Material] = []
		for colour: Color in [body, ACCENT[kind]]:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = colour
			mat.roughness = 0.9
			pair.append(mat)
		if kind == "dumpster":
			var tex := load(_DUMPSTER_TEXTURE) as Texture2D
			if tex != null:
				var metal := pair[0] as StandardMaterial3D
				metal.albedo_texture = tex
				metal.metallic = 0.5
				metal.roughness = 0.55
		_materials[kind] = pair
	return _materials[kind]

static func _parts(kind: String) -> Array:
	var out: Array = []
	match kind:
		"dumpster":
			out = [_p(&"box", Vector3(1.8, 0.8, 0.9), Vector3(0, 0.6, 0)), _p(&"box", Vector3(1.8, 0.2, 1.0), Vector3(0, 1.1, 0), Vector3.ZERO, true)]
			for x in [-0.75, 0.75]:
				out.append(_p(&"cyl", Vector3(0.11, 0.08, 0.11), Vector3(x, 0.11, 0.38), Vector3(0, 0, 90), true))
				out.append(_p(&"box", Vector3(0.1, 0.2, 0.1), Vector3(x, 0.1, -0.38)))
			for x in [-0.6, 0.0, 0.6]:
				out.append(_p(&"box", Vector3(0.07, 0.7, 0.03), Vector3(x, 0.6, 0.465), Vector3.ZERO, true))
		"car":
			out = [_p(&"box", Vector3(4.2, 0.55, 1.9), Vector3(0, 0.6, 0)), _p(&"box", Vector3(2.3, 0.5, 1.7), Vector3(-0.2, 1.125, 0)), _p(&"box", Vector3(2.0, 0.3, 1.76), Vector3(-0.2, 1.15, 0), Vector3.ZERO, true)]
			for x in [-1.35, 1.35]:
				for z in [-0.88, 0.88]:
					out.append(_p(&"cyl", Vector3(0.34, 0.24, 0.34), Vector3(x, 0.34, z), Vector3(90, 0, 0), true))
				out.append(_p(&"box", Vector3(0.1, 0.22, 1.9), Vector3(x * 1.52, 0.45, 0), Vector3.ZERO, true))
		"crate":
			out = [_p(&"box", Vector3(1.1, 1.1, 1.1), Vector3(0, 0.6, 0)), _p(&"box", Vector3(1.2, 0.08, 1.2), Vector3(0, 1.16, 0), Vector3.ZERO, true), _p(&"box", Vector3(1.2, 0.08, 1.2), Vector3(0, 0.04, 0), Vector3.ZERO, true),
				_p(&"box", Vector3(1.45, 0.1, 0.03), Vector3(0, 0.6, 0.585), Vector3(0, 0, 38), true)]
			for x in [-0.54, 0.54]:
				for z in [-0.54, 0.54]:
					out.append(_p(&"box", Vector3(0.12, 1.2, 0.12), Vector3(x, 0.6, z), Vector3.ZERO, true))
		"bush":
			out = [_p(&"sph", Vector3(1.0, 0.9, 0.9), Vector3(0, 0.45, 0)), _p(&"sph", Vector3(0.8, 0.66, 0.8), Vector3(-0.4, 0.33, 0.05)), _p(&"sph", Vector3(0.76, 0.66, 0.76), Vector3(0.42, 0.33, -0.05)),
				_p(&"sph", Vector3(0.7, 0.64, 0.7), Vector3(0, 0.78, 0)), _p(&"sph", Vector3(0.6, 0.5, 0.5), Vector3(0.2, 0.55, 0.2), Vector3.ZERO, true), _p(&"sph", Vector3(0.5, 0.4, 0.4), Vector3(-0.25, 0.6, 0.15), Vector3.ZERO, true)]
		"dark_corner":
			out = [_p(&"box", Vector3(1.4, 2.1, 0.3), Vector3(0, 1.05, -0.1)), _p(&"box", Vector3(0.1, 2.2, 0.5), Vector3(-0.75, 1.1, 0), Vector3.ZERO, true), _p(&"box", Vector3(0.1, 2.2, 0.5), Vector3(0.75, 1.1, 0), Vector3.ZERO, true),
				_p(&"box", Vector3(1.6, 0.1, 0.5), Vector3(0, 2.15, 0), Vector3.ZERO, true)]
		_:
			out = [_p(&"box", Vector3(0.9, 1.9, 0.64), Vector3(0, 1.0, 0)), _p(&"box", Vector3(0.9, 0.05, 0.7), Vector3(0, 1.975, 0), Vector3.ZERO, true), _p(&"box", Vector3(0.8, 1.76, 0.05), Vector3(0, 0.98, 0.325), Vector3.ZERO, true),
				_p(&"box", Vector3(0.05, 0.22, 0.04), Vector3(0.3, 0.95, 0.33))]
			for i in 3:
				out.append(_p(&"box", Vector3(0.5, 0.035, 0.03), Vector3(0, 1.62 - 0.1 * i, 0.335)))
			for x in [-0.35, 0.35]:
				for z in [-0.2, 0.2]:
					out.append(_p(&"box", Vector3(0.1, 0.05, 0.1), Vector3(x, 0.025, z), Vector3.ZERO, true))
	return out
