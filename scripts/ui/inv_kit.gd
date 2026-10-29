extends RefCounted
## The component kit of the visual recovery brief (Plate A and the palette of its section 04): flat rectangles with a 1 px aged-brass edge and no cut corners, and the states of a slot, a tab and
## an action in one place, so the inventory and the screens after it read as one family. The screens keep ThemeProvider for fonts and for the controls they do not restyle.

const BG := Color("#080E10")
const PANEL := Color("#121A1B")
const RAISED := Color("#1C2423")
const EDGE := Color("#655332")
const EDGE_DIM := Color("#2B332F")
const AMBER := Color("#C58A2D")
const TEXT := Color("#D7CCB6")
const TEXT_DIM := Color("#A89F8D")
const DANGER := Color("#A43C2B")

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

## The states of a button by kind: &"action" (a rectangle with a brass edge), &"danger" (the same with the ember edge), &"tab" (text, a thin amber underline when `active`) and &"slot" (a pack cell, an amber edge
## when `active`, which is the selected one). Hover lifts the edge, pressed sinks the fill, disabled drops the text and the edge to the dim of the palette.
static func style_button(button: Button, kind: StringName, active: bool = false) -> void:
	var normal: StyleBoxFlat
	var hover: StyleBoxFlat
	var pressed: StyleBoxFlat
	var disabled: StyleBoxFlat
	var color := TEXT
	match kind:
		&"tab":
			normal = box(Color(0.0, 0.0, 0.0, 0.0), AMBER if active else Color(0.0, 0.0, 0.0, 0.0), 0, 0, 6.0)
			normal.border_width_bottom = 2
			hover = box(Color(1.0, 1.0, 1.0, 0.05), Color(0.0, 0.0, 0.0, 0.0), 0, 0, 6.0)
			hover.border_width_bottom = 2
			hover.border_color = AMBER if active else EDGE
			pressed = box(Color(0.0, 0.0, 0.0, 0.25), AMBER, 0, 0, 6.0)
			pressed.border_width_bottom = 2
			disabled = normal
			color = AMBER if active else TEXT_DIM
		&"slot":
			var fill := _lit(RAISED, 0.06) if active else RAISED
			normal = box(fill, AMBER if active else EDGE_DIM, 2 if active else 1, 0, 12.0)
			hover = box(_lit(RAISED, 0.08), AMBER if active else TEXT_DIM, 2 if active else 1, 0, 12.0)
			pressed = box(PANEL, AMBER, 2, 0, 12.0)
			disabled = box(PANEL, EDGE_DIM, 1, 0, 12.0)
		_:
			var edge := DANGER if kind == &"danger" else EDGE
			normal = box(RAISED, edge, 1, 0, 8.0)
			hover = box(_lit(RAISED, 0.08), AMBER, 1, 0, 8.0)
			pressed = box(PANEL, AMBER, 1, 0, 8.0)
			disabled = box(PANEL, EDGE_DIM, 1, 0, 8.0)
			if kind == &"row":  # a line of a list (the equipment slots): the same states, a third less tall
				for style in [normal, hover, pressed, disabled]:
					style.content_margin_top = 1.0
					style.content_margin_bottom = 1.0
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("hover_pressed", pressed)
	button.add_theme_stylebox_override("focus", normal)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", AMBER if kind != &"tab" else (AMBER if active else TEXT))
	button.add_theme_color_override("font_pressed_color", AMBER)
	button.add_theme_color_override("font_disabled_color", Color(TEXT_DIM, 0.45))

## The largest font size from `max_size` down to `min_size` at which the text of a button, in the face its theme gives it, fits `width` less its padding: a longer language than English (German, Russian) shrinks the text
## before it clips. Call it once the button is in the tree, after its text is set.
static func fit(button: Button, width: float, max_size: int, min_size: int) -> void:
	var font := button.get_theme_font("font")
	var size := max_size
	while size > min_size and font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width - 16.0:
		size -= 1
	button.add_theme_font_size_override("font_size", size)

## A label in the face of a heading (Bebas) or of the body (the theme's), with the palette's colour and a size in design pixels.
static func label(text: String, size: int, color: Color = TEXT, heading: bool = false) -> Label:
	var item := Label.new()
	item.text = text
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", color)
	if heading:
		item.add_theme_font_override("font", ThemeProvider.heading_font())
	return item
