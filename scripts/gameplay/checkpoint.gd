
extends Area3D

@onready 
var light: OmniLight3D = $OmniLight3D

@onready 
var particles: GPUParticles3D = $GPUParticles3D

var _activated: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if _activated:
		return
	if body.is_in_group("player"):
		_activate(body)

func _activate(player: Node3D) -> void:
	_activated = true
	light.light_color = Color(0.2, 1.0, 0.4)
	if particles:
		particles.modulate = Color(0.2, 1.0, 0.4)
	SaveSystem.set_checkpoint(get_tree().current_scene.scene_file_path, player.global_position)
	var lm := get_tree().root.get_node_or_null("/root/LevelManager")
	if lm and lm.has_method("set_checkpoint"):
		lm.set_checkpoint(player.global_position)
	EventBus.inventory_notice.emit("ЧЕКПОИНТ АКТИВИРОВАН")
