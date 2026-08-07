class_name TrapComponent
extends Area3D

@export var damage: int = 30
@export var trigger_delay: float = 0.5
@export var reset_time: float = 5.0
@export var is_mine: bool = false

var _armed: bool = true
var _triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not _armed or _triggered:
		return
	if body.is_in_group("player") or body.is_in_group("enemy"):
		_trigger()

func _trigger() -> void:
	_triggered = true
	await get_tree().create_timer(trigger_delay).timeout
	for body in get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(damage)
	_visual_trigger()
	if is_mine:
		queue_free()
		return
	await get_tree().create_timer(reset_time).timeout
	_reset()

func _visual_trigger() -> void:
	var am := get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx(preload("res://assets/audio/sfx/sfx_click.wav"))
	var mesh := get_node_or_null("MeshInstance3D")
	if mesh:
		mesh.visible = false

func _reset() -> void:
	_triggered = false
	_armed = true
	var mesh := get_node_or_null("MeshInstance3D")
	if mesh:
		mesh.visible = true
