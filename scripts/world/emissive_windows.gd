extends Node3D
class_name EmissiveWindows

@export var window_count: int = 60
@export var random_seed: int = 0
@export var lit_chance: float = 0.65
@export var warm_color: bool = true

var _rng := RandomNumberGenerator.new()
var _win_mesh: QuadMesh
var _win_mat: StandardMaterial3D

func _ready() -> void:
	_rng.seed = random_seed if random_seed != 0 else hash(str(global_position))
	_win_mesh = QuadMesh.new()
	_win_mesh.size = Vector2(0.6, 0.9)
	_win_mat = StandardMaterial3D.new()
	_win_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if warm_color:
		_win_mat.albedo_color = Color(1.0, 0.85, 0.45)
		_win_mat.emission = Color(1.0, 0.78, 0.35)
	else:
		_win_mat.albedo_color = Color(0.75, 0.85, 1.0)
		_win_mat.emission = Color(0.55, 0.70, 1.0)
	_win_mat.emission_enabled = true
	_win_mat.emission_energy_multiplier = 1.6
	call_deferred("populate")

func populate() -> void:
	var walls: Array[MeshInstance3D] = []
	_collect_walls(self, walls)
	if walls.is_empty():
		return
	var n: int = mini(window_count, walls.size() * 6)
	for i in range(n):
		var w: MeshInstance3D = walls[_rng.randi_range(0, walls.size() - 1)]
		var aabb: AABB = w.get_aabb()
		if aabb.size.length() < 0.5:
			continue
		var face: int = _rng.randi_range(0, 3)
		var u: float = _rng.randf()
		var v: float = _rng.randf()
		var origin: Vector3 = aabb.position
		var basis: Basis = Basis()
		if face == 0:
			basis = Basis(Vector3.UP, 0.0) * Basis(Vector3.RIGHT, PI * 0.5)
			origin += Vector3(u * aabb.size.x, v * aabb.size.y, aabb.size.z)
		elif face == 1:
			basis = Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, PI * 0.5)
			origin += Vector3(u * aabb.size.x, v * aabb.size.y, 0.0)
		elif face == 2:
			basis = Basis(Vector3.UP, -PI * 0.5) * Basis(Vector3.RIGHT, PI * 0.5)
			origin += Vector3(aabb.size.x, v * aabb.size.y, u * aabb.size.z)
		else:
			basis = Basis(Vector3.UP, PI * 0.5) * Basis(Vector3.RIGHT, PI * 0.5)
			origin += Vector3(0.0, v * aabb.size.y, u * aabb.size.z)
		var node := MeshInstance3D.new()
		node.mesh = _win_mesh
		node.material_override = _win_mat
		node.transform = Transform3D(basis, origin)
		w.add_child(node)
		node.visible = _rng.randf() < lit_chance

func _collect_walls(n: Node, out: Array[MeshInstance3D]) -> void:
	if n is MeshInstance3D and String((n as MeshInstance3D).name) != "Ground":
		out.append(n)
	for c in n.get_children():
		_collect_walls(c, out)