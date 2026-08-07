extends CanvasLayer

var _queue: Array = []
var _current_idx: int = 0
var _active: bool = false

func start_dialog(lines: Array) -> void:
	if _active: return
	_queue = lines
	_current_idx = 0
	_active = true
	_show_line()

func _show_line() -> void:
	if _current_idx >= _queue.size():
		_end_dialog()
		return
	var line = _queue[_current_idx]
	_show_panel(line.speaker, line.text)
	get_tree().paused = true

func _show_panel(speaker: String, text: String) -> void:
	hide()
	var panel := ColorRect.new()
	panel.color = Color(0.078, 0.106, 0.141, 0.95)
	panel.size = Vector2(get_viewport().size.x, 160)
	panel.position = Vector2(0, get_viewport().size.y - 160)
	panel.name = "DialogPanel"
	add_child(panel)
	var name_lbl := Label.new()
	name_lbl.text = speaker.to_upper()
	name_lbl.position = Vector2(120, 16)
	name_lbl.add_theme_color_override("font_color", Color(0.847, 0.824, 0.769))
	name_lbl.add_theme_font_size_override("font_size", 20)
	panel.add_child(name_lbl)
	var text_lbl := Label.new()
	text_lbl.text = text
	text_lbl.position = Vector2(120, 50)
	text_lbl.size = Vector2(panel.size.x - 140, 80)
	text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_lbl.add_theme_color_override("font_color", Color(0.682, 0.714, 0.749))
	text_lbl.add_theme_font_size_override("font_size", 16)
	panel.add_child(text_lbl)
	var skip_lbl := Label.new()
	skip_lbl.text = "ПРОПУСТИТЬ [SPACE]"
	skip_lbl.position = Vector2(panel.size.x - 160, panel.size.y - 30)
	skip_lbl.add_theme_color_override("font_color", Color(0.541, 0.451, 0.220))
	skip_lbl.add_theme_font_size_override("font_size", 10)
	panel.add_child(skip_lbl)
	var portrait := ColorRect.new()
	portrait.color = Color(0.165, 0.200, 0.251)
	portrait.size = Vector2(80, 80)
	portrait.position = Vector2(20, 40)
	panel.add_child(portrait)

func _input(event: InputEvent) -> void:
	if not _active: return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("close_screen"):
		_current_idx += 1
		if _current_idx >= _queue.size():
			_end_dialog()
		else:
			_show_line()
		get_viewport().set_input_as_handled()

func _end_dialog() -> void:
	_active = false
	hide()
	get_tree().paused = false

func is_active() -> bool:
	return _active
