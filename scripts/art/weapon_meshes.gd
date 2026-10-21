extends RefCounted
## C6 (the v1.0.0-ship pass): the three guns, each its own shape out of parts (part_mesh.gd) in place of the three boxes the placeholder model scaled to a length. model(id) is the viewmodel in the weapon's frame (the
## muzzle toward -Z, the grip at the origin): a "Body" mesh and the part that works on a shot, "Slide" (pistol), "Bolt" (rifle) or "Pump" (shotgun), which weapon_manager.gd moves back and forward on a shot and a
## reload. mesh_for(id) is the same gun in one mesh, lying on its side, for the one on the ground (weapon_pickup.gd). A gun is 600 triangles at most. Surface 0 is steel, surface 1 the polymer or the wood.

const _Parts := preload("res://scripts/art/part_mesh.gd")
const _STEEL := Color(0.15, 0.16, 0.18)
const _ACCENT := {&"pistol": Color(0.10, 0.10, 0.11), &"rifle": Color(0.30, 0.20, 0.12), &"shotgun": Color(0.34, 0.22, 0.12)}
const MOVING: Dictionary = {&"pistol": "Slide", &"rifle": "Bolt", &"shotgun": "Pump"}

static var _materials: Dictionary = {}

static func _p(kind: StringName, size: Vector3, at: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO, accent: bool = false) -> Array:
	return _Parts.part(kind, size, at, rot, 1 if accent else 0)

## [parts that stay, parts that move] of a gun.
static func _parts(id: StringName) -> Array:
	match id:
		&"rifle":
			return [[_p(&"box", Vector3(0.044, 0.06, 0.28), Vector3(0, 0.01, -0.14)), _p(&"cyl", Vector3(0.011, 0.4, 0.011), Vector3(0, 0.025, -0.48), Vector3(90, 0, 0)),
				_p(&"box", Vector3(0.046, 0.045, 0.22), Vector3(0, 0, -0.34), Vector3.ZERO, true), _p(&"box", Vector3(0.028, 0.12, 0.05), Vector3(0, -0.085, -0.16), Vector3(14, 0, 0)),
				_p(&"box", Vector3(0.034, 0.09, 0.04), Vector3(0, -0.075, -0.01), Vector3(-18, 0, 0), true), _p(&"box", Vector3(0.04, 0.085, 0.24), Vector3(0, -0.01, 0.16), Vector3(-6, 0, 0), true),
				_p(&"box", Vector3(0.004, 0.03, 0.004), Vector3(0, 0.058, -0.67)), _p(&"box", Vector3(0.02, 0.015, 0.01), Vector3(0, 0.047, -0.05)), _p(&"tor", Vector3(0.01, 0.022, 0), Vector3(0, -0.04, -0.06), Vector3(0, 0, 90))],
				[_p(&"box", Vector3(0.026, 0.02, 0.09), Vector3(0.012, 0.03, -0.17)), _p(&"cyl", Vector3(0.006, 0.04, 0.006), Vector3(0.04, 0.03, -0.14), Vector3(0, 0, 90)), _p(&"sph", Vector3(0.02, 0.02, 0.02), Vector3(0.062, 0.03, -0.14))]]
		&"shotgun":
			return [[_p(&"box", Vector3(0.046, 0.065, 0.17), Vector3(0, 0.005, -0.085)), _p(&"cyl", Vector3(0.014, 0.5, 0.014), Vector3(-0.0155, 0.035, -0.43), Vector3(90, 0, 0)),
				_p(&"cyl", Vector3(0.014, 0.5, 0.014), Vector3(0.0155, 0.035, -0.43), Vector3(90, 0, 0)), _p(&"box", Vector3(0.012, 0.006, 0.5), Vector3(0, 0.052, -0.43)),
				_p(&"box", Vector3(0.042, 0.09, 0.26), Vector3(0, -0.02, 0.17), Vector3(-8, 0, 0), true), _p(&"box", Vector3(0.036, 0.08, 0.04), Vector3(0, -0.065, 0), Vector3(-16, 0, 0), true),
				_p(&"sph", Vector3(0.01, 0.01, 0.01), Vector3(0, 0.058, -0.67)), _p(&"tor", Vector3(0.01, 0.022, 0), Vector3(0, -0.045, -0.07), Vector3(0, 0, 90))],
				[_p(&"cyl", Vector3(0.02, 0.2, 0.02), Vector3(0, -0.005, -0.36), Vector3(90, 0, 0)), _p(&"box", Vector3(0.056, 0.05, 0.2), Vector3(0, -0.015, -0.36), Vector3.ZERO, true)]]
	return [[_p(&"box", Vector3(0.034, 0.028, 0.15), Vector3(0, 0, -0.075)), _p(&"tor", Vector3(0.012, 0.026, 0), Vector3(0, -0.035, -0.07), Vector3(0, 0, 90)), _p(&"box", Vector3(0.008, 0.026, 0.01), Vector3(0, -0.026, -0.065)),
			_p(&"box", Vector3(0.034, 0.10, 0.052), Vector3(0, -0.06, 0.012), Vector3(-14, 0, 0), true)],
			[_p(&"box", Vector3(0.032, 0.036, 0.19), Vector3(0, 0.032, -0.105)), _p(&"cyl", Vector3(0.009, 0.03, 0.009), Vector3(0, 0.033, -0.215), Vector3(90, 0, 0)),
			_p(&"box", Vector3(0.006, 0.01, 0.01), Vector3(0, 0.054, -0.19)), _p(&"box", Vector3(0.018, 0.01, 0.01), Vector3(0, 0.054, -0.015))]]

## The viewmodel of a gun: Node3D "WeaponModel" with the children "Body" and the moving part (MOVING[id]), steel and the gun's accent on them.
static func model(id: StringName) -> Node3D:
	var parts: Array = _parts(id)
	var root := Node3D.new()
	root.name = "WeaponModel"
	for i in 2:
		var piece := MeshInstance3D.new()
		piece.name = "Body" if i == 0 else String(MOVING[id])
		piece.mesh = _Parts.build(parts[i])
		var mats: Array[Material] = _gun_materials(id)
		for s in piece.mesh.get_surface_count():
			piece.set_surface_override_material(s, mats[s])
		piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(piece)
	return root

## The gun on the ground, in one mesh, on its side.
static func mesh_for(id: StringName) -> Mesh:
	var parts: Array = _parts(id)
	return _Parts.build(parts[0] + parts[1], Transform3D(Basis(Vector3.BACK, PI / 2.0), Vector3.ZERO))

static func _gun_materials(id: StringName) -> Array[Material]:
	if not _materials.has(id):
		var steel := StandardMaterial3D.new()
		steel.albedo_color = _STEEL
		steel.metallic = 0.6
		steel.roughness = 0.5
		var accent := StandardMaterial3D.new()
		accent.albedo_color = _ACCENT[id]
		accent.roughness = 0.8
		var pair: Array[Material] = [steel, accent]
		_materials[id] = pair
	return _materials[id]
