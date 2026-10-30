extends RefCounted
## Slender, weathered streetlight body shared by the per-instance fixture and the district MultiMesh.
## The lamp head stays its own mesh so the flicker material can drive only the light.

const _Parts := preload("res://scripts/art/part_mesh.gd")
static var _mesh: ArrayMesh = null

static func mesh() -> ArrayMesh:
	if _mesh != null:
		return _mesh
	var parts: Array = [
		_Parts.part(&"cyl", Vector3(0.34, 0.10, 0.40), Vector3(0, 0.05, 0)),
		_Parts.part(&"cyl", Vector3(0.16, 0.28, 0.22), Vector3(0, 0.24, 0)),
		_Parts.part(&"cyl", Vector3(0.085, 4.0, 0.11), Vector3(0, 2.18, 0)),
		_Parts.part(&"cyl", Vector3(0.075, 0.52, 0.075), Vector3(0.17, 4.24, 0), Vector3(0, 0, 58)),
		_Parts.part(&"cyl", Vector3(0.065, 0.58, 0.065), Vector3(0.66, 4.40, 0), Vector3(0, 0, 78)),
		_Parts.part(&"box", Vector3(0.32, 0.10, 0.22), Vector3(1.12, 4.31, 0)),
		_Parts.part(&"box", Vector3(0.14, 0.16, 0.15), Vector3(0.0, 1.10, 0.08)),
	]
	_mesh = _Parts.build(parts)
	return _mesh
