# ThemeProvider — ЕДИНЫЙ визуальный слой по арт-библии docs/ART_UI_STYLE.md:
# латунь (brass) вместо янтаря, СРЕЗАННЫЕ углы (chamfer, радиус 0), шрифты Saira/Rajdhani/Share Tech Mono.
# Все 14 экранов тянут build_theme() отсюда — это единственная точка истины для UI.
class_name ThemeProvider
extends RefCounted

# ── Цветовые токены (docs/ART_UI_STYLE.md) ─────────────────────────────
const COLOR_BG_DARK   := Color("#0c1016")   # bg-deep
const COLOR_BG_PANEL  := Color("#141b24")   # panel
const COLOR_BG_PANEL2 := Color("#1b232e")   # panel-hover (чуть светлее)
const COLOR_BORDER    := Color("#2a3340")   # panel-edge
const COLOR_AMBER     := Color("#c9a24a")   # brass — акцент, активное
const COLOR_AMBER_DIM := Color("#8a7338")   # brass-dim — неактивное
const COLOR_AMBER_HI  := Color("#d8d2c4")   # bone — заголовки
const COLOR_TEXT      := Color("#d8d2c4")   # bone-text
const COLOR_TEXT_DIM  := Color("#aeb6bf")   # steel-text
const COLOR_DANGER    := Color("#b4452f")   # ember
const COLOR_STAMINA   := Color("#5f8a4e")   # stamina green

const FONT_SIZE_BODY: int = 16
const FONT_SIZE_TITLE: int = 22
const FONT_SIZE_HUGE: int = 30

static func _make_font(names: PackedStringArray, weight: int = 400) -> SystemFont:
	var f := SystemFont.new()
	f.font_names = names
	f.font_weight = weight
	return f

static func build_theme() -> Theme:
	var theme := Theme.new()
	# Шрифты по арт-библии (запрещены Inter/Roboto/Arial и системные по умолчанию).
	var font_body := _make_font(PackedStringArray(["Rajdhani-Regular", "Rajdhani"]))
	var font_body_bold := _make_font(PackedStringArray(["Rajdhani-SemiBold", "Rajdhani"]), 600)
	var font_heading := _make_font(PackedStringArray(["SairaCondensed-Bold", "Saira Condensed"]), 700)
	var font_panel := _make_font(PackedStringArray(["SairaCondensed-Regular", "Saira Condensed"]))
	var font_mono := _make_font(PackedStringArray(["ShareTechMono-Regular", "Share Tech Mono"]))
	theme.default_font = font_body
	theme.set_font(&"font", &"Label", font_body)
	theme.set_font(&"font", &"Button", font_panel)
	theme.set_font(&"font", &"PanelContainer", font_panel)
	theme.set_font(&"font", &"RichTextLabel", font_body)
	theme.set_font(&"font", &"LineEdit", font_mono)
	theme.set_font(&"font", &"TextEdit", font_mono)
	theme.set_font(&"font", &"OptionButton", font_panel)
	theme.set_font(&"font", &"TabBar", font_panel)

	# Панель: chamfer (0 радиус), рамка panel-edge 1px, зерно не тут (ColorRect-слой).
	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = COLOR_BG_PANEL
	panel_sb.border_color = COLOR_BORDER
	panel_sb.set_border_width_all(1)
	panel_sb.set_corner_radius_all(0)
	panel_sb.set_content_margin_all(12)
	theme.set_stylebox("panel", "Panel", panel_sb)
	theme.set_stylebox("panel", "PanelContainer", panel_sb)
	var panel2 := panel_sb.duplicate() as StyleBoxFlat
	panel2.bg_color = COLOR_BG_PANEL2
	theme.set_stylebox("panel", "Frame", panel2)
	theme.set_color("font_color", "Label", COLOR_TEXT)
	theme.set_font_size("font_size", "Label", FONT_SIZE_BODY)

	# Кнопка: chamfer, 1px рамка brass-dim → brass при наведении.
	var btn_n := StyleBoxFlat.new()
	btn_n.bg_color = COLOR_BG_DARK
	btn_n.border_color = COLOR_AMBER_DIM
	btn_n.set_border_width_all(1)
	btn_n.set_corner_radius_all(0)
	btn_n.set_content_margin_all(10)
	var btn_h := btn_n.duplicate() as StyleBoxFlat
	btn_h.border_color = COLOR_AMBER
	var btn_p := btn_n.duplicate() as StyleBoxFlat
	btn_p.bg_color = COLOR_BG_PANEL
	btn_p.border_color = COLOR_AMBER
	theme.set_stylebox("normal", "Button", btn_n)
	theme.set_stylebox("hover", "Button", btn_h)
	theme.set_stylebox("pressed", "Button", btn_p)
	theme.set_stylebox("disabled", "Button", btn_n)
	theme.set_color("font_color", "Button", COLOR_TEXT)
	theme.set_color("font_hover_color", "Button", COLOR_AMBER_HI)
	theme.set_color("font_disabled_color", "Button", COLOR_TEXT_DIM)
	theme.set_font_size("font_size", "Button", FONT_SIZE_BODY)

	# Прогресс-бары: chamfer, заполнение brass.
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

	# Скроллбары: тонкая латунь.
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_AMBER_DIM
	sb.set_corner_radius_all(0)
	theme.set_stylebox("grabber", "VScrollBar", sb)
	theme.set_stylebox("grabber", "HScrollBar", sb)
	var sb_bg := StyleBoxFlat.new()
	sb_bg.bg_color = COLOR_BG_DARK
	theme.set_stylebox("scroll", "VScrollBar", sb_bg)
	theme.set_stylebox("scroll", "HScrollBar", sb_bg)
	return theme

# Рамка секции с латунным уголком-акцентом (как блоки на инфографике референса).
static func draw_section_frame(c: CanvasItem, r: Rect2) -> void:
	c.draw_rect(r, COLOR_BORDER, false, 1.0)
	c.draw_line(r.position, r.position + Vector2(18, 0), COLOR_AMBER, 2.0)
	c.draw_line(r.position, r.position + Vector2(0, 18), COLOR_AMBER, 2.0)
