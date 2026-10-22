extends RefCounted
## What six props of the world look like (v10 N051, N010 and the owner's first complaint, no bare box left): the secret, the workbench, the bed, the power switch of a district, the cable box and the generator. One mesh of
## parts per kind (part_mesh.gd) resting on y = 0, over the box of the collider the prop keeps (LOOK[kind][0]); surface 0 is the body, surface 1 the accent (the part that glows, when the prop glows). The props that glow set the
## energy of the material dress() returns from their own state: the switch with the stage of its district, the generator while it runs.

const _Parts := preload("res://scripts/art/part_mesh.gd")
## Per kind: [size of the collider, colour of the body, colour of the accent, emission of the accent (-1: none)].
const LOOK: Dictionary = {
	"secret": [Vector3(0.2, 0.15, 0.2), Color(0.30, 0.33, 0.34), Color(0.541, 0.62, 0.639), 0.9],
	"workbench": [Vector3(1.4, 1.0, 0.8), Color(0.35, 0.28, 0.20), Color(0.56, 0.58, 0.61), -1.0],
	"bed": [Vector3(2.0, 0.5, 1.0), Color(0.27, 0.22, 0.20), Color(0.55, 0.52, 0.46), -1.0],
	"switch": [Vector3(0.8, 1.6, 0.2), Color(0.15, 0.15, 0.18), Color(1.0, 0.7, 0.3), 0.4],
	"cable_box": [Vector3(0.6, 1.0, 0.4), Color(0.16, 0.16, 0.20), Color(0.788, 0.635, 0.29), 0.5],
	"generator": [Vector3(1.0, 1.2, 0.8), Color(0.18, 0.17, 0.15), Color(0.706, 0.271, 0.184), 0.0],
}

static var _meshes: Dictionary = {}

static func _p(kind: StringName, size: Vector3, at: Vector3, rot: Vector3 = Vector3.ZERO, accent: bool = false) -> Array:
	return _Parts.part(kind, size, at, rot, 1 if accent else 0)

static func mesh_for(kind: String) -> ArrayMesh:
	if not _meshes.has(kind):
		_meshes[kind] = _Parts.build(_parts(kind))
	return _meshes[kind]

## Puts the look of `kind` on `piece`: the mesh and its two materials (one pair for each prop, the glow of a prop is its own). Returns the accent material.
static func dress(piece: MeshInstance3D, kind: String) -> StandardMaterial3D:
	var look: Array = LOOK[kind]
	var mesh := mesh_for(kind)
	piece.mesh = mesh
	var accent: StandardMaterial3D = null
	for s in mesh.get_surface_count():
		var mat := StandardMaterial3D.new()
		mat.albedo_color = look[1 + s]
		mat.roughness = 0.9
		if s == 1:
			mat.emission_enabled = float(look[3]) >= 0.0
			mat.emission = look[2]
			mat.emission_energy_multiplier = maxf(float(look[3]), 0.0)
			accent = mat
		piece.set_surface_override_material(s, mat)
	return accent

static func _parts(kind: String) -> Array:
	var out: Array = []
	match kind:
		"secret":
			out = [_p(&"cyl", Vector3(0.085, 0.10, 0.09), Vector3(0, 0.05, 0)), _p(&"cyl", Vector3(0.09, 0.03, 0.09), Vector3(0, 0.115, 0), Vector3.ZERO, true), _p(&"tor", Vector3(0.088, 0.098, 0), Vector3(0, 0.06, 0), Vector3.ZERO, true),
				_p(&"box", Vector3(0.03, 0.05, 0.02), Vector3(0.09, 0.085, 0), Vector3.ZERO, true)]
		"workbench":
			out = [_p(&"box", Vector3(1.4, 0.08, 0.8), Vector3(0, 0.96, 0)), _p(&"box", Vector3(1.2, 0.05, 0.6), Vector3(0, 0.25, 0)), _p(&"box", Vector3(1.3, 0.4, 0.03), Vector3(0, 0.75, -0.37)),
				_p(&"box", Vector3(0.16, 0.12, 0.14), Vector3(0.5, 1.06, 0.1), Vector3.ZERO, true), _p(&"cyl", Vector3(0.015, 0.3, 0.015), Vector3(-0.3, 1.01, 0.15), Vector3(0, 0, 90), true), _p(&"box", Vector3(0.07, 0.05, 0.05), Vector3(-0.42, 1.03, 0.15), Vector3.ZERO, true)]
			for x in [-0.62, 0.62]:
				for z in [-0.32, 0.32]:
					out.append(_p(&"box", Vector3(0.08, 0.92, 0.08), Vector3(x, 0.46, z)))
		"bed":
			out = [_p(&"box", Vector3(2.0, 0.12, 1.0), Vector3(0, 0.2, 0)), _p(&"box", Vector3(0.06, 0.55, 1.0), Vector3(-0.97, 0.38, 0)), _p(&"box", Vector3(1.9, 0.14, 0.92), Vector3(0.0, 0.33, 0), Vector3.ZERO, true),
				_p(&"box", Vector3(0.45, 0.1, 0.6), Vector3(-0.7, 0.45, 0), Vector3.ZERO, true), _p(&"box", Vector3(1.0, 0.05, 0.95), Vector3(0.45, 0.42, 0))]
			for x in [-0.93, 0.93]:
				for z in [-0.43, 0.43]:
					out.append(_p(&"box", Vector3(0.08, 0.14, 0.08), Vector3(x, 0.07, z)))
		"switch":
			out = [_p(&"box", Vector3(0.8, 0.1, 0.2), Vector3(0, 0.05, 0)), _p(&"box", Vector3(0.8, 1.45, 0.18), Vector3(0, 0.825, -0.01)), _p(&"box", Vector3(0.7, 1.2, 0.02), Vector3(0, 0.8, 0.09)),
				_p(&"box", Vector3(0.14, 0.2, 0.03), Vector3(0, 0.85, 0.115)), _p(&"cyl", Vector3(0.02, 0.3, 0.02), Vector3(0.0, 0.95, 0.16), Vector3(35, 0, 0)), _p(&"sph", Vector3(0.08, 0.08, 0.08), Vector3(0.0, 1.08, 0.23), Vector3.ZERO, true),
				_p(&"box", Vector3(0.5, 0.12, 0.012), Vector3(0, 1.15, 0.106), Vector3.ZERO, true)]
			for x in [-0.22, 0.0, 0.22]:
				out.append(_p(&"box", Vector3(0.07, 0.07, 0.03), Vector3(x, 1.4, 0.105), Vector3.ZERO, true))
			for i in 4:
				out.append(_p(&"box", Vector3(0.5, 0.025, 0.012), Vector3(0, 0.3 + 0.08 * i, 0.106)))
		"cable_box":
			out = [_p(&"box", Vector3(0.62, 0.05, 0.4), Vector3(0, 0.025, 0)), _p(&"box", Vector3(0.6, 0.9, 0.36), Vector3(0, 0.5, 0)), _p(&"box", Vector3(0.5, 0.75, 0.03), Vector3(0, 0.52, 0.195)),
				_p(&"box", Vector3(0.14, 0.2, 0.03), Vector3(0.2, 0.5, 0.215))]
			for x in [-0.15, 0.15]:
				out.append(_p(&"cyl", Vector3(0.035, 0.3, 0.035), Vector3(x, 1.1, 0)))
			for x in [-0.15, 0.0, 0.15]:
				out.append(_p(&"box", Vector3(0.08, 0.1, 0.02), Vector3(x, 0.78, 0.212), Vector3.ZERO, true))
		"generator":
			out = [_p(&"box", Vector3(1.0, 0.1, 0.8), Vector3(0, 0.05, 0)), _p(&"box", Vector3(0.8, 0.55, 0.6), Vector3(-0.05, 0.4, 0)), _p(&"cyl", Vector3(0.2, 0.7, 0.2), Vector3(-0.05, 0.9, 0), Vector3(0, 0, 90)),
				_p(&"cyl", Vector3(0.04, 0.5, 0.04), Vector3(0.38, 1.0, -0.2)), _p(&"box", Vector3(0.34, 0.26, 0.04), Vector3(0.0, 0.45, 0.31), Vector3.ZERO, true)]
			for i in 5:
				out.append(_p(&"box", Vector3(0.03, 0.4, 0.62), Vector3(-0.4 + 0.1 * i, 0.4, 0)))
	return out
