extends Node3D
## GDD achievement "Midsummer Night's Dream" (ach_19): a bed in the first district. Sleeping fades out and in,
## restores the player's health and counts for the achievement (AchievementManager listens to EventBus.slept).

const SIZE := Vector3(2.0, 0.5, 1.0)

func _ready() -> void:
	add_to_group("interactable")
	var mattress := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = SIZE
	mattress.mesh = box
	mattress.position = Vector3(0.0, SIZE.y * 0.5, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.27, 0.22, 0.2)
	mattress.material_override = mat
	add_child(mattress)
	var pillow := MeshInstance3D.new()
	var pillow_box := BoxMesh.new()
	pillow_box.size = Vector3(0.5, 0.15, 0.8)
	pillow.mesh = pillow_box
	pillow.position = Vector3(-0.7, SIZE.y + 0.07, 0.0)
	var pillow_mat := StandardMaterial3D.new()
	pillow_mat.albedo_color = Color(0.55, 0.52, 0.46)
	pillow.material_override = pillow_mat
	add_child(pillow)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = SIZE
	shape.shape = box_shape
	shape.position = mattress.position
	body.add_child(shape)
	add_child(body)

func can_interact() -> bool:
	return true

func interact(player: Node) -> void:
	FadeTransition.fade_to(func() -> void:
		if is_instance_valid(player) and player.has_method("heal"):
			player.heal(1000.0)
		EventBus.slept.emit()
		EventBus.inventory_notice.emit(LocalizationManager.t("SLEPT")))

func interact_prompt() -> String:
	return LocalizationManager.t("PROMPT_SLEEP")
