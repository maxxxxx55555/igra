extends Control
## DamageVignette — красная кайма при HP < 30%.
## Добавляется как дочерний узел HUD или UILayer (CanvasLayer).
## Слушает EventBus.player_health_changed(ratio: float).

const HP_THRESHOLD: float = 0.30
const PULSE_PERIOD: float = 1.2  # секунды на один пульс

var _overlay: ColorRect
var _pulsing: bool = false
var _pulse_time: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay = ColorRect.new()
	_overlay.color = Color(0.6, 0.0, 0.0, 0.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	EventBus.player_health_changed.connect(_on_health)

func _on_health(ratio: float) -> void:
	if ratio < HP_THRESHOLD:
		if not _pulsing:
			_pulsing = true
			_pulse_time = 0.0
	else:
		_pulsing = false
		_overlay.color.a = 0.0

func _process(delta: float) -> void:
	if not _pulsing:
		return
	_pulse_time += delta
	# Синусоидальный пульс: 0 → 0.45 → 0
	var alpha: float = (sin(_pulse_time / PULSE_PERIOD * TAU - PI * 0.5) * 0.5 + 0.5) * 0.45
	_overlay.color.a = alpha
