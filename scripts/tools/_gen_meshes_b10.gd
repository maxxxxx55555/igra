extends "res://scripts/tools/_gen_meshes.gd"
## B10 modeled assets (2026-11-16): reusable, close-range geometry for the
## three families the release packet asked for -- recessed masonry facade
## bays, a modeled creature shell and first-person hands. Extends the B9
## generator without editing it, so no existing citation or mesh moves.
##
##   godot --headless --path . res://scenes/tools/gen_meshes_b10_scene.tscn
##
## Every mesh carries ARRAY_VERTEX / NORMAL / TEX_UV / COLOR and tangents.
## The *_lod meshes keep the same silhouette with a fraction of the detail;
## the consumers switch between them with GeometryInstance3D visibility
## ranges. Project-owned geometry, no third-party art, no license needed.

const B10: Array[String] = [
	"mesh_facade_bay", "mesh_facade_bay_lod",
	"mesh_creature_shell", "mesh_creature_shell_lod",
	"mesh_hand_viewmodel", "mesh_hand_viewmodel_lod",
]

## Muted, low-chroma palette: dark unpowered streets, no vivid/magenta pixels.
const BRICK := Color(0.24, 0.22, 0.20)
const PLASTER := Color(0.30, 0.29, 0.26)
const METAL := Color(0.15, 0.15, 0.14)
const RECESS := Color(0.045, 0.050, 0.055)
const HIDE := Color(0.10, 0.10, 0.09)
const BONE := Color(0.19, 0.18, 0.15)
const GLOVE := Color(0.13, 0.12, 0.11)
const CUFF := Color(0.085, 0.090, 0.095)

var _tint: Color = Color.WHITE

func _ready() -> void:
	_probe_winding()
	DirAccess.make_dir_recursive_absolute(OUT)
	var made: int = 0
	made += _facade_bay(false)
	made += _facade_bay(true)
	made += _creature_shell(false)
	made += _creature_shell(true)
	made += _hand_viewmodel(false)
	made += _hand_viewmodel(true)
	print("[mesh-b10] DONE generated=", made, "/", B10.size())
	_verify_b10()
	get_tree().quit(0 if made == B10.size() else 1)

func _begin() -> void:
	super._begin()
	_st.set_color(_tint)

func _col(c: Color) -> void:
	_tint = c
	_st.set_color(c)

func _verify_b10() -> void:
	for base in B10:
		var path: String = OUT + base + ".res"
		var m: ArrayMesh = ResourceLoader.load(path, "ArrayMesh", ResourceLoader.CACHE_MODE_IGNORE)
		if m == null:
			printerr("[mesh-b10] verify FAIL missing ", path)
			continue
		var verts: int = 0
		var tris: int = 0
		var ok: bool = true
		for s in m.get_surface_count():
			var arr: Array = m.surface_get_arrays(s)
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			var us: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
			var cs: PackedColorArray = arr[Mesh.ARRAY_COLOR]
			var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			verts += vs.size()
			tris += (ix.size() / 3) if ix != null else (vs.size() / 3)
			ok = ok and ns.size() == vs.size() and us.size() == vs.size() and cs.size() == vs.size()
		print("[mesh-b10] verify ", base, " tris=", tris, " verts=", verts,
				" uv/normal/color=", ok, " aabb=", m.get_aabb().size.snappedf(0.01))

# ---------------- reusable masonry facade bay ----------------

## A 3.4 m wide, 3.5 m high street-level bay. Front plane is local z = 0,
## facing +Z (toward the street); recesses push into -Z. Origin at the
## pavement. Both LOD and full meshes share the exact same envelope.
func _facade_bay(lod: bool) -> int:
	_begin()
	_col(PLASTER)
	var door := Rect2(-0.50, 0.0, 1.0, 2.20)
	var win_a := Rect2(-1.48, 2.38, 0.72, 0.78)
	var win_b := Rect2(0.76, 2.38, 0.72, 0.78)
	var holes: Array[Rect2] = [door, win_a, win_b]
	_wall_holes(0.0, 1.0, -1.70, 1.70, 0.0, 3.40, holes)
	_col(RECESS)
	_recess(door.position.x, door.end.x, 0.0, door.end.y, 0.0, 0.24, true)
	_recess(win_a.position.x, win_a.end.x, win_a.position.y, win_a.end.y, 0.0, 0.20, true)
	_recess(win_b.position.x, win_b.end.x, win_b.position.y, win_b.end.y, 0.0, 0.20, true)
	# plinth, string course and cornice give the wall a real profile
	_col(PLASTER)
	_box(Vector3(0.0, 0.10, 0.09), Vector3(3.60, 0.20, 0.30))
	_box(Vector3(0.0, 2.30, 0.075), Vector3(3.52, 0.10, 0.24))
	_box(Vector3(0.0, 3.46, 0.13), Vector3(3.74, 0.14, 0.36))
	# door jambs, lintel, sill and window heads
	_col(BRICK)
	for sx: float in [-1.0, 1.0]:
		_box(Vector3(sx * 0.60, 1.12, 0.11), Vector3(0.16, 2.34, 0.26))
	_box(Vector3(0.0, 2.24, 0.13), Vector3(1.36, 0.16, 0.30))
	for w in [win_a, win_b]:
		var cx: float = (w.position.x + w.end.x) * 0.5
		_box(Vector3(cx, w.position.y - 0.07, 0.14), Vector3(w.size.x + 0.24, 0.11, 0.28))
		_box(Vector3(cx, w.end.y + 0.07, 0.12), Vector3(w.size.x + 0.22, 0.12, 0.26))
	if not lod:
		# brick courses, damaged plaster patches, ironwork and a downpipe
		_col(BRICK)
		for row: int in 11:
			var y: float = 0.34 + float(row) * 0.27
			if y > 2.24:
				break
			for seg: float in [-1.28, 0.0, 1.28]:
				if absf(seg) < 0.1 and y < 2.20:
					continue
				_box(Vector3(seg, y, 0.045), Vector3(1.10, 0.024, 0.045))
		_col(PLASTER)
		_box(Vector3(-1.42, 1.05, 0.032), Vector3(0.44, 0.62, 0.035))
		_box(Vector3(1.30, 2.86, 0.030), Vector3(0.52, 0.36, 0.035))
		_col(METAL)
		_box(Vector3(0.0, 2.42, 0.30), Vector3(1.52, 0.06, 0.52))
		for sx2: float in [-0.62, 0.62]:
			_box(Vector3(sx2, 2.34, 0.52), Vector3(0.045, 0.18, 0.44))
		_tube(Vector3(1.58, 0.22, 0.16), Vector3.UP, 0.045, 0.045, 3.12, 8, false, true)
		_box(Vector3(1.58, 1.60, 0.21), Vector3(0.12, 0.06, 0.06))
		# recessed door panels read as depth, not a flat dark quad
		_col(RECESS)
		_box(Vector3(-0.24, 1.12, -0.225), Vector3(0.40, 1.74, 0.02))
		_box(Vector3(0.24, 1.12, -0.225), Vector3(0.40, 1.74, 0.02))
	return _commit("mesh_facade_bay_lod") if lod else _commit("mesh_facade_bay")

# ---------------- reusable modeled creature shell ----------------

## A hunched humanoid silhouette: carapace, shoulder plates, spine ridges,
## skull with recessed sockets, jaw and claws. Built around y = 0 so it can
## be parented to the existing animated Torso without changing hitboxes.
func _creature_shell(lod: bool) -> int:
	_begin()
	_col(HIDE)
	_tube(Vector3(0.0, -0.52, 0.0), Vector3.UP, 0.30, 0.22, 0.98, 10 if not lod else 6, true, true)
	_col(BONE)
	# shoulder plates slope forward, so the silhouette is not a capsule
	_slab(Vector3(-0.20, 0.36, -0.16), Vector3(0.20, 0.36, -0.16),
			Vector3(0.34, 0.20, -0.10), Vector3(-0.34, 0.20, -0.10),
			Vector3(0.0, 0.06, 0.16).normalized(), 0.09)
	if not lod:
		_col(HIDE)
		for i: int in 5:
			var y: float = -0.36 + float(i) * 0.17
			_box(Vector3(0.0, y, -0.28), Vector3(0.14 - float(i) * 0.012, 0.055, 0.10))
		_col(BONE)
		for sx: float in [-1.0, 1.0]:
			_box(Vector3(sx * 0.30, 0.18, 0.02), Vector3(0.13, 0.34, 0.22))
			_box(Vector3(sx * 0.34, -0.16, -0.02), Vector3(0.09, 0.42, 0.11))
	# skull, brow, jaw and two dark recessed sockets
	_col(BONE)
	_dome(Vector3(0.0, 0.46, 0.02), 0.25, 0.30, 10 if not lod else 6, 3)
	_box(Vector3(0.0, 0.43, 0.235), Vector3(0.42, 0.09, 0.09))
	_box(Vector3(0.0, 0.29, 0.16), Vector3(0.34, 0.11, 0.28))
	_col(RECESS)
	for sx2: float in [-1.0, 1.0]:
		_box(Vector3(sx2 * 0.105, 0.47, 0.262), Vector3(0.115, 0.085, 0.045))
	if not lod:
		_col(BONE)
		for sx3: float in [-1.0, 1.0]:
			for k: int in 3:
				_tube(Vector3(sx3 * (0.30 + float(k) * 0.035), -0.52, 0.10),
						Vector3(0.0, -0.55, -0.84).normalized(), 0.026, 0.004, 0.20, 5, false, false)
	return _commit("mesh_creature_shell_lod") if lod else _commit("mesh_creature_shell")

# ---------------- first-person hands ----------------

## Two gloved hands in viewmodel space (weapon_meshes.gd frame: muzzle -Z,
## grip at the origin). The right palm wraps the right side of the grip and
## its four fingers cross the grip front; the left hand cups under the
## receiver/fore-end at z -0.15, fingers up its left side -- the frame spans
## z -0.28..0 on the pistol, the receiver z -0.17..0 on the rifle and the
## pump z -0.20..-0.01 on the shotgun, so one hold reads on all three guns.
func _hand_viewmodel(lod: bool) -> int:
	_begin()
	_col(CUFF)
	_tube(Vector3(0.060, -0.130, 0.300), Vector3(0.0, -0.10, -1.0).normalized(),
			0.060, 0.052, 0.28, 8 if not lod else 5, false, true)
	_tube(Vector3(-0.075, -0.160, 0.160), Vector3(0.05, -0.08, -1.0).normalized(),
			0.058, 0.050, 0.26, 8 if not lod else 5, false, true)
	_col(GLOVE)
	_box(Vector3(0.034, -0.062, 0.018), Vector3(0.034, 0.095, 0.055))
	_box(Vector3(-0.052, -0.060, -0.150), Vector3(0.036, 0.085, 0.060))
	if not lod:
		# right hand: four fingers across the grip front, thumb over the back
		for i: int in 4:
			var y: float = -0.030 - float(i) * 0.024
			_tube(Vector3(0.035, y, -0.024), Vector3.LEFT, 0.011, 0.010, 0.071, 8, true, true)
			_tube(Vector3(-0.036, y, -0.024), Vector3.BACK, 0.010, 0.008, 0.037, 8, true, true)
		_box(Vector3(0.018, -0.030, 0.032), Vector3(0.022, 0.055, 0.026))
		# left hand: four fingers up the left side of the receiver, tips over
		# the top, thumb toward the centreline
		for i: int in 4:
			var z: float = -0.125 - float(i) * 0.020
			_tube(Vector3(-0.070, -0.052, z), Vector3.UP, 0.011, 0.010, 0.073, 8, true, true)
			_tube(Vector3(-0.070, 0.021, z), Vector3.RIGHT, 0.010, 0.008, 0.038, 8, true, true)
		_box(Vector3(-0.028, -0.035, -0.125), Vector3(0.022, 0.050, 0.026))
		_col(BONE)
		_box(Vector3(0.058, -0.118, 0.272), Vector3(0.125, 0.026, 0.028))
		_box(Vector3(-0.072, -0.148, 0.132), Vector3(0.120, 0.024, 0.026))
	else:
		_box(Vector3(0.0, -0.062, -0.024), Vector3(0.078, 0.070, 0.028))
		_box(Vector3(-0.062, -0.020, -0.150), Vector3(0.028, 0.075, 0.062))
	return _commit("mesh_hand_viewmodel_lod") if lod else _commit("mesh_hand_viewmodel")
