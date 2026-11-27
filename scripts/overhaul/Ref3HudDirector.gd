class_name Ref3HudDirector
extends RefCounted

## Reference Photo #3 HUD Layout, Controls & Minimap Director for Last Streetlight.
## Uses strictly canonical ThemeProvider palette tokens (zero color drift).

const COL_BG: Color = Color("#0f1314")
const COL_BG_DEEP: Color = Color("#060f13")
const COL_BRONZE: Color = Color("#5a4a2a")
const COL_AMBER: Color = Color("#d4a94e")
const COL_IVORY: Color = Color("#e6dfd1")
const COL_ASH: Color = Color("#8a8a85")
const RADAR_MASK_SHADER: String = "res://shaders/overhaul/circular_radar_mask.gdshader"


static func deduplicate_joystick(hud_root: Node, viewport_size: Vector2, inset: Vector4) -> void:
	"""Ensures strictly ONE BottomLeft circular joystick anchored cleanly bottom-left."""
	if hud_root == null or not is_instance_valid(hud_root):
		return
	var bottom_left := hud_root.get_node_or_null("BottomLeft") as Control
	var ring := hud_root.get_node_or_null("BottomLeft/JoystickRing") as Control
	var sf: float = clampf(viewport_size.y / 720.0, 0.78, 1.25)
	var joy_d: float = roundf(144.0 * sf)
	var margin_x: float = 24.0 + inset.x
	var margin_y: float = 22.0 + inset.w

	# Hide any stray duplicate joystick nodes created elsewhere in HUD
	for child in hud_root.get_children():
		if child == bottom_left:
			continue
		var ln: String = child.name.to_lower()
		if ("joystick" in ln or "joyring" in ln) and child is CanvasItem:
			(child as CanvasItem).visible = false

	if bottom_left != null:
		bottom_left.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		bottom_left.offset_left = margin_x
		bottom_left.offset_top = viewport_size.y - margin_y - joy_d
		bottom_left.offset_right = margin_x + joy_d
		bottom_left.offset_bottom = viewport_size.y - margin_y
		bottom_left.scale = Vector2.ONE
	# One pad in the whole tree: a second pad left over from a scene swap is
	# the duplicate the Reference #3 plate must not show.
	for node in hud_root.get_tree().root.find_children("*", "CanvasItem", true, false):
		if node != ring and node != bottom_left and ("joystick" in node.name.to_lower() or "joyring" in node.name.to_lower()):
			(node as CanvasItem).visible = false

	if ring != null:
		ring.set_anchors_preset(Control.PRESET_FULL_RECT)
		ring.offset_left = 0.0
		ring.offset_top = 0.0
		ring.offset_right = 0.0
		ring.offset_bottom = 0.0
		# Remove duplicate Panel border so virtual_joystick_ref3 draws the single clean bezel
		var empty_sb := StyleBoxEmpty.new()
		ring.add_theme_stylebox_override("panel", empty_sb)
		# Keep strictly ONE JoystickInput child
		var seen_input: bool = false
		for ch in ring.get_children():
			if "joystick" in ch.name.to_lower():
				if seen_input:
					ch.queue_free()
				else:
					seen_input = true


static func arrange_ref3_stat_bars(hud_root: Node, viewport_size: Vector2, inset: Vector4, touch_active: bool) -> void:
	"""Places compact horizontal stat bars right beside the bottom-left joystick (Ref Photo #3)."""
	if hud_root == null or not is_instance_valid(hud_root):
		return
	var top_left := hud_root.get_node_or_null("TopLeft") as Control
	var backing := hud_root.get_node_or_null("StatusBacking") as Control
	if top_left == null:
		return
	var sf: float = clampf(viewport_size.y / 720.0, 0.78, 1.25)
	var joy_d: float = roundf(144.0 * sf) if touch_active else 0.0
	var x0: float = 24.0 + inset.x + (joy_d + 18.0 if touch_active else 0.0)
	var h: float = 98.0
	var y0: float = viewport_size.y - (22.0 + inset.w) - h

	top_left.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top_left.position = Vector2(x0, y0)
	top_left.size = Vector2(246.0, h)
	if backing != null:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(COL_BG, 0.66)
		sb.border_color = Color(COL_BRONZE, 0.48)
		sb.border_width_left = 2
		sb.border_width_bottom = 1
		sb.border_width_top = 0
		sb.border_width_right = 0
		sb.set_corner_radius_all(2)
		backing.add_theme_stylebox_override("panel", sb)
		backing.set_anchors_preset(Control.PRESET_TOP_LEFT)
		backing.position = Vector2(x0 - 10.0, y0 - 6.0)
		backing.size = Vector2(264.0, h + 12.0)


static func apply_circular_radar_style(mini_btn: Control, mini_canvas: Control, viewport_size: Vector2, inset: Vector4) -> float:
	"""Converts top-right minimap into a true Reference Photo #3 circular radar (zero square frame!).
	Returns the Y coordinate directly below the radar so the objective card docks beneath it."""
	var sf: float = clampf(viewport_size.y / 720.0, 0.78, 1.25)
	var d: float = roundf(138.0 * sf)
	var pause_gap: float = 64.0
	var x0: float = viewport_size.x - inset.z - 18.0 - pause_gap - d
	var y0: float = inset.y + 14.0

	if mini_btn != null and is_instance_valid(mini_btn):
		mini_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
		mini_btn.position = Vector2(x0, y0)
		mini_btn.size = Vector2(d, d)
		mini_btn.custom_minimum_size = Vector2(d, d)
		var trans := StyleBoxEmpty.new()
		for st: StringName in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
			mini_btn.add_theme_stylebox_override(st, trans)

	if mini_canvas != null and is_instance_valid(mini_canvas):
		mini_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
		mini_canvas.offset_left = 0.0
		mini_canvas.offset_top = 0.0
		mini_canvas.offset_right = 0.0
		mini_canvas.offset_bottom = 0.0
		if ResourceLoader.exists(RADAR_MASK_SHADER):
			var sh := load(RADAR_MASK_SHADER) as Shader
			if sh != null:
				var sm := ShaderMaterial.new()
				sm.shader = sh
				mini_canvas.material = sm

	return y0 + d + 10.0


static func make_objective_card_style() -> StyleBoxFlat:
	"""Borderless dark charcoal objective card docked under circular minimap (Ref Photo #3)."""
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(COL_BG, 0.74)
	sb.border_color = Color(COL_BRONZE, 0.65)
	sb.border_width_left = 2
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	return sb


static func make_ref3_touch_button_style(pressed: bool, primary: bool = false) -> StyleBoxFlat:
	"""Clean circular charcoal & weathered bronze mobile action button (Ref Photo #3)."""
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(COL_BG_DEEP, 0.92) if pressed else Color(COL_BG, 0.76)
	sb.border_color = COL_AMBER if (pressed or primary) else Color(COL_BRONZE, 0.85)
	sb.set_border_width_all(2 if (pressed or primary) else 1)
	sb.set_corner_radius_all(48)
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	return sb


static func dock_objective_under_radar(obj_ctrl: Control, radar_bottom_y: float, viewport_size: Vector2, inset: Vector4) -> void:
	if obj_ctrl == null or not is_instance_valid(obj_ctrl):
		return
	var w: float = 236.0
	obj_ctrl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	obj_ctrl.position = Vector2(viewport_size.x - inset.z - 18.0 - w, radar_bottom_y)
	obj_ctrl.custom_minimum_size = Vector2(w, 0.0)
	if obj_ctrl is PanelContainer or obj_ctrl is Panel:
		obj_ctrl.add_theme_stylebox_override("panel", make_objective_card_style())
