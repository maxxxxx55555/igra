extends MultiMeshInstance3D
## W6 of docs/VISUAL_PASS.md section 8: contact shadows, what stops things looking as if they float. ONE MultiMesh of soft dark blobs (assets/shaders/contact_shadow.gdshader) LIFT_M above the ground: under the props of
## the district (`stamp`, from street_props.gd) and under what stands on it and is spawned by other scripts, found by group (the monsters, the pickups, the hiding spots, the barrels: none of those scripts knows about this
## one). One draw call for all of them, and none on the Low tier (visual_quality.tres, key contact_shadows).

const SHADER: String = "res://assets/shaders/contact_shadow.gdshader"
const GROUPS: Array[StringName] = [&"monsters", &"pickups", &"hiding_spot", &"barrels"]
const CAPACITY: int = 256
const LIFT_M: float = 0.02
## The top of the street tiles: a box of street_builder.gd TILE_THICKNESS 0.1 centred on y = 0.
const GROUND_Y: float = 0.05
const SCAN_SEC: float = 0.5
## The blob is a soft disc inside its quad: the quad is this many radii of the thing wide.
const SPREAD: float = 2.6

var _top: int = 0
var _free: Array[int] = []
var _tracked: Array[Dictionary] = []
var _scan: float = 0.0

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
			if node == null or node.has_meta(&"contact_shadow") or not node.is_inside_tree():
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
	return Vector2(reach, low - node.global_position.y + LIFT_M)

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
