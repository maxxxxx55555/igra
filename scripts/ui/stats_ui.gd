extends Control
func _ready() -> void:
    _build()
func _build() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_preset(Control.PRESET_FULL_RECT)
    theme = ThemeProvider.build_theme()
    var bg := ColorRect.new()
    bg.color = Color(0.04, 0.05, 0.07, 0.94)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var panel := PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.custom_minimum_size = Vector2(460, 360)
    add_child(panel)
    var vb := VBoxContainer.new()
    vb.add_theme_constant_override("separation", 10)
    panel.add_child(vb)
    var t := Label.new()
    t.text = "СТАТИСТИКА"
    t.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_TITLE)
    t.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
    t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vb.add_child(t)
    var s := ProgressTracker.get_stats()
    _line(vb, "Восстановлено районов", "%d / %d" % [s["districts"], PowerGrid.all_districts().size()])
    _line(vb, "Найдено секретов", "%d" % s["secrets"])
    _line(vb, "Повержено существ", "%d" % s["kills"])
    _line(vb, "Время в игре", "%d сек" % int(s["time_played"]))
    var b := Button.new()
    b.text = "Закрыть"
    b.focus_mode = Control.FOCUS_NONE
    b.pressed.connect(func() -> void: UIManager.close(&"stats"))
    vb.add_child(b)
func _line(p: Node, k: String, v: String) -> void:
    var row := HBoxContainer.new()
    p.add_child(row)
    var lk := Label.new()
    lk.text = k
    lk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(lk)
    var lv := Label.new()
    lv.text = v
    lv.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
    row.add_child(lv)