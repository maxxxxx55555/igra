extends CanvasLayer

enum Phase { IDLE, FADE_IN, HOLD, FADE_OUT }

const FADE_SPEED: float = 4.0
const BLACK_HOLD: float = 0.3

var _rect: ColorRect
var _phase: int = Phase.IDLE
var _hold: float = 0.0
var _cb: Callable = Callable()

func _ready() -> void:
	_rect = ColorRect.new()
	_rect.name = "FadeOverlay"
	_rect.color = Color.BLACK
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)
	layer = 128

func fade_in(callback: Callable = Callable()) -> void:
	_phase = Phase.FADE_IN
	_cb = callback
	_hold = 0.0
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP

func _process(delta: float) -> void:
	match _phase:
		Phase.FADE_IN:
			_rect.modulate.a = minf(1.0, _rect.modulate.a + delta * FADE_SPEED)
			if _rect.modulate.a >= 1.0:
				_phase = Phase.HOLD
				_hold = 0.0
		Phase.HOLD:
			_hold += delta
			if _hold >= BLACK_HOLD:
				_phase = Phase.FADE_OUT
				if _cb:
					_cb.call()
		Phase.FADE_OUT:
			_rect.modulate.a = maxf(0.0, _rect.modulate.a - delta * FADE_SPEED)
			if _rect.modulate.a <= 0.0:
				_phase = Phase.IDLE
				_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE