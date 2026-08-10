

extends "res://legacy_quarantine/enemies2d/enemy_fps.gd"

@onready 

var flashlight: SpotLight3D = $SpotLight3D

@onready 

var light_timer: Timer = $LightTimer
var _light_on: bool = true
func _ready() -> void:
	super._ready()
	if light_timer:
		light_timer.timeout.connect(_toggle_light)

func _toggle_light() -> void:
	_light_on = !_light_on
	if flashlight:
		flashlight.visible = _light_on
	if light_timer:
		light_timer.wait_time = randf_range(2.0, 8.0)
	light_timer.start()

func _do_chase(delta: float) -> void:
	super._do_chase(delta)
	if flashlight:
		flashlight.look_at(_target.global_position if _target else global_position + Vector3.FORWARD)