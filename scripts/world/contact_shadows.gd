extends MultiMeshInstance3D
## W6 of docs/VISUAL_PASS.md section 8: contact shadows, what stops things looking as if they float. ONE MultiMesh of soft dark blobs (assets/shaders/contact_shadow.gdshader) LIFT_M above the ground: under the props of
## the district (`stamp`, from street_props.gd) and under what stands on it and is spawned by other scripts, found by group (the monsters, the pickups, the hiding spots, the barrels: none of those scripts knows about this
## one). One draw call for all of them, and none on the Low tier (visual_quality.tres, key contact_shadows).
## C2: the same node holds the pool of light of the pickups, in place of a real light on each: ONE MultiMesh of GLOW_CAP quads (assets/shaders/pickup_glow.gdshader) under the nearest tracked pickups whose meta "glow"
## (scripts/art/pickup_meshes.gd) has a strength, full within GLOW_FADE_FROM_M and gone at GLOW_FADE_TO_M. A note, whether on a pole or on the ground, throws neither a shadow nor a glow.

const SHADER: String = "res://assets/shaders/contact_shadow.gdshader"
const GROUPS: Array[StringName] = [&"monsters", &"pickup", &"hiding_spot", &"barrels"]
const CAPACITY: int = 256
const LIFT_M: float = 0.02
## The top of the street tiles: a box of street_builder.gd TILE_THICKNESS 0.1 centred on y = 0.
const GROUND_Y: float = 0.05
const SCAN_SEC: float = 0.5
const GLOW_SHADER: String = "res://assets/shaders/pickup_glow.gdshader"
const GLOW_CAP: int = 6
const GLOW_FADE_FROM_M: float = 10.0
const GLOW_FADE_TO_M: float = 16.0
const GLOW_SIZE_M: float = 1.6
const GLOW_SEC: float = 0.15
## The blob is a soft disc inside its quad: the quad is this many radii of the thing wide.
const SPREAD: float = 2.6

var _top: int = 0
var _free: Array[int] = []
var _tracked: Array[Dictionary] = []
var _scan: float = 0.0
var _glow: MultiMeshInstance3D = null
var _glow_clock: float = 0.0
## The strengths written to the pools last, nearest first (a headless run keeps no instance colours: this is what a check reads).
var glow_strengths: Array[float] = []

static func enabled() -> bool:
	var table := load("res://assets/config/visual_quality.tres")
	if table == null:
		return false
	var names: Array[String] = ["low", "medium", "high", "ultra"]
	var tier: Dictionary = table.get_meta(names[clampi(int(SettingsManager.get_setting("graphics_tier", 2)), 0, names.size() - 1)], {})
	return bool(tier.get("contact_shadows", false))

func _ready() -> void:
	name = "ContactShadows"
	var quad := PlaneMesh.new()
	quad.size = Vector2.ONE
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = quad
	multimesh.instance_count = CAPACITY
	multimesh.visible_instance_count = 0
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER)
	material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	custom_aabb = AABB(Vector3(-300.0, -1.0, -300.0), Vector3(600.0, 3.0, 600.0))
	_glow = MultiMeshInstance3D.new()
	_glow.name = "PickupGlow"
	_glow.multimesh = MultiMesh.new()
	_glow.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_glow.multimesh.use_colors = true
	_glow.multimesh.mesh = quad
	_glow.multimesh.instance_count = GLOW_CAP
	_glow.multimesh.visible_instance_count = 0
	var glow_mat := ShaderMaterial.new()
	glow_mat.shader = load(GLOW_SHADER)
	_glow.material_override = glow_mat
	_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_glow.custom_aabb = custom_aabb
	add_child(_glow)
	_collect()

## One blob at the foot of a prop of the district (the street's own height: a prop's origin is lifted to rest on it).
func stamp(position: Vector3, radius: float) -> void:
	_write(_slot(), Vector3(position.x, GROUND_Y + LIFT_M, position.z), radius)

func stamp_all(positions: Array[Vector3], radius: float) -> void:
	for position in positions:
		stamp(position, radius)

func _process(delta: float) -> void:
	_scan -= delta
	if _scan <= 0.0:
		_scan = SCAN_SEC
		_collect()
	_glow_clock -= delta
	if _glow_clock <= 0.0:
		_glow_clock = GLOW_SEC
		_update_glow()
	for i in range(_tracked.size() - 1, -1, -1):
		var entry: Dictionary = _tracked[i]
		var node: Node3D = entry["node"] as Node3D if is_instance_valid(entry["node"]) else null
		if node == null or not node.is_inside_tree():
			_hide(int(entry["index"]))
			_free.append(int(entry["index"]))
			if node != null:
				node.remove_meta(&"contact_shadow")
			_tracked.remove_at(i)
		else:
			var at: Vector3 = node.global_position
			_write(int(entry["index"]), Vector3(at.x, at.y + float(entry["lift"]), at.z), float(entry["radius"]))

## The things of the groups that stand on the ground and are not tracked yet, the ones that exist before this node and the ones that come later.
func _collect() -> void:
	for group in GROUPS:
		for member in get_tree().get_nodes_in_group(group):
			var node := member as Node3D
			if node == null or node.has_meta(&"contact_shadow") or not node.is_inside_tree() or node.is_in_group(&"document"):
				continue
			node.set_meta(&"contact_shadow", true)
			var foot: Vector2 = _measure(node)
			_tracked.append({"node": node, "radius": foot.x, "lift": foot.y, "index": _slot()})

## The footprint radius of a thing and the height of its lowest point over its origin (plus the lift), from the boxes of its meshes.
func _measure(node: Node3D) -> Vector2:
	var low: float = INF
	var reach: float = 0.0
	for found in node.find_children("*", "MeshInstance3D", true, false):
		var mesh := found as MeshInstance3D
		if mesh.mesh == null or not mesh.is_visible_in_tree():
			continue
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		low = minf(low, box.position.y)
		reach = maxf(reach, maxf(box.size.x, box.size.z) * 0.5)
	if low == INF:
		return Vector2(0.4, LIFT_M)
	return Vector2(reach, LIFT_M if node.is_in_group(&"pickup") else low - node.global_position.y + LIFT_M)

func _slot() -> int:
	if not _free.is_empty():
		return _free.pop_back()
	_top = mini(_top + 1, CAPACITY)
	multimesh.visible_instance_count = _top
	return _top - 1

func _write(index: int, at: Vector3, radius: float) -> void:
	multimesh.set_instance_transform(index, Transform3D(Basis.from_scale(Vector3.ONE * radius * SPREAD), at))

func _hide(index: int) -> void:
	multimesh.set_instance_transform(index, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))

## The pools of light under the GLOW_CAP nearest pickups with a glow: the colour is the pickup's, the strength faded with the distance from the camera.
func _update_glow() -> void:
	var camera := get_viewport().get_camera_3d()
	var near: Array[Array] = []
	if camera != null:
		for entry in _tracked:
			var node: Node3D = entry["node"] as Node3D if is_instance_valid(entry["node"]) else null
			var glow: Color = node.get_meta(&"glow", Color(0.0, 0.0, 0.0, 0.0)) if node != null else Color(0.0, 0.0, 0.0, 0.0)
			var reach: float = node.global_position.distance_to(camera.global_position) if glow.a > 0.0 else GLOW_FADE_TO_M
			if reach < GLOW_FADE_TO_M:
				near.append([reach, node.global_position, glow])
	near.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var count: int = mini(near.size(), GLOW_CAP)
	glow_strengths.clear()
	for i in count:
		var at: Vector3 = near[i][1]
		var glow: Color = near[i][2]
		var fade: float = 1.0 - clampf((float(near[i][0]) - GLOW_FADE_FROM_M) / (GLOW_FADE_TO_M - GLOW_FADE_FROM_M), 0.0, 1.0)
		_glow.multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * GLOW_SIZE_M), Vector3(at.x, GROUND_Y + LIFT_M * 1.5, at.z)))
		_glow.multimesh.set_instance_color(i, Color(glow.r, glow.g, glow.b, glow.a * fade))
		glow_strengths.append(glow.a * fade)
	_glow.multimesh.visible_instance_count = count
