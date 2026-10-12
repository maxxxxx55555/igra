extends Area3D
## A box of space with a reverb of its own (a tunnel, a room, an open yard): while the player is inside, AudioManager uses the preset instead of what
## its rays sense (AudioManager.ZONE_PRESETS). Leaving hands the reverb back to the rays.

@export var preset: StringName = &"room"
@export var size: Vector3 = Vector3(8.0, 4.0, 8.0)

func _ready() -> void:
	add_to_group("reverb_zone")
	collision_layer = 0
	collision_mask = 1
	if get_child_count() == 0:
		var box := BoxShape3D.new()
		box.size = size
		var shape := CollisionShape3D.new()
		shape.shape = box
		add_child(shape)
	body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("player"):
			AudioManager.enter_reverb_zone(preset))
	body_exited.connect(func(body: Node) -> void:
		if body.is_in_group("player"):
			AudioManager.exit_reverb_zone(preset))
