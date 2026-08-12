extends Node
class_name EnemyPool
## Mobile-safe enemy pool and district spawn-point owner.
##
## Раньше пул спавнил в каждом из 11 районов три одинаковых shadow_3d:
## четыре готовых типа врага (crawler/hunter/watcher/destroyer) не
## использовались вообще, и все районы ощущались одинаково. Теперь состав
## берётся из ROSTER_BY_DISTRICT (GDD §V.3: у каждого района свой набор),
## а количество зависит от стадии энергосети — в темноте тварей больше.

const MIN_ENEMIES_PER_DISTRICT: int = 3
const DEFAULT_ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/shadow_3d.tscn")

const SHADOW: PackedScene = preload("res://scenes/enemies/shadow_3d.tscn")
const CRAWLER: PackedScene = preload("res://scenes/enemies/crawler_3d.tscn")
const HUNTER: PackedScene = preload("res://scenes/enemies/hunter_3d.tscn")
const WATCHER: PackedScene = preload("res://scenes/enemies/watcher_3d.tscn")
const DESTROYER: PackedScene = preload("res://scenes/enemies/destroyer_3d.tscn")

## Состав по районам. Порядок = порядок появления на точках спавна, поэтому
## первым идёт «фоновый» тип района, дальше — редкие и опасные.
const ROSTER_BY_DISTRICT: Dictionary = {
	&"suburbs":       [SHADOW, SHADOW, CRAWLER],
	&"residential":   [SHADOW, CRAWLER, CRAWLER],
	&"park":          [CRAWLER, HUNTER, SHADOW],
	&"school":        [SHADOW, CRAWLER, WATCHER],
	&"hospital":      [WATCHER, SHADOW, CRAWLER],
	&"gas_station":   [HUNTER, SHADOW, CRAWLER],
	&"police":        [WATCHER, HUNTER, DESTROYER],
	&"warehouses":    [CRAWLER, DESTROYER, HUNTER],
	&"industrial":    [DESTROYER, HUNTER, WATCHER],
	&"substation":    [DESTROYER, WATCHER, HUNTER],
	&"power_station": [DESTROYER, DESTROYER, WATCHER],
}

## Смещения точек спавна вокруг центра района — используются, когда в сцене
## района нет узла EnemySpawnPoints. Шесть позиций: до трёх «базовых» и до
## трёх дополнительных для тёмных стадий.
const DEFAULT_SPAWN_OFFSETS: Array[Vector3] = [
	Vector3(-12.0, 0.0, -10.0),
	Vector3(12.0, 0.0, -8.0),
	Vector3(0.0, 0.0, 14.0),
	Vector3(-16.0, 0.0, 6.0),
	Vector3(17.0, 0.0, 9.0),
	Vector3(4.0, 0.0, -17.0),
]

@export var max_active: int = 8
@export var enemy_scene: PackedScene = DEFAULT_ENEMY_SCENE

var _active: int = 0

func spawn_for_district(parent: Node3D) -> Array[Node3D]:
	var district_id: StringName = _district_of(parent)
	var roster: Array = _roster_for(district_id)
	var points: Array[Vector3] = _district_spawn_points(parent, _target_count(district_id))
	var spawned: Array[Node3D] = []
	for i in points.size():
		var scene: PackedScene = roster[i % roster.size()] if not roster.is_empty() else enemy_scene
		var enemy: Node3D = try_spawn(scene, points[i], parent)
		if enemy != null:
			spawned.append(enemy)
	return spawned

## Процедурный район зовётся "District_<id>" (DistrictSceneFactory), готовые
## сцены — "district_<id>" в нижнем регистре, плюс запасной вариант по имени
## файла сцены.
func _district_of(parent: Node3D) -> StringName:
	var n := String(parent.name).to_lower()
	if n.begins_with("district_"):
		var id := StringName(n.substr(9))
		if ROSTER_BY_DISTRICT.has(id):
			return id
	var path := String(parent.scene_file_path)
	if not path.is_empty():
		var from_file := StringName(path.get_file().get_basename())
		if ROSTER_BY_DISTRICT.has(from_file):
			return from_file
	return &"suburbs"

func _roster_for(district_id: StringName) -> Array:
	var roster: Array = ROSTER_BY_DISTRICT.get(district_id, [])
	if roster.is_empty():
		return [enemy_scene] if enemy_scene != null else []
	return roster

## Чем темнее район, тем больше врагов: DARK/PARTIAL — плюс половина состава,
## полностью освещённый район заметно спокойнее.
func _target_count(district_id: StringName) -> int:
	var base: int = MIN_ENEMIES_PER_DISTRICT
	var pg := get_node_or_null("/root/PowerGrid")
	if pg == null or not pg.has_method("get_stage"):
		return base
	var stage: int = int(pg.get_stage(district_id))
	if stage <= 0:
		return base + 3
	if stage == 1:
		return base + 2
	if stage == 2:
		return base + 1
	return base

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

func _district_spawn_points(parent: Node3D, wanted: int) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var container: Node = parent.get_node_or_null("EnemySpawnPoints")
	if container != null:
		for child: Node in container.get_children():
			if child is Marker3D:
				points.append((child as Marker3D).global_position)
	if points.size() >= MIN_ENEMIES_PER_DISTRICT:
		return points
	points.clear()
	for i in mini(wanted, DEFAULT_SPAWN_OFFSETS.size()):
		points.append(parent.global_position + DEFAULT_SPAWN_OFFSETS[i])
	return points

func _on_dead() -> void:
	_active = maxi(0, _active - 1)

func active_count() -> int:
	return _active
