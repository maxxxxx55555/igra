class_name Generator
extends Node3D

@onready var power_lever: Node3D = %PowerLever
@onready var fuel_gauge: Node3D = %FuelGauge
@onready var interact_area: Area3D = %InteractArea

var is_active: bool = false
var fuel_level: float = 1.0
var fuel_drain_rate: float = 0.001
var is_player_near: bool = false

signal generator_activated()
signal generator_deactivated()
signal fuel_low()
signal fuel_empty()


func _ready() -> void:
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	if is_active and fuel_level > 0.0:
		fuel_level -= fuel_drain_rate * delta
		if fuel_level <= 0.2 and fuel_level > 0.0:
			fuel_low.emit()
		if fuel_level <= 0.0:
			fuel_level = 0.0
			_deactivate()


func interact() -> void:
	if not is_active and fuel_level > 0.0:
		_activate()
	elif is_active:
		_deactivate()
	else:
		push_warning("Generator: No fuel to activate.")


func refuel(amount: float) -> void:
	fuel_level = min(fuel_level + amount, 1.0)


func _activate() -> void:
	is_active = true
	generator_activated.emit()


func _deactivate() -> void:
	is_active = false
	generator_deactivated.emit()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		is_player_near = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		is_player_near = false
