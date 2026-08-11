extends CanvasLayer

@export var show_splash: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if not show_splash:
		queue_free()
		return
	if GameManager and GameManager.has_method("is_playing") and GameManager.is_playing():
		queue_free()
		return
	$Timer.timeout.connect(_dismiss)

func _dismiss() -> void:
	if GameManager and GameManager.has_method("return_to_menu"):
		GameManager.return_to_menu()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton or (event is InputEventKey and event.pressed):
		if visible:
			_dismiss()
