extends Node
class_name EnemyPool
## Mobile-safe enemy pool and district spawn-point owner.

const MIN_ENEMIES_PER_DISTRICT: int = 3
const DEFAULT_ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/shadow_3d.tscn")
const DEFAULT_SPAWN_OFFSETS: Array[Vector3] = [
	Vector3(-12.0, 0.0, -10.0),
	Vector3(12.0, 0.0, -8.0),
	Vector3(0.0, 0.0, 14.0),
]

@export var max_active: int = 8
@export var enemy_scene: PackedScene = DEFAULT_ENEMY_SCENE

var _active: int = 0

func spawn_for_district(parent: Node3D) -> Array[Node3D]:
	var spawned: Array[Node3D] = []
	var points: Array[Vector3] = _district_spawn_points(parent)
	for point: Vector3 in points:
		var enemy: Node3D = try_spawn(enemy_scene, point, parent)
		if enemy != null:
			spawned.append(enemy)
	return spawned

func try_spawn(scene: PackedScene, pos: Vector3, parent: Node) -> Node3D:
	if scene == null or parent == null or _active >= max_active:
		return null
	var enemy: Node3D = scene.instantiate() as Node3D
	if enemy == null:
		return null
	parent.add_child(enemy)
	enemy.global_position = pos
	_active += 1
	enemy.tree_exited.connect(_on_dead, CONNECT_ONE_SHOT)
	EventBus.enemy_spawned.emit(enemy)
	return enemy

func _district_spawn_points(parent: Node3D) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var container: Node = parent.get_node_or_null("EnemySpawnPoints")
	if container != null:
		for child: Node in container.get_children():
			if child is Marker3D:
				points.append((child as Marker3D).global_position)
	if points.size() < MIN_ENEMIES_PER_DISTRICT:
		points.clear()
		for offset: Vector3 in DEFAULT_SPAWN_OFFSETS:
			points.append(parent.global_position + offset)
	return points

func _on_dead() -> void:
	_active = maxi(0, _active - 1)

func active_count() -> int:
	return _active
