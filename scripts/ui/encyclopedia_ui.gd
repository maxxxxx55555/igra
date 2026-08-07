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
    panel.custom_minimum_size = Vector2(660, 480)
    add_child(panel)
    var vb := VBoxContainer.new()
    panel.add_child(vb)
    var t := Label.new()
    t.text = "ЭНЦИКЛОПЕДИЯ СУЩЕСТВ"
    t.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_TITLE)
    t.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
    t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vb.add_child(t)
    var grid := GridContainer.new()
    grid.columns = 3
    grid.add_theme_constant_override("h_separation", 12)
    grid.add_theme_constant_override("v_separation", 12)
    vb.add_child(grid)
    for id in Encyclopedia.all_ids():
        var unlocked := Encyclopedia.is_unlocked(id)
        var data := Encyclopedia.get_data(id)
        var card := PanelContainer.new()
        card.custom_minimum_size = Vector2(190, 140)
        grid.add_child(card)
        var cv := VBoxContainer.new()
        card.add_child(cv)
        var prev := ColorRect.new()
        prev.custom_minimum_size = Vector2(190, 44)
        prev.color = data.body_color if (unlocked and data) else ThemeProvider.COLOR_BG_DARK
        cv.add_child(prev)
        var nm := Label.new()
        nm.text = data.display_name if unlocked else "???"
        nm.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER if unlocked else ThemeProvider.COLOR_TEXT_DIM)
        cv.add_child(nm)
        var ds := Label.new()
        ds.text = data.description if unlocked else "Встреть существо, чтобы открыть запись."
        ds.add_theme_font_size_override("font_size", 11)
        ds.autowrap_mode = TextServer.AUTOWRAP_WORD
        ds.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
        cv.add_child(ds)
    var b := Button.new()
    b.text = "Закрыть"
    b.focus_mode = Control.FOCUS_NONE
    b.pressed.connect(func() -> void: UIManager.close(&"encyclopedia"))
    vb.add_child(b)