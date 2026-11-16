extends RefCounted
## B10 asset wiring (2026-11-16): the reusable modeled meshes of
## scripts/tools/_gen_meshes_b10.gd, put into real gameplay nodes.
##
## Three consumers, all additive -- no existing node is renamed or removed:
##   * facade bays  -> CitySkyline "FacadeBays" / "FacadeBaysLOD" MultiMeshes
##   * creature     -> MonsterRig "ModeledShell" / "ModeledShellLOD" children
##   * hands        -> WeaponManager "FirstPersonHands" / "FirstPersonHandsLOD"
##
## Materials: the facade bays use the shipped painted-brick PBR set with the
## authored UVs; the creature shell shares the rig's hide material (hit flash,
## rim, emission); the hands are untextured PBR with authored vertex colours.
## Collision comes from the world's existing GroundBody perimeter walls / the
## monster capsule, so no new physics bodies or navigation changes are
## introduced. LOD uses GeometryInstance3D visibility ranges with a margin,
## so the high-detail mesh is drawn close and the simplified mesh far away.

const FACADE := preload("res://assets/mesh/mesh_facade_bay.res")
const FACADE_LOD := preload("res://assets/mesh/mesh_facade_bay_lod.res")
const CREATURE := preload("res://assets/mesh/mesh_creature_shell.res")
const CREATURE_LOD := preload("res://assets/mesh/mesh_creature_shell_lod.res")
const HANDS := preload("res://assets/mesh/mesh_hand_viewmodel.res")
const HANDS_LOD := preload("res://assets/mesh/mesh_hand_viewmodel_lod.res")
const _PBR := preload("res://scripts/world/pbr_sets.gd")

const FACADE_RANGE_M: float = 46.0
const CREATURE_RANGE_M: float = 26.0
const HANDS_RANGE_M: float = 2.0
const LOD_MARGIN_M: float = 4.0

static func _material(set_name: String, tint: Color, rough: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat = _PBR.apply(mat, set_name)
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = tint
	mat.roughness = rough
	mat.metallic = 0.0
	mat.uv1_triplanar = false   # the B10 meshes carry authored UVs
	return mat

static func _lod(node: GeometryInstance3D, near: float, far: bool) -> void:
	node.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	if far:
		node.visibility_range_begin = near
		node.visibility_range_begin_margin = minf(LOD_MARGIN_M, near * 0.1)
	else:
		node.visibility_range_end = near
		node.visibility_range_end_margin = minf(LOD_MARGIN_M, near * 0.1)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## Add high/low masonry-bay MultiMeshes per facade direction. `fronts` and
## `widths` are the same arrays skyline.gd already builds for the sign bands.
static func add_facade_bays(sky: Node3D, district_id: StringName, fronts: Array, widths: Array) -> void:
	if sky == null or fronts.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("b10_bays_" + String(district_id))
	var near_xf: Dictionary = {}
	for i in fronts.size():
		var frame: Transform3D = fronts[i]
		var direction := Vector3i(frame.basis.z.round())
		if not near_xf.has(direction):
			var transforms: Array[Transform3D] = []
			near_xf[direction] = transforms
		var group: Array[Transform3D] = near_xf[direction]
		var w: float = float(widths[i]) if i < widths.size() else 8.0
		var count: int = maxi(1, int(w / 3.8))
		for k in count:
			var x: float = -w * 0.5 + (float(k) + 0.5) * (w / float(count))
			var bay := frame * Transform3D(Basis.IDENTITY, Vector3(x, 0.0, 0.34))
			# Small deterministic yaw/scale variation keeps the ring from tiling.
			bay = bay * Transform3D(Basis(Vector3.UP, rng.randf_range(-0.008, 0.008)), Vector3.ZERO)
			group.append(bay)
	if near_xf.is_empty():
		return
	var mat := _material("painted_brick", Color(0.62, 0.60, 0.56), 0.94)
	var directions: Array = near_xf.keys()
	for i in directions.size():
		var group: Array[Transform3D] = near_xf[directions[i]]
		var hi := _multimesh("FacadeBays_%d" % i, FACADE, group, mat, sky)
		var lo := _multimesh("FacadeBaysLOD_%d" % i, FACADE_LOD, group, mat, sky)
		if hi != null:
			_lod(hi, FACADE_RANGE_M, false)
		if lo != null:
			_lod(lo, FACADE_RANGE_M, true)

static func _multimesh(node_name: String, mesh: Mesh, xf: Array[Transform3D], mat: Material, parent: Node3D) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xf.size()
	for i in xf.size():
		mm.set_instance_transform(i, xf[i])
	var node := MultiMeshInstance3D.new()
	node.name = node_name
	node.multimesh = mm
	node.material_override = mat
	parent.add_child(node)
	return node

## Attach the modeled shell to the existing animated rig, fitted to the look:
## the carapace spans the body from its bottom to the neck and the skull dome
## caps the primitive head (which stays as the face/jaw below it). It inherits
## the gait, windup, flinch and collapse transforms of Torso unchanged, and
## shares the rig material so the hide, rim, emission and hit flash read as
## one creature. Quadrupeds (crawler, hound) and the special silhouettes
## (shadow cloak, watcher eye, faceless boss) keep their own bodies.
const SHELL_IDS: Array[StringName] = [&"rotter", &"hunter", &"brute", &"burner", &"sharpshooter", &"tvar", &"destroyer"]

static func add_creature_shell(torso: Node3D, id: StringName, look: Dictionary, mat: StandardMaterial3D, hip_y: float) -> void:
	if torso == null or not SHELL_IDS.has(id):
		return
	var body: Array = look["body"]
	var head: Array = look["head"]
	var bh: float = float(body[3]) if body[0] == "cyl" else float(body[2])
	var bw: float = float(body[1]) * 2.0 if body[0] == "box" else maxf(float(body[1]), float(body[2])) * 2.0
	var by: float = float(body[4])
	var hy: float = float(head[4])
	var hz: float = float(head[5])
	var hr: float = float(head[1]) if head[0] == "sph" else float(head[2]) * 0.5
	var bottom: float = by - bh * 0.5
	var sy: float = (hy - bottom) / 0.98
	var sx: float = clampf(bw / 0.68 * 0.85, 0.8, 2.2)
	var sz: float = sx * 0.9
	var at := Vector3(0.0, bottom - hip_y + 0.52 * sy + hr * 0.10, hz * 0.5 - 0.02 * sz)
	var hi := MeshInstance3D.new()
	hi.name = "ModeledShell"
	hi.mesh = CREATURE
	hi.material_override = mat
	hi.position = at
	hi.scale = Vector3(sx, sy, sz)
	hi.rotation.y = PI
	torso.add_child(hi)
	var lo := MeshInstance3D.new()
	lo.name = "ModeledShellLOD"
	lo.mesh = CREATURE_LOD
	lo.material_override = mat
	lo.position = at
	lo.scale = Vector3(sx, sy, sz)
	lo.rotation.y = PI
	torso.add_child(lo)
	_lod(hi, CREATURE_RANGE_M, false)
	_lod(lo, CREATURE_RANGE_M, true)

## First-person hands, parented to the weapon (not to WeaponModel, whose two
## children the closeout gate counts). They inherit the viewmodel motion,
## the rack tween and the holster visibility for free. Untextured PBR: the
## authored vertex colours carry the glove, cuff and strap, so no world
## surface texture reads as skin.
static func add_hands(weapon: Node3D, grip_offset: Vector3) -> void:
	if weapon == null:
		return
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color.WHITE
	mat.roughness = 0.78
	mat.metallic = 0.0
	var hi := MeshInstance3D.new()
	hi.name = "FirstPersonHands"
	hi.mesh = HANDS
	hi.position = grip_offset
	hi.material_override = mat
	weapon.add_child(hi)
	var lo := MeshInstance3D.new()
	lo.name = "FirstPersonHandsLOD"
	lo.mesh = HANDS_LOD
	lo.position = grip_offset
	lo.material_override = mat
	weapon.add_child(lo)
	_lod(hi, HANDS_RANGE_M, false)
	_lod(lo, HANDS_RANGE_M, true)
