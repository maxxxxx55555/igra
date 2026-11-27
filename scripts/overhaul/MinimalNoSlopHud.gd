class_name MinimalNoSlopHud
extends RefCounted

## Borderless, diegetic minimal HUD styling matching 01_main_menu_ru.png & 12_death_and_victory.png.
## Eliminates every 1px bright-yellow prototype rectangle from HUD panels, objective pill,
## minimap, hotbar slots, and settings modal.

const COL_INK_VEIL: Color = Color(0.024, 0.043, 0.055, 0.56)
const COL_INK_MODAL: Color = Color(0.020, 0.036, 0.048, 0.90)
const COL_HAIRLINE_SLATE: Color = Color(0.32, 0.43, 0.50, 0.24)
const COL_HAIRLINE_BRASS: Color = Color(0.788, 0.635, 0.290, 0.26)
const COL_TEXT_WARM: Color = Color(0.86, 0.81, 0.70, 0.94)
const COL_TEXT_MUTED: Color = Color(0.62, 0.69, 0.74, 0.85)


static func make_borderless_hud_style(left_brass_accent: bool = false) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = COL_INK_VEIL
	sb.border_color = COL_HAIRLINE_BRASS if left_brass_accent else COL_HAIRLINE_SLATE
	sb.border_width_left = 2 if left_brass_accent else 0
	sb.border_width_right = 0
	sb.border_width_top = 0
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_left = 2
	sb.corner_radius_bottom_right = 2
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 6.0
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.40)
	sb.shadow_size = 10
	return sb


static func make_minimap_frame() -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.020, 0.039, 0.051, 0.78)
	sb.border_color = COL_HAIRLINE_SLATE
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 3
	sb.corner_radius_top_right = 3
	sb.corner_radius_bottom_left = 3
	sb.corner_radius_bottom_right = 3
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.48)
	sb.shadow_size = 12
	return sb


static func make_hotbar_slot(active: bool) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.035, 0.058, 0.074, 0.76 if active else 0.54)
	sb.border_color = Color(0.831, 0.663, 0.306, 0.72) if active else COL_HAIRLINE_SLATE
	sb.border_width_left = 0
	sb.border_width_right = 0
	sb.border_width_top = 0
	sb.border_width_bottom = 2 if active else 1
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_left = 2
	sb.corner_radius_bottom_right = 2
	return sb


static func make_modal_card() -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = COL_INK_MODAL
	sb.border_color = COL_HAIRLINE_BRASS
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	sb.content_margin_left = 20.0
	sb.content_margin_right = 20.0
	sb.content_margin_top = 16.0
	sb.content_margin_bottom = 16.0
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.65)
	sb.shadow_size = 24
	return sb


static func strip_yellow_boxes_recursive(node: Node) -> int:
	"""Replaces loud 1px yellow StyleBoxFlat outlines on runtime HUD controls with subtle slate/brass hairlines."""
	var patched: int = 0
	if node is Control:
		var ctrl: Control = node as Control
		for prop in ["panel", "normal"]:
			var sb: StyleBox = ctrl.get_theme_stylebox(prop)
			if sb is StyleBoxFlat:
				var flat: StyleBoxFlat = sb as StyleBoxFlat
				if flat.border_color.r > 0.65 and flat.border_color.g > 0.45 and flat.border_color.b < 0.45 and flat.border_color.a > 0.45:
					var dup: StyleBoxFlat = flat.duplicate() as StyleBoxFlat
					dup.border_color = COL_HAIRLINE_SLATE
					dup.bg_color = COL_INK_VEIL
					ctrl.add_theme_stylebox_override(prop, dup)
					patched += 1
	for child in node.get_children():
		patched += strip_yellow_boxes_recursive(child)
	return patched
