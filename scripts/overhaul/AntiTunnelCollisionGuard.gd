class_name AntiTunnelCollisionGuard
extends Node

## Hard anti-walk-through & anti-tunneling guard for multi-story buildings & player movement.

@export var max_delta_sec: float = 0.05
@export var max_substep_distance_m: float = 0.15
@export var max_substeps: int = 8
@export var min_safe_margin_m: float = 0.045
@export var world_collision_layer: int = 1
@export var auto_harden_world_on_ready: bool = true
@export var auto_create_missing_static_colliders: bool = true

var _last_safe_transform: Transform3D = Transform3D.IDENTITY
var _has_safe_transform: bool = false

const DECORATIVE_NAME_TOKENS: Array[String] = [
	"sky", "fog", "cloud", "dust", "rain", "puddle", "decal",
	"light", "glow", "halo", "beam", "cone", "particle", "grass", "leaf", "wire", "cable"
]


func _ready() -> void:
	var parent_body: CharacterBody3D = get_parent() as CharacterBody3D
	if parent_body != null:
		if parent_body.safe_margin < min_safe_margin_m:
			parent_body.safe_margin = min_safe_margin_m
		if (parent_body.collision_mask & world_collision_layer) == 0:
			parent_body.collision_mask |= world_collision_layer
		_last_safe_transform = parent_body.global_transform
		_has_safe_transform = true
	if auto_harden_world_on_ready and get_tree() != null and get_tree().current_scene != null:
		call_deferred("harden_world_colliders", get_tree().current_scene)


func move_guarded(body: CharacterBody3D, desired_velocity: Vector3, delta: float) -> Vector3:
	if not is_instance_valid(body):
		return Vector3.ZERO
	var safe_vel: Vector3 = _sanitize_vec3(desired_velocity)
	var clamped_delta: float = clampf(delta, 0.0, max_delta_sec)
	var phys_delta: float = get_physics_process_delta_time()
	if clamped_delta <= 0.0 or phys_delta <= 0.0:
		return Vector3.ZERO

	if body.test_move(body.global_transform, Vector3.ZERO):
		if _has_safe_transform:
			body.global_transform = _last_safe_transform
	else:
		_last_safe_transform = body.global_transform
		_has_safe_transform = true

	var travel_dist: float = safe_vel.length() * clamped_delta
	var horizontal := Vector3(safe_vel.x, 0.0, safe_vel.z)
	if horizontal.length() > 0.001 and travel_dist > max_substep_distance_m:
		var space := body.get_world_3d().direct_space_state
		var from := body.global_transform.origin + Vector3.UP * 0.8
		var to := from + horizontal.normalized() * max_substep_distance_m
		var query := PhysicsRayQueryParameters3D.create(from, to, world_collision_layer, [body])
		query.hit_from_inside = true
		query.hit_back_faces = true
		if not space.intersect_ray(query).is_empty():
			safe_vel.x = 0.0
			safe_vel.z = 0.0
			travel_dist = absf(safe_vel.y) * clamped_delta
	var steps: int = clampi(ceili(travel_dist / maxf(0.05, max_substep_distance_m)), 1, max_substeps)
	var step_scale: float = clamped_delta / (phys_delta * float(steps))

	var working_vel: Vector3 = safe_vel * step_scale
	for _i in range(steps):
		body.velocity = working_vel
		body.move_and_slide()
		working_vel = _sanitize_vec3(body.velocity)

	var final_vel: Vector3 = working_vel / maxf(0.0001, step_scale)
	body.velocity = final_vel

	if not body.test_move(body.global_transform, Vector3.ZERO):
		_last_safe_transform = body.global_transform
		_has_safe_transform = true
	return final_vel


func harden_world_colliders(root: Node) -> Dictionary:
	var hardened_concave: int = 0
	var fixed_layers: int = 0
	var generated_colliders: int = 0
	var stack: Array[Node] = [root]

	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)

		if node is CollisionShape3D:
			var cs: CollisionShape3D = node as CollisionShape3D
			if cs.shape is ConcavePolygonShape3D:
				var concave: ConcavePolygonShape3D = cs.shape as ConcavePolygonShape3D
				if not concave.backface_collision:
					concave.backface_collision = true
					hardened_concave += 1
		elif node is StaticBody3D:
			var sb: StaticBody3D = node as StaticBody3D
			if (sb.collision_layer & world_collision_layer) == 0:
				sb.collision_layer |= world_collision_layer
				fixed_layers += 1
		elif auto_create_missing_static_colliders and node is MeshInstance3D:
			var mi: MeshInstance3D = node as MeshInstance3D
			if mi.visible and mi.mesh != null and not _is_decorative(mi.name) and not _has_associated_collider(mi):
				if not _is_inside_dynamic_entity(mi):
					var local_aabb: AABB = mi.get_aabb()
					if local_aabb.size.x >= 0.35 and local_aabb.size.y >= 1.2 and local_aabb.size.z >= 0.35 and _is_boxy_building_or_wall(mi.name, local_aabb):
						_attach_box_collider(mi, local_aabb)
					else:
						mi.create_trimesh_collision()
						for new_child in mi.get_children():
							if new_child is StaticBody3D:
								(new_child as StaticBody3D).collision_layer |= world_collision_layer
								for gc in new_child.get_children():
									if gc is CollisionShape3D and (gc as CollisionShape3D).shape is ConcavePolygonShape3D:
										((gc as CollisionShape3D).shape as ConcavePolygonShape3D).backface_collision = true
					generated_colliders += 1

	return {
		"hardened_concave_shapes": hardened_concave,
		"fixed_static_layers": fixed_layers,
		"runtime_generated_colliders": generated_colliders,
	}


func _attach_box_collider(mi: MeshInstance3D, local_aabb: AABB) -> void:
	var sb: StaticBody3D = StaticBody3D.new()
	sb.name = "AutoSolidBody"
	sb.collision_layer = world_collision_layer
	sb.collision_mask = 0
	var cs: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(maxf(0.4, local_aabb.size.x), maxf(0.4, local_aabb.size.y), maxf(0.4, local_aabb.size.z))
	cs.shape = box
	cs.position = local_aabb.get_center()
	sb.add_child(cs)
	mi.add_child(sb)


func _is_boxy_building_or_wall(node_name: String, aabb: AABB) -> bool:
	var ln: String = node_name.to_lower()
	for tok in ["building", "house", "block", "tower", "facade", "wall", "fence", "pillar", "khrushch", "panel"]:
		if ln.contains(tok):
			return true
	return aabb.size.y >= 3.5 and aabb.size.x >= 2.0 and aabb.size.z >= 2.0


func _is_decorative(node_name: String) -> bool:
	var lower: String = node_name.to_lower()
	for tok in DECORATIVE_NAME_TOKENS:
		if lower.contains(tok):
			return true
	return false


func _is_inside_dynamic_entity(node: Node) -> bool:
	var p: Node = node.get_parent()
	while p != null:
		if p is CharacterBody3D or p is RigidBody3D or p is Skeleton3D or p is Area3D:
			return true
		var ln: String = p.name.to_lower()
		if ln.contains("pickup") or ln.contains("scrap") or ln.contains("item") or ln.contains("player") or ln.contains("enemy"):
			return true
		p = p.get_parent()
	return false


func _has_associated_collider(mi: MeshInstance3D) -> bool:
	if mi.get_parent() is CollisionObject3D:
		return true
	for child in mi.get_children():
		if child is CollisionObject3D or child is CollisionShape3D:
			return true
	var parent: Node = mi.get_parent()
	if parent != null:
		for sibling in parent.get_children():
			if sibling is CollisionObject3D or sibling is CollisionShape3D:
				return true
	return false


func _sanitize_vec3(v: Vector3) -> Vector3:
	return Vector3(
		0.0 if (is_nan(v.x) or is_inf(v.x)) else clampf(v.x, -60.0, 60.0),
		0.0 if (is_nan(v.y) or is_inf(v.y)) else clampf(v.y, -60.0, 60.0),
		0.0 if (is_nan(v.z) or is_inf(v.z)) else clampf(v.z, -60.0, 60.0)
	)
