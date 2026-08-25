extends Control
## Встроен во вкладку «Кодекса»: тогда экран не рисует свой затемняющий фон
## и кнопку закрытия — их даёт общая рамка, — а панель растягивается на всю
## вкладку вместо центрирования.
var embedded: bool = false

func _ready() -> void:
	_build()
func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = ThemeProvider.build_theme()
	if not embedded:
		# V2 SKIN WIRING P4: real background art over the old flat tint.
		var bg_path := "res://assets/textures/screens_v2/character_dim.png"
		if ResourceLoader.exists(bg_path):
			var bg_tex := TextureRect.new()
			bg_tex.texture = load(bg_path)
			bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			bg_tex.stretch_mode = TextureRect.STRETCH_SCALE
			bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
			add_child(bg_tex)
			var tint := ColorRect.new()
			tint.color = Color(0.04, 0.05, 0.07, 0.5)
			tint.set_anchors_preset(Control.PRESET_FULL_RECT)
			add_child(tint)
		else:
			var bg := ColorRect.new()
			bg.color = Color(0.04, 0.05, 0.07, 0.94)
			bg.set_anchors_preset(Control.PRESET_FULL_RECT)
			add_child(bg)
	var panel := PanelContainer.new()
	if embedded:
		panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	else:
		panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(460, 360)
	add_child(panel)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	panel.add_child(hb)
	# P2 (FINAL INTEGRATION wave): real player render, side panel next to
	# the stats column - delivered mid-session (REPORT_UNBLOCK_V2.md),
	# this was logged as blocked/missing earlier in this same session.
	var render_path := "res://assets/textures/renders_v2/player_512x768.png"
	if ResourceLoader.exists(render_path):
		var render := TextureRect.new()
		render.custom_minimum_size = Vector2(128, 192)
		render.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		render.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hb.add_child(render)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(vb)
	var t := Label.new()
	t.text = LocalizationManager.t("STATS_TITLE")
	t.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_TITLE)
	t.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var s := ProgressTracker.get_stats()
	_line(vb, LocalizationManager.t("STATS_DISTRICTS"), "%d / %d" % [s["districts"], PowerGrid.all_districts().size()], "district")
	_line(vb, LocalizationManager.t("STATS_SECRETS"), "%d" % s["secrets"], "document")
	_line(vb, LocalizationManager.t("STATS_KILLS"), "%d" % s["kills"], "skull")
	_line(vb, LocalizationManager.t("STATS_TIME"), LocalizationManager.tf("STATS_SECONDS", [int(s["time_played"])]), "clock")
	if not embedded:
		var b := Button.new()
		b.text = LocalizationManager.t("ui_close")
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func() -> void: UIManager.close(&"stats"))
		vb.add_child(b)
## icon_id: V2 SKIN WIRING P1: icons_v2/stat_[id]_64.png, drawn before the
## label when present on disk.
func _line(p: Node, k: String, v: String, icon_id: String = "") -> void:
	var row := HBoxContainer.new()
	p.add_child(row)
	if icon_id != "":
		var icon_path := "res://assets/textures/icons_v2/stat_%s_64.png" % icon_id
		if ResourceLoader.exists(icon_path):
			var icon := TextureRect.new()
			icon.custom_minimum_size = Vector2(18, 18)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.texture = load(icon_path)
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			row.add_child(icon)
	var lk := Label.new()
	lk.text = k
	lk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lk)
	var lv := Label.new()
	lv.text = v
	lv.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	row.add_child(lv)