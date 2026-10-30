extends Control
## GDD §12.2 INVENTORY / CHARACTER and the V.5 sheet, composed as Plate A of the visual recovery brief on a 1280 x 720 design canvas: the survivor and the five equipment slots on the left, the pack in the
## middle (four columns of 112 px slots at the shown capacity of 12, free slots drawn as empty cells), the selected item's inspector on the right, quick access, the status and the input hints below.
## Tab opens it (UIManager), Esc or Tab closes it, Delete drops the selected stack. The operations are the ones that were there (use, equip, drop, sort, the rarity filter, the quick bar by drag);
## the kit of inv_kit.gd draws their states.

const KIT := preload("res://scripts/ui/inv_kit.gd")
const QUICK_SLOTS := preload("res://scripts/ui/quick_slots.gd")
const QUICK_CELL := preload("res://scripts/ui/quick_slot_cell.gd")
const ITEM_ICONS := preload("res://scripts/ui/item_icons.gd")
const SURVIVOR := preload("res://assets/textures/screens_v2/character_dim.png")
## The survivor of that art, cut out of its 1920 x 1080 frame for the equipment column.
const SURVIVOR_CROP := Rect2(640.0, 300.0, 640.0, 693.0)
const CANVAS := Vector2(1280.0, 720.0)
const SLOT := Vector2(112.0, 112.0)
const GAP: int = 8
const COLUMNS: int = 4
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
const QUICK_TARGET := Vector2(56.0, 56.0)
const QUICK_ICON: float = 36.0
const QUICK_KEY_POS := Vector2(4.0, 0.0)

var _selected: int = -1
var _filter: int = -1
var _drop_armed: bool = false
var _stage: Control
var _title: Label
var _load: Label
var _equip_title: Label
var _equip_rows: VBoxContainer
var _grid: GridContainer
var _note: Label
var _preview: TextureRect
var _detail: VBoxContainer
var _actions: VBoxContainer
var _close: Button
var _sort_label: Label
var _quick_title: Label
var _quick_hint: Label
var _vitals: Label
var _hints: Label
var _sort_buttons: Array[Button] = []
var _filter_buttons: Array[Button] = []
var _quick_targets: Array[Button] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = ThemeProvider.build_theme()
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.6)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage = Control.new()
	_stage.size = CANVAS
	add_child(_stage)
	_put(_panel(KIT.box(Color(KIT.BG, 0.96), KIT.EDGE, 1, 2)), Rect2(24, 24, 1232, 672))
	_title = _put(KIT.label("", 30, KIT.AMBER, true), Rect2(60, 52, 360, 40)) as Label
	_put(_bar(KIT.AMBER), Rect2(60, 96, 132, 2))
	_load = _put(KIT.label("", 18, KIT.TEXT_DIM), Rect2(560, 58, 548, 30)) as Label
	_load.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_close = _put(_action("", true, "", func() -> void: UIManager.close(&"inventory")), Rect2(1124, 52, 100, 40)) as Button
	_put(_bar(Color(KIT.EDGE, 0.55)), Rect2(44, 118, 1192, 1))
	_build_equipment()
	_build_items()
	_build_inspector()
	_build_footer()
	resized.connect(_fit)
	_fit()
	EventBus.inventory_changed.connect(_refresh)
	EventBus.settings_changed.connect(func(key: String, _value: Variant) -> void:
		if key == QUICK_SLOTS.KEY:
			_refresh_quick_strip())
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

## The design canvas is scaled to the screen and centred; the text keeps its design size relative to it.
func _fit() -> void:
	var factor := minf(size.x / CANVAS.x, size.y / CANVAS.y)
	_stage.scale = Vector2.ONE * factor
	_stage.position = (size - CANVAS * factor) * 0.5

func _put(node: Control, rect: Rect2) -> Control:
	_stage.add_child(node)
	node.position = rect.position
	node.size = rect.size
	return node

func _panel(style: StyleBoxFlat) -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _bar(color: Color) -> ColorRect:
	var bar := ColorRect.new()
	bar.color = color
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bar

func _build_equipment() -> void:
	_put(_panel(KIT.box(KIT.PANEL, KIT.EDGE_DIM)), Rect2(44, 138, 216, 424))
	_equip_title = _put(KIT.label("", 18, KIT.AMBER, true), Rect2(56, 146, 192, 24)) as Label
	_put(_panel(KIT.box(KIT.BG, KIT.EDGE_DIM)), Rect2(56, 174, 192, 204))
	var portrait := TextureRect.new()
	var crop := AtlasTexture.new()
	crop.atlas = SURVIVOR
	crop.region = SURVIVOR_CROP
	portrait.texture = crop
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_put(portrait, Rect2(57, 175, 190, 202))
	_equip_rows = _put(VBoxContainer.new(), Rect2(56, 388, 192, 170)) as VBoxContainer
	_equip_rows.add_theme_constant_override("separation", 4)

func _build_items() -> void:
	_put(_panel(KIT.box(KIT.PANEL, KIT.EDGE_DIM)), Rect2(280, 138, 568, 424))
	var filters := _put(HBoxContainer.new(), Rect2(288, 144, 544, 28)) as HBoxContainer
	filters.add_theme_constant_override("separation", 0)
	for i in RARITY_KEYS.size() + 1:
		var tab := _tab(_on_filter.bind(i))
		filters.add_child(tab)
		_filter_buttons.append(tab)
	var sorts := _put(HBoxContainer.new(), Rect2(288, 174, 544, 26)) as HBoxContainer
	sorts.add_theme_constant_override("separation", 0)
	_sort_label = KIT.label("", 13, KIT.TEXT_DIM)
	_sort_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_sort_label.custom_minimum_size.x = 64.0
	sorts.add_child(_sort_label)
	for i in SORT_MODES.size():
		var tab := _tab(_on_sort.bind(i))
		tab.add_theme_font_size_override("font_size", 14)
		sorts.add_child(tab)
		_sort_buttons.append(tab)
	var scroll := _put(ScrollContainer.new(), Rect2(328, 206, 480, 352)) as ScrollContainer
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", GAP)
	_grid.add_theme_constant_override("v_separation", GAP)
	scroll.add_child(_grid)
	_note = _put(KIT.label("", 16, KIT.TEXT_DIM), Rect2(328, 360, 472, 40)) as Label
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _build_inspector() -> void:
	_put(_panel(KIT.box(KIT.PANEL, KIT.EDGE_DIM)), Rect2(868, 138, 368, 424))
	_put(_panel(KIT.box(KIT.BG, KIT.EDGE_DIM)), Rect2(932, 150, 240, 176))
	_preview = TextureRect.new()
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_put(_preview, Rect2(940, 156, 224, 164))
	_detail = _put(VBoxContainer.new(), Rect2(884, 334, 336, 124)) as VBoxContainer
	_detail.add_theme_constant_override("separation", 4)
	_actions = _put(VBoxContainer.new(), Rect2(884, 464, 336, 84)) as VBoxContainer
	_actions.add_theme_constant_override("separation", 6)

func _build_footer() -> void:
	_put(_panel(KIT.box(KIT.PANEL, KIT.EDGE_DIM)), Rect2(44, 584, 1192, 88))
	_quick_title = _put(KIT.label("", 14, KIT.TEXT_DIM, true), Rect2(56, 588, 240, 20)) as Label
	var strip := _put(HBoxContainer.new(), Rect2(56, 610, 376, 56)) as HBoxContainer
	strip.add_theme_constant_override("separation", GAP)
	for i in QUICK_SLOTS.SLOTS:
		var target: Button = QUICK_CELL.new()
		target.name = "QuickSlot%d" % i
		target.slot = i
		target.focus_mode = Control.FOCUS_NONE
		target.custom_minimum_size = QUICK_TARGET
		KIT.style_button(target, &"slot")
		var key := KIT.label(str(i + 1), 14, KIT.AMBER, true)
		key.position = QUICK_KEY_POS
		key.mouse_filter = Control.MOUSE_FILTER_IGNORE
		target.add_child(key)
		var icon_box := Control.new()
		icon_box.name = "IconBox"
		icon_box.position = (QUICK_TARGET - Vector2(QUICK_ICON, QUICK_ICON)) / 2.0
		icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		target.add_child(icon_box)
		strip.add_child(target)
		_quick_targets.append(target)
	_quick_hint = _put(KIT.label("", 13, KIT.TEXT_DIM), Rect2(448, 610, 262, 56)) as Label
	_quick_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vitals = _put(KIT.label("", 15, KIT.TEXT), Rect2(718, 596, 262, 68)) as Label
	_vitals.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hints = _put(KIT.label("", 14, KIT.TEXT_DIM), Rect2(990, 596, 234, 68)) as Label
	_hints.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hints.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _tab(handler: Callable) -> Button:
	var tab := Button.new()
	tab.focus_mode = Control.FOCUS_NONE
	tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab.clip_text = true
	tab.add_theme_font_size_override("font_size", 16)
	tab.pressed.connect(handler)
	KIT.style_button(tab, &"tab")
	return tab

func _action(text: String, enabled: bool, reason: String, handler: Callable, kind: StringName = &"action") -> Button:
	var button := Button.new()
	button.text = text
	button.disabled = not enabled
	button.tooltip_text = "" if enabled else reason
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(handler)
	KIT.style_button(button, kind)
	return button

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

func _shown(index: int) -> bool:
	var slot: Variant = InventoryManager.slots[index] if index >= 0 and index < InventoryManager.slots.size() else null
	var data := ItemDatabase.get_item(slot["item_id"]) if slot != null else null
	return data != null and (_filter < 0 or int(data.rarity) == _filter)

func _refresh() -> void:
	_drop_armed = false
	_title.text = LocalizationManager.t("inventory").to_upper()
	_close.text = LocalizationManager.t("ui_close")
	_load.text = "%s   %d / %d" % [LocalizationManager.tf("INV_WEIGHT", [InventoryManager.current_weight, InventoryManager.stats.capacity_kg]),
		_used_slots(), InventoryManager.slots.size()]
	_equip_title.text = LocalizationManager.t("INV_EQUIPMENT").to_upper()
	_quick_title.text = LocalizationManager.t("INV_QUICK_ACCESS").to_upper()
	_quick_hint.text = LocalizationManager.t("INV_QUICKSLOT_HINT")
	_hints.text = LocalizationManager.t("INV_HINTS")
	_sort_label.text = LocalizationManager.t("INV_SORT_LABEL").to_upper() + " "
	for i in SORT_MODES.size():
		_sort_buttons[i].text = LocalizationManager.t(String(SORT_KEYS[SORT_MODES[i]])).to_upper()
	_filter_buttons[0].text = LocalizationManager.t("INV_FILTER_ALL").to_upper()
	for i in RARITY_KEYS.size():
		_filter_buttons[i + 1].text = LocalizationManager.t(RARITY_KEYS[i]).to_upper()
	for i in _filter_buttons.size():
		KIT.style_button(_filter_buttons[i], &"tab", i == _filter + 1)
		KIT.fit(_filter_buttons[i], 108.0, 16, 12)
	for tab in _sort_buttons:
		KIT.fit(tab, 150.0, 14, 12)
	for cell in _grid.get_children():
		cell.queue_free()
	var first := -1
	var shown := 0
	for index in InventoryManager.slots.size():
		if InventoryManager.slots[index] == null or not _shown(index):
			continue
		var slot: Dictionary = InventoryManager.slots[index]
		_grid.add_child(_cell(index, ItemDatabase.get_item(slot["item_id"]), int(slot["count"])))
		shown += 1
		first = index if first < 0 else first
	if _filter < 0:
		for _free in InventoryManager.slots.size() - _used_slots():
			_grid.add_child(_empty_cell())
	_note.text = LocalizationManager.t("INV_FILTER_EMPTY") if shown == 0 and _filter >= 0 else ""
	if not _shown(_selected):
		_selected = first
	_refresh_detail()
	_refresh_equipment()
	_refresh_quick_strip()
	_refresh_status()

func _used_slots() -> int:
	var used := 0
	for slot in InventoryManager.slots:
		if slot != null:
			used += 1
	return used

## A free slot of the pack, drawn as an empty cell, so a pack with little in it does not read as a blank panel.
func _empty_cell() -> Panel:
	var cell := _panel(KIT.box(Color("#0D1415"), Color(KIT.EDGE_DIM, 0.7)))
	cell.custom_minimum_size = SLOT
	return cell

func _cell(index: int, data: ItemData, count: int) -> Button:
	var button: Button = QUICK_CELL.new()
	button.item_id = data.id
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = SLOT
	button.icon = data.icon
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	button.tooltip_text = _item_name(data)
	KIT.style_button(button, &"slot", index == _selected)
	if count > 1:
		var quantity := KIT.label("x%d" % count, 18, KIT.TEXT, true)
		quantity.position = Vector2(SLOT.x - 50.0, SLOT.y - 28.0)
		quantity.size = Vector2(42.0, 24.0)
		quantity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		quantity.mouse_filter = Control.MOUSE_FILTER_IGNORE
		quantity.add_theme_color_override("font_outline_color", KIT.BG)
		quantity.add_theme_constant_override("outline_size", 5)
		button.add_child(quantity)
	button.pressed.connect(func() -> void:
		_selected = index
		_refresh())
	return button

func _line(text: String, size: int, color: Color = KIT.TEXT) -> Label:
	var label := KIT.label(text, size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _refresh_detail() -> void:
	for child in _detail.get_children():
		child.queue_free()
	for child in _actions.get_children():
		child.queue_free()
	var slot: Variant = InventoryManager.slots[_selected] if _selected >= 0 and _selected < InventoryManager.slots.size() else null
	var data := ItemDatabase.get_item(slot["item_id"]) if slot != null else null
	_preview.texture = data.icon if data != null else null
	if data == null:
		_detail.add_child(_line(LocalizationManager.t("INV_PACK_EMPTY" if _used_slots() == 0 else "INV_SELECT"), 18, KIT.TEXT_DIM))
		return
	var count: int = int(slot["count"])
	var name_label := _line(_item_name(data), 26, KIT.AMBER)
	name_label.add_theme_font_override("font", ThemeProvider.heading_font())
	_detail.add_child(name_label)
	_detail.add_child(_line(LocalizationManager.t(RARITY_KEYS[clampi(int(data.rarity), 0, RARITY_KEYS.size() - 1)]), 15, KIT.TEXT_DIM))
	_detail.add_child(_line(LocalizationManager.tf("INV_ITEM_WEIGHT", [data.weight * count, count]), 16))
	_detail.add_child(_line(_effect_text(data), 16))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", GAP)
	_actions.add_child(row)
	row.add_child(_action(LocalizationManager.t("INV_USE").to_upper(), data.consumable, LocalizationManager.t("INV_NOT_USABLE"), func() -> void: _on_use()))
	row.add_child(_action(LocalizationManager.t("INV_EQUIP").to_upper(), data.equip_slot != ItemData.EquipSlot.NONE, LocalizationManager.t("INV_NOT_EQUIPPABLE"), func() -> void: _on_equip()))
	var drop := _action(LocalizationManager.t("INV_DROP_CONFIRM" if _drop_armed else "INV_DROP").to_upper(), true, "", func() -> void: _on_drop(), &"danger")
	_actions.add_child(drop)
	for button: Button in [row.get_child(0), row.get_child(1)]:
		KIT.fit(button, 164.0, 18, 13)
	KIT.fit(drop, 336.0, 18, 13)

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

func _refresh_equipment() -> void:
	for child in _equip_rows.get_children():
		child.queue_free()
	for equip_slot in EQUIP_ORDER:
		var worn := InventoryManager.get_equipped(equip_slot)
		var shown := LocalizationManager.t("INV_EMPTY")
		if not worn.is_empty():
			var worn_data := ItemDatabase.get_item(worn["item_id"])
			shown = _item_name(worn_data) if worn_data != null else String(worn["item_id"])
		var row := _action("%s   %s" % [LocalizationManager.t(String(EQUIP_KEYS[equip_slot])).to_upper(), shown], not worn.is_empty(), "",
			func() -> void: InventoryManager.unequip_item(equip_slot), &"row")
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.clip_text = true
		row.custom_minimum_size = Vector2(192.0, 30.0)
		row.add_theme_font_size_override("font_size", 15)
		_equip_rows.add_child(row)

## One target per quick-bar key: drop an item on it to bind it, right-click puts the slot back to its default.
func _refresh_quick_strip() -> void:
	var bound: Array = QUICK_SLOTS.read()
	for i in _quick_targets.size():
		var icon_box := _quick_targets[i].get_node("IconBox") as Control
		for child in icon_box.get_children():
			child.queue_free()
		ITEM_ICONS.draw_icon(icon_box, bound[i], QUICK_ICON)
		var data := ItemDatabase.get_item(bound[i])
		_quick_targets[i].tooltip_text = _item_name(data) if data != null else ""

## The status summary of the footer: the vitals, the ammunition and the weapons carried (the drawn one marked).
func _refresh_status() -> void:
	var lines := PackedStringArray()
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		lines.append(LocalizationManager.tf("INV_VITALS", [int(player.hp), int(player.stamina), int(player.battery)]))
	lines.append(LocalizationManager.tf("INV_AMMO", [ProgressTracker.ammo]))
	var drawn := _drawn_weapon()
	var carried := PackedStringArray()
	for id in WEAPONS:
		if ProgressTracker.has_weapon(String(id)):
			carried.append(("> " if id == drawn else "") + LocalizationManager.name_for("ITEM_", id, String(id)))
	if not carried.is_empty():
		lines.append("%s: %s" % [LocalizationManager.t("INV_WEAPONS"), ", ".join(carried)])
	_vitals.text = "\n".join(lines)

func _drawn_weapon() -> StringName:
	var player := get_tree().get_first_node_in_group("player")
	var weapons := player.get_node_or_null("WeaponManager") as WeaponManager if player != null else null
	return weapons.equipped if weapons != null else &""
