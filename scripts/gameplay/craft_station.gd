extends Node3D
## S8 workbench in the world (GDD §9): interact opens the workbench screen (ui/workbench.gd), where every
## recipe lives (crafting/workbench_logic.gd). The portable workbench, an ability crafted from its blueprint,
## opens the same screen anywhere with the "workbench" key (player_3d.gd).

const SIZE := Vector3(1.4, 1.0, 0.8)

func _ready() -> void:
	add_to_group("interactable")
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = SIZE
	mesh.mesh = box
	mesh.position = Vector3(0.0, SIZE.y * 0.5, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.28, 0.2)
	mesh.material_override = mat
	add_child(mesh)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = SIZE
	shape.shape = box_shape
	shape.position = mesh.position
	body.add_child(shape)
	add_child(body)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.8, 0.4)
	light.light_energy = 1.2
	light.omni_range = 4.0
	light.shadow_enabled = false
	light.position = Vector3(0.0, 1.6, 0.0)
	add_child(light)

func can_interact() -> bool:
	return true

func interact(_player: Node) -> void:
	UIManager.open(&"workbench")

func interact_prompt() -> String:
	return LocalizationManager.t("PROMPT_WORKBENCH")
