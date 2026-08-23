extends Node
## T17: авто-подстройка графики под FPS поверх существующих тиров
## SettingsManager.GRAPHICS_TIERS (0=Low..3=Ultra).
##
## FPS < 30 пять секунд подряд -> тир вниз. FPS >= 45 десять секунд
## подряд -> тир вверх, но не выше "потолка" — тира, который последним
## выбрал сам игрок в настройках (авто-подъём не должен превышать то,
## что игрок выставил вручную).

const LOW_FPS: float = 30.0
const STABLE_FPS: float = 45.0
const DROP_AFTER: float = 5.0
const RAISE_AFTER: float = 10.0

var enabled: bool = true
var _low_timer: float = 0.0
var _stable_timer: float = 0.0
var _ceiling: int = 2
var _adjusting_self: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ceiling = int(SettingsManager.get_setting("graphics_tier", 2))
	EventBus.settings_changed.connect(_on_settings_changed)

func _on_settings_changed(key: String, value: Variant) -> void:
	if key != "graphics_tier" or _adjusting_self:
		return
	_ceiling = int(value)
	_low_timer = 0.0
	_stable_timer = 0.0

func _process(delta: float) -> void:
	if not enabled or not GameManager.is_playing():
		_low_timer = 0.0
		_stable_timer = 0.0
		return
	var fps := Engine.get_frames_per_second()
	var tier := int(SettingsManager.get_setting("graphics_tier", 2))
	if fps < LOW_FPS:
		_low_timer += delta
		_stable_timer = 0.0
		if _low_timer >= DROP_AFTER and tier > 0:
			_low_timer = 0.0
			_set_tier(tier - 1)
	elif fps >= STABLE_FPS:
		_stable_timer += delta
		_low_timer = 0.0
		if _stable_timer >= RAISE_AFTER and tier < _ceiling:
			_stable_timer = 0.0
			_set_tier(tier + 1)
	else:
		_low_timer = 0.0
		_stable_timer = 0.0

func _set_tier(idx: int) -> void:
	_adjusting_self = true
	SettingsManager.set_graphics_tier(idx)
	_adjusting_self = false
