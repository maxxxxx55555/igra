extends RefCounted
## Spent cases (docs/VFX_BUDGET.md). A shot throws a little brass case to the right of the aim; it falls, bounces on the street and lies there
## for LIFE_SEC before it goes back to the pool. At most POOL cases exist: with all of them in the air the oldest is thrown again. The Effects
## setting at Low throws none.

const POOL: int = 10
const LIFE_SEC: float = 2.0
const CASE_LENGTH: float = 0.045
const CASE_RADIUS: float = 0.009
const CASE_MASS: float = 0.02
const BOUNCE: float = 0.45
const CASE_COLOR := Color("#8a7338")
const THROW_SIDE: float = 1.3  # m/s to the right of the aim
const THROW_UP: float = 1.6  # m/s up
const THROW_BACK: float = 0.4  # m/s away from the muzzle
const SPIN: float = 18.0

static var _cases: Array[RigidBody3D] = []
static var _next: int = 0

## Throws a case from `from` (the weapon) with `aim` the direction of the shot. Returns it, or null at Effects Low.
static func eject(tree: SceneTree, from: Vector3, aim: Vector3) -> RigidBody3D:
	if int(SettingsManager.get_setting("effects", 2)) < 1:
		return null
	var body := _take(tree)
	var side: Vector3 = aim.cross(Vector3.UP).normalized()
	body.linear_velocity = Vector3.ZERO
	body.angular_velocity = Vector3.ZERO
	body.global_position = from
	body.visible = true
	body.freeze = false
	body.linear_velocity = side * THROW_SIDE + Vector3.UP * THROW_UP - aim * THROW_BACK + Vector3(randf_range(-0.2, 0.2), 0.0, randf_range(-0.2, 0.2))
	body.angular_velocity = Vector3(randf_range(-SPIN, SPIN), randf_range(-SPIN, SPIN), randf_range(-SPIN, SPIN))
	var ticket: int = int(body.get_meta(&"ticket", 0)) + 1
	body.set_meta(&"ticket", ticket)
	tree.create_timer(LIFE_SEC).timeout.connect(func() -> void:
		if is_instance_valid(body) and int(body.get_meta(&"ticket", 0)) == ticket:
			body.freeze = true
			body.visible = false)
	return body

static func _take(tree: SceneTree) -> RigidBody3D:
	for body in _cases:
		if is_instance_valid(body) and not body.visible:
			return body
	var alive: Array[RigidBody3D] = []
	for body in _cases:
		if is_instance_valid(body):
			alive.append(body)
	_cases = alive
	if _cases.size() >= POOL:
		_next = (_next + 1) % _cases.size()
		return _cases[_next]
	var fresh := RigidBody3D.new()
	fresh.name = "ShellCase"
	fresh.mass = CASE_MASS
	fresh.collision_layer = 0
	fresh.collision_mask = 1
	var bounce := PhysicsMaterial.new()
	bounce.bounce = BOUNCE
	bounce.friction = 0.6
	fresh.physics_material_override = bounce
	var collider := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = CASE_RADIUS
	shape.height = CASE_LENGTH
	collider.shape = shape
	fresh.add_child(collider)
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = CASE_RADIUS
	cylinder.bottom_radius = CASE_RADIUS
	cylinder.height = CASE_LENGTH
	cylinder.radial_segments = 6
	cylinder.rings = 1
	var material := StandardMaterial3D.new()
	material.albedo_color = CASE_COLOR
	material.metallic = 0.8
	material.roughness = 0.4
	cylinder.material = material
	mesh.mesh = cylinder
	fresh.add_child(mesh)
	tree.root.add_child(fresh)
	_cases.append(fresh)
	return fresh
