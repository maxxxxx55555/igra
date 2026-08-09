extends CanvasLayer
## FadeTransition — автозагрузка. Чёрный fade-out → callback → fade-in.
## Использование: FadeTransition.fade_to(callable, duration)

const DEFAULT_DURATION := 0.35

var _overlay: ColorRect
var _busy: bool = false

func _ready() -> void:
	layer = 100
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func fade_to(callback: Callable, duration: float = DEFAULT_DURATION) -> void:
	if _busy:
		return
	_busy = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_overlay, "color", Color(0, 0, 0, 1.0), duration).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		callback.call()
		var tw2 := create_tween()
		tw2.tween_property(_overlay, "color", Color(0, 0, 0, 0.0), duration).set_ease(Tween.EASE_OUT)
		tw2.tween_callback(func() -> void:
			_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_busy = false
		)
	)

func fade_in(duration: float = DEFAULT_DURATION) -> void:
	_overlay.color = Color(0, 0, 0, 1.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_overlay, "color", Color(0, 0, 0, 0.0), duration).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void: _overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE)

func fade_out(duration: float = DEFAULT_DURATION) -> void:
	var tw := create_tween()
	tw.tween_property(_overlay, "color", Color(0, 0, 0, 1.0), duration).set_ease(Tween.EASE_IN)
