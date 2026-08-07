extends CanvasLayer

## Toast notification system — всплывающие сообщения (достижения, квесты, находки).

signal toast_dismissed()

@onready var _timer: Timer = Timer.new()
var _queue: Array[Dictionary] = []
var _active: bool = false

const DURATION: float = 3.0
const TOAST_HEIGHT: float = 60.0

func _ready() -> void:
	layer = 100
	_timer.wait_time = DURATION
	_timer.one_shot = true
	_timer.timeout.connect(_on_timeout)
	add_child(_timer)

## Показать toast: text (строка), type (achievement/finding/warning/quest)
func show_toast(text: String, type: String = "finding") -> void:
	_queue.append({"text": text, "type": type})
	if not _active:
		_display_next()

func _display_next() -> void:
	if _queue.is_empty():
		_active = false
		return
	_active = true
	var data: Dictionary = _queue.pop_front()
	var color: Color
	var icon_text: String
	match data["type"]:
		"achievement":
			color = Color("c9a24a")
			icon_text = "*"
		"quest":
			color = Color("4a9ab5")
			icon_text = "?"
		"warning":
			color = Color("b4452f")
			icon_text = "!"
		_:
			color = Color("aeb6bf")
			icon_text = "-"
	_build_toast(data["text"], color, icon_text)
	_timer.start()

func _build_toast(text: String, color: Color, icon_text: String) -> void:
	for c in get_children():
		if c is Control:
			c.queue_free()
	await get_tree().process_frame

	var panel := PanelContainer.new()
	panel.anchors_preset = Control.PRESET_TOP_RIGHT
	panel.anchor_left = 0.65
	panel.anchor_right = 0.95
	panel.anchor_top = 0.02
	panel.anchor_bottom = 0.0
	panel.offset_bottom = TOAST_HEIGHT
	var style := StyleBoxFlat.new()
	style.bg_color = Color("141b24")
	style.border_color = color
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	panel.add_child(hbox)

	var icon_label := Label.new()
	icon_label.text = icon_text
	icon_label.add_theme_color_override("font_color", color)
	icon_label.custom_minimum_size = Vector2(20, 0)
	hbox.add_child(icon_label)

	var msg_label := Label.new()
	msg_label.text = text
	msg_label.add_theme_color_override("font_color", Color("d8d2c4"))
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	hbox.add_child(msg_label)

	add_child(panel)
	_fade_in(panel)

func _fade_in(panel: Control) -> void:
	panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.2)

func _on_timeout() -> void:
	for c in get_children():
		if c is Control:
			var tw := create_tween()
			tw.tween_property(c, "modulate:a", 0.0, 0.3)
			tw.tween_callback(c.queue_free)
	toast_dismissed.emit()
	await get_tree().create_timer(0.4).timeout
	_display_next()
