extends RefCounted
## Inventory roles share quiet typography while preserving pack-grid selection.

const BG := ThemeProvider.COLOR_BG_DARK
const PANEL := ThemeProvider.COLOR_BG_PANEL
const RAISED := ThemeProvider.COLOR_BG_PANEL2
const EDGE := Color(ThemeProvider.COLOR_TEXT_DIM, 0.18)
const EDGE_DIM := EDGE
const AMBER := ThemeProvider.COLOR_AMBER
const TEXT := ThemeProvider.COLOR_TEXT
const TEXT_DIM := ThemeProvider.COLOR_TEXT_DIM
const DANGER := ThemeProvider.COLOR_DANGER

static func box(fill: Color, edge: Color = EDGE, width: int = 1, radius: int = 0, pad: float = 0.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(pad)
	return style

static func _lit(color: Color, by: float) -> Color:
	return color.lerp(Color.WHITE, by)

## Pack cells retain grid selection; action, row and tab roles stay visually distinct.
static func style_button(button: Button, kind: StringName, active: bool = false) -> void:
	if kind != &"slot":
		var role: StringName = &"secondary" if kind == &"action" else (&"row" if kind == &"row" else &"ghost")
		ThemeProvider.style_control(button, role, active)
		if kind == &"danger":
			button.add_theme_color_override("font_color", ThemeProvider.COLOR_DANGER_TEXT)
		if kind == &"tab":
			for state: StringName in [&"normal", &"hover", &"pressed"]:
				var style := button.get_theme_stylebox(state) as StyleBoxFlat
				style.border_width_left = 0
				style.border_width_bottom = 2 if active else 0
		return
	var edge := AMBER if active else Color(TEXT_DIM, 0.22)
	for state: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
		var fill: Color = RAISED if state == &"normal" else PANEL
		button.add_theme_stylebox_override(state, box(fill, edge, 2 if active else 1, 0, 12.0))
	button.add_theme_stylebox_override("focus", ThemeProvider.button_style(&"focus"))
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_disabled_color", TEXT_DIM)

## The largest font size from `max_size` down to `min_size` at which the text of a button, in the face its theme gives it, fits `width` less its padding: a longer language than English (German, Russian) shrinks the text
## before it clips. Call it once the button is in the tree, after its text is set.
static func fit(button: Button, width: float, max_size: int, min_size: int) -> void:
	var font := button.get_theme_font("font")
	var size := max_size
	var style: StyleBox = button.get_theme_stylebox(&"normal")
	var padding: float = maxf(16.0, style.get_content_margin(SIDE_LEFT) + style.get_content_margin(SIDE_RIGHT))
	while size > min_size and font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width - padding:
		size -= 1
	button.add_theme_font_size_override("font_size", size)

## A label in the heading or body face (the theme's), with the palette's colour and a size in design pixels.
static func label(text: String, size: int, color: Color = TEXT, heading: bool = false) -> Label:
	var item := Label.new()
	item.text = text
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", color)
	if heading:
		item.add_theme_font_override("font", ThemeProvider.heading_font())
	return item
