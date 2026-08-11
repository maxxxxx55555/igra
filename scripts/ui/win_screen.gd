extends Control
func _ready() -> void:
    _build()
func _build() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_preset(Control.PRESET_FULL_RECT)
    theme = ThemeProvider.build_theme()
    var bg := ColorRect.new()
    bg.color = Color(0.12, 0.09, 0.02, 0.92)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var vb := VBoxContainer.new()
    vb.set_anchors_preset(Control.PRESET_CENTER)
    vb.add_theme_constant_override("separation", 16)
    add_child(vb)
    var t := Label.new()
    t.text = "СВЕТ ВЕРНУЛСЯ В ГОРОД"
    t.add_theme_font_size_override("font_size", 28)
    t.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
    t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vb.add_child(t)
    var s := Label.new()
    s.text = "Электростанция запущена. Ты узнал правду о катастрофе."
    s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    s.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
    vb.add_child(s)
    var b := Button.new()
    b.text = "В главное меню"
    b.focus_mode = Control.FOCUS_NONE
    b.pressed.connect(func() -> void: GameManager.return_to_menu())
    vb.add_child(b)