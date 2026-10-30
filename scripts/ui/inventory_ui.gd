extends Control
## The pack: equipment left, a stable item grid in the centre, the selected object and actions right.
## Phone-width layouts keep equipment and items on the primary view and open the inspector as a
## deliberate full-height secondary view. Every operation still belongs to InventoryManager.

const COLUMNS: int = 4
const CELL := Vector2(112, 112)
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
const QUICK_SLOTS := preload("res://scripts/ui/quick_slots.gd")
const QUICK_CELL := preload("res://scripts/ui/quick_slot_cell.gd")
const ITEM_ICONS := preload("res://scripts/ui/item_icons.gd")
const SURVIVOR := preload("res://scripts/ui/survivor_preview.gd")
const QUICK_TARGET := Vector2(64, 64)
const QUICK_ICON: float = 40.0
const QUICK_KEY_POS := Vector2(6.0, 2.0)
const EQUIPMENT_WIDTH: float = 216.0
const INSPECTOR_WIDTH: float = 368.0
const MIN_ACTION_HEIGHT: float = 48.0

var _selected: int = -1
var _filter: int = -1
var _sort_index: int = 0
var _drop_armed: bool = false
var _narrow: bool = false
var _overlay_open: bool = false

var _margin: MarginContainer
var _body: HBoxContainer
var _equipment_col: VBoxContainer
var _item_col: VBoxContainer
var _inspector_col: PanelContainer
var _detail: VBoxContainer
var _overlay: PanelContainer
var _overlay_detail: VBoxContainer
var _equip_list: VBoxContainer
var _title: Label
var _load: Label
var _grid: GridContainer
var _sort_select: OptionButton
var _filter_select: OptionButton
var _close: Button
var _back: Button
var _hints: Label
var _quick_targets: Array[Button] = []
var _quick_hint: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = ThemeProvider.build_theme()
	var bg := ColorRect.new()
	bg.color = Color(ThemeProvider.COLOR_BG_DARK, 0.98)
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_margin = MarginContainer.new()
	add_child(_margin)
	_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var frame := PanelContainer.new()
	frame.name = "InventoryFrame"
	_margin.add_child(frame)
	_root(frame)
	_build_overlay()
	_apply_safe_area()
	_apply_responsive()
	resized.connect(_on_resized)
	if get_window() != null:
		get_window().size_changed.connect(_on_resized)
	EventBus.inventory_changed.connect(_refresh)
	EventBus.settings_changed.connect(func(key: String, _value: Variant) -> void:
		if key == QUICK_SLOTS.KEY:
			_refresh_quick_strip()
		if key == "text_size" or key == "button_size":
			_apply_responsive())
	EventBus.ammo_changed.connect(func(_current: int, _reserve: int) -> void: _refresh())
	LocalizationManager.language_changed.connect(func(_lang: String) -> void: _refresh())
	visibility_changed.connect(func() -> void:
		if visible:
			_apply_responsive()
			_refresh())
	_refresh()

func _root(frame: PanelContainer) -> void:
	var root := VBoxContainer.new()
	root.name = "InventoryRoot"
	root.add_theme_constant_override("separation", 12)
	frame.add_child(root)
	var header := HBoxContainer.new()
	header.name = "InventoryHeader"
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
	_close.name = "Close"
	_close.focus_mode = Control.FOCUS_NONE
	_close.custom_minimum_size = Vector2(132, MIN_ACTION_HEIGHT)
	_close.pressed.connect(func() -> void: UIManager.close(&"inventory"))
	header.add_child(_close)
	_body = HBoxContainer.new()
	_body.name = "InventoryBody"
	_body.add_theme_constant_override("separation", 14)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_body)
	_equipment_col = VBoxContainer.new()
	_equipment_col.name = "EquipmentColumn"
	_equipment_col.add_theme_constant_override("separation", 8)
	_equipment_col.custom_minimum_size = Vector2(EQUIPMENT_WIDTH, 0)
	_equipment_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(_equipment_col)
	_item_col = VBoxContainer.new()
	_item_col.name = "ItemColumn"
	_item_col.add_theme_constant_override("separation", 8)
	_item_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_item_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(_item_col)
	_build_toolbar()
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_item_col.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	_grid = GridContainer.new()
	_grid.name = "ItemGrid"
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	center.add_child(_grid)
	_inspector_col = PanelContainer.new()
	_inspector_col.name = "InspectorColumn"
	_inspector_col.theme_type_variation = &"RaisedPanel"
	_inspector_col.custom_minimum_size = Vector2(INSPECTOR_WIDTH, 0)
	_body.add_child(_inspector_col)
	_detail = VBoxContainer.new()
	_detail.name = "ItemInspector"
	_detail.add_theme_constant_override("separation", 8)
	_inspector_col.add_child(_detail)
	root.add_child(_footer())

func _build_toolbar() -> void:
	var toolbar := HBoxContainer.new()
	toolbar.name = "InventoryToolbar"
	toolbar.add_theme_constant_override("separation", 8)
	_item_col.add_child(toolbar)
	_sort_select = OptionButton.new()
	_sort_select.name = "SortSelect"
	_sort_select.custom_minimum_size = Vector2(150, MIN_ACTION_HEIGHT)
	_sort_select.item_selected.connect(_on_sort_selected)
	toolbar.add_child(_sort_select)
	_filter_select = OptionButton.new()
	_filter_select.name = "FilterSelect"
	_filter_select.custom_minimum_size = Vector2(160, MIN_ACTION_HEIGHT)
	_filter_select.item_selected.connect(_on_filter_selected)
	toolbar.add_child(_filter_select)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toolbar.add_child(spacer)

func _build_overlay() -> void:
	_overlay = PanelContainer.new()
	_overlay.name = "InventoryInspectorOverlay"
	_overlay.theme_type_variation = &"RaisedPanel"
	_overlay.visible = false
	_overlay.z_index = 2
	add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.offset_left = 16.0
	_overlay.offset_top = 16.0
	_overlay.offset_right = -16.0
	_overlay.offset_bottom = -16.0
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_overlay.add_child(box)
	_back = Button.new()
	_back.name = "InspectorBack"
	_back.focus_mode = Control.FOCUS_NONE
	_back.custom_minimum_size = Vector2(0, MIN_ACTION_HEIGHT)
	_back.pressed.connect(func() -> void:
		_overlay_open = false
		_apply_responsive())
	box.add_child(_back)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	_overlay_detail = VBoxContainer.new()
	_overlay_detail.add_theme_constant_override("separation", 10)
	_overlay_detail.custom_minimum_size = Vector2(640, 0)
	_overlay_detail.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	scroll.add_child(_overlay_detail)

func _footer() -> VBoxContainer:
	var footer := VBoxContainer.new()
	footer.name = "InventoryFooter"
	footer.add_theme_constant_override("separation", 6)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	footer.add_child(row)
	for i in QUICK_SLOTS.SLOTS:
		var target: Button = QUICK_CELL.new()
		target.name = "QuickSlot%d" % i
		target.slot = i
		target.focus_mode = Control.FOCUS_NONE
		target.custom_minimum_size = QUICK_TARGET
		var key := Label.new()
		key.text = str(i + 1)
		key.position = QUICK_KEY_POS
		key.mouse_filter = Control.MOUSE_FILTER_IGNORE
		key.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
		target.add_child(key)
		var icon_box := Control.new()
		icon_box.name = "IconBox"
		icon_box.position = (QUICK_TARGET - Vector2(QUICK_ICON, QUICK_ICON)) / 2.0
		icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		target.add_child(icon_box)
		row.add_child(target)
		_quick_targets.append(target)
	_quick_hint = _label("", ThemeProvider.COLOR_TEXT_DIM)
	_quick_hint.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_SMALL)
	footer.add_child(_quick_hint)
	_hints = _label("", ThemeProvider.COLOR_TEXT_DIM)
	_hints.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_SMALL)
	footer.add_child(_hints)
	return footer

func _on_resized() -> void:
	_apply_safe_area()
	_apply_responsive()

func _apply_safe_area() -> void:
	if _margin == null:
		return
	var inset: Vector4 = UiScale.insets(get_viewport_rect().size)
	_margin.add_theme_constant_override("margin_left", 24 + int(inset.x))
	_margin.add_theme_constant_override("margin_top", 20 + int(inset.y))
	_margin.add_theme_constant_override("margin_right", 24 + int(inset.z))
	_margin.add_theme_constant_override("margin_bottom", 20 + int(inset.w))

func _apply_responsive() -> void:
	if _body == null:
		return
	var window_width: float = float(get_window().size.x) if get_window() != null else get_viewport_rect().size.x
	var text_scale: float = SettingsManager.TEXT_SCALE[clampi(int(SettingsManager.get_setting("text_size", 1)), 0, 2)]
	_narrow = UiScale.narrow_layout(window_width, text_scale)
	_inspector_col.visible = not _narrow
	_equipment_col.custom_minimum_size.x = 184.0 if _narrow else EQUIPMENT_WIDTH
	_overlay.visible = _narrow and _overlay_open and _selected >= 0
	if _narrow and _selected >= 0:
		_refresh_detail()

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_DELETE:
		_on_drop()
		get_viewport().set_input_as_handled()

func _on_sort_selected(index: int) -> void:
	_sort_index = clampi(index, 0, SORT_MODES.size() - 1)
	InventoryManager.sort_slots(SORT_MODES[_sort_index])
	_selected = -1
	_refresh()

func _on_filter_selected(index: int) -> void:
	_filter = index - 1
	_selected = -1
	_refresh()

func _item_name(data: ItemData) -> String:
	return LocalizationManager.name_for("ITEM_", data.id, data.display_name)

func _selected_slot() -> Variant:
	if _selected < 0 or _selected >= InventoryManager.slots.size():
		return null
	return InventoryManager.slots[_selected]

func _first_visible_index() -> int:
	for index in InventoryManager.slots.size():
		var slot: Variant = InventoryManager.slots[index]
		if slot == null:
			continue
		var data := ItemDatabase.get_item(slot["item_id"])
		if data != null and (_filter < 0 or int(data.rarity) == _filter):
			return index
	return -1

func _refresh() -> void:
	_drop_armed = false
	_title.text = LocalizationManager.t("inventory").to_upper()
	_close.text = LocalizationManager.t("ui_close")
	_back.text = LocalizationManager.t("SCR_NAZAD")
	_load.text = "%s   %d / %d" % [LocalizationManager.tf("INV_WEIGHT", [InventoryManager.current_weight, InventoryManager.stats.capacity_kg]),
		_used_slots(), InventoryManager.slots.size()]
	var touch: bool = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	_hints.text = LocalizationManager.t("INV_HINTS_TOUCH" if touch else "INV_HINTS")
	_quick_hint.text = LocalizationManager.t("INV_QUICKSLOT_HINT")
	_sort_select.clear()
	for mode in SORT_MODES:
		_sort_select.add_item(LocalizationManager.t(String(SORT_KEYS[mode])))
	_sort_select.select(_sort_index)
	_filter_select.clear()
	_filter_select.add_item(LocalizationManager.t("INV_FILTER_ALL"))
	for key in RARITY_KEYS:
		_filter_select.add_item(LocalizationManager.t(key))
	_filter_select.select(_filter + 1)
	var data := _data_at(_selected)
	if data == null or (_filter >= 0 and int(data.rarity) != _filter):
		_selected = _first_visible_index()
	for cell in _grid.get_children():
		_grid.remove_child(cell)
		cell.queue_free()
	for index in InventoryManager.slots.size():
		var slot: Variant = InventoryManager.slots[index]
		var item := ItemDatabase.get_item(slot["item_id"]) if slot != null else null
		if item != null and (_filter < 0 or int(item.rarity) == _filter):
			_grid.add_child(_cell(index, item, int(slot["count"])))
		else:
			_grid.add_child(_empty_cell(index, slot != null))
	_refresh_detail()
	_refresh_equipment()
	_refresh_quick_strip()
	_apply_responsive()

func _data_at(index: int) -> ItemData:
	if index < 0 or index >= InventoryManager.slots.size():
		return null
	var slot: Variant = InventoryManager.slots[index]
	return ItemDatabase.get_item(slot["item_id"]) if slot != null else null

func _used_slots() -> int:
	var used := 0
	for slot in InventoryManager.slots:
		if slot != null:
			used += 1
	return used

func _cell(index: int, data: ItemData, count: int) -> Button:
	var button: Button = QUICK_CELL.new()
	button.name = "Slot%d" % index
	button.item_id = data.id
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
		if _narrow:
			_overlay_open = true
		_refresh())
	return button

func _empty_cell(index: int, filtered: bool) -> Button:
	var button := Button.new()
	button.name = "EmptySlot%d" % index
	button.focus_mode = Control.FOCUS_NONE
	button.disabled = true
	button.custom_minimum_size = CELL
	button.tooltip_text = LocalizationManager.t("INV_EMPTY")
	if filtered:
		button.modulate = Color(1.0, 1.0, 1.0, 0.45)
	return button

func _label(text: String, color: Color = ThemeProvider.COLOR_TEXT) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	return label

func _clear(container: VBoxContainer) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _refresh_detail() -> void:
	_clear(_detail)
	_clear(_overlay_detail)
	var target := _overlay_detail if _narrow else _detail
	var slot: Variant = _selected_slot()
	var data := ItemDatabase.get_item(slot["item_id"]) if slot != null else null
	if data == null:
		target.add_child(_label(LocalizationManager.t("INV_SELECT"), ThemeProvider.COLOR_TEXT_DIM))
		_overlay.visible = false
		return
	var heading := _label(_item_name(data), ThemeProvider.COLOR_AMBER)
	heading.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_TITLE)
	heading.add_theme_font_override("font", ThemeProvider.heading_font())
	target.add_child(heading)
	var preview := Control.new()
	preview.name = "ItemPreview"
	preview.custom_minimum_size = Vector2(240, 176)
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	target.add_child(preview)
	ITEM_ICONS.draw_icon(preview, data.id, 140.0)
	if preview.get_child_count() > 0:
		var icon := preview.get_child(0) as Control
		icon.position = (preview.custom_minimum_size - Vector2(140, 140)) * 0.5
	target.add_child(_label(LocalizationManager.t(RARITY_KEYS[clampi(int(data.rarity), 0, RARITY_KEYS.size() - 1)]),
		ThemeProvider.COLOR_TEXT_DIM))
	target.add_child(_label(LocalizationManager.tf("INV_ITEM_WEIGHT", [data.weight * int(slot["count"]), int(slot["count"])])))
	target.add_child(_label(_effect_text(data)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	target.add_child(row)
	row.add_child(_action(LocalizationManager.t("INV_USE"), data.consumable, func() -> void: _on_use()))
	row.add_child(_action(LocalizationManager.t("INV_EQUIP"), data.equip_slot != ItemData.EquipSlot.NONE, func() -> void: _on_equip()))
	row.add_child(_action(LocalizationManager.t("INV_DROP_CONFIRM") if _drop_armed else LocalizationManager.t("INV_DROP"), true, func() -> void: _on_drop()))

func _action(text: String, enabled: bool, handler: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.disabled = not enabled
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, MIN_ACTION_HEIGHT)
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

func _on_drop() -> void:
	var slot: Variant = _selected_slot()
	if slot == null:
		return
	if not _drop_armed:
		_drop_armed = true
		_refresh_detail()
		return
	InventoryManager.remove(slot["item_id"], int(slot["count"]))
	_selected = -1

func _refresh_quick_strip() -> void:
	var bound: Array = QUICK_SLOTS.read()
	for i in _quick_targets.size():
		var icon_box := _quick_targets[i].get_node("IconBox") as Control
		for child in icon_box.get_children():
			icon_box.remove_child(child)
			child.queue_free()
		ITEM_ICONS.draw_icon(icon_box, bound[i], QUICK_ICON)
		var data := ItemDatabase.get_item(bound[i])
		_quick_targets[i].tooltip_text = _item_name(data) if data != null else ""

func _refresh_equipment() -> void:
	_clear(_equipment_col)
	var header := _label(LocalizationManager.t("INV_EQUIPMENT"), ThemeProvider.COLOR_AMBER)
	header.add_theme_font_override("font", ThemeProvider.heading_font())
	header.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_TITLE)
	_equipment_col.add_child(header)
	var preview: Control = SURVIVOR.new()
	preview.name = "SurvivorPreview"
	_equipment_col.add_child(preview)
	_equip_list = VBoxContainer.new()
	_equip_list.name = "EquipmentList"
	_equip_list.add_theme_constant_override("separation", 4)
	_equipment_col.add_child(_equip_list)
	for equip_slot in EQUIP_ORDER:
		var worn := InventoryManager.get_equipped(equip_slot)
		var shown := LocalizationManager.t("INV_EMPTY")
		if not worn.is_empty():
			var worn_data := ItemDatabase.get_item(worn["item_id"])
			shown = _item_name(worn_data) if worn_data != null else String(worn["item_id"])
		var button := _action("%s: %s" % [LocalizationManager.t(String(EQUIP_KEYS[equip_slot])), shown], not worn.is_empty(),
			func() -> void: InventoryManager.unequip_item(equip_slot))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_equip_list.add_child(button)
	var weapons := _label(LocalizationManager.t("INV_WEAPONS"), ThemeProvider.COLOR_AMBER)
	_equipment_col.add_child(weapons)
	var drawn := _drawn_weapon()
	for id in WEAPONS:
		if ProgressTracker.has_weapon(String(id)):
			var mark := "> " if id == drawn else ""
			_equipment_col.add_child(_label(mark + LocalizationManager.name_for("ITEM_", id, String(id))))
	_equipment_col.add_child(_label(LocalizationManager.tf("INV_AMMO", [ProgressTracker.ammo]), ThemeProvider.COLOR_TEXT_DIM))
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		_equipment_col.add_child(_label(LocalizationManager.tf("INV_VITALS", [int(player.hp), int(player.stamina), int(player.battery)]), ThemeProvider.COLOR_TEXT_DIM))

func _drawn_weapon() -> StringName:
	var player := get_tree().get_first_node_in_group("player")
	var weapons := player.get_node_or_null("WeaponManager") as WeaponManager if player != null else null
	return weapons.equipped if weapons != null else &""
