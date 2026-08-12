extends Node

## Токены канона (обновлены под 5 листов UI/UX-спеки + GDD §11.2)
const C_BG_DEEP = Color("#0c1016")   ## bg-deep
const C_PANEL = Color("#141b24")     ## panel
const C_PANEL_EDGE = Color("#2a3340") ## panel-edge
const C_BRASS = Color("#c9a24a")     ## brass (акцент)
const C_BRASS_DIM = Color("#8a7338") ## brass-dim
const C_EMBER = Color("#b4452f")     ## ember (опасность)
const C_STEEL_TEXT = Color("#aeb6bf") ## steel-text
const C_BONE_TEXT = Color("#d8d2c4") ## bone-text
const C_STAMINA = Color("#5f8a4e")   ## stamina

var theme_res: Theme = null

func _ready() -> void:
	_build_theme()
	# Раньше тема присваивалась КАЖДОМУ Control через node_added: это затирало
	# собственные темы сцен и стоило обхода дерева на каждый создаваемый узел.
	# Правильное место одно — тема окна: она наследуется всем деревом Control.
	if theme_res != null:
		get_tree().root.theme = theme_res

func _build_theme() -> void:
	# 1) Попытаться загрузить существующую theme_tls.tres как базу.
	var t: Theme = null
	var path := "res://assets/ui/theme_tls.tres"
	if ResourceLoader.exists(path):
		t = load(path)
	if t == null:
		t = Theme.new()

	# 2) Шрифты: Bebas Neue (headers) + Roboto Condensed (body) — канон листов.
	var head: Font = null
	var body: Font = null
	if ResourceLoader.exists("res://assets/fonts/BebasNeue-Regular.ttf"):
		head = load("res://assets/fonts/BebasNeue-Regular.ttf")
	if ResourceLoader.exists("res://assets/fonts/RobotoCondensed-Regular.ttf"):
		body = load("res://assets/fonts/RobotoCondensed-Regular.ttf")
	if body == null:
		body = ThemeDB.fallback_font
	if head == null:
		head = body

	t.default_font = body
	t.default_font_size = 18

	# 3) базовые overrides (только если не заданы в .tres)
	if not t.has_font("font", "Label"):
		t.set_font("font", "Label", body)
	if not t.has_font_size("font_size", "Label"):
		t.set_font_size("font_size", "Label", 18)
	if not t.has_color("font_color", "Label"):
		t.set_color("font_color", "Label", C_STEEL_TEXT)

	# 4) Button / Panel / ProgressBar: дописать или расширить
	if not t.has_font("font", "Button"):
		t.set_font("font", "Button", head)
		t.set_font_size("font_size", "Button", 22)
		t.set_color("font_color", "Button", C_BONE_TEXT)
		t.set_color("font_hover_color", "Button", C_BRASS)
		t.set_color("font_pressed_color", "Button", C_EMBER)

		if not t.has_stylebox("normal", "Button"):
			var bn := StyleBoxFlat.new()
			bn.bg_color = C_PANEL
			bn.border_color = C_PANEL_EDGE
			bn.set_border_width_all(1)
			bn.set_content_margin_all(12)
			bn.corner_radius_top_left = 0
			bn.corner_radius_top_right = 0
			bn.corner_radius_bottom_left = 0
			bn.corner_radius_bottom_right = 0
			t.set_stylebox("normal", "Button", bn)
		if not t.has_stylebox("hover", "Button"):
			var bh: StyleBoxFlat = t.get_stylebox("normal", "Button").duplicate()
			bh.bg_color = C_PANEL.lightened(0.08)
			t.set_stylebox("hover", "Button", bh)
		if not t.has_stylebox("pressed", "Button"):
			var bp: StyleBoxFlat = t.get_stylebox("normal", "Button").duplicate()
			bp.bg_color = C_BRASS
			bp.border_color = C_BRASS_DIM
			t.set_stylebox("pressed", "Button", bp)

	if not t.has_stylebox("panel", "Panel"):
		var pn := StyleBoxFlat.new()
		pn.bg_color = C_PANEL
		pn.border_color = C_PANEL_EDGE
		pn.set_border_width_all(1)
		pn.set_content_margin_all(16)
		pn.corner_radius_top_left = 0
		pn.corner_radius_top_right = 0
		pn.corner_radius_bottom_left = 0
		pn.corner_radius_bottom_right = 0
		t.set_stylebox("panel", "Panel", pn)
		t.set_stylebox("panel", "PanelContainer", pn)

	if not t.has_stylebox("background", "ProgressBar"):
		var pbb := StyleBoxFlat.new()
		pbb.bg_color = C_BG_DEEP
		pbb.set_content_margin_all(4)
		t.set_stylebox("background", "ProgressBar", pbb)
	if not t.has_stylebox("fill", "ProgressBar"):
		var pbf := StyleBoxFlat.new()
		pbf.bg_color = C_BRASS
		t.set_stylebox("fill", "ProgressBar", pbf)

	theme_res = t
