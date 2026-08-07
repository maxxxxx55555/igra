extends Node3D
class_name CityStreetProps
## Reads StreetBuilder.roads, spawns poles+lamps+benches+trees+cones per theme.

@export var street_builder_path: NodePath
@export var density: float = 1.0
@export var random_seed: int = 0

var _rng := RandomNumberGenerator.new()
var _pole: CylinderMesh
var _lamp: SphereMesh
var _bench: BoxMesh
var _trunk: CylinderMesh
var _leaf: SphereMesh
var _cone: CylinderMesh

func _ready() -> void:
	_rng.seed = random_seed if random_seed != 0 else hash(str(global_position))
	_init_meshes()
	call_deferred("build")

func _init_meshes() -> void:
	_pole = CylinderMesh.new()
	_pole.top_radius = 0.06
	_pole.bottom_radius = 0.08
	_pole.height = 4.0
	_lamp = SphereMesh.new()
	_lamp.radius = 0.18
	_lamp.height = 0.36
	_bench = BoxMesh.new()
	_bench.size = Vector3(1.6, 0.4, 0.5)
	_trunk = CylinderMesh.new()
	_trunk.top_radius = 0.12
	_trunk.bottom_radius = 0.18
	_trunk.height = 2.5
	_leaf = SphereMesh.new()
	_leaf.radius = 1.2
	_leaf.height = 2.4
	_cone = CylinderMesh.new()
	_cone.top_radius = 0.0
	_cone.bottom_radius = 0.35
	_cone.height = 0.7

func build() -> void:
	var sb: Node = get_node_or_null(street_builder_path)
	if sb == null:
		return
	var step: int = 4
	for road in sb.roads:
		var length: float = float(road.get("length", 0.0))
		var count: int = max(1, int(length / (float(step) * 4.0)))
		for s in range(count):
			var pos: Vector3 = sb.road_step_pos(road, s * step)
			_spawn_pole_pair(pos, road)
			if _rng.randf() < 0.30 * density:
				_spawn_bench(pos, road)
			if _rng.randf() < 0.25 * density:
				_spawn_tree(pos, road)
			if _rng.randf() < 0.15 * density:
				_spawn_cone(pos, road)

func _side_offset(road: Dictionary, dist: float) -> Vector3:
	var dir: String = String(road.get("dir", "h"))
	return Vector3(0.0, 0.0, dist) if dir == "h" else Vector3(dist, 0.0, 0.0)

func _spawn_pole_pair(center: Vector3, road: Dictionary) -> void:
	var perp: Vector3 = _side_offset(road, 3.5)
	for side in [-1, 1]:
		var p := MeshInstance3D.new()
		p.mesh = _pole
		var pm := StandardMaterial3D.new()
		pm.albedo_color = Color(0.15, 0.15, 0.18)
		p.material_override = pm
		p.position = center + perp * float(side)
		add_child(p)
		var l := MeshInstance3D.new()
		l.mesh = _lamp
		var lm := StandardMaterial3D.new()
		lm.albedo_color = Color(1.0, 0.92, 0.75)
		lm.emission_enabled = true
		lm.emission = Color(1.0, 0.85, 0.55)
		lm.emission_energy_multiplier = 2.0
		l.material_override = lm
		l.position = p.position + Vector3(0.0, 2.2, 0.0)
		add_child(l)

func _spawn_bench(center: Vector3, road: Dictionary) -> void:
	var b := MeshInstance3D.new()
	b.mesh = _bench
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.35, 0.25, 0.15)
	b.material_override = m
	b.position = center + _side_offset(road, 2.8)
	add_child(b)

func _spawn_tree(center: Vector3, road: Dictionary) -> void:
	var off: Vector3 = _side_offset(road, 2.8)
	var t := MeshInstance3D.new()
	t.mesh = _trunk
	var tm := StandardMaterial3D.new()
	tm.albedo_color = Color(0.3, 0.18, 0.08)
	t.material_override = tm
	t.position = center + off
	add_child(t)
	var l := MeshInstance3D.new()
	l.mesh = _leaf
	l.position = t.position + Vector3(0.0, 1.8, 0.0)
	var lm := StandardMaterial3D.new()
	lm.albedo_color = Color(0.15, 0.45, 0.18)
	l.material_override = lm
	add_child(l)

func _spawn_cone(center: Vector3, road: Dictionary) -> void:
	var c := MeshInstance3D.new()
	c.mesh = _cone
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.55, 0.1)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.45, 0.05)
	m.emission_energy_multiplier = 0.6
	c.material_override = m
	c.position = center + _side_offset(road, 2.4)
	add_child(c)