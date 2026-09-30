extends CanvasLayer
## P0 (CONTENT UX wave): EventBus.toast_requested is emitted from 10+ call
## sites (puzzle_system.gd, power_switch.gd, finale_director.gd, ftue_*.gd,
## daily_events_ui.gd) but had zero listeners anywhere in the project —
## every "+5 coins", "District restored!", "Boss appears" notification was
## silently dropped. Emitter call sites are unchanged; message text is
## exactly what they already send.
##
## This file already existed (committed, unused - never instantiated
## anywhere, never connected to the signal, own show_toast() API nobody
## called) with a different design: top-right, one-at-a-time via a Timer
## queue, text-glyph icons, and a type vocabulary (achievement/quest/
## warning/finding) that doesn't match what's actually emitted (finding/
## achievement/objective/danger - "warning"/"quest" never fire). This wave
## asks for top-left, up to 3 simultaneous, real icons_v2 art - a different
## shape, not a tweak - so replaced rather than patched. Prior version is
## in git history (commit bddbded) if any of it is wanted later.
##
## GDD V.1 3.5/3.14: every toast now carries a run-clock stamp in the GDD's
## own "[12.42]" shape (minutes.seconds off GameManager.play_time), and this
## manager keeps a rolling history the player can read back - a toast fades
## after 3.5 s and used to be unrecoverable, so any message missed while
## fighting was lost for good.

const MAX_VISIBLE: int = 3
const FADE_IN: float = 0.2
const HOLD: float = 3.5
const FADE_OUT: float = 0.3

## 3.14: how many read-back entries the log keeps.
const HISTORY_MAX: int = 50
## Share Tech Mono - the canon font for numbers/stats (GDD 11.3).
const _MONO_FONT_PATH: String = "res://assets/fonts/ShareTechMono-Regular.ttf"
var _mono_font: Font = null
var _mono_font_loaded: bool = false

## type -> icons_v2/event_*_48.png. Only "danger" and "objective" have a
## real semantic match (siren = alarm, breaker = power event); "finding"
## and "achievement" (the other two types actually emitted) render
## text-only by design, not by a missing-file accident - ResourceLoader.
## exists() is still checked so a renamed/missing file degrades the same way.
const _TYPE_ICON: Dictionary = {
	"danger": "res://assets/textures/icons_v2/event_siren_48.png",
	"objective": "res://assets/textures/icons_v2/event_breaker_48.png",
}

var _column: VBoxContainer
var _header: Control
var _log_toggle: Button
var _log_panel: PanelContainer
var _log_title: Label
var _log_scroll: ScrollContainer
var _log_rows: VBoxContainer
var _stack: VBoxContainer
var _queue: Array[Dictionary] = []
var _visible_count: int = 0
## 3.14: newest last, capped at HISTORY_MAX.
var _history: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root.position = Vector2(16, 16)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_column = VBoxContainer.new()
	_column.name = "ToastColumn"
	_column.add_theme_constant_override("separation", 8)
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_column)
	_build_log_header()
	_stack = VBoxContainer.new()
	_stack.name = "ToastStack"
	_stack.add_theme_constant_override("separation", 8)
	_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_child(_stack)
	_build_log_panel()
	EventBus.toast_requested.connect(_on_toast_requested)
	EventBus.hud_visibility_changed.connect(_on_hud_visibility)
	LocalizationManager.language_changed.connect(_retranslate)
	_retranslate()

func _on_toast_requested(text: String, type: String) -> void:
	var entry := _record(text, type)
	_queue.append(entry)
	_pump()

## 3.5/3.14: "[12.42]" = minutes.seconds of the current run.
func _stamp() -> String:
	var total := int(maxf(GameManager.play_time, 0.0))
	return "[%d.%02d]" % [total / 60, total % 60]

## Same guarded load ThemeProvider uses for fonts: the editor is the only thing
## that generates a .ttf's import metadata, so a checkout that never imported
## degrades to the theme's body font instead of failing this script.
func _load_mono_font() -> Font:
	if not _mono_font_loaded:
		_mono_font_loaded = true
		if ResourceLoader.exists(_MONO_FONT_PATH):
			_mono_font = load(_MONO_FONT_PATH) as Font
	return _mono_font

## Run-clock stamp label (3.5/3.14) with the mono number font when available.
func _make_stamp_label(stamp_text: String) -> Label:
	var stamp := Label.new()
	stamp.text = stamp_text
	var mono := _load_mono_font()
	if mono != null:
		stamp.add_theme_font_override("font", mono)
	stamp.add_theme_font_size_override("font_size", 12)
	stamp.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
	return stamp

## Records every requested message, whether or not it still fits on screen.
func _record(text: String, type: String) -> Dictionary:
	var entry := {"text": text, "type": type, "stamp": _stamp()}
	_history.append(entry)
	if _history.size() > HISTORY_MAX:
		_history.remove_at(0)
	if _log_panel.visible:
		if _history.size() == 1:
			_rebuild_log()
		else:
			_append_log_row(entry)
			_scroll_log_to_end()
	return entry

func _build_log_header() -> void:
	_header = HBoxContainer.new()
	_header.name = "LogHeader"
	_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_child(_header)
	_log_toggle = Button.new()
	_log_toggle.name = "LogToggle"
	_log_toggle.focus_mode = Control.FOCUS_NONE
	_log_toggle.add_theme_font_size_override("font_size", 12)
	_log_toggle.pressed.connect(_toggle_log)
	_header.add_child(_log_toggle)

func _build_log_panel() -> void:
	_log_panel = PanelContainer.new()
	_log_panel.name = "LogPanel"
	_log_panel.custom_minimum_size = Vector2(360, 220)
	_log_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_log_panel.visible = false
	_log_panel.add_theme_stylebox_override("panel", _panel_style())
	_column.add_child(_log_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	_log_panel.add_child(vb)
	_log_title = Label.new()
	_log_title.add_theme_font_size_override("font_size", 14)
	_log_title.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	vb.add_child(_log_title)
	_log_scroll = ScrollContainer.new()
	_log_scroll.name = "LogScroll"
	_log_scroll.custom_minimum_size = Vector2(340, 180)
	_log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(_log_scroll)
	_log_rows = VBoxContainer.new()
	_log_rows.name = "LogRows"
	_log_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_rows.add_theme_constant_override("separation", 4)
	_log_scroll.add_child(_log_rows)

## GDD 11.4: panels are `panel` fill, a 1 px `panel-edge` frame, chamfer (radius
## 0) and a light drop shadow; amber is the accent for active text, not for every
## message frame - the toast rectangle used to outline itself in brass.
func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(ThemeProvider.COLOR_BG_PANEL.r, ThemeProvider.COLOR_BG_PANEL.g,
		ThemeProvider.COLOR_BG_PANEL.b, 0.92)
	sb.border_color = ThemeProvider.COLOR_BORDER
	sb.set_border_width_all(1)
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0.0, 2.0)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb

func _toggle_log() -> void:
	_log_panel.visible = not _log_panel.visible
	if _log_panel.visible:
		_rebuild_log()

func _rebuild_log() -> void:
	for c in _log_rows.get_children():
		_log_rows.remove_child(c)
		c.queue_free()
	if _history.is_empty():
		var empty := Label.new()
		empty.text = LocalizationManager.t("HUD_LOG_EMPTY")
		empty.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
		_log_rows.add_child(empty)
		return
	for entry in _history:
		_append_log_row(entry)
	_scroll_log_to_end()

func _append_log_row(entry: Dictionary) -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	hb.add_child(_make_stamp_label(String(entry.get("stamp", _stamp()))))
	var text := Label.new()
	text.text = String(entry.get("text", ""))
	text.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(text)
	_log_rows.add_child(hb)

func _scroll_log_to_end() -> void:
	call_deferred("_apply_log_scroll")

## Waits one frame: the scroll bar's max_value is only final after the new rows
## have been laid out, so reading it in the same frame pins the view to the top.
func _apply_log_scroll() -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if is_instance_valid(_log_scroll):
		_log_scroll.scroll_vertical = int(_log_scroll.get_v_scroll_bar().max_value)

## A blocking screen (pause, codex, city map) hides the HUD; the log follows it
## instead of drawing a 360 px panel over the open menu.
func _on_hud_visibility(v: bool) -> void:
	_header.visible = v
	if not v:
		_log_panel.visible = false

func _retranslate(_lang: Variant = null) -> void:
	_log_toggle.text = LocalizationManager.t("HUD_LOG_TOGGLE")
	_log_title.text = LocalizationManager.t("HUD_LOG_TITLE")
	if _log_panel.visible:
		_rebuild_log()

func _pump() -> void:
	while _visible_count < MAX_VISIBLE and not _queue.is_empty():
		_show(_queue.pop_front())

func _show(data: Dictionary) -> void:
	_visible_count += 1
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", _panel_style())
	row.modulate.a = 0.0
	_stack.add_child(row)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	row.add_child(hb)

	hb.add_child(_make_stamp_label(String(data.get("stamp", _stamp()))))

	var icon_path: String = _TYPE_ICON.get(String(data["type"]), "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var icon := TextureRect.new()
		icon.texture = load(icon_path)
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hb.add_child(icon)

	var lbl := Label.new()
	lbl.text = String(data["text"])
	lbl.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT)
	hb.add_child(lbl)

	# docs/GAMEFEEL_SPEC.md: scale-pop stands in for a particle burst on
	# finding/achievement/daily-quest toasts — same trigger points, no new
	# GPUParticles scene needed. Gated: a repeated pop-in is exactly the
	# kind of motion Reduce UI Motion exists to turn off. Deferred one frame
	# so row.size reflects the icon+label layout, not zero.
	var reduce_motion := bool(SettingsManager.get_setting("reduce_ui_motion", false))
	if not reduce_motion:
		call_deferred("_pop_in", row)

	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(row, "modulate:a", 1.0, FADE_IN)
	tw.tween_interval(HOLD)
	tw.tween_property(row, "modulate:a", 0.0, FADE_OUT)
	tw.tween_callback(func() -> void:
		row.queue_free()
		_visible_count -= 1
		_pump())

func _pop_in(row: Control) -> void:
	if not is_instance_valid(row):
		return
	row.pivot_offset = row.size / 2.0
	row.scale = Vector2(0.85, 0.85)
	var pop := create_tween()
	pop.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	pop.tween_property(row, "scale", Vector2.ONE, FADE_IN).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
