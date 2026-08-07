extends Node

const C_BG = Color("#12100C")
const C_PANEL = Color("#1D1812")
const C_AMBER = Color("#E2A33C")
const C_BONE = Color("#CFC9B8")
const C_RED = Color("#A63A32")

var theme_res: Theme = null

func _ready() -> void:
	_build_theme()
	get_tree().node_added.connect(_on_node)

func _on_node(n: Node) -> void:
	if theme_res != null and n is Control:
		n.theme = theme_res

func _build_theme() -> void:
	var t := Theme.new()
	var head: Font = null
	var body: Font = null
	if ResourceLoader.exists("res://assets/fonts/bebas_neue_bold.ttf"):
		head = load("res://assets/fonts/bebas_neue_bold.ttf")
	if ResourceLoader.exists("res://assets/fonts/roboto_condensed.ttf"):
		body = load("res://assets/fonts/roboto_condensed.ttf")
	if body == null:
		body = ThemeDB.fallback_font
	if head == null:
		head = body
	t.default_font = body
	t.default_font_size = 18
	t.set_font("font", "Label", body)
	t.set_font_size("font_size", "Label", 18)
	t.set_color("font_color", "Label", C_BONE)
	t.set_font("font", "Button", head)
	t.set_font_size("font_size", "Button", 22)
	t.set_color("font_color", "Button", C_BONE)
	t.set_color("font_hover_color", "Button", C_AMBER)
	t.set_color("font_pressed_color", "Button", C_RED)
	var bn = StyleBoxFlat.new()
	bn.bg_color = C_PANEL
	bn.border_color = C_AMBER
	bn.set_border_width_all(2)
	bn.set_content_margin_all(12)
	t.set_stylebox("normal", "Button", bn)
	var bh = bn.duplicate()
	bh.bg_color = C_PANEL.lightened(0.08)
	t.set_stylebox("hover", "Button", bh)
	var bp = bn.duplicate()
	bp.bg_color = C_AMBER
	t.set_stylebox("pressed", "Button", bp)
	var pn = StyleBoxFlat.new()
	pn.bg_color = C_PANEL
	pn.border_color = C_AMBER
	pn.set_border_width_all(1)
	pn.set_content_margin_all(16)
	t.set_stylebox("panel", "Panel", pn)
	t.set_stylebox("panel", "PanelContainer", pn)
	var pbb = StyleBoxFlat.new()
	pbb.bg_color = C_BG
	pbb.set_content_margin_all(4)
	t.set_stylebox("background", "ProgressBar", pbb)
	var pbf = StyleBoxFlat.new()
	pbf.bg_color = C_AMBER
	t.set_stylebox("fill", "ProgressBar", pbf)
	theme_res = t
	if OS.has_feature("editor"):
		DirAccess.make_dir_recursive_absolute("res://assets/theme")
		ResourceSaver.save(t, "res://assets/theme/tls_theme.tres")
	print("THEME ready")
