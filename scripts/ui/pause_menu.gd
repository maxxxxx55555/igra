extends Control
func _ready() -> void:
    _build()
func _build() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_preset(Control.PRESET_FULL_RECT)
    theme = ThemeProvider.build_theme()
    var bg := ColorRect.new()
    bg.color = Color(0.04, 0.05, 0.07, 0.92)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var panel := PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.custom_minimum_size = Vector2(380, 320)
    add_child(panel)
    var vb := VBoxContainer.new()
    vb.add_theme_constant_override("separation", 12)
    panel.add_child(vb)
    var t := Label.new()
    t.text = "ПАУЗА"
    t.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_TITLE)
    t.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
    t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vb.add_child(t)
    _btn(vb, "Продолжить", func() -> void: UIManager.close(&"pause"); GameManager.resume_game())
    _btn(vb, "Настройки", func() -> void: UIManager.open(&"settings"))
    _btn(vb, "Карта электросети", func() -> void: UIManager.open(&"city_map"))
    _btn(vb, "В главное меню", func() -> void: GameManager.return_to_menu())
func _btn(p: Node, text: String, cb: Callable) -> void:
    var b := Button.new()
    b.text = text
    b.focus_mode = Control.FOCUS_NONE
    b.pressed.connect(cb)
    p.add_child(b)