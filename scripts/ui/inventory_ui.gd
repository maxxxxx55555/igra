extends Control
## GDD §12.2 INVENTORY / CHARACTER and the V.5 sheet: the pack as a grid, the selected item's details with use,
## equip and drop, the five equipment slots, sorting, a rarity filter, the weapons carried and the vitals.
## Tab opens it (UIManager), Esc or Tab closes it, Delete drops the selected stack.

const COLUMNS: int = 4
const CELL := Vector2(96, 96)
const SORT_MODES: Array[String] = ["type", "weight", "rarity"]
const SORT_KEYS: Dictionary = {"type": "INV_SORT_TYPE", "weight": "CHAR_WEIGHT", "rarity": "INV_SORT_RARITY"}
const RARITY_KEYS: Array[String] = ["RARITY_COMMON", "RARITY_UNCOMMON", "RARITY_RARE", "RARITY_EPIC"]
const EQUIP_ORDER: Array = [
	ItemData.EquipSlot.HEAD, ItemData.EquipSlot.BODY, ItemData.EquipSlot.LEGS,
	ItemData.EquipSlot.HOLSTER, ItemData.EquipSlot.BACKPACK,
]
const EQUIP_KEYS: Dictionary = {
	ItemData.EquipSlot.HEAD: "CHAR_HEAD", ItemData.EquipSlot.BODY: "CHAR_BODY", ItemData.EquipSlot.LEGS: "CHAR_LEGS",
	ItemData.EquipSlot.HOLSTER: "CHAR_HOLSTER", ItemData.EquipSlot.BACKPACK: "CHAR_BACKPACK",
}
const WEAPONS: Array[StringName] = [&"pistol", &"rifle", &"shotgun"]

var _selected: int = -1
var _filter: int = -1
var _drop_armed: bool = false
var _title: Label
var _load: Label
var _grid: GridContainer
var _detail: VBoxContainer
var _side: VBoxContainer
var _close: Button
var _hints: Label
var _sort_buttons: Array[Button] = []
var _filter_buttons: Array[Button] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = ThemeProvider.build_theme()
	var bg := ColorRect.new()
	bg.color = Color(ThemeProvider.COLOR_BG_DARK, 0.94)
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 24.0
	root.offset_right = -24.0
	root.offset_top = 18.0
	root.offset_bottom = -18.0
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	root.add_child(header)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_TITLE)
	_title.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	_load = Label.new()
	_load.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
	header.add_child(_load)
	_close = Button.new()
	_close.focus_mode = Control.FOCUS_NONE
	_close.custom_minimum_size = Vector2(140, 40)
	_close.pressed.connect(func() -> void: UIManager.close(&"inventory"))
	header.add_child(_close)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(left)
	left.add_child(_button_row(_sort_buttons, SORT_MODES.size(), _on_sort))
	left.add_child(_button_row(_filter_buttons, RARITY_KEYS.size() + 1, _on_filter))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_grid)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 12)
	right.custom_minimum_size = Vector2(380, 0)
	body.add_child(right)
	_detail = VBoxContainer.new()
	_detail.add_theme_constant_override("separation", 6)
	right.add_child(_panel(_detail))
	_side = VBoxContainer.new()
	_side.add_theme_constant_override("separation", 4)
	right.add_child(_panel(_side))
	_hints = Label.new()
	_hints.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
	root.add_child(_hints)
	EventBus.inventory_changed.connect(_refresh)
	EventBus.ammo_changed.connect(func(_current: int, _reserve: int) -> void: _refresh())
	LocalizationManager.language_changed.connect(func(_lang: String) -> void: _refresh())
	visibility_changed.connect(func() -> void:
		if visible:
			_refresh())
	_refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_DELETE:
		_on_drop()
		get_viewport().set_input_as_handled()

func _panel(content: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_child(content)
	return panel

func _button_row(store: Array[Button], count: int, handler: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for i in count:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(handler.bind(i))
		row.add_child(button)
		store.append(button)
	return row

func _on_sort(index: int) -> void:
	InventoryManager.sort_slots(SORT_MODES[index])
	_selected = -1
	_refresh()

func _on_filter(index: int) -> void:
	_filter = index - 1
	_selected = -1
	_refresh()

func _item_name(data: ItemData) -> String:
	return LocalizationManager.name_for("ITEM_", data.id, data.display_name)

func _refresh() -> void:
	_drop_armed = false
	_title.text = LocalizationManager.t("inventory").to_upper()
	_close.text = LocalizationManager.t("ui_close")
	_load.text = "%s   %d / %d" % [LocalizationManager.tf("INV_WEIGHT", [InventoryManager.current_weight, InventoryManager.stats.capacity_kg]),
		_used_slots(), InventoryManager.slots.size()]
	_hints.text = LocalizationManager.t("INV_HINTS")
	for i in SORT_MODES.size():
		_sort_buttons[i].text = LocalizationManager.t(String(SORT_KEYS[SORT_MODES[i]]))
	_filter_buttons[0].text = LocalizationManager.t("INV_FILTER_ALL")
	for i in RARITY_KEYS.size():
		_filter_buttons[i + 1].text = LocalizationManager.t(RARITY_KEYS[i])
		_filter_buttons[i + 1].add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER if _filter == i else ThemeProvider.COLOR_TEXT_DIM)
	_filter_buttons[0].add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER if _filter < 0 else ThemeProvider.COLOR_TEXT_DIM)
	for cell in _grid.get_children():
		cell.queue_free()
	for index in InventoryManager.slots.size():
		var slot: Variant = InventoryManager.slots[index]
		if slot == null:
			continue
		var data := ItemDatabase.get_item(slot["item_id"])
		if data != null and (_filter < 0 or int(data.rarity) == _filter):
			_grid.add_child(_cell(index, data, int(slot["count"])))
	_refresh_detail()
	_refresh_side()

func _used_slots() -> int:
	var used := 0
	for slot in InventoryManager.slots:
		if slot != null:
			used += 1
	return used

func _cell(index: int, data: ItemData, count: int) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = CELL
	button.icon = data.icon
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.text = "x%d" % count if count > 1 else ""
	button.tooltip_text = _item_name(data)
	if index == _selected:
		button.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
		button.add_theme_stylebox_override("normal", button.get_theme_stylebox("pressed", "Button"))
	button.pressed.connect(func() -> void:
		_selected = index
		_refresh())
	return button

func _label(text: String, color: Color = ThemeProvider.COLOR_TEXT) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	return label

func _refresh_detail() -> void:
	for child in _detail.get_children():
		child.queue_free()
	var slot: Variant = InventoryManager.slots[_selected] if _selected >= 0 and _selected < InventoryManager.slots.size() else null
	var data := ItemDatabase.get_item(slot["item_id"]) if slot != null else null
	if data == null:
		_detail.add_child(_label(LocalizationManager.t("INV_SELECT"), ThemeProvider.COLOR_TEXT_DIM))
		return
	var count: int = int(slot["count"])
	_detail.add_child(_label(_item_name(data), ThemeProvider.COLOR_AMBER))
	_detail.add_child(_label(LocalizationManager.t(RARITY_KEYS[clampi(int(data.rarity), 0, RARITY_KEYS.size() - 1)]), ThemeProvider.COLOR_TEXT_DIM))
	_detail.add_child(_label(LocalizationManager.tf("INV_ITEM_WEIGHT", [data.weight * count, count])))
	_detail.add_child(_label(_effect_text(data)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_detail.add_child(row)
	row.add_child(_action(LocalizationManager.t("INV_USE"), data.consumable, func() -> void: _on_use()))
	row.add_child(_action(LocalizationManager.t("INV_EQUIP"), data.equip_slot != ItemData.EquipSlot.NONE, func() -> void: _on_equip()))
	row.add_child(_action(LocalizationManager.t("INV_DROP_CONFIRM") if _drop_armed else LocalizationManager.t("INV_DROP"), true, func() -> void: _on_drop()))

func _action(text: String, enabled: bool, handler: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.disabled = not enabled
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(handler)
	return button

func _effect_text(data: ItemData) -> String:
	match data.effect:
		ItemData.Effect.HEAL:
			return LocalizationManager.tf("INV_EFFECT_HEAL", [int(data.effect_value)])
		ItemData.Effect.RECHARGE:
			return LocalizationManager.tf("INV_EFFECT_RECHARGE", [int(data.effect_value)])
		ItemData.Effect.CAPACITY:
			return LocalizationManager.tf("INV_EFFECT_CAPACITY", [int(data.effect_value)])
	return LocalizationManager.t("INV_NO_EFFECT")

func _on_use() -> void:
	if _selected >= 0 and InventoryManager.use_item(_selected):
		EventBus.inventory_notice.emit(LocalizationManager.t("INV_ITEM_USED"))

func _on_equip() -> void:
	if _selected >= 0:
		InventoryManager.equip_item(_selected)

## The first press arms the drop (the button asks for confirmation), the second throws the stack away.
func _on_drop() -> void:
	var slot: Variant = InventoryManager.slots[_selected] if _selected >= 0 and _selected < InventoryManager.slots.size() else null
	if slot == null:
		return
	if not _drop_armed:
		_drop_armed = true
		_refresh_detail()
		return
	InventoryManager.remove(slot["item_id"], int(slot["count"]))
	_selected = -1

func _refresh_side() -> void:
	for child in _side.get_children():
		child.queue_free()
	_side.add_child(_label(LocalizationManager.t("INV_EQUIPMENT"), ThemeProvider.COLOR_AMBER))
	for equip_slot in EQUIP_ORDER:
		var worn := InventoryManager.get_equipped(equip_slot)
		var shown := LocalizationManager.t("INV_EMPTY")
		if not worn.is_empty():
			var worn_data := ItemDatabase.get_item(worn["item_id"])
			shown = _item_name(worn_data) if worn_data != null else String(worn["item_id"])
		var button := _action("%s: %s" % [LocalizationManager.t(String(EQUIP_KEYS[equip_slot])), shown], not worn.is_empty(),
			func() -> void: InventoryManager.unequip_item(equip_slot))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_side.add_child(button)
	_side.add_child(_label(LocalizationManager.t("INV_WEAPONS"), ThemeProvider.COLOR_AMBER))
	var drawn := _drawn_weapon()
	for id in WEAPONS:
		if ProgressTracker.has_weapon(String(id)):
			var mark := "> " if id == drawn else ""
			_side.add_child(_label(mark + LocalizationManager.name_for("ITEM_", id, String(id))))
	_side.add_child(_label(LocalizationManager.tf("INV_AMMO", [ProgressTracker.ammo]), ThemeProvider.COLOR_TEXT_DIM))
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		_side.add_child(_label(LocalizationManager.tf("INV_VITALS", [int(player.hp), int(player.stamina), int(player.battery)]), ThemeProvider.COLOR_TEXT_DIM))

func _drawn_weapon() -> StringName:
	var player := get_tree().get_first_node_in_group("player")
	var weapons := player.get_node_or_null("WeaponManager") as WeaponManager if player != null else null
	return weapons.equipped if weapons != null else &""
