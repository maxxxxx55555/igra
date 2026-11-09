extends RefCounted
## CanvasLayer-owned cards need an explicit theme; Window inheritance stops here.

static func apply(card: Control, border: ColorRect, rule: ColorRect) -> void:
	card.theme = ThemeProvider.build_theme()
	border.color = Color(ThemeProvider.COLOR_TEXT_DIM, 0.18)
	rule.color = Color(ThemeProvider.COLOR_TEXT_DIM, 0.18)

static func item_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = ThemeProvider.COLOR_BG_PANEL2
	style.set_content_margin_all(14.0)
	return style
