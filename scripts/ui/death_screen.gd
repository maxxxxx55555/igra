extends Control
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	LocalizationManager.language_changed.connect(_apply_localization.unbind(1))

var _t: Label
var _s: Label
var _b: Button
var _b2: Button

func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = ThemeProvider.build_theme()
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.02, 0.02, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.add_theme_constant_override("separation", 16)
	add_child(vb)
	_t = Label.new()
	_t.add_theme_font_size_override("font_size", 28)
	_t.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_t)
	_s = Label.new()
	_s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_s.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
	vb.add_child(_s)
	_b = Button.new()
	_b.focus_mode = Control.FOCUS_NONE
	_b.pressed.connect(func() -> void: GameManager.start_new_game())
	vb.add_child(_b)
	_b2 = Button.new()
	_b2.focus_mode = Control.FOCUS_NONE
	_b2.pressed.connect(func() -> void: GameManager.return_to_menu())
	vb.add_child(_b2)
	_apply_localization()

func _apply_localization() -> void:
	_t.text = LocalizationManager.t("DEATH_TITLE")
	_s.text = LocalizationManager.t("DEATH_BY")
	_b.text = LocalizationManager.t("retry")
	_b2.text = LocalizationManager.t("back_menu")
