extends Area3D

signal entered_hiding(player: Node3D)
signal exited_hiding(player: Node3D)

@export var hide_duration: float = 0.5
@export var detection_multiplier: float = 0.3

var _player_inside: bool = false
var _player_ref: Node3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		_player_ref = body as Node3D
		entered_hiding.emit(body as Node3D)

func _on_body_exited(body: Node) -> void:
	if body == _player_ref:
		_player_inside = false
		_player_ref = null
		exited_hiding.emit(body as Node3D)

func is_player_hiding() -> bool:
	return _player_inside

func get_detection_multiplier() -> float:
	return detection_multiplier

func get_hide_duration() -> float:
	return hide_duration