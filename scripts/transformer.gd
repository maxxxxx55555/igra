class_name Transformer
extends Node3D

@onready var voltage_dial: Node3D = %VoltageDial
@onready var interact_area: Area3D = %InteractArea

var target_voltage: int = 240
var current_voltage: int = 0
var voltage_step: int = 20
var is_solved: bool = false
var is_player_near: bool = false

signal voltage_changed(voltage: int)
signal transformer_solved()
signal transformer_mismatch()


func _ready() -> void:
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	current_voltage = voltage_step


func interact() -> void:
	if is_solved:
		return
	current_voltage += voltage_step
	if current_voltage > 300:
		current_voltage = voltage_step
	voltage_changed.emit(current_voltage)
	_check_solution()


func _check_solution() -> void:
	if current_voltage == target_voltage:
		is_solved = true
		transformer_solved.emit()
	else:
		transformer_mismatch.emit()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		is_player_near = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		is_player_near = false
