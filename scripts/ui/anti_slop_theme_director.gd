# Save to: scripts/ui/anti_slop_theme_director.gd
class_name AntiSlopThemeDirector
extends RefCounted

const TEX_ROOT := "res://assets/textures/ui_craft/"

const COL_SHADOW_DEEP := Color("#060f13")
const COL_SHADOW_MID := Color("#0f1314")
const COL_IRON_DARK := Color("#161e22")
const COL_IRON_EDGE := Color("#2a363c")
const COL_SODIUM_DIM := Color("#9e7832")
const COL_SODIUM_KEY := Color("#d4a94e")
const COL_SODIUM_HOT := Color("#f0c46c")
const COL_PARCHMENT := Color("#e6dfd1")
const COL_MUTED := Color("#8fa1a8")


static func _make_box(tex_file: String, fallback_bg: Color, fallback_border: Color, left_accent: Color, pad_x: int, pad_y: int) -> StyleBox:
	var full_path := TEX_ROOT + tex_file
	if ResourceLoader.exists(full_path):
		var tex := load(full_path) as Texture2D
		if tex != null:
			var sbt := StyleBoxTexture.new()
			sbt.texture = tex
			sbt.texture_margin_left = 10.0
			sbt.texture_margin_right = 10.0
			sbt.texture_margin_top = 10.0
			sbt.texture_margin_bottom = 10.0
			sbt.content_margin_left = float(pad_x)
			sbt.content_margin_right = float(pad_x)
			sbt.content_margin_top = float(pad_y)
			sbt.content_margin_bottom = float(pad_y)
			return sbt

	var sbf := StyleBoxFlat.new()
	sbf.bg_color = fallback_bg
	sbf.border_color = fallback_border
	sbf.border_width_left = 3 if left_accent.a > 0.0 else 1
	sbf.border_width_top = 1
	sbf.border_width_right = 1
	sbf.border_width_bottom = 1
	if left_accent.a > 0.0:
		sbf.border_color = left_accent
	sbf.corner_radius_top_left = 2
	sbf.corner_radius_top_right = 2
	sbf.corner_radius_bottom_left = 2
	sbf.corner_radius_bottom_right = 2
	sbf.content_margin_left = float(pad_x)
	sbf.content_margin_right = float(pad_x)
	sbf.content_margin_top = float(pad_y)
	sbf.content_margin_bottom = float(pad_y)
	return sbf


static func build_theme(base_font: Font = null) -> Theme:
	var theme := Theme.new()
	if base_font != null:
		theme.default_font = base_font
	theme.default_font_size = 16

	# Visual overhaul v2: the chamfered dark-iron panel (10 px 9-slice, 8 px
	# corner cut) replaces the plain panel chrome while the canonical fonts and
	# type scale are kept by CraftThemeBridge/ThemeProvider above it.
	# Wave 3: the menu-canon panel is the photographic iron plate of the owner's
	# main menu (chamfered corners, a bronze rim, a patina surface). The v2
	# chamfer plate stays as the fallback, so no shipped texture is orphaned.
	var panel_box: StyleBox = _make_box("menu_ui_panel_9slice.webp", Color(COL_SHADOW_MID, 0.92), COL_IRON_EDGE, Color(0, 0, 0, 0), 16, 16)
	if panel_box is StyleBoxFlat:
		# The canon plate is missing: the v2 chamfer plate is the fallback.
		panel_box = _make_box("ui_panel_chamfer_9slice_v2.webp", Color(COL_SHADOW_MID, 0.92), COL_IRON_EDGE, Color(0, 0, 0, 0), 16, 16)
	theme.set_stylebox("panel", "PanelContainer", panel_box)
	theme.set_stylebox("panel", "Panel", panel_box)
	theme.set_stylebox("normal", "Button", _make_box("btn_normal_9slice.webp", Color(COL_IRON_DARK, 0.88), COL_IRON_EDGE, COL_SODIUM_DIM, 20, 12))
	theme.set_stylebox("hover", "Button", _make_box("btn_hover_9slice.webp", Color("#1e292e"), COL_SODIUM_KEY, COL_SODIUM_HOT, 20, 12))
	theme.set_stylebox("focus", "Button", _make_box("btn_hover_9slice.webp", Color("#1e292e"), COL_SODIUM_HOT, COL_SODIUM_HOT, 20, 12))
	theme.set_stylebox("pressed", "Button", _make_box("btn_pressed_9slice.webp", COL_SHADOW_DEEP, COL_SODIUM_DIM, COL_SODIUM_KEY, 20, 12))
	theme.set_stylebox("disabled", "Button", _make_box("btn_disabled_9slice.webp", Color(COL_SHADOW_MID, 0.62), COL_IRON_EDGE, Color(0, 0, 0, 0), 20, 12))

	theme.set_color("font_color", "Button", COL_PARCHMENT)
	theme.set_color("font_hover_color", "Button", COL_SODIUM_HOT)
	theme.set_color("font_focus_color", "Button", COL_SODIUM_HOT)
	theme.set_color("font_pressed_color", "Button", COL_SODIUM_KEY)
	theme.set_color("font_disabled_color", "Button", COL_MUTED)
	theme.set_font_size("font_size", "Button", 18)

	theme.set_color("font_color", "Label", COL_PARCHMENT)
	theme.set_color("font_shadow_color", "Label", Color(COL_SHADOW_DEEP, 0.85))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 2)
	return theme


static func apply_main_menu_composition(menu_panel: Control, buttons_box: BoxContainer) -> void:
	if not is_instance_valid(menu_panel):
		return
	# Left-third architectural dock: leaves center/right parallax streetlight art completely clear
	menu_panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	menu_panel.anchor_left = 0.045
	menu_panel.anchor_right = 0.34
	menu_panel.anchor_top = 0.14
	menu_panel.anchor_bottom = 0.86
	menu_panel.offset_left = 0.0
	menu_panel.offset_right = 0.0
	menu_panel.offset_top = 0.0
	menu_panel.offset_bottom = 0.0

	if is_instance_valid(buttons_box):
		buttons_box.add_theme_constant_override("separation", 10)
		for child in buttons_box.get_children():
			if child is Button:
				var btn := child as Button
				btn.custom_minimum_size = Vector2(248.0, 52.0)
				btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
				btn.clip_text = false
				btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				apply_button_micro_feel(btn)


static func apply_button_micro_feel(btn: BaseButton) -> void:
	if not is_instance_valid(btn) or btn.has_meta("_craft_feel_wired"):
		return
	btn.set_meta("_craft_feel_wired", true)
	btn.mouse_entered.connect(func() -> void:
		if not is_instance_valid(btn) or btn.disabled:
			return
		var tw := btn.create_tween()
		tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "modulate", Color(1.06, 1.03, 0.98, 1.0), 0.085)
	)
	btn.mouse_exited.connect(func() -> void:
		if not is_instance_valid(btn):
			return
		var tw := btn.create_tween()
		tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "modulate", Color.WHITE, 0.11)
	)
