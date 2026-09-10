extends Control
## Photo mode overlay — corner frame, shot counter, and scalar colour
## filters. Every filter is applied on top of a snapshot of the live
## WorldEnvironment taken when photo mode opens, and the snapshot is
## restored on close or when switching to "none" — so a filter can never
## leak into normal gameplay (the old scripts/systems/photo_mode.gd never
## restored anything).

var active: bool = false
var _shots: int = 0

const FILTERS: Array[String] = ["none", "noir", "faded", "vivid", "bright", "moody", "bloom"]
var _fi: int = 0
var _env_snap: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false

func toggle() -> void:
	active = not active
	visible = active
	EventBus.hud_visibility_changed.emit(not active)
	EventBus.inventory_notice.emit(LocalizationManager.t("PHOTO_MODE_ON" if active else "PHOTO_MODE_OFF"))
	if active:
		_snapshot_env()
		_apply_filter()
	else:
		_restore_env()
		_fi = 0
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not active or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.is_action_pressed("photo_capture"):
		_shots += 1
		EventBus.inventory_notice.emit(LocalizationManager.tf("PHOTO_SAVED", [_shots]))
		queue_redraw()
	elif event.keycode == KEY_TAB:
		_fi = (_fi + 1) % FILTERS.size()
		_apply_filter()
		EventBus.inventory_notice.emit(LocalizationManager.tf("PHOTO_FILTER", [FILTERS[_fi]]))
		queue_redraw()

func _env() -> Environment:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return null
	var w := cam.get_world_3d()
	return w.environment if w != null else null

const _SNAP_KEYS: Array[String] = [
	"adjustment_enabled", "adjustment_brightness", "adjustment_contrast",
	"adjustment_saturation", "glow_enabled", "glow_intensity",
]

func _snapshot_env() -> void:
	var e := _env()
	_env_snap.clear()
	if e == null:
		return
	for k in _SNAP_KEYS:
		_env_snap[k] = e.get(k)

func _restore_env() -> void:
	var e := _env()
	if e == null or _env_snap.is_empty():
		return
	for k in _SNAP_KEYS:
		e.set(k, _env_snap[k])

func _apply_filter() -> void:
	_restore_env()  # always start from the untouched snapshot
	var e := _env()
	if e == null:
		return
	match FILTERS[_fi]:
		"noir":
			e.adjustment_enabled = true
			e.adjustment_saturation = 0.0
			e.adjustment_contrast = 1.4
		"faded":
			e.adjustment_enabled = true
			e.adjustment_saturation = 0.45
			e.adjustment_contrast = 0.92
		"vivid":
			e.adjustment_enabled = true
			e.adjustment_saturation = 1.45
			e.adjustment_contrast = 1.12
		"bright":
			e.adjustment_enabled = true
			e.adjustment_brightness = 1.18
		"moody":
			e.adjustment_enabled = true
			e.adjustment_brightness = 0.82
			e.adjustment_contrast = 1.25
		"bloom":
			e.glow_enabled = true
			e.glow_intensity = float(_env_snap.get("glow_intensity", 0.8)) + 0.9
		_:
			pass  # "none" — snapshot already restored above

func _draw() -> void:
	if not active:
		return
	var r := get_rect()
	var m := 40.0
	var col := ThemeProvider.COLOR_AMBER
	var font := get_theme_default_font()
	for corner in [Vector2(m, m), Vector2(r.size.x - m, m), Vector2(m, r.size.y - m), Vector2(r.size.x - m, r.size.y - m)]:
		draw_arc(corner, 18.0, 0.0, TAU, 16, col, 2.0, true)
	draw_string(font, Vector2(m, m - 12), "PHOTO  #%d  [%s]" % [_shots, FILTERS[_fi]], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)
