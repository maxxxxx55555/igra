extends Button
## A cell of the inventory screen with a part in rebinding the quick bar (GDD 9.7). With `item_id` set it can be dragged;
## with `slot` set (0..5) it is one of the six targets that take the drop, and a right-click puts the slot back to its default.

const QUICK_SLOTS := preload("res://scripts/ui/quick_slots.gd")
const ITEM_ICONS := preload("res://scripts/ui/item_icons.gd")
const DRAG_KEY: String = "quick_item"
const PREVIEW_SIZE: float = 48.0

var item_id: StringName = &""
var slot: int = -1

func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_id == &"":
		return null
	var preview := Control.new()
	preview.name = "DragPreview"
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ITEM_ICONS.draw_icon(preview, item_id, PREVIEW_SIZE)
	set_drag_preview(preview)
	return {DRAG_KEY: item_id}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return slot >= 0 and data is Dictionary and QUICK_SLOTS.can_bind(StringName(str((data as Dictionary).get(DRAG_KEY, ""))))

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if _can_drop_data(at_position, data):
		QUICK_SLOTS.bind(slot, StringName(str((data as Dictionary)[DRAG_KEY])))

func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if slot >= 0 and click != null and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT:
		QUICK_SLOTS.clear(slot)
		accept_event()
