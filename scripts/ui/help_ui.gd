extends Control
## Help / Codex screen (GOLD MASTER v4 mobile-art pass, STEP 2 onboarding).
## Embeds into the "Codex" tab frame like stats_ui.gd/journal_ui.gd — see
## codex_ui.gd. Two sections: live controls (keyboard actions read from
## InputMap, so this can never drift from project.godot; touch controls as
## a fixed reference list since InputMap has no touch equivalent) and a
## short mechanics glossary. The glossary reuses existing, already-13-
## locale-translated hint/onboarding strings (ponytail: reuse before
## write) rather than authoring new prose.

var embedded: bool = false

## action name -> display label key, and the touch HUD control that does
## the same thing (fixed reference text — InputMap has no touch mapping
## to read, unlike the keyboard column).
const CONTROLS: Array[Dictionary] = [
	{"action": "move_up", "label": "tutorial_move", "touch": "TOUCH_JOYSTICK"},
	{"action": "flashlight_toggle", "label": "SCR_FONARIK", "touch": "TOUCH_FLASH_BTN"},
	{"action": "interact", "label": "PROMPT_REPAIR", "touch": "TOUCH_INTERACT_BTN"},
	{"action": "stealth", "label": "HUD_STEALTH", "touch": "TOUCH_STEALTH_BTN"},
	{"action": "sprint", "label": "HUD_SPRINT", "touch": "TOUCH_SPRINT_BTN"},
	{"action": "city_map_toggle", "label": "SCR_RAYONOV", "touch": "TOUCH_MAP_BTN"},
	{"action": "journal_toggle", "label": "JOURNAL_TITLE", "touch": "TOUCH_MENU_BTN"},
	{"action": "ui_pause", "label": "back_menu", "touch": "TOUCH_PAUSE_BTN"},
]

## Glossary: title key (existing, short) -> description key (existing,
## already 13-locale). icon: assets/textures/touch/help_<icon>_96.png.
const GLOSSARY: Array[Dictionary] = [
	{"title": "HUD_BATTERY", "desc": "TUT_BATTERY_FOUND", "icon": "battery"},
	{"title": "Cable Puzzle", "desc": "ONBOARD_06_CAPTION", "icon": "puzzle"},
	{"title": "HUD_STEALTH", "desc": "ONBOARD_07_CAPTION", "icon": "stealth"},
	{"title": "SCR_RAYONOV", "desc": "ONBOARD_04_CAPTION", "icon": ""},
	{"title": "SCR_FONARIK", "desc": "HINT_FLASHLIGHT", "icon": ""},
]

func _ready() -> void:
	_build()
	LocalizationManager.language_changed.connect(func(_l: String) -> void:
		for c in get_children():
			c.queue_free()
		_build())

func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = ThemeProvider.build_theme()
	if not embedded:
		var bg := ColorRect.new()
		bg.color = Color(0.04, 0.05, 0.07, 0.94)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(bg)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 14)
	scroll.add_child(col)

	if not embedded:
		var t := Label.new()
		t.text = LocalizationManager.t("Help")
		t.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_TITLE)
		t.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(t)

	_section_header(col, "controls", "controls")
	for row in CONTROLS:
		_control_row(col, LocalizationManager.t(String(row["label"])),
			_keycap_for(String(row["action"])), LocalizationManager.t(String(row["touch"])))

	_section_header(col, "Glossary", "controls")
	for g in GLOSSARY:
		_glossary_entry(col, LocalizationManager.t(String(g["title"])),
			LocalizationManager.t(String(g["desc"])), String(g["icon"]))

	if not embedded:
		var close_btn := Button.new()
		close_btn.text = LocalizationManager.t("ui_close")
		close_btn.focus_mode = Control.FOCUS_NONE
		close_btn.pressed.connect(func() -> void: UIManager.close(&"help"))
		col.add_child(close_btn)

func _section_header(parent: Node, key: String, icon_id: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	_icon(row, icon_id, 20)
	var l := Label.new()
	l.text = LocalizationManager.t(key)
	l.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_TITLE - 4)
	l.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	row.add_child(l)

## One control row: action label, then its keyboard keycap and its touch
## HUD equivalent side by side — a player on either input method finds
## their column at a glance.
func _control_row(parent: Node, label: String, keycap: String, touch: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var lk := Label.new()
	lk.text = label
	lk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(lk)
	var lkey := Label.new()
	lkey.text = keycap
	lkey.custom_minimum_size.x = 90
	lkey.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	row.add_child(lkey)
	var ltouch := Label.new()
	ltouch.text = touch
	ltouch.custom_minimum_size.x = 170
	ltouch.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ltouch.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
	row.add_child(ltouch)

func _glossary_entry(parent: Node, title: String, desc: String, icon_id: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	_icon(row, icon_id, 28)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(vb)
	var t := Label.new()
	t.text = title
	t.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT)
	vb.add_child(t)
	var d := Label.new()
	d.text = desc
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
	vb.add_child(d)

func _icon(parent: Node, icon_id: String, px: int) -> void:
	if icon_id == "":
		return
	var path := "res://assets/textures/touch/help_%s_96.png" % icon_id
	if not ResourceLoader.exists(path):
		return
	var tr := TextureRect.new()
	tr.custom_minimum_size = Vector2(px, px)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture = load(path)
	parent.add_child(tr)

## First bound key/button for an action, as display text ("E", "Space" ...).
## Falls back to the action name if nothing is bound (still readable, never
## a raw KEY_NONE).
func _keycap_for(action: String) -> String:
	if not InputMap.has_action(action):
		return action
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			var k := ev as InputEventKey
			var label := OS.get_keycode_string(k.physical_keycode if k.physical_keycode != 0 else k.keycode)
			if label != "":
				return label
		elif ev is InputEventMouseButton:
			return "Mouse %d" % (ev as InputEventMouseButton).button_index
	return action
