extends Area3D

@export var debug_color: Color = Color(0.2, 0.6, 1.0, 0.15)
@export var debug_visible: bool = true

var _camera: Node3D = null

func _ready() -> void:
	add_to_group("interior_zone")
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_debug_vis()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if _camera == null:
			_camera = get_tree().root.find_child("CameraFollow3D", true, false)
		if _camera and _camera.has_method("set_interior"):
			_camera.set_interior(true)


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		if _camera and is_instance_valid(_camera) and _camera.has_method("set_interior"):
			_camera.set_interior(false)


func _update_debug_vis() -> void:
	if not debug_visible:
		return
	var shape_node := find_child("CollisionShape3D", true, false) as CollisionShape3D
	if shape_node and shape_node.shape is BoxShape3D:
		var box: BoxShape3D = shape_node.shape
		var mi := MeshInstance3D.new()
		mi.name = "InteriorZoneDebug"
		var box_mesh := BoxMesh.new()
		box_mesh.size = box.size
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = debug_color
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		box_mesh.material = mat
		mi.mesh = box_mesh
		add_child(mi)
		mi.owner = self