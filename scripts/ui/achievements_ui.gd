extends Control
const ACH := {
    "first_light": "Первый свет",
    "district_one": "Один район спасён",
    "shadow_slayer": "Тени не пройдут",
    "secret_hunter": "Искатель тайн",
}
var _list: VBoxContainer
func _ready() -> void:
    EventBus.achievement_unlocked.connect(func(_id: StringName) -> void: _refresh())
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
    panel.custom_minimum_size = Vector2(480, 420)
    add_child(panel)
    var vb := VBoxContainer.new()
    panel.add_child(vb)
    var t := Label.new()
    t.text = "ДОСТИЖЕНИЯ"
    t.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_TITLE)
    t.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
    t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vb.add_child(t)
    _list = VBoxContainer.new()
    vb.add_child(_list)
    var back := Button.new()
    back.text = "Закрыть"
    back.focus_mode = Control.FOCUS_NONE
    back.pressed.connect(func() -> void: UIManager.close(&"achievements"))
    vb.add_child(back)
    _refresh()
func _refresh() -> void:
    for c in _list.get_children():
        c.queue_free()
    var done := ProgressTracker._ach_done
    for id in ACH.keys():
        var l := Label.new()
        var d: bool = done.get(id, false)
        l.text = "%s  %s" % ["[+]" if d else "[ ]", ACH[id]]
        l.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER if d else ThemeProvider.COLOR_TEXT_DIM)
        _list.add_child(l)