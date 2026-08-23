extends Node3D
## S8 Craft Station: interact (inspectable) -> recipe list -> craft from inventory.

const RECIPES: Dictionary = {
	# "name" — ключ локализации: названия рецептов видит игрок, а языков 13.
	&"battery": {"result": &"battery", "amount": 1, "ingredients": {&"scrap": 2, &"cable": 1}, "name": "CRAFT_BATTERY"},
	&"medkit": {"result": &"medkit", "amount": 1, "ingredients": {&"scrap": 1, &"gear": 1}, "name": "ITEM_MEDKIT"},
	&"fuse": {"result": &"fuse", "amount": 1, "ingredients": {&"scrap": 1, &"wiring": 1}, "name": "ITEM_FUSE"},
}

var _ui: CanvasLayer = null
var _inv: Node = null
var _panel: PanelContainer = null
var _list: VBoxContainer = null

func _ready() -> void:
	_inv = get_tree().root.get_node_or_null("/root/InventoryManager")
	var area := Area3D.new()
	area.name = "InteractArea"
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.0, 2.0, 2.0)
	col.shape = shape
	area.add_child(col)
	area.add_to_group("inspectable")
	add_child(area)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.4, 1.0, 0.8)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.28, 0.2)
	mesh.material_override = mat
	add_child(mesh)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.8, 0.4)
	light.light_energy = 1.2
	light.omni_range = 4.0
	light.shadow_enabled = false
	add_child(light)

func try_inspect() -> bool:
	_open_ui()
	return true

func _open_ui() -> void:
	if _ui != null:
		return
	_ui = CanvasLayer.new()
	_ui.name = "CraftUI"
	_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.08, 0.08, 0.1, 0.96)
	st.set_corner_radius_all(0)
	_panel.add_theme_stylebox_override("panel", st)
	_panel.anchors_preset = Control.PRESET_CENTER
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.size = Vector2(480, 360)
	_ui.add_child(_panel)
	var box := VBoxContainer.new()
	_panel.add_child(box)
	var title := Label.new()
	title.text = LocalizationManager.t("WORKBENCH_TITLE").to_upper()
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_list = VBoxContainer.new()
	box.add_child(_list)
	var close_btn := Button.new()
	close_btn.text = LocalizationManager.t("WORKBENCH_CLOSE")
	close_btn.pressed.connect(_close_ui)
	box.add_child(close_btn)
	get_tree().root.add_child(_ui)
	EventBus.inventory_changed.connect(_refresh)
	_refresh()

func _close_ui() -> void:
	if _ui == null:
		return
	if EventBus.inventory_changed.is_connected(_refresh):
		EventBus.inventory_changed.disconnect(_refresh)
	_ui.queue_free()
	_ui = null

func _refresh() -> void:
	if _list == null:
		return
	for child in _list.get_children():
		child.queue_free()
	for id: StringName in RECIPES:
		var r: Dictionary = RECIPES[id]
		var can := _can_craft(r)
		var btn := Button.new()
		btn.text = "%s x%d — %s" % [LocalizationManager.t(str(r["name"])), r["amount"], _ingredients_text(r["ingredients"])]
		btn.disabled = not can
		btn.pressed.connect(_on_craft.bind(id))
		_list.add_child(btn)

func _ingredients_text(ingredients: Dictionary) -> String:
	var parts: PackedStringArray = []
	for item_id: StringName in ingredients:
		# Имя ингредиента берём из ItemDatabase, а не из сырого id.
		var item: ItemData = ItemDatabase.get_item(item_id)
		var nm: String = LocalizationManager.name_for("ITEM_", item_id, item.display_name if item != null else "")
		parts.append("%s x%d" % [nm, int(ingredients[item_id])])
	return " + ".join(parts)

func _can_craft(r: Dictionary) -> bool:
	if _inv == null:
		return false
	for item_id: StringName in r["ingredients"]:
		if not _inv.has(item_id, int(r["ingredients"][item_id])):
			return false
	return true

func _on_craft(recipe_id: StringName) -> void:
	if not RECIPES.has(recipe_id):
		return
	var r: Dictionary = RECIPES[recipe_id]
	if not _can_craft(r):
		return
	for item_id: StringName in r["ingredients"]:
		_inv.remove(item_id, int(r["ingredients"][item_id]))
	if _inv.try_add(r["result"], int(r["amount"])):
		EventBus.inventory_notice.emit(LocalizationManager.tf("WORKBENCH_CRAFTED", [LocalizationManager.t(str(r["name"]))]))
		print("[craft] done: ", recipe_id)
	_refresh()
