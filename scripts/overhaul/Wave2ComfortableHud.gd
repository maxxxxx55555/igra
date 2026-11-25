class_name Wave2ComfortableHud
extends Node

## The HUD owns the touch arc, left-handed layout and user scaling. Keep the hotbar
## above the light dock and use the same safe rectangle as the map and action buttons.
const REMOVE_TOKENS: Array[String] = ["wifi", "wi-fi", "bonusoffer", "bonus_offer", "debuglog", "btnlog", "logpanel"]

func _ready() -> void:
	var hud := get_parent()
	_purge_clutter_nodes(hud)
	get_viewport().size_changed.connect(apply_comfortable_layout)
	call_deferred("apply_comfortable_layout")

func apply_comfortable_layout() -> void:
	var canvas := get_viewport().get_visible_rect().size
	layout_in_safe_area(canvas, UiScale.insets(canvas))

func layout_in_safe_area(canvas: Vector2, inset: Vector4) -> void:
	var hud := get_parent()
	var bar := hud.get_node_or_null("BottomCenter") as Control
	if bar == null:
		return
	var bar_size := bar.get_combined_minimum_size().max(Vector2(348, 56))
	var clearance := 24.0
	if hud.has_touch_ui():
		# Leave room for all four dock targets below the six quick slots.
		clearance += maxf(56.0, roundf(canvas.y / 720.0 * 54.0)) + 20.0
	bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	bar.size = bar_size
	bar.position = Vector2((canvas.x + inset.x - inset.z - bar_size.x) * 0.5,
		canvas.y - inset.w - clearance - bar_size.y)

func _purge_clutter_nodes(root: Node) -> void:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		if not is_instance_valid(cur):
			continue
		var ln: String = cur.name.to_lower()
		var is_clutter: bool = false
		for tok in REMOVE_TOKENS:
			if ln.contains(tok):
				is_clutter = true
				break
		if is_clutter and cur != root:
			if cur is CanvasItem:
				(cur as CanvasItem).visible = false
			if cur is Control:
				(cur as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
			continue
		for ch in cur.get_children():
			stack.append(ch)
