extends Node
## D27: Edinyj stil UI - PanelCard tokeny

const COLORS: Dictionary = {
	"bg_dark": Color(0.04, 0.04, 0.07, 0.95),
	"bg_panel": Color(0.08, 0.08, 0.12, 0.9),
	"bg_card": Color(0.1, 0.1, 0.15, 0.85),
	"border": Color(0.3, 0.25, 0.2, 0.8),
	"border_hover": Color(0.6, 0.5, 0.3, 1.0),
	"text_primary": Color(0.9, 0.88, 0.82, 1.0),
	"text_secondary": Color(0.6, 0.58, 0.52, 1.0),
	"accent": Color(0.9, 0.7, 0.3, 1.0),
	"danger": Color(0.8, 0.2, 0.15, 1.0),
	"success": Color(0.2, 0.7, 0.3, 1.0),
	"health": Color(0.8, 0.15, 0.1, 1.0),
	"battery": Color(0.2, 0.8, 0.3, 1.0),
	"xp": Color(0.3, 0.5, 0.9, 1.0)
}

const SIZES: Dictionary = {
	"touch_target": 80,
	"button_height": 56,
	"icon_size": 64,
	"panel_padding": 16,
	"card_corner": 8,
	"font_title": 28,
	"font_body": 18,
	"font_small": 14
}

func apply_panel_style(panel: Panel) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = COLORS.bg_panel
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = COLORS.border
	sb.corner_radius_top_left = SIZES.card_corner
	sb.corner_radius_top_right = SIZES.card_corner
	sb.corner_radius_bottom_right = SIZES.card_corner
	sb.corner_radius_bottom_left = SIZES.card_corner
	panel.add_theme_stylebox_override("panel", sb)

func apply_button_style(btn: Button) -> void:
	btn.custom_minimum_size.y = SIZES.button_height
	btn.add_theme_font_size_override("font_size", SIZES.font_body)
	btn.add_theme_color_override("font_color", COLORS.text_primary)
	btn.add_theme_color_override("font_hover_color", COLORS.accent)

func animate_screen_in(node: Control) -> void:
	node.modulate.a = 0.0
	node.scale = Vector2(0.95, 0.95)
	var tw = node.create_tween()
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(node, "modulate:a", 1.0, 0.3)
	tw.parallel().tween_property(node, "scale", Vector2.ONE, 0.3)

func animate_screen_out(node: Control) -> void:
	var tw = node.create_tween()
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(node, "modulate:a", 0.0, 0.2)
	tw.parallel().tween_property(node, "scale", Vector2(1.05, 1.05), 0.2)