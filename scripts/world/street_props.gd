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

const _TEX_BRICK       := "res://assets/textures/environment/brick.png"
const _TEX_RUSTY_METAL := "res://assets/textures/environment/rusty_metal.png"
const _TEX_STREETLIGHT := "res://assets/textures/surfaces/streetlight_metal_512.png"
const _TEX_BENCH       := "res://assets/textures/surfaces/bench_wood_512.png"

## Returns a StandardMaterial3D with albedo_texture loaded from path.
## Falls back to albedo_color if the texture file is missing.
static func _wall_material(tex_path: String, fallback_color: Color) -> StandardMaterial3D:
	return _prop_material(tex_path, fallback_color, 0.9, 0.0)

## Same idea as _wall_material() but for props: optional texture, always a
## deliberate roughness/metallic so nothing renders at the engine's flat-grey
## default (roughness 1 / metallic 0 / albedo ~0.8,0.8,0.8).
static func _prop_material(tex_path: String, fallback_color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = fallback_color
	if not tex_path.is_empty():
		var tex: Texture2D = load(tex_path)
		if tex:
			mat.albedo_texture = tex
	mat.roughness = roughness
	mat.metallic = metallic
	return mat

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
		p.material_override = _prop_material(_TEX_STREETLIGHT, Color(0.15, 0.15, 0.18), 0.55, 0.6)
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
	b.material_override = _prop_material(_TEX_BENCH, Color(0.35, 0.25, 0.15), 0.85, 0.0)
	b.position = center + _side_offset(road, 2.8)
	add_child(b)

func _spawn_tree(center: Vector3, road: Dictionary) -> void:
	var off: Vector3 = _side_offset(road, 2.8)
	var t := MeshInstance3D.new()
	t.mesh = _trunk
	t.material_override = _prop_material("", Color(0.3, 0.18, 0.08), 0.95, 0.0)
	t.position = center + off
	add_child(t)
	var l := MeshInstance3D.new()
	l.mesh = _leaf
	l.position = t.position + Vector3(0.0, 1.8, 0.0)
	l.material_override = _prop_material("", Color(0.15, 0.45, 0.18), 0.9, 0.0)
	add_child(l)

func _spawn_cone(center: Vector3, road: Dictionary) -> void:
	var c := MeshInstance3D.new()
	c.mesh = _cone
	var m := _prop_material("", Color(1.0, 0.55, 0.1), 0.6, 0.0)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.45, 0.05)
	m.emission_energy_multiplier = 0.6
	c.material_override = m
	c.position = center + _side_offset(road, 2.4)
	add_child(c)

## Convenience: build a wall MeshInstance3D with brick or rusty_metal texture.
## Call from a building-spawner script: CityStreetProps.make_wall_mesh(...)
static func make_wall_mesh(use_brick: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = BoxMesh.new()
	mi.material_override = _wall_material(
		_TEX_BRICK if use_brick else _TEX_RUSTY_METAL,
		Color(0.45, 0.32, 0.25) if use_brick else Color(0.35, 0.22, 0.18)
	)
	return mi
