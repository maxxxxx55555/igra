extends CanvasLayer
## D21: TransitionManager - fade mezhdu vsem

@onready var rect: ColorRect = $FadeRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color(0, 0, 0, 0)

func fade_out(time: float = 0.18) -> void:
	var tw = create_tween()
	tw.tween_property(rect, "color", Color(0, 0, 0, 1), time)
	await tw.finished

func fade_in(time: float = 0.18) -> void:
	var tw = create_tween()
	tw.tween_property(rect, "color", Color(0, 0, 0, 0), time)
	await tw.finished