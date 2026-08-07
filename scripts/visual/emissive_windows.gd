extends MultiMeshInstance3D

@export var cols: int = 16
@export var rows: int = 4
@export var density: float = 0.55
@export var warm_bias: float = 0.75
@export var seed_value: int = 0

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.seed = hash(str(get_path()))
	var count := cols * rows
	multimesh = MultiMesh.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.5, 0.7)
	multimesh.mesh = qm
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.instance_count = count
	var ox := -cols * 1.6 * 0.5
	for r in rows:
		for c in cols:
			var idx := r * cols + c
			var t := Transform3D()
			t.origin = Vector3(ox + (c + 0.5) * 1.6, 1.5 + (r + 0.5) * 2.2, 0)
			multimesh.set_instance_transform(idx, t)
			var col: Color
			if _rng.randf() < density:
				if _rng.randf() < warm_bias:
					col = Color(1.0, 0.85, 0.55)
				else:
					col = Color(0.55, 0.7, 1.0)
			else:
				col = Color(0.02, 0.025, 0.04)
			multimesh.set_instance_color(idx, col)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	material_override = mat