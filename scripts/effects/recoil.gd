
extends Node

@export 
var recoil_amount: float = 0.05

@export 
var recoil_recovery: float = 5.0

var _current_recoil: float = 0.0

var _camera: Camera3D = null

func setup(camera: Camera3D) -> void:
	_camera = camera

func add_recoil() -> void:
	_current_recoil += recoil_amount

func _process(delta: float) -> void:
	if _camera and _current_recoil > 0:
		_camera.rotation.x -= _current_recoil
		_current_recoil = max(0.0, _current_recoil - recoil_recovery * delta)
