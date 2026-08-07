extends Node3D
## Shop: interactable vendor NPC + UI panel for battery/medkit/stamina.

const ITEMS := [
	{"id": "battery", "key": "shop_battery", "cost":  50},
	{"id": "medkit",  "key": "shop_medkit",  "cost": 100},
	{"id": "stamina", "key": "shop_stamina", "cost":  75}
]

var _ui: CanvasLayer
var _bus: Node
var _sl: Node

func _ready() -> void:
	_bus = get_node_or_null("/root/EventBus")
	_sl = get_node_or_null("/root/SaveLoad")

func interact(player: Node) -> void:
	if _ui == null:
		_build_ui()
	_ui.visible = true

func close() -> void:
	if _ui != null:
		_ui.visible = false

func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 50
	add_child(_ui)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	_ui.add_child(bg)

	var center := CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	_ui.add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)

	var title := Label.new()
	title.text = "SHOP"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	for it in ITEMS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		box.add_child(row)

		var name_l := Label.new()
		name_l.custom_minimum_size = Vector2(220, 0)
		var i18n := get_node_or_null("/root/I18n")
		if i18n != null and i18n.has_method("t"):
			name_l.text = i18n.t(StringName(it["key"]))
		else:
			name_l.text = it["id"]
		name_l.add_theme_font_size_override("font_size", 18)
		name_l.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
		row.add_child(name_l)

		var cost_l := Label.new()
		cost_l.text = "● %d" % int(it["cost"])
		cost_l.add_theme_font_size_override("font_size", 18)
		cost_l.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		row.add_child(cost_l)

		var btn := Button.new()
		btn.text = "BUY"
		btn.pressed.connect(_on_buy.bind(it["id"], int(it["cost"])))
		row.add_child(btn)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.pressed.connect(_on_close)
	box.add_child(close_btn)

func _on_buy(item_id: String, cost: int) -> void:
	if _sl == null or not _sl.has_method("get_coins"):
		return
	if int(_sl.get_coins()) < cost:
		return
	_sl.add_coins(-cost)
	if _bus != null:
		_bus.shop_purchased.emit(StringName(item_id))

func _on_close() -> void:
	close()