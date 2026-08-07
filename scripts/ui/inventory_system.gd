extends CanvasLayer

signal inventory_toggled(is_open: bool)
signal item_used(item_id: String)

@onready var inventory_panel: Panel = $InventoryPanel
@onready var item_grid: GridContainer = $InventoryPanel/VBoxContainer/ItemGrid
@onready var weight_bar: ProgressBar = $InventoryPanel/VBoxContainer/WeightBar
@onready var weight_label: Label = $InventoryPanel/VBoxContainer/WeightLabel
@onready var close_button: Button = $InventoryPanel/VBoxContainer/CloseButton

var inventory_slots: Array[Dictionary] = []

const MAX_SLOTS: int = 20
const MAX_WEIGHT: float = 40.0
var current_weight: float = 0.0
var is_open: bool = false
var items_db: Dictionary = {
	"medkit": {"name": "Aptechka", "weight": 0.5, "icon": "res://assets/textures/items/medkit.png", "type": "consumable", "effect": "heal", "value": 25},
	"flashlight": {"name": "Fonarik", "weight": 0.8, "icon": "res://assets/textures/items/flashlight.png", "type": "tool"},
	"can_food": {"name": "Konservy", "weight": 0.4, "icon": "res://assets/textures/items/can_food.png", "type": "consumable", "effect": "hunger", "value": 20},
	"key": {"name": "Kljuch", "weight": 0.1, "icon": "res://assets/textures/items/key.png", "type": "key"},
	"water": {"name": "Voda", "weight": 0.6, "icon": "res://assets/textures/items/water.png", "type": "consumable", "effect": "thirst", "value": 30},
	"wrench": {"name": "Gaechnyj kljuch", "weight": 1.2, "icon": "res://assets/textures/items/wrench.png", "type": "tool"},
	"backpack": {"name": "Rjuzak", "weight": 1.0, "icon": "res://assets/textures/items/backpack.png", "type": "container"},
	"pistol": {"name": "Pistolet", "weight": 1.5, "icon": "res://assets/textures/items/pistol.png", "type": "weapon"}
}

func _ready() -> void:
	inventory_panel.visible = false
	close_button.pressed.connect(_on_close_pressed)
	_init_slots()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		_toggle_inventory()

func _init_slots() -> void:
	for i in range(MAX_SLOTS):
		inventory_slots.append({"item_id": null, "quantity": 0})
		var slot_btn = Button.new()
		slot_btn.custom_minimum_size = Vector2(64, 64)
		slot_btn.name = "Slot" + str(i)
		slot_btn.pressed.connect(_on_slot_pressed.bind(i))
		item_grid.add_child(slot_btn)
	_update_ui()

func _toggle_inventory() -> void:
	is_open = !is_open
	inventory_panel.visible = is_open
	get_tree().paused = is_open
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_open else Input.MOUSE_MODE_CAPTURED
	inventory_toggled.emit(is_open)
	_update_ui()

func _on_close_pressed() -> void:
	_toggle_inventory()

func _on_slot_pressed(slot_index: int) -> void:
	var slot = inventory_slots[slot_index]
	if slot.item_id:
		_use_item(slot.item_id, slot_index)

func _use_item(item_id: String, slot_index: int) -> void:
	var item = items_db.get(item_id)
	if not item:
		return
	if item.type == "consumable":
		if item.effect == "heal" and GameManager.player and GameManager.player.has_node("HealthComponent"):
			GameManager.player.get_node("HealthComponent").heal(item.value)
		inventory_slots[slot_index].quantity -= 1
		if inventory_slots[slot_index].quantity <= 0:
			inventory_slots[slot_index] = {"item_id": null, "quantity": 0}
		_recalculate_weight()
		_update_ui()
	item_used.emit(item_id)

func add_item(item_id: String, quantity: int = 1) -> bool:
	var item = items_db.get(item_id)
	if not item:
		return false
	for i in range(inventory_slots.size()):
		if inventory_slots[i].item_id == item_id and inventory_slots[i].quantity > 0:
			inventory_slots[i].quantity += quantity
			_recalculate_weight()
			_update_ui()
			return true
	for i in range(inventory_slots.size()):
		if not inventory_slots[i].item_id:
			inventory_slots[i] = {"item_id": item_id, "quantity": quantity}
			_recalculate_weight()
			_update_ui()
			return true
	return false

func _recalculate_weight() -> void:
	current_weight = 0.0
	for slot in inventory_slots:
		if slot.item_id and items_db.has(slot.item_id):
			current_weight += items_db[slot.item_id].weight * slot.quantity

func _update_ui() -> void:
	for i in range(inventory_slots.size()):
		var slot_btn = item_grid.get_node("Slot" + str(i)) as Button
		if slot_btn == null:
			continue
		var slot = inventory_slots[i]
		for child in slot_btn.get_children():
			child.queue_free()
		if slot.item_id and items_db.has(slot.item_id):
			var item = items_db[slot.item_id]
			if ResourceLoader.exists(item.icon):
				var tex = load(item.icon)
				if tex:
					var icon = TextureRect.new()
					icon.texture = tex
					icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
					icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					slot_btn.add_child(icon)
			if slot.quantity > 1:
				var label = Label.new()
				label.text = str(slot.quantity)
				label.position = Vector2(40, 40)
				label.add_theme_color_override("font_color", Color.WHITE)
				slot_btn.add_child(label)
	weight_bar.value = (current_weight / MAX_WEIGHT) * 100.0
	weight_label.text = str("%.1f" % current_weight) + " / " + str(MAX_WEIGHT) + " kg"
	if current_weight > MAX_WEIGHT * 0.9:
		weight_bar.modulate = Color(1, 0.2, 0.2)
	elif current_weight > MAX_WEIGHT * 0.7:
		weight_bar.modulate = Color(1, 0.8, 0.2)
	else:
		weight_bar.modulate = Color.WHITE
