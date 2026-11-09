# Shared quiet controls and bundled natural-case typography.
class_name ThemeProvider
extends RefCounted

# One palette (owner canon 2026-10-29): inventory, shop, menus and HUD read these tokens; InvKit takes them too.
const COLOR_BG_DARK   := Color("#060f13")   # bg-deep (owner canon 2026-10-29, docs/STYLE_GUIDE.md section 8)
const COLOR_BG_PANEL  := Color("#0f1314")   # panel
const COLOR_BG_PANEL2 := Color("#1c1e1d")   # panel-hover (чуть светлее)
const COLOR_BORDER    := Color("#5a4a2a")   # panel-edge: the 1 px bronze of the canon
const COLOR_AMBER     := Color("#c9a24a")   # brass — акцент, активное
const COLOR_AMBER_DIM := Color("#9e8645")   # brass-dim — неактивное; doubles as the essential focus-edge token
const COLOR_AMBER_HI  := Color("#d8d5cc")   # bone — заголовки
const COLOR_TEXT      := Color("#d8d5cc")   # bone-text
const COLOR_TEXT_DIM  := Color("#8a8a85")   # steel-text
const COLOR_DANGER    := Color("#c0392b")   # ember (fills only)
const COLOR_DANGER_TEXT := Color("#e8695a") # ember lifted for small danger/requirement text on dark fills: #c0392b fails 3:1 there

const FONT_SIZE_BODY: int = 16
const SCROLLBAR_MARGIN: float = 5.0
const FONT_SIZE_TITLE: int = 22
const FONT_SIZE_BUTTON: int = 20
const FULL_BODY_FONT: String = "res://assets/fonts/RobotoCondensed-Full-VF.ttf"

## The owner reserves Bebas for the menu wordmark; controls use bundled medium Roboto.
const HEADING_EMBOLDEN: float = 0.35

static func _bold(base: Font) -> Font:
	var f := FontVariation.new()
	f.base_font = base
	f.variation_embolden = HEADING_EMBOLDEN
	f.spacing_glyph = 1  # Bebas is set tight; a pixel of tracking lets the capitals breathe
	return f

static var _heading: Font
static var _fonts: Dictionary = {}

## Reuse bundled font caches; private copies disable operating-system substitution.
static func _font_set() -> Dictionary:
	if _fonts.is_empty():
		var body := load(FULL_BODY_FONT) as FontFile
		body = body.duplicate() as FontFile
		body.allow_system_fallback = false
		# Bitmap oversampling preserves scaled text without MSDF contour artifacts.
		body.oversampling = 2.0
		body.fallbacks = []
		var display := load("res://assets/fonts/BebasNeue-Regular.ttf") as FontFile
		display = display.duplicate() as FontFile
		display.allow_system_fallback = false
		display.oversampling = 2.0
		display.fallbacks = []
		var heading: Font = _bold(display)
		heading.fallbacks = [body]
		var mono := load("res://assets/fonts/ShareTechMono-Regular.ttf") as FontFile
		mono = mono.duplicate() as FontFile
		mono.allow_system_fallback = false
		mono.oversampling = 2.0
		mono.fallbacks = [body]
		var medium := FontVariation.new()
		medium.base_font = body
		medium.variation_opentype = {"wght": 500.0}
		var strong := FontVariation.new()
		strong.base_font = body
		strong.variation_opentype = {"wght": 600.0}
		_fonts = {"body": body, "heading": strong, "button": medium, "wordmark": heading, "mono": mono}
	return _fonts

## Quiet control hierarchy: emphasis belongs to the action, not its frame.
static func button_style(state: StringName = &"normal", kind: StringName = &"ghost", active: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color.TRANSPARENT
	box.set_content_margin_all(12.0)
	box.content_margin_left = 18.0
	box.content_margin_right = 18.0
	if kind == &"primary":
		box.bg_color = COLOR_AMBER
	elif kind == &"secondary":
		box.bg_color = COLOR_BG_PANEL2
	elif kind == &"row":
		box.border_width_bottom = 1
		box.border_color = Color(COLOR_TEXT_DIM, 0.2)
	if active:
		box.border_width_left = 2
		box.border_color = COLOR_AMBER
	if state == &"hover":
		box.bg_color = COLOR_BG_PANEL2 if kind != &"primary" else COLOR_AMBER_HI
	elif state in [&"pressed", &"hover_pressed"]:
		box.bg_color = COLOR_BG_PANEL
	elif state == &"focus":
		box.draw_center = false
		box.set_border_width_all(2)
		box.border_color = COLOR_AMBER
		box.expand_margin_left = 4.0
		box.expand_margin_right = 4.0
		box.expand_margin_top = 4.0
		box.expand_margin_bottom = 4.0
	elif state == &"disabled":
		box.bg_color = Color.TRANSPARENT
	return box

static func style_control(button: Button, kind: StringName = &"ghost", active: bool = false) -> void:
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled", &"focus"]:
		button.add_theme_stylebox_override(state, button_style(state, kind, active))
	button.add_theme_color_override("font_color", COLOR_BG_DARK if kind == &"primary" else (COLOR_AMBER if active else COLOR_TEXT))
	button.add_theme_color_override("font_hover_color", COLOR_BG_DARK if kind == &"primary" else COLOR_TEXT)
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 48.0)
	button.focus_mode = Control.FOCUS_ALL

static func wordmark_font() -> Font:
	return _font_set()["wordmark"]

## The face of the buttons, for a Label that heads a screen (v10 N016): a plain Label takes the body face of its theme.
static func heading_font() -> Font:
	if _heading == null:
		_heading = _font_set()["heading"]
	return _heading

static func build_theme() -> Theme:
	var theme := Theme.new()
	var fonts: Dictionary = _font_set()
	var font_body: Font = fonts["body"]
	var font_heading: Font = fonts["heading"]
	var font_panel: Font = fonts["button"]
	var font_mono: Font = fonts["mono"]
	theme.default_font = font_body
	theme.set_font(&"font", &"Label", font_body)
	theme.set_font(&"font", &"Button", font_panel)
	theme.set_font(&"font", &"PanelContainer", font_panel)
	theme.set_font(&"font", &"RichTextLabel", font_body)
	theme.set_font(&"font", &"LineEdit", font_mono)
	theme.set_font(&"font", &"TextEdit", font_mono)
	theme.set_font(&"font", &"OptionButton", font_panel)
	theme.set_font(&"font", &"TabBar", font_panel)

	# Reading surfaces use spacing and tone, without a frame around every region.
	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = COLOR_BG_PANEL
	panel_sb.border_color = COLOR_BORDER
	panel_sb.set_border_width_all(0)
	panel_sb.set_corner_radius_all(0)
	panel_sb.set_content_margin_all(12)
	theme.set_stylebox("panel", "Panel", panel_sb)
	theme.set_stylebox("panel", "PanelContainer", panel_sb)
	var panel2 := panel_sb.duplicate() as StyleBoxFlat
	panel2.bg_color = COLOR_BG_PANEL2
	theme.set_stylebox("panel", "Frame", panel2)
	theme.set_color("font_color", "Label", COLOR_TEXT)
	theme.set_font_size("font_size", "Label", FONT_SIZE_BODY)

	# Ordinary actions are quiet; explicit primary actions carry the emphasis.
	var btn_n := button_style(&"normal")
	var btn_h := button_style(&"hover")
	var btn_p := button_style(&"pressed")
	# Focus outlines cannot cover the underlying action label.
	var btn_focus := button_style(&"focus")
	var btn_d := button_style(&"disabled")
	theme.set_stylebox("normal", "Button", btn_n)
	theme.set_stylebox("hover", "Button", btn_h)
	theme.set_stylebox("pressed", "Button", btn_p)
	theme.set_stylebox("hover_pressed", "Button", btn_p)
	theme.set_stylebox("focus", "Button", btn_focus)
	theme.set_stylebox("disabled", "Button", btn_d)
	theme.set_stylebox("focus", "LineEdit", btn_focus)
	theme.set_color("font_color", "Button", COLOR_TEXT)
	theme.set_color("font_hover_color", "Button", COLOR_AMBER_HI)
	theme.set_color("font_disabled_color", "Button", COLOR_TEXT_DIM)
	theme.set_color("font_pressed_color", "Button", COLOR_TEXT)
	theme.set_font_size("font_size", "Button", FONT_SIZE_BUTTON)

	# Functional progress retains its status colour.
	var pb_bg := StyleBoxFlat.new()
	pb_bg.bg_color = COLOR_BG_DARK
	pb_bg.border_color = COLOR_BORDER
	pb_bg.set_border_width_all(1)
	pb_bg.set_corner_radius_all(0)
	var pb_fill := StyleBoxFlat.new()
	pb_fill.bg_color = COLOR_AMBER
	pb_fill.set_corner_radius_all(0)
	theme.set_stylebox("background", "ProgressBar", pb_bg)
	theme.set_stylebox("fill", "ProgressBar", pb_fill)

	# A flat stylebox has no size of its own and a bar is as wide as its two styleboxes, so the
	# bars were 0 px wide: a list longer than its window (the city map, 11 rows) showed no scroll bar at all.
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_AMBER_DIM
	sb.set_corner_radius_all(0)
	sb.set_content_margin_all(SCROLLBAR_MARGIN)
	theme.set_stylebox("grabber", "VScrollBar", sb)
	theme.set_stylebox("grabber", "HScrollBar", sb)
	var sb_bg := StyleBoxFlat.new()
	sb_bg.bg_color = COLOR_BG_DARK
	sb_bg.set_content_margin_all(SCROLLBAR_MARGIN)
	theme.set_stylebox("scroll", "VScrollBar", sb_bg)
	theme.set_stylebox("scroll", "HScrollBar", sb_bg)
	return _scale(theme, font_heading, font_mono)

## W9 of docs/VISUAL_PASS.md section 8: the type scale (Display 44, Huge 30, Title 22, Body 16, Small 13, Mono 15) as label variations that a screen picks by name (theme_type_variation), the titles on the heading face, and the
## option buttons given the brass focus ring and the dimmed disabled fill of the buttons.
const FONT_SIZE_DISPLAY: int = 44
const FONT_SIZE_HUGE: int = 30
const FONT_SIZE_SMALL: int = 13
const FONT_SIZE_MONO: int = 15

static func _scale(theme: Theme, heading: Font, mono: Font) -> Theme:
	var scale: Dictionary = {
		&"DisplayLabel": [FONT_SIZE_DISPLAY, heading], &"HugeLabel": [FONT_SIZE_HUGE, heading], &"TitleLabel": [FONT_SIZE_TITLE, heading],
		&"SmallLabel": [FONT_SIZE_SMALL, null], &"MonoLabel": [FONT_SIZE_MONO, mono]}
	for variation: StringName in scale:
		theme.set_type_variation(variation, &"Label")
		theme.set_font_size(&"font_size", variation, int(scale[variation][0]))
		if scale[variation][1] != null:
			theme.set_font(&"font", variation, scale[variation][1])
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		theme.set_stylebox(state, "OptionButton", theme.get_stylebox(state, "Button"))
	theme.set_font_size("font_size", "OptionButton", FONT_SIZE_BUTTON)
	# the tabs: the selected one stands on the panel fill over a brass rule, the others rest dark in steel (the engine's grey rounded tabs were the last default look)
	var tab := StyleBoxFlat.new()
	tab.bg_color = Color.TRANSPARENT
	tab.border_color = COLOR_BORDER
	tab.border_width_bottom = 0
	tab.set_content_margin_all(10)
	var tab_hover := tab.duplicate() as StyleBoxFlat
	tab_hover.border_color = COLOR_AMBER_DIM
	var tab_on := tab.duplicate() as StyleBoxFlat
	tab_on.bg_color = COLOR_BG_PANEL
	tab_on.border_color = COLOR_AMBER
	tab_on.border_width_bottom = 2
	for type: StringName in [&"TabBar", &"TabContainer"]:
		theme.set_stylebox(&"tab_unselected", type, tab)
		theme.set_stylebox(&"tab_disabled", type, tab)
		theme.set_stylebox(&"tab_hovered", type, tab_hover)
		theme.set_stylebox(&"tab_selected", type, tab_on)
		theme.set_stylebox(&"tab_focus", type, theme.get_stylebox(&"focus", &"Button"))
		theme.set_color(&"font_selected_color", type, COLOR_AMBER)
		theme.set_color(&"font_hovered_color", type, COLOR_TEXT)
		theme.set_color(&"font_unselected_color", type, COLOR_TEXT_DIM)
	theme.set_font(&"font", &"TabContainer", heading)
	theme.set_stylebox(&"panel", &"TabContainer", theme.get_stylebox(&"panel", &"PanelContainer"))
	return theme
