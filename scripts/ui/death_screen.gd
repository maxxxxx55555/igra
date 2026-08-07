extends Control
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = ThemeProvider.build_theme()
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.02, 0.02, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.add_theme_constant_override("separation", 16)
	add_child(vb)
	var t := Label.new()
	t.text = "ТЫ ПОГИБ В ТЕМНОТЕ"
	t.add_theme_font_size_override("font_size", 28)
	t.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var s := Label.new()
	s.text = "Город остался без света. Попробуй снова."
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
	vb.add_child(s)
	var b := Button.new()
	b.text = "Заново"
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func() -> void: GameManager.start_new_game())
	vb.add_child(b)
	var b2 := Button.new()
	b2.text = "В главное меню"
	b2.focus_mode = Control.FOCUS_NONE
	b2.pressed.connect(func() -> void: GameManager.return_to_menu())
	vb.add_child(b2)
