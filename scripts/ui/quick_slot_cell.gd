extends Button
## A cell of the inventory screen with a part in rebinding the quick bar (GDD 9.7). With `item_id` set it can be dragged;
## with `slot` set (0..5) it is one of the six targets that take the drop, and a right-click puts the slot back to its default.
## The states of a drag (the recovery brief): the cell it starts from dims, and every target edges amber while an item that can be bound is carried, ember while one that cannot is.

const QUICK_SLOTS := preload("res://scripts/ui/quick_slots.gd")
const ITEM_ICONS := preload("res://scripts/ui/item_icons.gd")
const KIT := preload("res://scripts/ui/inv_kit.gd")
const DRAG_KEY: String = "quick_item"
const PREVIEW_SIZE: float = 48.0
const SOURCE_ALPHA: float = 0.45

var item_id: StringName = &""
var slot: int = -1
var _base: StyleBox = null

func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_id == &"":
		return null
	var preview := Control.new()
	preview.name = "DragPreview"
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ITEM_ICONS.draw_icon(preview, item_id, PREVIEW_SIZE)
	if is_inside_tree() and get_viewport().gui_is_dragging():
		set_drag_preview(preview)
		modulate.a = SOURCE_ALPHA
	else:
		preview.free()
	return {DRAG_KEY: item_id}

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		modulate.a = 1.0
		if _base != null:
			add_theme_stylebox_override("normal", _base)
			_base = null
	elif what == NOTIFICATION_DRAG_BEGIN and slot >= 0 and get_viewport().gui_get_drag_data() is Dictionary:
		var carried := StringName(str((get_viewport().gui_get_drag_data() as Dictionary).get(DRAG_KEY, "")))
		var style := get_theme_stylebox("normal") as StyleBoxFlat
		if style != null:
			_base = style
			var marked := style.duplicate() as StyleBoxFlat
			marked.border_color = KIT.AMBER if QUICK_SLOTS.can_bind(carried) else KIT.DANGER
			marked.set_border_width_all(2)
			add_theme_stylebox_override("normal", marked)

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
