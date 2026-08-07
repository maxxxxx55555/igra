extends Node3D
class_name CityDecorator

@export var district_id: StringName = &""
@export var street_builder_path: NodePath
@export var density: float = 1.0
@export var prop_seed: int = 0

@onready var _street = get_node_or_null(street_builder_path)
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	if prop_seed == 0:
		prop_seed = hash(str(district_id))
	_rng.seed = prop_seed
	if _street == null:
		return
	if not _street.streets_ready.is_connected(_on_streets_ready):
		_street.streets_ready.connect(_on_streets_ready)
	if _street.roads.size() > 0:
		_on_streets_ready()

func _on_streets_ready() -> void:
	if _street.roads.is_empty():
		return
	var total := int(24 * density)
	for i in range(total):
		var mm := MultiMeshInstance3D.new()
		mm.name = "Prop_%d" % i
		mm.multimesh = MultiMesh.new()
		mm.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		mm.multimesh.mesh = _make_box_mesh(Color(0.3, 0.3, 0.3))
		mm.multimesh.instance_count = 1
		add_child(mm)
		mm.multimesh.set_instance_transform(0, _random_transform())

func _make_box_mesh(color: Color) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = Vector3(0.5, 1.0, 0.5)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	m.material = mat
	return m

func _random_transform() -> Transform3D:
	var road: Dictionary = _street.roads[_rng.randi() % _street.roads.size()]
	var steps := int(road.length / _street.tile_size)
	var s: int = _rng.randi() % max(1, steps)
	var pos: Vector3 = _street.road_step_pos(road, s)
	var side: float = -1.0 if _rng.randi() % 2 == 0 else 1.0
	var off: float = _street.road_width * 0.5 + 1.0
	var lateral: Vector3 = Vector3(0, 0, off * side) if road.dir == "h" else Vector3(off * side, 0, 0)
	var t := Transform3D()
	t.origin = pos + lateral
	t.basis = t.basis.rotated(Vector3.UP, _rng.randf() * TAU)
	return t
