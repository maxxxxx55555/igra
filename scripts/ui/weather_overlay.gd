extends Control
var _fog: float = 0.0
var _rain: float = 0.0
var _t: float = 0.0
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	EventBus.weather_changed.connect(_on_weather)
func _on_weather(_w: int, _name: String, fog: float, rain: float) -> void:
	_fog = fog
	_rain = rain
func _process(delta: float) -> void:
	if _fog > 0.0 or _rain > 0.0:
		_t += delta
		queue_redraw()
func _draw() -> void:
	var r := get_rect()
	if _fog > 0.0:
		draw_rect(r, Color(0.05, 0.06, 0.08, _fog * 0.8))
	if _rain > 0.0:
		var count := int(40 * _rain)
		var col := Color(0.7, 0.8, 0.95, 0.25 * _rain)
		for i in count:
			var x := fmod(i * 53.0 + _t * 600.0, r.size.x + 40.0) - 20.0
			var y := fmod(i * 91.0 + _t * 1400.0, r.size.y + 60.0) - 30.0
			draw_line(Vector2(x, y), Vector2(x - 6.0, y + 24.0), col, 1.0)