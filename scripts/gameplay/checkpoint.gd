
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
	# Дубль в /root/LevelManager убран: чекпоинт уже сохранён строкой выше.
	EventBus.inventory_notice.emit(LocalizationManager.t("CHECKPOINT_SET"))
