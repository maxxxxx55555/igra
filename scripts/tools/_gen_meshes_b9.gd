extends "res://scripts/tools/_gen_meshes.gd"
## B9 production props (2026-11-13): seven reusable, triangulated, UV-mapped
## meshes that replace primitive world shapes and fill the set-piece gap of
## docs/KNOWN_ISSUES.md ("a car, a cart, desks, luggage"). Reuses the winding,
## UV and normal framework of _gen_meshes.gd without editing that generator, so
## no existing doc citation moves. Project-owned geometry, no third-party art.
##
##   godot --headless --path . res://scenes/tools/gen_meshes_b9_scene.tscn
##
## Every mesh rests on y = 0 (crate and barrel are centred on the origin to be
## drop-in replacements for the 0.7^3 BoxMesh and the 0.28 x 0.9 CylinderMesh
## that district_dressing.gd used). All triangles carry normals and planar UVs.

const B9: Array[String] = [
	"mesh_car", "mesh_cabinet", "mesh_fence", "mesh_cart",
	"mesh_crate", "mesh_barrel", "mesh_debris",
]

func _ready() -> void:
	_probe_winding()
	DirAccess.make_dir_recursive_absolute(OUT)
	var made: int = 0
	made += _car()
	made += _cabinet()
	made += _fence()
	made += _cart()
	made += _crate()
	made += _barrel()
	made += _debris()
	print("[mesh-b9] DONE generated=", made, "/", B9.size())
	_verify_b9()
	get_tree().quit(0 if made == B9.size() else 1)

func _verify_b9() -> void:
	for base in B9:
		var path: String = OUT + base + ".res"
		var m: ArrayMesh = ResourceLoader.load(path, "ArrayMesh", ResourceLoader.CACHE_MODE_IGNORE)
		if m == null:
			printerr("[mesh-b9] verify FAIL missing ", path)
			continue
		var verts: int = 0
		var tris: int = 0
		var uv_ok: bool = true
		var n_ok: bool = true
		for s in m.get_surface_count():
			var arr: Array = m.surface_get_arrays(s)
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			var us: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
			var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			verts += vs.size()
			tris += (ix.size() / 3) if ix != null else (vs.size() / 3)
			uv_ok = uv_ok and us.size() == vs.size()
			n_ok = n_ok and ns.size() == vs.size()
		var box: AABB = m.get_aabb()
		print("[mesh-b9] verify ", base, " tris=", tris, " verts=", verts,
				" uv=", uv_ok, " normals=", n_ok, " aabb=", box.size.snappedf(0.01))

# ---------------- set pieces ----------------

## Parked sedan, 4.3 m along X, front at -X. Body, bonnet, boot, a glazed cabin
## with sloped screens, four wheels with hubs, bumpers, lamps, grille and mirrors.
func _car() -> int:
	_begin()
	_box(Vector3(0, 0.52, 0), Vector3(4.10, 0.44, 1.72))              # chassis
	_box(Vector3(0, 0.32, 0), Vector3(3.86, 0.14, 1.60))              # sill
	_box(Vector3(-1.34, 0.82, 0), Vector3(1.44, 0.20, 1.66))          # bonnet
	_box(Vector3(1.56, 0.82, 0), Vector3(1.00, 0.20, 1.66))           # boot
	_box(Vector3(-0.06, 0.94, 0), Vector3(1.08, 0.08, 1.60))          # scuttle
	# Cabin sides: two door skins and a recessed glass band on each flank.
	for side in [-1.0, 1.0]:
		var z: float = side * 0.80
		_box(Vector3(0.10, 0.62, z), Vector3(2.10, 0.58, 0.08))        # doors
		_box(Vector3(0.10, 1.16, side * 0.755), Vector3(1.86, 0.42, 0.05))  # glass
		_box(Vector3(0.10, 0.94, side * 0.84), Vector3(0.05, 0.42, 0.04))   # B pillar
		_box(Vector3(0.10, 0.34, side * 0.86), Vector3(2.20, 0.05, 0.05))   # chrome strip
		_box(Vector3(-0.64, 1.04, side * 0.92), Vector3(0.20, 0.10, 0.14))  # mirror
	# Windshield, roof and rear screen as slanted slabs with real thickness.
	var nw: Vector3 = Vector3(-0.80, 0.60, 0.0)
	_slab(Vector3(-0.68, 0.94, -0.76), Vector3(-0.68, 0.94, 0.76),
			Vector3(-0.30, 1.42, 0.76), Vector3(-0.30, 1.42, -0.76), nw, 0.05)
	_box(Vector3(0.32, 1.44, 0), Vector3(1.28, 0.08, 1.54))
	var nr: Vector3 = Vector3(0.80, 0.60, 0.0)
	_slab(Vector3(0.94, 1.42, -0.76), Vector3(0.94, 1.42, 0.76),
			Vector3(1.34, 0.94, 0.76), Vector3(1.34, 0.94, -0.76), nr, 0.05)
	# Wheels: the axle runs along Z, so the disc faces the flank and its radius
	# lies in the XY plane (a wheel that can actually roll). Hub disc on the outer face.
	for x in [-1.32, 1.32]:
		for s in [-1.0, 1.0]:
			var z: float = s * 0.78
			_tube(Vector3(x, 0.34, z - 0.11), Vector3.BACK, 0.34, 0.34, 0.22, 14, true, true)
			_tube(Vector3(x, 0.34, s * 0.892), Vector3.BACK, 0.17, 0.17, 0.018, 12, false, true)
	# Bumpers, lamps, grille and a pair of number plates.
	_box(Vector3(-2.11, 0.46, 0), Vector3(0.16, 0.18, 1.78))
	_box(Vector3(2.11, 0.46, 0), Vector3(0.16, 0.18, 1.78))
	for s in [-1.0, 1.0]:
		_box(Vector3(-2.055, 0.78, s * 0.60), Vector3(0.06, 0.14, 0.30))
		_box(Vector3(2.055, 0.78, s * 0.60), Vector3(0.06, 0.12, 0.26))
	_box(Vector3(-2.09, 0.66, 0), Vector3(0.05, 0.16, 0.70))
	_box(Vector3(-2.16, 0.46, 0), Vector3(0.03, 0.10, 0.46))
	_box(Vector3(2.16, 0.46, 0), Vector3(0.03, 0.10, 0.46))
	return _commit("mesh_car")

## Street-side electrical cabinet: plinth, body, recessed door, louvres, a
## warning plate, a handle, a rain hood and two external conduits.
func _cabinet() -> int:
	_begin()
	_box(Vector3(0, 0.09, 0), Vector3(1.16, 0.18, 0.66))               # plinth
	_box(Vector3(0, 1.02, 0), Vector3(1.02, 1.70, 0.52))               # body
	_box(Vector3(0, 1.02, 0.27), Vector3(0.88, 1.52, 0.05))            # door leaf
	for x in [-0.46, 0.46]:
		_box(Vector3(x, 1.02, 0.31), Vector3(0.06, 1.58, 0.05))        # door stiles
	for y in [0.27, 1.76]:
		_box(Vector3(0, y, 0.31), Vector3(0.98, 0.06, 0.05))           # door rails
	for i in 6:                                                          # ventilation
		_box(Vector3(0, 0.46 + float(i) * 0.085, 0.315), Vector3(0.62, 0.028, 0.035))
	_box(Vector3(0, 1.58, 0.322), Vector3(0.24, 0.20, 0.016))          # warning plate
	_tube(Vector3(0.34, 0.86, 0.33), Vector3.UP, 0.022, 0.022, 0.30, 8, true, true)
	_box(Vector3(0.34, 1.02, 0.36), Vector3(0.10, 0.05, 0.05))         # latch
	# Slanted rain hood over the top, extruded by 0.06 m.
	_slab(Vector3(-0.58, 1.92, -0.34), Vector3(0.58, 1.92, -0.34),
			Vector3(0.58, 1.92, 0.36), Vector3(-0.58, 1.92, 0.36),
			Vector3(0, 1, 0), 0.06)
	for x in [-0.56, 0.56]:                                              # conduits
		_tube(Vector3(x, 0.18, -0.20), Vector3.UP, 0.045, 0.045, 1.62, 10, true, true)
		_box(Vector3(x * 0.86, 1.78, -0.20), Vector3(0.20, 0.08, 0.10))
	for x in [-0.48, 0.48]:
		for z in [-0.26, 0.26]:
			_box(Vector3(x, 0.20, z), Vector3(0.09, 0.10, 0.09))        # anchor bolts
	return _commit("mesh_cabinet")

## A 2.4 m fence bay: two capped posts, two rails, nine pickets, a diagonal brace.
func _fence() -> int:
	_begin()
	for x in [-1.15, 1.15]:
		_box(Vector3(x, 0.63, 0), Vector3(0.11, 1.26, 0.11))
		_box(Vector3(x, 1.29, 0), Vector3(0.15, 0.06, 0.15))
	for y in [0.30, 1.06]:
		_box(Vector3(0, y, 0), Vector3(2.30, 0.09, 0.07))
	for i in 9:
		var x: float = -1.00 + float(i) * 0.25
		_box(Vector3(x, 0.68, 0), Vector3(0.055, 0.94, 0.05))
	_slab(Vector3(-1.10, 0.20, 0.05), Vector3(1.10, 1.12, 0.05),
			Vector3(1.10, 1.18, 0.05), Vector3(-1.10, 0.26, 0.05),
			Vector3(0, 0, 1), 0.035)
	return _commit("mesh_fence")

## Handcart: a plank tray with three walls, two spoked wheels, long handles, legs.
func _cart() -> int:
	_begin()
	_box(Vector3(0, 0.56, 0), Vector3(1.46, 0.07, 0.86))               # tray floor
	_box(Vector3(-0.70, 0.72, 0), Vector3(0.06, 0.32, 0.86))           # head board
	for z in [-0.42, 0.42]:
		_box(Vector3(0, 0.72, z), Vector3(1.46, 0.30, 0.055))          # side boards
		_box(Vector3(0, 0.88, z), Vector3(1.50, 0.045, 0.075))         # rail caps
	for z in [-0.50, 0.50]:
		_tube(Vector3(-0.42, 0.30, z - 0.055), Vector3.BACK, 0.28, 0.28, 0.11, 14, true, true)
		_tube(Vector3(-0.42, 0.30, z + 0.058), Vector3.BACK, 0.07, 0.07, 0.02, 10, false, true)
		_tube(Vector3(0.62, 0.86, z * 0.72), Vector3.RIGHT, 0.032, 0.032, 0.92, 8, true, true)
		_box(Vector3(0.62, 0.30, z * 0.72), Vector3(0.07, 0.55, 0.07)) # legs
	return _commit("mesh_cart")

## 0.7 m plank crate centred on the origin: a drop-in for the old 0.7^3 BoxMesh.
func _crate() -> int:
	_begin()
	for face in [0, 1]:
		var z: float = (0.335 if face == 0 else -0.335) * 1.0
		for i in 3:
			var y: float = -0.23 + float(i) * 0.23
			_box(Vector3(0, y, z), Vector3(0.68, 0.215, 0.045))
	for face in [0, 1]:
		var x: float = 0.335 if face == 0 else -0.335
		for i in 3:
			var y: float = -0.23 + float(i) * 0.23
			_box(Vector3(x, y, 0), Vector3(0.045, 0.215, 0.68))
	for i in 3:
		var z: float = -0.23 + float(i) * 0.23
		_box(Vector3(0, 0.335, z), Vector3(0.68, 0.045, 0.215))
		_box(Vector3(0, -0.335, z), Vector3(0.68, 0.045, 0.215))
	for x in [-0.325, 0.325]:                                            # corner braces
		for z in [-0.325, 0.325]:
			_box(Vector3(x, 0, z), Vector3(0.075, 0.70, 0.075))
	_slab(Vector3(-0.31, -0.29, 0.363), Vector3(0.31, 0.29, 0.363),
			Vector3(0.31, 0.33, 0.363), Vector3(-0.31, -0.25, 0.363),
			Vector3(0, 0, 1), 0.025)
	return _commit("mesh_crate")

## 0.28 r x 0.9 h riveted drum centred on the origin: a drop-in for _drum().
func _barrel() -> int:
	_begin()
	_tube(Vector3(0, -0.45, 0), Vector3.UP, 0.255, 0.280, 0.30, 16, true, false)
	_tube(Vector3(0, -0.15, 0), Vector3.UP, 0.280, 0.280, 0.30, 16)
	_tube(Vector3(0, 0.15, 0), Vector3.UP, 0.280, 0.255, 0.30, 16, false, true)
	for y in [-0.30, 0.0, 0.30]:                                         # hoop bands
		_tube(Vector3(0, y - 0.028, 0), Vector3.UP, 0.288, 0.288, 0.056, 16)
	_tube(Vector3(0, 0.45, 0), Vector3.UP, 0.255, 0.255, 0.025, 16, false, true)
	_tube(Vector3(0.12, 0.465, 0), Vector3.UP, 0.045, 0.045, 0.03, 8, false, true)
	return _commit("mesh_barrel")

## A rubble pile: broken slabs, bricks, a pipe and a plank, all above y = 0.
func _debris() -> int:
	_begin()
	_slab(Vector3(-0.55, 0.02, -0.40), Vector3(-0.10, 0.02, -0.45),
			Vector3(-0.05, 0.22, -0.05), Vector3(-0.52, 0.26, 0.02),
			Vector3(-0.1, 0.9, 0.4).normalized(), 0.07)
	_slab(Vector3(0.10, 0.02, 0.10), Vector3(0.60, 0.02, 0.02),
			Vector3(0.55, 0.18, 0.44), Vector3(0.06, 0.20, 0.50),
			Vector3(0.1, 0.9, -0.3).normalized(), 0.06)
	for i in 5:                                                           # broken bricks
		var x: float = -0.42 + float(i) * 0.21
		_box(Vector3(x, 0.07, 0.34 + 0.06 * float(i % 2)), Vector3(0.20, 0.13, 0.10))
	_tube(Vector3(-0.30, 0.10, 0.45), Vector3.RIGHT, 0.055, 0.055, 0.82, 10, true, true)
	_box(Vector3(0.20, 0.055, -0.30), Vector3(0.72, 0.055, 0.10))       # plank
	return _commit("mesh_debris")
