
extends StaticBody3D

@export
var required_key: String = "key_red"

@export
var is_open: bool = false

@onready
var mesh: MeshInstance3D = $MeshInstance3D

@onready
var collision: CollisionShape3D = $CollisionShape3D

const _OPEN_SFX := preload("res://assets/audio/sfx/interact/door_open_wood.wav")
const _LOCKED_SFX := preload("res://assets/audio/sfx/interact/door_close_wood.wav")

func interact(player: Node3D) -> void:
	if is_open:
		return

	var inv := player.get_node_or_null("InventoryManager")
	if inv and inv.has_item(required_key):
		_open()
	else:
		_show_locked()

func _open() -> void:
	is_open = true
	AudioManager.play_sound_3d(_OPEN_SFX, global_position, -6.0, &"Environment")

	var tween := create_tween()
	tween.tween_property(mesh, "position:y", -2.0, 1.0).set_trans(Tween.TRANS_QUAD)
	collision.disabled = true

func _show_locked() -> void:
	AudioManager.play_sound_3d(_LOCKED_SFX, global_position, -8.0, &"Environment")

	var tween := create_tween()
	tween.tween_property(mesh, "position:z", 0.2, 0.1)
	tween.tween_property(mesh, "position:z", 0.0, 0.1)
