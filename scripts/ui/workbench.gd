extends Control

@export var enable_workbench: bool = true

const PANEL := Color("#141b24")
const PANEL_EDGE := Color("#2a3340")
const BRASS := Color("#c9a24a")
const BRASS_DIM := Color("#8a7338")
const EMBER := Color("#b4452f")
const STEEL_TEXT := Color("#aeb6bf")
const BONE_TEXT := Color("#d8d2c4")
const STAMINA := Color("#5f8a4e")

const RECIPES: Array[Dictionary] = [
	{"id":"medkit","name_key":"ITEM_MEDKIT","result":"medkit","count":1,"components":[["fabric",2],["alcohol",1]]},
	{"id":"battery","name_key":"ITEM_BATTERY","result":"battery","count":1,"components":[["cable",1],["fuse",1]]},
	{"id":"noise_bomb","name_key":"ITEM_NOISE_BOMB","result":"noise_bomb","count":1,"components":[["gunpowder",2],["case",1]]},
	{"id":"lockpick","name_key":"ITEM_LOCKPICK","result":"lockpick","count":1,"components":[["metal",2]]},
	{"id":"repair_kit","name_key":"ITEM_REPAIR_KIT","result":"repair_kit","count":1,"components":[["fabric",3],["tool",1]]},
	{"id":"firework","name_key":"ITEM_FIREWORK","result":"firework","count":1,"components":[["gunpowder",1],["paper",1]]},
	{"id":"molotov","name_key":"ITEM_MOLOTOV","result":"molotov","count":1,"components":[["bottle",1],["fabric",1],["alcohol",1]]},
	{"id":"makeshift_lamp","name_key":"ITEM_MAKESHIFT_LAMP","result":"makeshift_lamp","count":1,"components":[["metal",2],["battery",1]]},
]

var _active_tab: int = 0
var _selected_recipe: int = -1
var _craft_qty: int = 1
var _recipe_btns: Array = []
var _comp_labels: Array = []
var _detail_frame: ColorRect
var _detail_title: Label
var _qty_label: Label
var _create_btn: Button
var _craft_panel: Control
var _upgrade_panel: Control
var _salvage_panel: Control
var _salvage_vbox: VBoxContainer
var _salvage_info: Label
var _salvage_btn: Button
var _selected_salvage: int = -1

func _ready() -> void:
	if not enable_workbench: return
	_build_tabs()
	_build_craft_panel()
	_build_upgrade_panel()
	_build_salvage_panel()
	_switch_tab(0)

func _build_tabs() -> void:
	var tw := size.x / 3.0
	var names := [tr("WORKBENCH_CRAFT"), tr("WORKBENCH_UPGRADE"), tr("WORKBENCH_SALVAGE")]
	for i in 3:
		var btn := Button.new()
		btn.text = names[i]
		btn.size = Vector2(tw - 4, 26)
		btn.position = Vector2(i * tw + 2, 2)
		btn.add_theme_font_size_override("font_size", 11)
		btn.toggle_mode = true
		btn.button_pressed = i == 0
		add_child(btn)
		btn.pressed.connect(func(idx := i): _on_tab_pressed(idx))

func _on_tab_pressed(idx: int) -> void:
	_active_tab = idx
	_switch_tab(idx)

func _switch_tab(idx: int) -> void:
	if _craft_panel: _craft_panel.visible = idx == 0
	if _upgrade_panel: _upgrade_panel.visible = idx == 1
	if _salvage_panel: _salvage_panel.visible = idx == 2
	if idx == 2: _refresh_salvage()

func _build_craft_panel() -> void:
	_craft_panel = Control.new()
	_craft_panel.size = Vector2(size.x, size.y - 32)
	_craft_panel.position = Vector2(0, 32)
	add_child(_craft_panel)

	var list_w := size.x * 0.42
	var list_scroll := ScrollContainer.new()
	list_scroll.size = Vector2(list_w, _craft_panel.size.y - 10)
	list_scroll.position = Vector2(0, 0)
	_craft_panel.add_child(list_scroll)
	var list_vbox := VBoxContainer.new()
	list_vbox.size = Vector2(list_w, RECIPES.size() * 38)
	list_scroll.add_child(list_vbox)

	for i in RECIPES.size():
		var r := RECIPES[i]
		var row = ColorRect.new()
		row.color = PANEL_EDGE
		row.custom_minimum_size = Vector2(list_w - 6, 34)
		row.size = Vector2(list_w - 6, 34)
		list_vbox.add_child(row)
		var lbl := Label.new()
		lbl.text = tr(r["name_key"])
		lbl.size = Vector2(row.size.x - 36, 30)
		lbl.position = Vector2(4, 2)
		lbl.add_theme_color_override("font_color", STEEL_TEXT)
		lbl.add_theme_font_size_override("font_size", 11)
		row.add_child(lbl)
		var stlbl := Label.new()
		stlbl.name = "Status"
		stlbl.text = "OK" if _can_craft_recipe(i) else "--"
		stlbl.size = Vector2(24, 20)
		stlbl.position = Vector2(row.size.x - 28, 7)
		stlbl.add_theme_color_override("font_color", STAMINA if _can_craft_recipe(i) else EMBER)
		stlbl.add_theme_font_size_override("font_size", 10)
		row.add_child(stlbl)
		_recipe_btns.append(row)
		var idx := i
		row.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_select_recipe(idx)
		)

	var detail_x := list_w + 10
	_detail_frame = ColorRect.new()
	_detail_frame.color = PANEL
	_detail_frame.size = Vector2(size.x - detail_x - 10, _craft_panel.size.y - 10)
	_detail_frame.position = Vector2(detail_x, 0)
	_craft_panel.add_child(_detail_frame)

	_detail_title = Label.new()
	_detail_title.size = Vector2(_detail_frame.size.x - 20, 22)
	_detail_title.position = Vector2(10, 6)
	_detail_title.add_theme_color_override("font_color", BONE_TEXT)
	_detail_title.add_theme_font_size_override("font_size", 14)
	_detail_frame.add_child(_detail_title)

	var req_lbl := Label.new()
	req_lbl.text = tr("CRAFT_REQUIRES")
	req_lbl.size = Vector2(_detail_frame.size.x - 20, 18)
	req_lbl.position = Vector2(10, 32)
	req_lbl.add_theme_color_override("font_color", STEEL_TEXT)
	req_lbl.add_theme_font_size_override("font_size", 11)
	_detail_frame.add_child(req_lbl)

	var qty_y := _detail_frame.size.y - 70
	var minus := Button.new()
	minus.text = "-1"
	minus.size = Vector2(36, 26)
	minus.position = Vector2(10, qty_y)
	minus.add_theme_font_size_override("font_size", 10)
	_detail_frame.add_child(minus)
	minus.pressed.connect(func(): _change_qty(-1))

	_qty_label = Label.new()
	_qty_label.text = "1"
	_qty_label.size = Vector2(40, 26)
	_qty_label.position = Vector2(50, qty_y)
	_qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_qty_label.add_theme_color_override("font_color", BONE_TEXT)
	_qty_label.add_theme_font_size_override("font_size", 14)
	_detail_frame.add_child(_qty_label)

	var plus := Button.new()
	plus.text = "+1"
	plus.size = Vector2(36, 26)
	plus.position = Vector2(94, qty_y)
	plus.add_theme_font_size_override("font_size", 10)
	_detail_frame.add_child(plus)
	plus.pressed.connect(func(): _change_qty(1))

	_create_btn = Button.new()
	_create_btn.text = tr("WORKBENCH_CREATE_BTN")
	_create_btn.size = Vector2(110, 30)
	_create_btn.position = Vector2(_detail_frame.size.x * 0.5 - 55, qty_y)
	_create_btn.add_theme_font_size_override("font_size", 11)
	_create_btn.disabled = true
	_detail_frame.add_child(_create_btn)
	_create_btn.pressed.connect(_do_craft)

	_select_recipe(0)

func _select_recipe(idx: int) -> void:
	_selected_recipe = idx
	_craft_qty = 1
	_update_detail()

func _update_detail() -> void:
	for l in _comp_labels: l.queue_free()
	_comp_labels.clear()
	if _selected_recipe < 0 or _selected_recipe >= RECIPES.size():
		_detail_title.text = ""
		_create_btn.disabled = true
		return
	var r := RECIPES[_selected_recipe]
	_detail_title.text = tr(r["name_key"])
	var cy := 54.0
	for comp in r["components"]:
		var item_id = comp[0] as String
		var needed = comp[1] * _craft_qty
		var have := InventoryManager.count_of(item_id) if InventoryManager else 0
		var key := "ITEM_" + item_id.to_upper()
		var clbl := Label.new()
		clbl.text = tr(key) + ": " + str(needed) + " / " + str(have)
		clbl.size = Vector2(_detail_frame.size.x - 20, 18)
		clbl.position = Vector2(10, cy)
		clbl.add_theme_color_override("font_color", STAMINA if have >= needed else EMBER)
		clbl.add_theme_font_size_override("font_size", 11)
		_detail_frame.add_child(clbl)
		_comp_labels.append(clbl)
		cy += 22
	var can := _can_craft_qty(_selected_recipe, _craft_qty)
	_create_btn.disabled = not can
	_qty_label.text = str(_craft_qty)
	_refresh_list()

func _change_qty(delta: int) -> void:
	if _selected_recipe < 0: return
	var max_qty := 99
	var r := RECIPES[_selected_recipe]
	for comp in r["components"]:
		var item_id = comp[0] as String
		var have := InventoryManager.count_of(item_id) if InventoryManager else 0
		var per = comp[1]
		if per > 0:
			max_qty = mini(max_qty, floori(have / per))
	_craft_qty = clampi(_craft_qty + delta, 1, maxi(1, max_qty))
	_update_detail()

func _can_craft_recipe(idx: int) -> bool:
	if not InventoryManager or idx < 0 or idx >= RECIPES.size(): return false
	var r := RECIPES[idx]
	for comp in r["components"]:
		if InventoryManager.count_of(comp[0]) < comp[1]: return false
	return true

func _can_craft_qty(idx: int, qty: int) -> bool:
	if not InventoryManager or idx < 0 or idx >= RECIPES.size(): return false
	var r := RECIPES[idx]
	for comp in r["components"]:
		if InventoryManager.count_of(comp[0]) < comp[1] * qty: return false
	return qty > 0

func _do_craft() -> void:
	if _selected_recipe < 0 or not _can_craft_qty(_selected_recipe, _craft_qty): return
	var r := RECIPES[_selected_recipe]
	for comp in r["components"]:
		InventoryManager.remove(comp[0], comp[1] * _craft_qty)
	InventoryManager.try_add(r["result"], r["count"] * _craft_qty)
	# q_craft_items only advanced via crafting_manager.gd, which is never
	# autoloaded/instantiated anywhere - the real crafting path (here)
	# never satisfied it, so the quest was permanently uncompletable.
	var qm := get_node_or_null("/root/QuestManager")
	if qm != null and qm.has_method("complete_objective"):
		qm.complete_objective(&"q_craft_items", &"", _craft_qty)
	if EventBus and EventBus.has_signal("inventory_notice"):
		EventBus.inventory_notice.emit(tr("CRAFT_CREATED") + ": " + tr(r["name_key"]) + " x" + str(_craft_qty))
	_update_detail()
	_refresh_list()

func _refresh_list() -> void:
	for i in _recipe_btns.size():
		var row = _recipe_btns[i]
		if not is_instance_valid(row): continue
		var stlbl := row.get_node_or_null("Status") as Label
		if stlbl:
			var can := _can_craft_recipe(i)
			stlbl.text = "OK" if can else "--"
			stlbl.add_theme_color_override("font_color", STAMINA if can else EMBER)

func _build_upgrade_panel() -> void:
	_upgrade_panel = Control.new()
	_upgrade_panel.size = Vector2(size.x, size.y - 32)
	_upgrade_panel.position = Vector2(0, 32)
	_upgrade_panel.visible = false
	add_child(_upgrade_panel)
	var title := Label.new()
	title.text = tr("WORKBENCH_UPGRADE")
	title.size = Vector2(size.x - 20, 24)
	title.position = Vector2(10, 10)
	title.add_theme_color_override("font_color", BONE_TEXT)
	title.add_theme_font_size_override("font_size", 14)
	_upgrade_panel.add_child(title)
	title.add_theme_color_override("font_outline_color", Color(0.047, 0.063, 0.086, 1.0))
	title.add_theme_constant_override("outline_size", 2)
	var info := Label.new()
	info.text = "Upgrade system \u2014 coming soon"
	info.size = Vector2(size.x - 20, 100)
	info.position = Vector2(10, 40)
	info.add_theme_color_override("font_color", STEEL_TEXT)
	info.add_theme_font_size_override("font_size", 11)
	_upgrade_panel.add_child(info)

func _build_salvage_panel() -> void:
	_salvage_panel = Control.new()
	_salvage_panel.size = Vector2(size.x, size.y - 32)
	_salvage_panel.position = Vector2(0, 32)
	_salvage_panel.visible = false
	add_child(_salvage_panel)
	var title := Label.new()
	title.text = tr("WORKBENCH_SALVAGE")
	title.size = Vector2(size.x - 20, 24)
	title.position = Vector2(10, 10)
	title.add_theme_color_override("font_color", BONE_TEXT)
	title.add_theme_font_size_override("font_size", 14)
	_salvage_panel.add_child(title)
	title.add_theme_color_override("font_outline_color", Color(0.047, 0.063, 0.086, 1.0))
	title.add_theme_constant_override("outline_size", 2)

	var scroll := ScrollContainer.new()
	scroll.name = "SalvageScroll"
	scroll.size = Vector2(size.x * 0.55, _salvage_panel.size.y - 50)
	scroll.position = Vector2(10, 36)
	_salvage_panel.add_child(scroll)
	_salvage_vbox = VBoxContainer.new()
	_salvage_vbox.size = Vector2(scroll.size.x, 0)
	scroll.add_child(_salvage_vbox)

	_salvage_info = Label.new()
	_salvage_info.text = ""
	_salvage_info.size = Vector2(size.x * 0.35, 80)
	_salvage_info.position = Vector2(size.x * 0.55 + 20, 36)
	_salvage_info.add_theme_color_override("font_color", STEEL_TEXT)
	_salvage_info.add_theme_font_size_override("font_size", 11)
	_salvage_panel.add_child(_salvage_info)

	_salvage_btn = Button.new()
	_salvage_btn.text = tr("WORKBENCH_CREATE_BTN")
	_salvage_btn.size = Vector2(110, 30)
	_salvage_btn.position = Vector2(size.x * 0.55 + 20, 120)
	_salvage_btn.add_theme_font_size_override("font_size", 11)
	_salvage_btn.disabled = true
	_salvage_panel.add_child(_salvage_btn)
	_salvage_btn.pressed.connect(_do_salvage)

func _refresh_salvage() -> void:
	if not _salvage_vbox: return
	for c in _salvage_vbox.get_children(): c.queue_free()
	_selected_salvage = -1
	_salvage_info.text = ""
	_salvage_btn.disabled = true
	var idx := 0
	for slot in InventoryManager.slots:
		if slot == null: idx += 1; continue
		var item_id = slot["item_id"]
		var cnt = slot["count"]
		var row = ColorRect.new()
		row.color = PANEL_EDGE
		row.custom_minimum_size = Vector2(_salvage_vbox.size.x - 6, 30)
		row.size = Vector2(_salvage_vbox.size.x - 6, 30)
		_salvage_vbox.add_child(row)
		var key := "ITEM_" + String(item_id).to_upper()
		var lbl := Label.new()
		lbl.text = tr(key) + " x" + str(cnt)
		lbl.size = Vector2(row.size.x - 8, 26)
		lbl.position = Vector2(4, 2)
		lbl.add_theme_color_override("font_color", STEEL_TEXT)
		lbl.add_theme_font_size_override("font_size", 11)
		row.add_child(lbl)
		var sidx := idx
		var click := ColorRect.new()
		click.color = Color(1, 1, 1, 0.01)
		click.size = row.size
		click.mouse_filter = Control.MOUSE_FILTER_STOP
		row.add_child(click)
		click.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_select_salvage(sidx)
		)
		idx += 1

func _select_salvage(idx: int) -> void:
	_selected_salvage = idx
	var sidx := 0
	for slot in InventoryManager.slots:
		if slot == null: sidx += 1; continue
		if sidx == idx:
			var key := "ITEM_" + String(slot["item_id"]).to_upper()
			var parts := []
			for r in RECIPES:
				if r["result"] == String(slot["item_id"]):
					for comp in r["components"]:
						var ckey = "ITEM_" + comp[0].to_upper()
						parts.append(tr(ckey) + " x" + str(maxi(1, comp[1] / 2)))
					break
			var extra := ""
			if parts.size() > 0:
				extra = "\n" + tr("CRAFT_REQUIRES") + ": " + ", ".join(parts)
			_salvage_info.text = tr(key) + extra
			_salvage_btn.disabled = false
			return
		sidx += 1
	_salvage_info.text = ""
	_salvage_btn.disabled = true

func _do_salvage() -> void:
	var sidx := 0
	for slot in InventoryManager.slots:
		if slot == null: sidx += 1; continue
		if sidx == _selected_salvage:
			var item_id = slot["item_id"]
			for r in RECIPES:
				if r["result"] == String(item_id):
					for comp in r["components"]:
						var half := maxi(1, comp[1] / 2)
						InventoryManager.try_add(comp[0], half)
					InventoryManager.remove(item_id, 1)
					if EventBus and EventBus.has_signal("inventory_notice"):
						var key := "ITEM_" + String(item_id).to_upper()
						EventBus.inventory_notice.emit("Salvaged: " + tr(key))
					_selected_salvage = -1
					_refresh_salvage()
					return
			return
		sidx += 1
