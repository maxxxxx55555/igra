extends Control
## Visual fog/rain layer only: the weather state and its audio live in WeatherSystem and are never touched here.
## Suppressed on the Low graphics tier (the rain_lens.gd pattern): hidden, with no drawing or ticking work, and it
## reacts live to a tier change. UIManager no longer drives its visibility - this overlay owns it (game state + tier).
var _fog: float = 0.0
var _rain: float = 0.0
var _t: float = 0.0
var _tier: int = 2

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_tier = int(SettingsManager.get_setting("graphics_tier", 2))
	EventBus.weather_changed.connect(_on_weather)
	EventBus.settings_changed.connect(_on_settings_changed)
	EventBus.game_state_changed.connect(_on_game_state)
	_sync_visibility()

func _on_settings_changed(key: String, value: Variant) -> void:
	if key == "graphics_tier":
		_tier = int(value)
		_sync_visibility()

func _on_game_state(_state: int) -> void:
	_sync_visibility()

func _sync_visibility() -> void:
	visible = _tier > 0 and GameManager.is_playing()
	set_process(visible and (_fog > 0.0 or _rain > 0.0))
	if visible:
		queue_redraw()

func _on_weather(_w: int, _name: String, fog: float, rain: float) -> void:
	_fog = fog
	_rain = rain
	set_process(visible and (_fog > 0.0 or _rain > 0.0))
	if visible:
		queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	if not visible:
		return
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