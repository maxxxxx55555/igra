extends Node
## THEME UNIFICATION proof: instantiates the real main_menu.tscn and hud_3d.tscn (no test doubles) and reads live,
## inherited styles and bundled glyph coverage on the real controls.

const KIT := preload("res://scripts/ui/inv_kit.gd")

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var bad: int = 0
	var menu: Control = load("res://scenes/ui/main_menu.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	var btn: Button = menu.get_node("VBox/Play")
	var sb := btn.get_theme_stylebox("normal", "Button")
	print("[theme-unify] main_menu Play button stylebox = ", sb.get_class())
	if _quiet_control(sb):
		print("[theme-unify] main menu uses quiet action hierarchy")
	else:
		bad += 1
	menu.queue_free()

	var hud: Node = load("res://scenes/ui/hud_3d.tscn").instantiate()
	add_child(hud)
	await get_tree().process_frame
	var pause_btn: Button = hud.get_node("BtnPause")
	var sb2 := pause_btn.get_theme_stylebox("normal", "Button")
	print("[theme-unify] hud_3d BtnPause stylebox = ", sb2.get_class())
	if _quiet_control(sb2):
		print("[theme-unify] HUD uses quiet shared controls")
	else:
		bad += 1
	var slot0: Panel = hud.find_child("Slot0", true, false) as Panel
	if slot0 != null:
		var panel_sb := slot0.get_theme_stylebox("panel", "Panel")
		var is_canon: bool = panel_sb is StyleBoxFlat and \
			(panel_sb as StyleBoxFlat).bg_color.is_equal_approx(ThemeProvider.COLOR_BG_PANEL)
		print("[theme-unify] hud_3d Slot0 (nested, inherited) panel bg matches ThemeProvider.COLOR_BG_PANEL: ", is_canon)
		if not is_canon:
			bad += 1
	else:
		print("[theme-unify] hud_3d has no Slot0: the quick bar is missing")
		bad += 1

	bad += _font_and_states()
	bad += await _journal_reader()
	bad += await _legacy_shop()
	print("[theme-unify] DONE bad=", bad)
	get_tree().quit(bad)

func _quiet_control(sb: StyleBox) -> bool:
	var flat := sb as StyleBoxFlat
	return flat != null and flat.border_width_left == 0 and flat.border_width_top == 0 and flat.border_width_right == 0 and flat.corner_radius_bottom_right == 0

func _font_and_states() -> int:
	var bad: int = 0
	var theme: Theme = ThemeProvider.build_theme()
	for control: StringName in [&"Button", &"OptionButton"]:
		for state: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
			if not _quiet_control(theme.get_stylebox(state, control)):
				print("[theme-unify] FAIL ordinary control has an ornamental frame %s/%s" % [control, state])
				bad += 1
		var focus := theme.get_stylebox(&"focus", control) as StyleBoxFlat
		if focus == null or focus.draw_center or focus.border_width_top < 2:
			print("[theme-unify] FAIL focus must outline without covering the label")
			bad += 1
	for type: StringName in [&"Label", &"Button", &"LineEdit"]:
		var font: Font = theme.get_font(&"font", type)
		var valid: bool = _bundled_chain(font, {})
		for letter: String in "Continue Продолжить Ёё Äß":
			valid = valid and font.has_char(letter.unicode_at(0))
		print("[theme-unify] bundled EN/RU/DE %s = %s" % [type, valid])
		if not valid:
			bad += 1
	var action_font := theme.get_font(&"font", &"Button") as FontVariation
	if action_font == null or float(action_font.variation_opentype.get("wght", 0.0)) < 500.0:
		print("[theme-unify] FAIL controls require the bundled medium natural-case face")
		bad += 1
	for kind: StringName in [&"action", &"danger", &"row", &"tab", &"slot"]:
		var button := Button.new()
		button.theme = theme
		add_child(button)
		KIT.style_button(button, kind)
		var normal := button.get_theme_stylebox(&"normal") as StyleBoxFlat
		if kind in [&"action", &"danger", &"row"] and (not _quiet_control(normal) or button.custom_minimum_size.y < 48.0):
			print("[theme-unify] FAIL inventory kind %s" % kind)
			bad += 1
		if kind == &"action":
			button.text = "Continue / Settings / Inventory"
			KIT.fit(button, 220.0, 26, 10)
			var font: Font = button.get_theme_font(&"font")
			var text_width: float = font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size(&"font_size")).x
			if text_width + normal.get_content_margin(SIDE_LEFT) + normal.get_content_margin(SIDE_RIGHT) > 220.0:
				print("[theme-unify] FAIL action text overlaps its padding")
				bad += 1
		button.queue_free()
	return bad

func _bundled_chain(font: Font, seen: Dictionary) -> bool:
	if font == null or font is SystemFont:
		return false
	if seen.has(font.get_instance_id()):
		return true
	seen[font.get_instance_id()] = true
	if font is FontFile and (font as FontFile).allow_system_fallback:
		return false
	if font is FontVariation and not _bundled_chain((font as FontVariation).base_font, seen):
		return false
	for fallback: Font in font.fallbacks:
		if not _bundled_chain(fallback, seen):
			return false
	return true

func _journal_reader() -> int:
	var bad: int = 0
	var previous_language: String = LocalizationManager.current_lang
	for embedded: bool in [false, true]:
		LocalizationManager.set_language("en")
		var journal: Control = load("res://scripts/ui/journal_ui.gd").new()
		journal.set("embedded", embedded)
		journal.size = get_viewport().get_visible_rect().size
		add_child(journal)
		journal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		await get_tree().process_frame
		await get_tree().process_frame
		var text: RichTextLabel = journal.get("_reader_text")
		var surface: Node = text.get_parent()
		while surface != null and not surface is PanelContainer:
			surface = surface.get_parent()
		var box: StyleBox = (surface as PanelContainer).get_theme_stylebox("panel")
		var contrast: float = 0.0
		if box is StyleBoxFlat and (box as StyleBoxFlat).draw_center and (box as StyleBoxFlat).bg_color.a == 1.0:
			var fg: Color = text.get_theme_color("default_color").srgb_to_linear()
			var bg: Color = (box as StyleBoxFlat).bg_color.srgb_to_linear()
			contrast = (maxf(fg.get_luminance(), bg.get_luminance()) + 0.05) / (minf(fg.get_luminance(), bg.get_luminance()) + 0.05)
		if contrast < 4.5 or not text.scroll_active or text.size.y < 100.0:
			print("[theme-unify] FAIL journal readable scrolling surface embedded=%s contrast=%s size=%s" % [embedded, contrast, text.size])
			bad += 1
		var art_ok: bool = false
		for node: Node in journal.find_children("*", "TextureRect", true, false):
			var art := node as TextureRect
			if art.texture != null and art.texture.resource_path.ends_with("journal_paper.png"):
				art_ok = art.stretch_mode in [TextureRect.STRETCH_KEEP_ASPECT_CENTERED, TextureRect.STRETCH_KEEP_ASPECT_COVERED] and art.size.y >= 100.0
		if not art_ok:
			print("[theme-unify] FAIL journal aspect-preserving manuscript/photo illustration embedded=", embedded)
			bad += 1
		for button: Node in journal.find_children("*", "Button", true, false):
			if (button as Button).text == "???":
				print("[theme-unify] FAIL journal exposes a wall of locked placeholders")
				bad += 1
				break
		LocalizationManager.set_language("ru")
		await get_tree().process_frame
		var translated_title: bool = false
		for label: Node in journal.find_children("*", "Label", true, false):
			translated_title = translated_title or (label as Label).text == LocalizationManager.t("JOURNAL_TITLE")
		if not translated_title:
			print("[theme-unify] FAIL journal title did not follow the live language switch")
			bad += 1
		journal.queue_free()
		await get_tree().process_frame
	LocalizationManager.set_language(previous_language)
	return bad

func _legacy_shop() -> int:
	var screens: Node = load("res://scripts/ui/screens.gd").new()
	add_child(screens)
	screens.call("show_screen", "Shop")
	await get_tree().process_frame
	var card: Control = screens.get("_screen_data")["Shop"]["card"]
	var buttons: Array[Node] = card.find_children("*", "Button", true, false)
	var valid: bool = buttons.size() >= 5
	for node: Node in buttons:
		var button := node as Button
		var font := button.get_theme_font("font") as FontVariation
		valid = valid and font != null and float(font.variation_opentype.get("wght", 0.0)) >= 500.0
		valid = valid and _quiet_control(button.get_theme_stylebox("normal"))
	print("[theme-unify] actual CanvasLayer Shop inherits quiet bundled controls = ", valid)
	screens.queue_free()
	return 0 if valid else 1
