class_name ElectronicDoor
extends Node3D

@onready var door_mesh: Node3D = %DoorMesh
@onready var interact_area: Area3D = %InteractArea

var is_open: bool = false
var requires_power: bool = true
var has_power: bool = false
var is_locked: bool = false
var is_player_near: bool = false

signal door_opened()
signal door_closed()
signal door_locked()
signal power_required()


func _ready() -> void:
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)


func set_power(state: bool) -> void:
	has_power = state
	if has_power and is_locked:
		is_locked = false
		door_locked.emit()


func interact() -> void:
	if is_locked:
		door_locked.emit()
		return
	if requires_power and not has_power:
		power_required.emit()
		return
	if is_open:
		_close()
	else:
		_open()


func lock() -> void:
	is_locked = true
	is_open = false
	door_locked.emit()


func unlock() -> void:
	is_locked = false
	door_locked.emit()


func _open() -> void:
	is_open = true
	door_opened.emit()


func _close() -> void:
	is_open = false
	door_closed.emit()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		is_player_near = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		is_player_near = false
