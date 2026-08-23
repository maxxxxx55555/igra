extends PanelContainer
class_name SaveSlotEntry

var slot_label: Label
var info_label: Label
var load_button: Button
var save_button: Button
var delete_button: Button

var _slot_index: int = 0

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)
	
	slot_label = Label.new()
	slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(slot_label)
	
	info_label = Label.new()
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(info_label)
	
	var hbox := HBoxContainer.new()
	vbox.add_child(hbox)
	
	load_button = Button.new()
	load_button.text = tr("Load")
	hbox.add_child(load_button)
	
	save_button = Button.new()
	save_button.text = tr("Save")
	hbox.add_child(save_button)
	
	delete_button = Button.new()
	delete_button.text = tr("Delete")
	hbox.add_child(delete_button)

func setup(slot_index: int) -> void:
	_slot_index = slot_index
	slot_label.text = tr("Slot %d") % slot_index
	
	var save_data = SaveSystem.get_slot_info(slot_index)
	if save_data and save_data.exists:
		var date = Time.get_datetime_string_from_unix_time(save_data.modified)
		info_label.text = tr("Level: %d\nPlaytime: %s\n%s") % [
			save_data.get("level", 1),
			_format_time(save_data.get("playtime", 0)),
			date
		]
		load_button.disabled = false
		delete_button.disabled = false
	else:
		info_label.text = tr("Empty")
		load_button.disabled = true
		delete_button.disabled = true
	
	load_button.pressed.connect(_on_load)
	save_button.pressed.connect(_on_save)
	delete_button.pressed.connect(_on_delete)

func _format_time(seconds: float) -> String:
	var hours = int(seconds / 3600)
	var mins = int(int(seconds) % 3600 / 60)
	return "%02d:%02d" % [hours, mins]

func _on_load() -> void:
	SaveSystem.load_slot(_slot_index)
	UIManager.close(&"save_slots")

func _on_save() -> void:
	SaveSystem.save_slot(_slot_index)
	setup(_slot_index)  # Refresh
	UIManager.show_notification(tr("Game saved to slot %d") % _slot_index)
	EventBus.game_saved.emit()

func _on_delete() -> void:
	SaveSystem.delete_slot(_slot_index)
	setup(_slot_index)  # Refresh
	UIManager.show_notification(tr("Slot %d deleted") % _slot_index)
