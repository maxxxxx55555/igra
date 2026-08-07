
extends Node

@onready 
var player: CharacterBody3D = get_parent()

@onready 
var camera: Camera3D = player.get_node("Camera3D")

var _is_dying: bool = false

func _ready() -> void:
	var health := player.get_node_or_null("HealthComponent")
	if health:
		health.died.connect(_on_died)

func _on_died() -> void:
	if _is_dying:
		return
	_is_dying = true
	Engine.time_scale = 0.3
	_red_out()
	await get_tree().create_timer(1.0).timeout
	Engine.time_scale = 1.0
	EventBus.player_died.emit()

func _red_out() -> void:
	var canvas := CanvasLayer.new()
	var rect := ColorRect.new()
	rect.color = Color(0.5, 0, 0, 0)
	rect.anchors_preset = Control.PRESET_FULL_RECT
	canvas.add_child(rect)
	player.add_child(canvas)
	
	var tween := create_tween()
	tween.tween_property(rect, "color:a", 0.8, 0.8)
