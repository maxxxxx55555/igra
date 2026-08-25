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

const MAX_VISIBLE: int = 3
const FADE_IN: float = 0.2
const HOLD: float = 3.5
const FADE_OUT: float = 0.3

## type -> icons_v2/event_*_48.png. Only "danger" and "objective" have a
## real semantic match (siren = alarm, breaker = power event); "finding"
## and "achievement" (the other two types actually emitted) render
## text-only by design, not by a missing-file accident - ResourceLoader.
## exists() is still checked so a renamed/missing file degrades the same way.
const _TYPE_ICON: Dictionary = {
	"danger": "res://assets/textures/icons_v2/event_siren_48.png",
	"objective": "res://assets/textures/icons_v2/event_breaker_48.png",
}

var _stack: VBoxContainer
var _queue: Array[Dictionary] = []
var _visible_count: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root.position = Vector2(16, 16)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_stack = VBoxContainer.new()
	_stack.add_theme_constant_override("separation", 8)
	_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_stack)
	EventBus.toast_requested.connect(_on_toast_requested)

func _on_toast_requested(text: String, type: String) -> void:
	_queue.append({"text": text, "type": type})
	_pump()

func _pump() -> void:
	while _visible_count < MAX_VISIBLE and not _queue.is_empty():
		_show(_queue.pop_front())

func _show(data: Dictionary) -> void:
	_visible_count += 1
	var row := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(ThemeProvider.COLOR_BG_PANEL.r, ThemeProvider.COLOR_BG_PANEL.g,
		ThemeProvider.COLOR_BG_PANEL.b, 0.92)
	sb.border_color = ThemeProvider.COLOR_AMBER
	sb.set_border_width_all(1)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	row.add_theme_stylebox_override("panel", sb)
	row.modulate.a = 0.0
	_stack.add_child(row)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	row.add_child(hb)

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

	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(row, "modulate:a", 1.0, FADE_IN)
	tw.tween_interval(HOLD)
	tw.tween_property(row, "modulate:a", 0.0, FADE_OUT)
	tw.tween_callback(func() -> void:
		row.queue_free()
		_visible_count -= 1
		_pump())
