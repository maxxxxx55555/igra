extends Node
## T17: авто-подстройка графики под FPS поверх существующих тиров
## SettingsManager.GRAPHICS_TIERS (0=Low..3=Ultra).
##
## FPS < 30 пять секунд подряд -> тир вниз. FPS >= 45 десять секунд
## подряд -> тир вверх, но не выше "потолка" — тира, который последним
## выбрал сам игрок в настройках (авто-подъём не должен превышать то,
## что игрок выставил вручную).
##
## Session 23 (docs/CORRECTION_LOG.md 241): Low and Medium cap the frame rate at 30, where 45 FPS never comes, so a manager that had stepped down could not step up again, and the 29.x FPS
## of a machine that holds the cap counted as "under 30". Both limits are no higher than CAP_SHARE of the cap now; each drop doubles the wait before the next raise, so a machine that cannot
## hold a tier does not flip between two every 15 s; the tier the player chose is kept under `graphics_ceiling`, because the one the manager applies is saved with the settings.

const LOW_FPS: float = 30.0
const STABLE_FPS: float = 45.0
const DROP_AFTER: float = 5.0
const RAISE_AFTER: float = 10.0
const CAP_SHARE: float = 0.9

var enabled: bool = true
var _low_timer: float = 0.0
var _stable_timer: float = 0.0
var _raise_after: float = RAISE_AFTER
var _ceiling: int = 2
var _adjusting_self: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ceiling = int(SettingsManager.get_setting("graphics_ceiling", SettingsManager.get_setting("graphics_tier", 2)))
	EventBus.settings_changed.connect(_on_settings_changed)

func _on_settings_changed(key: String, value: Variant) -> void:
	if key != "graphics_tier" or _adjusting_self:
		return
	_ceiling = int(value)
	SettingsManager.set_setting("graphics_ceiling", int(value))
	_raise_after = RAISE_AFTER
	_low_timer = 0.0
	_stable_timer = 0.0

func _process(delta: float) -> void:
	step(Engine.get_frames_per_second(), delta)

## One reading of the frame rate (the last second), taken `delta` seconds after the one before.
func step(fps: float, delta: float) -> void:
	if not enabled or not GameManager.is_playing():
		_low_timer = 0.0
		_stable_timer = 0.0
		return
	var tier := int(SettingsManager.get_setting("graphics_tier", 2))
	var limit := float(Engine.max_fps) * CAP_SHARE
	if fps < minf(LOW_FPS, limit):
		_low_timer += delta
		_stable_timer = 0.0
		if _low_timer >= DROP_AFTER and tier > 0:
			_low_timer = 0.0
			_raise_after *= 2.0
			_set_tier(tier - 1)
	elif fps >= minf(STABLE_FPS, limit):
		_stable_timer += delta
		_low_timer = 0.0
		if _stable_timer >= _raise_after and tier < _ceiling:
			_stable_timer = 0.0
			_set_tier(tier + 1)
	else:
		_low_timer = 0.0
		_stable_timer = 0.0

func _set_tier(idx: int) -> void:
	_adjusting_self = true
	SettingsManager.set_setting("graphics_ceiling", _ceiling)
	SettingsManager.set_graphics_tier(idx)
	_adjusting_self = false
