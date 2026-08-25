extends Control

## Встроен во вкладку «Кодекса»: тогда экран не рисует свой затемняющий фон
## и кнопку закрытия — их даёт общая рамка, — а панель растягивается на всю
## вкладку вместо центрирования.
var embedded: bool = false
var _detail: Control = null

## P1 (CONTENT UX wave): same roster EnemyRosterData base_monster.gd reads
## for weak_spot - existing data, no new tracking. get_entry_for_ai returns
## {} for "shadow" (not in AI_TO_ROSTER and no matching roster key), which
## the detail view treats as "no weak-spot data" rather than a blank row.
const _ROSTER := preload("res://data/balance/enemy_stats.tres")

## Keys spelled out explicitly, not assembled as "WEAKSPOT_" + value.to_upper() -
## the i18n audit greps for literal t("...") string arguments and finds
## nothing on a concatenated key (see city_map.gd's STAGE_KEYS for the same
## established fix). Covers every weak_spot value in data/balance/enemy_stats.tres.
const _WEAKSPOT_KEY: Dictionary = {
	"head": "WEAKSPOT_HEAD", "body": "WEAKSPOT_BODY", "back": "WEAKSPOT_BACK",
	"blunt": "WEAKSPOT_BLUNT", "fire_electric": "WEAKSPOT_FIRE_ELECTRIC",
	"fire_immune": "WEAKSPOT_FIRE_IMMUNE", "bullet": "WEAKSPOT_BULLET",
	"strobe_combo": "WEAKSPOT_STROBE_COMBO",
}

func _ready() -> void:
	_build()
	if not LocalizationManager.language_changed.is_connected(_on_lang_changed):
		LocalizationManager.language_changed.connect(_on_lang_changed)

func _on_lang_changed(_lang: String) -> void:
	_detail = null
	for c in get_children():
		c.queue_free()
	_build()

func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = ThemeProvider.build_theme()
	if not embedded:
		var bg := ColorRect.new()
		bg.color = Color(0.04, 0.05, 0.07, 0.94)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(bg)
	var panel := PanelContainer.new()
	if embedded:
		panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	else:
		panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(660, 480)
	add_child(panel)
	var vb := VBoxContainer.new()
	panel.add_child(vb)
	var t := Label.new()
	t.text = LocalizationManager.t("enc_title")
	t.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_TITLE)
	t.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	vb.add_child(grid)
	for id in Encyclopedia.all_ids():
		var unlocked := Encyclopedia.is_unlocked(id)
		var data := Encyclopedia.get_data(id)
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(190, 140)
		grid.add_child(card)
		# P1: unlocked cards open the detail view; locked ones stay inert -
		# there's nothing to reveal, same as the "???" text already shown.
		if unlocked:
			card.mouse_filter = Control.MOUSE_FILTER_STOP
			card.gui_input.connect(func(event: InputEvent) -> void:
				if event is InputEventMouseButton and event.pressed \
						and event.button_index == MOUSE_BUTTON_LEFT:
					_open_detail(id))
		var cv := VBoxContainer.new()
		card.add_child(cv)
		if unlocked and data and data.portrait != null:
			var portrait := TextureRect.new()
			portrait.custom_minimum_size = Vector2(190, 44)
			portrait.texture = data.portrait
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			cv.add_child(portrait)
		else:
			var prev := ColorRect.new()
			prev.custom_minimum_size = Vector2(190, 44)
			prev.color = data.body_color if (unlocked and data) else ThemeProvider.COLOR_BG_DARK
			cv.add_child(prev)
		# V2 SKIN WIRING P1: small line-art icon next to the portrait thumb,
		# unlocked entries only - locked cards stay "???" with no id to key on.
		if unlocked and data:
			var icon_path := "res://assets/textures/icons_v2/monster_%s_64.png" % String(data.id)
			if ResourceLoader.exists(icon_path):
				var icon := TextureRect.new()
				icon.custom_minimum_size = Vector2(20, 20)
				icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icon.texture = load(icon_path)
				icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon.size_flags_horizontal = Control.SIZE_SHRINK_END
				cv.add_child(icon)
		var nm := Label.new()
		nm.text = LocalizationManager.name_for("MONSTER_", data.id, data.display_name) if unlocked else "???"
		nm.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER if unlocked else ThemeProvider.COLOR_TEXT_DIM)
		cv.add_child(nm)
		var ds := Label.new()
		ds.text = data.description if unlocked else LocalizationManager.t("enc_locked")
		ds.add_theme_font_size_override("font_size", 11)
		ds.autowrap_mode = TextServer.AUTOWRAP_WORD
		ds.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
		cv.add_child(ds)
	if not embedded:
		var b := Button.new()
		b.text = LocalizationManager.t("ui_close")
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func() -> void: UIManager.close(&"encyclopedia"))
		vb.add_child(b)

## P1: detail panel for one already-unlocked entry, built in place (not a
## new scene) as a full-rect overlay on top of the grid. Real portrait if
## portraits_v2 delivered one for this monster, else the existing thumb
## already used on the card; real stats from MonsterData/EnemyRosterData,
## no invented fields.
func _open_detail(id: StringName) -> void:
	if _detail != null:
		_detail.queue_free()
	var data := Encyclopedia.get_data(id)
	if data == null:
		return
	var d := Control.new()
	d.set_anchors_preset(Control.PRESET_FULL_RECT)
	d.focus_mode = Control.FOCUS_ALL
	d.mouse_filter = Control.MOUSE_FILTER_STOP
	d.gui_input.connect(func(event: InputEvent) -> void:
		if event.is_action_pressed("ui_cancel"):
			_close_detail()
			d.accept_event())
	add_child(d)
	_detail = d

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.025, 0.03, 0.92)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	d.add_child(dim)

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.custom_minimum_size = Vector2(420, 420)
	d.add_child(card)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	card.add_child(vb)

	var full_path := "res://assets/textures/portraits_v2/%s_full_512x768.png" % String(id)
	var art := TextureRect.new()
	art.custom_minimum_size = Vector2(220, 220)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if ResourceLoader.exists(full_path):
		art.texture = load(full_path)
		vb.add_child(art)
	elif data.portrait != null:
		art.texture = data.portrait
		vb.add_child(art)

	var nm := Label.new()
	nm.text = LocalizationManager.name_for("MONSTER_", data.id, data.display_name)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_TITLE)
	nm.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	vb.add_child(nm)

	var ds := Label.new()
	ds.text = data.description
	ds.autowrap_mode = TextServer.AUTOWRAP_WORD
	ds.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ds.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
	vb.add_child(ds)

	var stats := VBoxContainer.new()
	vb.add_child(stats)
	_stat_row(stats, "ENC_STAT_HP", str(int(data.max_hp)))
	_stat_row(stats, "ENC_STAT_SPEED", "%d / %d" % [int(data.move_speed), int(data.chase_speed)])
	var weak_spot: String = String(_ROSTER.get_entry_for_ai(id).get("weak_spot", ""))
	if _WEAKSPOT_KEY.has(weak_spot):
		_stat_row(stats, "ENC_STAT_WEAKNESS", LocalizationManager.t(_WEAKSPOT_KEY[weak_spot]))
	_stat_row(stats, "ENC_STAT_STATUS", LocalizationManager.t("ENC_DISCOVERED"))

	var close := Button.new()
	close.text = LocalizationManager.t("ui_close")
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(_close_detail)
	vb.add_child(close)
	d.grab_focus()

func _stat_row(parent: Node, label_key: String, value: String) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var lk := Label.new()
	lk.text = LocalizationManager.t(label_key)
	lk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lk.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
	row.add_child(lk)
	var lv := Label.new()
	lv.text = value
	lv.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT)
	row.add_child(lv)

func _close_detail() -> void:
	if _detail != null:
		_detail.queue_free()
		_detail = null
