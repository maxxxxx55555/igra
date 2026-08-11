extends Control
var active: bool = false
var _shots: int = 0
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_preset(Control.PRESET_FULL_RECT)
    visible = false
func toggle() -> void:
    active = not active
    visible = active
    EventBus.hud_visibility_changed.emit(not active)
    EventBus.inventory_notice.emit("Фоторежим: ВКЛ" if active else "Фоторежим: ВЫКЛ")
    queue_redraw()
func _unhandled_input(event: InputEvent) -> void:
    if active and event is InputEventKey and event.pressed and not event.echo:
        if event.is_action_pressed("photo_capture"):
            _shots += 1
            EventBus.inventory_notice.emit("Снимок сохранён (%d)" % _shots)
func _draw() -> void:
    if not active:
        return
    var r := get_rect()
    var m := 40.0
    var col := ThemeProvider.COLOR_AMBER
    # Фикс #7: get_theme_default_font() возвращает валидный Font (НЕ Theme.DEFAULT_FONT).
    var font := get_theme_default_font()
    for corner in [Vector2(m, m), Vector2(r.size.x - m, m), Vector2(m, r.size.y - m), Vector2(r.size.x - m, r.size.y - m)]:
        draw_arc(corner, 18.0, 0.0, TAU, 16, col, 2.0, true)
    draw_string(font, Vector2(m, m - 12), "PHOTO  #%d" % _shots, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)