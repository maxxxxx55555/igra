

extends CanvasLayer

@onready 

var map_container: Control = $MapContainer
var _is_open: bool = false
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_map"):
		_toggle_map()

func _toggle_map() -> void:
	_is_open = !_is_open
	if map_container:
		map_container.visible = _is_open
	get_tree().paused = _is_open
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _is_open else Input.MOUSE_MODE_CAPTURED