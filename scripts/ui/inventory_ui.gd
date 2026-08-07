extends Control
@onready var grid: GridContainer = $Panel/VBox/Grid
@onready var weight_label: Label = $Panel/VBox/WeightLabel
const RARITY_COLORS := [Color("8c8a82"), Color("5fa86a"), Color("e8a13a")]
var _slot_buttons: Array = []
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    theme = ThemeProvider.build_theme()
    _build_slots()
    visible = false
    EventBus.inventory_changed.connect(_refresh)
    EventBus.inventory_weight_changed.connect(_on_weight)
    EventBus.inventory_toggle_requested.connect(toggle)
    _refresh()
    _on_weight(InventoryManager.weight_ratio())
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.is_action_pressed("inventory_toggle"):
            toggle()
            get_viewport().set_input_as_handled()
func toggle() -> void:
    visible = not visible
    if visible:
        _refresh()
        EventBus.ui_screen_opened.emit(&"inventory")
    else:
        EventBus.ui_screen_closed.emit(&"inventory")
func _build_slots() -> void:
    for c in grid.get_children():
        c.queue_free()
    _slot_buttons.clear()
    for i in InventoryManager.stats.base_slots:
        var btn := Button.new()
        btn.focus_mode = Control.FOCUS_NONE
        btn.custom_minimum_size = Vector2(64, 64)
        var idx := i
        btn.pressed.connect(func() -> void: InventoryManager.use_item(idx))
        grid.add_child(btn)
        _slot_buttons.append(btn)
func _refresh() -> void:
    var slots := InventoryManager.slots
    for i in _slot_buttons.size():
        var btn: Button = _slot_buttons[i]
        var s = slots[i] if i < slots.size() else null
        if s == null:
            btn.text = ""
            btn.modulate = Color.WHITE
        else:
            var data := ItemDatabase.get_item(s["item_id"])
            var r: int = data.rarity if data else 0
            btn.text = "%s\nx%d" % [_short(data), s["count"]]
            btn.modulate = RARITY_COLORS[r] if r < RARITY_COLORS.size() else Color.WHITE
func _on_weight(_ratio: float) -> void:
    weight_label.text = "Вес: %.1f / %.0f кг" % [InventoryManager.current_weight, InventoryManager.stats.capacity_kg]
func _short(data: ItemData) -> String:
    if data == null:
        return "?"
    return data.display_name.substr(0, 6)