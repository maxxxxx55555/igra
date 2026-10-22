extends Node3D
## GDD achievement "Midsummer Night's Dream" (ach_19): a bed in the first district. Sleeping fades out and in,
## restores the player's health and counts for the achievement (AchievementManager listens to EventBus.slept).

const SIZE := Vector3(2.0, 0.5, 1.0)
const _Props := preload("res://scripts/art/prop_meshes.gd")

func _ready() -> void:
	add_to_group("interactable")
	var mattress := MeshInstance3D.new()
	_Props.dress(mattress, "bed")
	add_child(mattress)
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

func interact(player: Node) -> void:
	FadeTransition.fade_to(func() -> void:
		if is_instance_valid(player) and player.has_method("heal"):
			player.heal(1000.0)
		EventBus.slept.emit()
		EventBus.inventory_notice.emit(LocalizationManager.t("SLEPT")))

func interact_prompt() -> String:
	return LocalizationManager.t("PROMPT_SLEEP")
