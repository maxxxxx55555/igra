extends Control
class_name SaveSlotsUI

@onready var slot_container: GridContainer = $MarginContainer/VBoxContainer/SlotContainer
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton

const MAX_SLOTS = 4

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(600, 400)
	
	back_button.pressed.connect(_close)
	_refresh_slots()

func _refresh_slots() -> void:
	# Clear old
	for child in slot_container.get_children():
		child.queue_free()
	
	for i in range(MAX_SLOTS):
		var slot = SaveSlotEntry.new()
		slot_container.add_child(slot)
		slot.setup(i + 1)

func _close() -> void:
	UIManager.close(&"save_slots")