extends Node3D
## S8 workbench in the world (GDD §9): interact opens the workbench screen (ui/workbench.gd), where every
## recipe lives (crafting/workbench_logic.gd). The portable workbench, an ability crafted from its blueprint,
## opens the same screen anywhere with the "workbench" key (player_3d.gd).

const SIZE := Vector3(1.4, 1.0, 0.8)
const _Props := preload("res://scripts/art/prop_meshes.gd")

func _ready() -> void:
	add_to_group("interactable")
	var mesh := MeshInstance3D.new()
	_Props.dress(mesh, "workbench")
	add_child(mesh)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = SIZE
	shape.shape = box_shape
	shape.position = Vector3(0.0, SIZE.y * 0.5, 0.0)
	body.add_child(shape)
	add_child(body)

func can_interact() -> bool:
	return true

func interact(_player: Node) -> void:
	UIManager.open(&"workbench")

func interact_prompt() -> String:
	return LocalizationManager.t("PROMPT_WORKBENCH")
