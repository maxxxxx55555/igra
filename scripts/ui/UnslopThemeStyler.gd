class_name UnslopThemeStyler
extends Node
## Apply style_tree_recursive(scene) after constructing a menu. For a standalone
## action Label, set its "ui_action" metadata to a Callable before styling.
## Set "translation_key" to opt into a catalog key separate from authored text.

const COAL := Color("#0b0d10")
const SLATE := Color("#14181e")
const INK := Color("#e8ecef")
const AMBER := Color("#d99b38")
const WARMTH := Color("#d96b38")
const EDGE := Color("#464443")
const MUTED := Color("#8e969e")
const PANEL := Color(0.066667, 0.082353, 0.105882, 0.86)
const PANEL_EDGE := Color(0.85098, 0.60784, 0.21961, 0.45)

class TextFit:
	extends RefCounted
	var maximum: int
	var locale: String
	var caption: String
	var font: Font
	var width: float = -1.0


static var _shared_theme: Theme


static func _box(fill: Color, edge: Color, radius: int, x: float, y: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.corner_detail = 3
	box.content_margin_left = x
	box.content_margin_right = x
	box.content_margin_top = y
	box.content_margin_bottom = y
	return box


static func build_release_theme() -> Theme:
	var skin := Theme.new()
	skin.default_font_size = 16
	var panel := _box(PANEL, PANEL_EDGE, 6, 12.0, 10.0)
	panel.shadow_size = 3
	panel.shadow_offset = Vector2(0.0, 2.0)
	panel.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	var normal := _box(SLATE, EDGE, 4, 10.0, 5.0)
	var hover := _box(Color("#232322"), AMBER, 4, 10.0, 5.0)
	hover.shadow_color = Color(AMBER, 0.22)
	hover.shadow_size = 2
	var down := _box(Color("#30261a"), PANEL_EDGE, 4, 10.0, 5.0)
	var locked := _box(Color("#111419"), Color("#30353a"), 4, 10.0, 5.0)
	var focus := _box(Color.TRANSPARENT, INK, 4, 0.0, 0.0)
	focus.draw_center = false
	skin.set_stylebox(&"panel", &"PanelContainer", panel)
	skin.set_stylebox(&"panel", &"Panel", panel)
	skin.set_stylebox(&"normal", &"Button", normal)
	skin.set_stylebox(&"hover", &"Button", hover)
	skin.set_stylebox(&"pressed", &"Button", down)
	skin.set_stylebox(&"hover_pressed", &"Button", down)
	skin.set_stylebox(&"disabled", &"Button", locked)
	skin.set_stylebox(&"focus", &"Button", focus)
	skin.set_color(&"font_color", &"Label", INK)
	skin.set_color(&"font_color", &"Button", INK)
	skin.set_color(&"font_hover_color", &"Button", AMBER)
	skin.set_color(&"font_pressed_color", &"Button", INK)
	skin.set_color(&"font_disabled_color", &"Button", MUTED)
	skin.set_constant(&"h_separation", &"Button", 6)
	skin.set_type_variation(&"ShopActionLabel", &"Label")
	skin.set_stylebox(&"normal", &"ShopActionLabel", normal)
	skin.set_type_variation(&"WarmthBar", &"ProgressBar")
	skin.set_stylebox(&"background", &"ProgressBar", _box(COAL, EDGE, 3, 1, 1))
	skin.set_stylebox(&"fill", &"ProgressBar", _box(AMBER, AMBER, 3, 0, 0))
	skin.set_stylebox(&"fill", &"WarmthBar", _box(WARMTH, WARMTH, 3, 0, 0))
	skin.set_color(&"font_color", &"ProgressBar", INK)
	skin.set_color(&"font_outline_color", &"ProgressBar", COAL)
	skin.set_constant(&"outline_size", &"ProgressBar", 3)
	for tab_type: StringName in [&"TabBar", &"TabContainer"]:
		skin.set_stylebox(&"tab_unselected", tab_type, normal)
		skin.set_stylebox(&"tab_selected", tab_type, down)
		skin.set_stylebox(&"tab_hovered", tab_type, hover)
		skin.set_stylebox(&"tab_disabled", tab_type, locked)
		skin.set_stylebox(&"tab_focus", tab_type, focus)
		skin.set_color(&"font_selected_color", tab_type, AMBER)
		skin.set_color(&"font_unselected_color", tab_type, INK)
		skin.set_color(&"font_disabled_color", tab_type, MUTED)
	skin.set_stylebox(&"panel", &"TabContainer", panel)
	return skin


static func style_tree_recursive(root: Node) -> void:
	if not is_instance_valid(root):
		return
	if _shared_theme == null:
		_shared_theme = build_release_theme()
	_style_branch(root, false)


static func _style_branch(node: Node, inherited: bool) -> void:
	var control := node as Control
	if control != null:
		if not inherited or control.theme != null:
			control.theme = _shared_theme
		if control is Button or control is Label:
			_style_text(control)
		elif control is ProgressBar:
			if control.is_in_group(&"warmth") or "warmth" in String(control.name).to_lower():
				control.theme_type_variation = &"WarmthBar"
	for child: Node in node.get_children():
		_style_branch(child, control != null)


static func _style_text(control: Control) -> void:
	var button := control as Button
	var label := control as Label
	var key := String(control.get_meta(&"translation_key", ""))
	if button != null:
		if not key.is_empty():
			button.text = key
		if control.has_meta(&"locked"):
			button.disabled = bool(control.get_meta(&"locked"))
		button.clip_text = true
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		if button.get_class() == "Button":
			button.flat = false
		button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 36.0)
	else:
		if not key.is_empty():
			label.text = key
		# Wrapped descriptions retain their full vertical minimum size.
		if label.autowrap_mode != TextServer.AUTOWRAP_OFF:
			return
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		var binding: Variant = label.get_meta(&"ui_action") if label.has_meta(&"ui_action") else null
		if binding is Callable and (binding as Callable).is_valid():
			_bind_label_action(label, binding as Callable)
		elif label.text.strip_edges().to_upper() in ["BUY", "КУПИТЬ", "UNLOCK", "РАЗБЛОКИРОВАТЬ"]:
			if not label.get_parent() is BaseButton:
				label.theme_type_variation = &"ShopActionLabel"
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				label.custom_minimum_size.y = maxf(label.custom_minimum_size.y, 36.0)
	# Source keys stay on controls so a locale switch can retranslate them.
	if not control.has_meta(&"_sodium_fit"):
		var base_size := control.get_theme_font_size(&"font_size")
		if label != null and label.label_settings != null:
			base_size = label.label_settings.font_size
			label.label_settings = label.label_settings.duplicate() as LabelSettings
		var cache := TextFit.new()
		cache.maximum = base_size
		control.set_meta(&"_sodium_fit", cache)
	var fit: Callable = _fit_text.bind(control)
	if not control.draw.is_connected(fit):
		control.draw.connect(fit, CONNECT_DEFERRED)
		fit.call_deferred()


static func _bind_label_action(label: Label, action: Callable) -> void:
	var button := label.get_node_or_null(^"_SodiumAction") as Button
	if button == null:
		button = Button.new()
		button.name = &"_SodiumAction"
		button.clip_text = true
		label.add_child(button)
		label.self_modulate.a = 0.0
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if button.has_meta(&"_sodium_binding"):
		var previous: Callable = button.get_meta(&"_sodium_binding")
		if previous.is_valid() and button.pressed.is_connected(previous):
			button.pressed.disconnect(previous)
	button.pressed.connect(action)
	button.set_meta(&"_sodium_binding", action)
	button.text = label.text
	button.disabled = bool(label.get_meta(&"locked", false))
	label.custom_minimum_size = label.custom_minimum_size.max(Vector2(48.0, 36.0))
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


static func _fit_text(control: Control) -> void:
	if not is_instance_valid(control) or not control.is_inside_tree() or control.size.x < 1.0:
		return
	var button := control as Button
	var label := control as Label
	var font := control.get_theme_font(&"font")
	var bounds: StyleBox = control.get_theme_stylebox(&"normal")
	var available := control.size.x - bounds.get_minimum_size().x
	var source: String
	if button != null:
		source = button.text
		if button.icon != null:
			available -= button.icon.get_width() + button.get_theme_constant(&"h_separation")
	else:
		source = label.text
		var action_button := label.get_node_or_null(^"_SodiumAction") as Button
		if action_button != null:
			if action_button.text != source:
				action_button.text = source
			return
		if label.label_settings != null and label.label_settings.font != null:
			font = label.label_settings.font
	if control.can_auto_translate():
		source = control.tr(source)
	var cache := control.get_meta(&"_sodium_fit") as TextFit
	var locale := TranslationServer.get_locale()
	if cache.caption == source and cache.locale == locale and cache.font == font and cache.width == available:
		return
	cache.caption = source
	cache.locale = locale
	cache.font = font
	cache.width = available
	var size_px := cache.maximum
	var min_px := mini(size_px, 12)
	while size_px > min_px and font.get_string_size(source, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x > available:
		size_px -= 1
	if label != null and label.label_settings != null:
		if label.label_settings.font_size != size_px:
			label.label_settings.font_size = size_px
	elif control.get_theme_font_size(&"font_size") != size_px:
		control.add_theme_font_size_override(&"font_size", size_px)
