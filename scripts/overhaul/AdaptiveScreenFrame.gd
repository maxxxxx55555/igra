class_name AdaptiveScreenFrame
extends Control

## Enforces 20:9 full-screen framing, cutout safe-area, and bespoke chamfered-brass theme (zero AI slop).

const COLOR_NIGHT_DEEP: Color = Color(0.055, 0.082, 0.106, 1.0)
const COLOR_BG: Color = Color(0.071, 0.094, 0.118, 0.86)
const COLOR_BG_ELEVATED: Color = Color(0.102, 0.137, 0.173, 0.94)
const COLOR_BRASS: Color = Color(0.784, 0.608, 0.329, 1.0)
const COLOR_BRASS_ACTIVE: Color = Color(0.890, 0.722, 0.431, 1.0)
const COLOR_TEXT: Color = Color(0.929, 0.902, 0.839, 1.0)
const COLOR_TEXT_MUTED: Color = Color(0.604, 0.651, 0.698, 1.0)
const COLOR_DANGER: Color = Color(0.784, 0.294, 0.192, 1.0)

@export var safe_margin_container_path: NodePath = NodePath("")
@export var background_texture_rect_path: NodePath = NodePath("")
@export var extra_padding_px: int = 16
@export var apply_bespoke_theme_on_ready: bool = true


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if apply_bespoke_theme_on_ready:
		theme = build_chamfered_brass_theme()
	_apply_adaptation()
	if get_viewport() != null and not get_viewport().size_changed.is_connected(_apply_adaptation):
		get_viewport().size_changed.connect(_apply_adaptation)


func _exit_tree() -> void:
	if get_viewport() != null and get_viewport().size_changed.is_connected(_apply_adaptation):
		get_viewport().size_changed.disconnect(_apply_adaptation)


func _apply_adaptation() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	if not background_texture_rect_path.is_empty():
		var bg_node: Node = get_node_or_null(background_texture_rect_path)
		if bg_node is TextureRect:
			var tr_bg: TextureRect = bg_node as TextureRect
			tr_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			tr_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	var insets: Vector4i = compute_safe_insets_logical()
	if not safe_margin_container_path.is_empty():
		var mc_node: Node = get_node_or_null(safe_margin_container_path)
		if mc_node is MarginContainer:
			var mc: MarginContainer = mc_node as MarginContainer
			mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			mc.add_theme_constant_override("margin_left", insets.x + extra_padding_px)
			mc.add_theme_constant_override("margin_top", insets.y + extra_padding_px)
			mc.add_theme_constant_override("margin_right", insets.z + extra_padding_px)
			mc.add_theme_constant_override("margin_bottom", insets.w + extra_padding_px)


func compute_safe_insets_logical() -> Vector4i:
	var vp: Viewport = get_viewport()
	if vp == null:
		return Vector4i.ZERO
	var vp_size: Vector2 = vp.get_visible_rect().size
	var win_size: Vector2i = DisplayServer.window_get_size()
	var safe_px: Rect2i = DisplayServer.get_display_safe_area()
	if win_size.x <= 0 or win_size.y <= 0 or safe_px.size.x <= 0 or safe_px.size.y <= 0:
		return Vector4i.ZERO
	var sx: float = vp_size.x / float(win_size.x)
	var sy: float = vp_size.y / float(win_size.y)
	return Vector4i(
		maxi(0, int(roundf(float(safe_px.position.x) * sx))),
		maxi(0, int(roundf(float(safe_px.position.y) * sy))),
		maxi(0, int(roundf(float(win_size.x - safe_px.end.x) * sx))),
		maxi(0, int(roundf(float(win_size.y - safe_px.end.y) * sy)))
	)


static func build_chamfered_brass_theme() -> Theme:
	var th: Theme = Theme.new()
	var btn_normal: StyleBoxFlat = _chamfer_box(COLOR_BG, COLOR_BRASS, 2, 16, 12)
	var btn_hover: StyleBoxFlat = _chamfer_box(COLOR_BG_ELEVATED, COLOR_BRASS_ACTIVE, 2, 16, 12)
	var btn_pressed: StyleBoxFlat = _chamfer_box(COLOR_BRASS_ACTIVE, COLOR_TEXT, 2, 16, 12)
	var btn_disabled: StyleBoxFlat = _chamfer_box(Color(0.071, 0.094, 0.118, 0.45), COLOR_TEXT_MUTED, 1, 16, 12)
	var panel_box: StyleBoxFlat = _chamfer_box(COLOR_BG_ELEVATED, COLOR_BRASS, 2, 16, 14)

	th.set_stylebox("normal", "Button", btn_normal)
	th.set_stylebox("hover", "Button", btn_hover)
	th.set_stylebox("focus", "Button", btn_hover)
	th.set_stylebox("pressed", "Button", btn_pressed)
	th.set_stylebox("disabled", "Button", btn_disabled)
	th.set_color("font_color", "Button", COLOR_TEXT)
	th.set_color("font_hover_color", "Button", COLOR_TEXT)
	th.set_color("font_focus_color", "Button", COLOR_TEXT)
	th.set_color("font_pressed_color", "Button", COLOR_NIGHT_DEEP)
	th.set_color("font_disabled_color", "Button", COLOR_TEXT_MUTED)
	th.set_font_size("font_size", "Button", 22)

	th.set_stylebox("panel", "PanelContainer", panel_box)
	th.set_stylebox("panel", "Panel", panel_box)
	th.set_color("font_color", "Label", COLOR_TEXT)
	th.set_font_size("font_size", "Label", 20)
	return th


static func _chamfer_box(fill: Color, border: Color, border_w: int, pad_h: int, pad_v: int) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(6)
	sb.corner_detail = 1
	sb.content_margin_left = pad_h
	sb.content_margin_right = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_bottom = pad_v
	return sb
