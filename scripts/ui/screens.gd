extends CanvasLayer
signal panel_ready(name: String)
const SCREEN_LIST: Array[String] = [
	"MainMenu", "Loading", "Pause", "Settings", "Inventory",
	"CityMap", "Journal", "QuestJournal", "Achievements", "Stats", "Shop",
	"Death", "Victory", "Saves", "Bestiary", "Character",
	"FlashlightUpgrade", "PhotoMode", "ControlsTouch",
	"Weather", "Workbench", "PuzzleCables", "Radio",
	"StoryScene", "FinalNight", "PowerGrid", "Events",
	"Tutorial",
]
const BRASS: Color = Color(0.788, 0.635, 0.290)
const BRASS_DIM: Color = Color(0.541, 0.451, 0.220)
const STEEL_TEXT: Color = Color(0.682, 0.714, 0.749)
const BONE_TEXT: Color = Color(0.682, 0.714, 0.749)
const EMPER: Color = Color(0.706, 0.271, 0.184)
const STAMINA_GREEN: Color = Color(0.373, 0.541, 0.306)
const PANEL_COLOR: Color = Color(0.078, 0.106, 0.141)
const PANEL_EDGE: Color = Color(0.165, 0.200, 0.251)
const BG_COLOR: Color = Color(0.047, 0.063, 0.086)
const OUTLINE_COLOR: Color = Color(0.047, 0.063, 0.086, 1.0)
const SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
var _active_screen: String = ""
var _screen_data: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 25
	_build_menu_bg()
	EventBus.game_state_changed.connect(_on_game_state)
	_on_game_state(int(GameManager.current_state))
	_build_all_screens()

func _build_menu_bg() -> void:
	var bg_full := ColorRect.new()
	bg_full.name = "MenuBG"
	bg_full.color = BG_COLOR
	bg_full.mouse_filter = Control.MOUSE_FILTER_STOP
	bg_full.visible = false
	add_child(bg_full)
	bg_full.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _on_game_state(state: int) -> void:
	var menu_visible := state == GameManager.GameState.MENU
	var pause_visible := state == GameManager.GameState.PAUSED
	for d in _screen_data.values():
		var name: String = d.card.name
		var keep_visible := (menu_visible and name == "MainMenu_Card") or (pause_visible and name == "Pause_Card")
		d.underlay.visible = keep_visible
		d.card.visible = keep_visible
	var bg_node := find_child("MenuBG", true, false) as ColorRect
	if bg_node:
		bg_node.visible = menu_visible or pause_visible
	if menu_visible:
		_active_screen = "MainMenu"
	elif pause_visible:
		_active_screen = "Pause"
	else:
		_active_screen = ""

func is_any_open() -> bool:
	return _active_screen != ""

func _build_all_screens() -> void:
	for name in SCREEN_LIST:
		_build_screen(name)

func _build_screen(name: String) -> void:
	var vp := get_viewport().get_visible_rect().size
	var underlay := ColorRect.new()
	underlay.color = Color(0.047, 0.063, 0.086, 0.0)
	underlay.size = vp
	underlay.mouse_filter = Control.MOUSE_FILTER_STOP
	underlay.name = name
	underlay.visible = false
	add_child(underlay)
	var card_w: float = 560.0
	var card_h: float = vp.y * 0.7
	card_h = clampf(card_h, 300, 520)
	var card := ColorRect.new()
	card.color = PANEL_COLOR
	card.size = Vector2(card_w, card_h)
	card.position = Vector2(vp.x / 2.0 - card_w / 2.0, vp.y / 2.0 - card_h / 2.0)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.name = name + "_Card"
	card.visible = false
	add_child(card)
	var border := ColorRect.new()
	border.color = BRASS
	border.size = Vector2(card_w + 4, card_h + 4)
	border.position = Vector2(-2, -2)
	border.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_child(border)
	var inner := ColorRect.new()
	inner.color = PANEL_COLOR
	inner.size = Vector2(card_w - 2, card_h - 2)
	inner.position = Vector2(1, 1)
	inner.mouse_filter = Control.MOUSE_FILTER_PASS
	border.add_child(inner)
	var header_line := ColorRect.new()
	header_line.color = BRASS
	header_line.size = Vector2(card_w - 4, 2)
	header_line.position = Vector2(2, 46)
	card.add_child(header_line)
	var title_lbl := Label.new()
	title_lbl.name = "Title"
	title_lbl.size = Vector2(card_w - 40, 36)
	title_lbl.position = Vector2(20, 8)
	title_lbl.add_theme_color_override("font_color", BONE_TEXT)
	title_lbl.add_theme_font_size_override("font_size", 20)
	_apply_outline(title_lbl)
	card.add_child(title_lbl)
	var content := ColorRect.new()
	content.color = Color(0, 0, 0, 0)
	content.size = Vector2(card_w - 40, card_h - 100)
	content.position = Vector2(20, 56)
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	content.name = "Content"
	card.add_child(content)
	var exempt_close := ["MainMenu", "Loading", "Death", "Victory", "Saves", "ControlsTouch", "Weather", "StoryScene", "FinalNight"]
	var close_btn: Button = null
	if not name in exempt_close:
		close_btn = _make_btn("ЗАКРЫТЬ", Vector2(card_w / 2.0 - 80, card_h - 46), Vector2(160, 36))
		close_btn.pressed.connect(_on_close)
		card.add_child(close_btn)
	_screen_data[name] = {
		"underlay": underlay, "card": card, "content": content,
		"close_btn": close_btn if close_btn else Button.new(), "title_lbl": title_lbl,
	}

func _apply_outline(lbl: Label) -> void:
	lbl.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.add_theme_color_override("font_shadow_color", SHADOW_COLOR)
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)

func _add_btn(parent: Node, text: String, pos: Vector2, sz: Vector2, callback: Callable) -> Button:
	var btn := _make_btn(text, pos, sz)
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn

func _make_btn(text: String, pos: Vector2, sz: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.size = sz
	btn.position = pos
	_setup_btn_hover(btn)
	return btn

func _setup_btn_hover(btn: Button) -> void:
	btn.mouse_entered.connect(func():
		btn.scale = Vector2(1.03, 1.03)
	)
	btn.mouse_exited.connect(func():
		btn.scale = Vector2(1.0, 1.0)
	)
	btn.pressed.connect(func():
		var t := btn.create_tween()
		t.tween_property(btn, "scale", Vector2(0.94, 0.94), 0.04)
		t.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.04)
	)

func _setup_btn_hover_connect(btn: Button) -> void:
	_setup_btn_hover(btn)

func show_screen(name: String) -> void:
	hide_all()
	_active_screen = name
	if not _screen_data.has(name):
		return
	var bg_node := find_child("MenuBG", true, false) as ColorRect
	if bg_node:
		bg_node.visible = true
		var vr := get_viewport().get_visible_rect()
		var mr := bg_node.get_global_rect()
		var covers := (mr.position.x <= vr.position.x + 1 and mr.position.y <= vr.position.y + 1 and mr.size.x >= vr.size.x - 2 and mr.size.y >= vr.size.y - 2)
	var d: Dictionary = _screen_data[name]
	d.underlay.visible = true
	d.card.visible = true
	d.underlay.modulate = Color(1, 1, 1, 0)
	d.card.scale = Vector2(0.96, 0.96)
	d.card.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(d.underlay, "modulate:a", 0.5, 0.18)
	tween.tween_property(d.card, "modulate:a", 1.0, 0.18)
	tween.tween_property(d.card, "scale", Vector2(1.0, 1.0), 0.18)
	tween.play()
	_populate_screen(name)
	EventBus.ui_screen_opened.emit(name)

func hide_all() -> void:
	var bg_node := find_child("MenuBG", true, false) as ColorRect
	if bg_node:
		bg_node.visible = false
	for d in _screen_data.values():
		d.underlay.visible = false
		d.card.visible = false
	_active_screen = ""
	EventBus.ui_screen_closed.emit("all")

func _populate_screen(name: String) -> void:
	var d: Dictionary = _screen_data.get(name) as Dictionary
	if not d: return
	var content: ColorRect = d.content
	var card: ColorRect = d.card
	var cw := card.size.x
	var ch := card.size.y
	d.title_lbl.text = _title_for(name)
	for child in card.get_children():
		if child is Button and child != d.close_btn:
			child.queue_free()
	if content:
		for c in content.get_children():
			c.queue_free()
	match name:
		"MainMenu":
			build_MainMenu(card, cw, ch, d)
		"Loading":
			build_Loading(content, card, cw, ch, d)
		"Pause":
			build_Pause(card, cw, ch)
		"Settings":
			build_Settings(content, card, cw, ch)
		"Inventory":
			build_Inventory(content, card, cw, ch)
		"CityMap":
			build_CityMap(content, card, cw, ch, d)
		"Journal":
			build_Journal(content, card, cw, ch)
		"QuestJournal":
			build_QuestJournal(content, card, cw, ch)
		"Achievements":
			build_Achievements(content, card, cw, ch)
		"Stats":
			build_Stats(content, card, cw, ch)
		"Shop":
			build_Shop(content, card, cw, ch)
		"Death":
			build_Death(card, cw, ch, d)
		"Victory":
			build_Victory(content, card, cw, ch)
		"Saves":
			build_Saves(content, card, cw, ch)
		"Bestiary":
			build_Bestiary(content, card, cw, ch)
		"Character":
			build_Character(content, card, cw, ch)
		"FlashlightUpgrade":
			build_FlashlightUpgrade(content, card, cw, ch)
		"PhotoMode":
			build_PhotoMode(content, card, cw, ch, d)
		"ControlsTouch":
			build_ControlsTouch(content, card, cw, ch)
		"Weather":
			build_Weather(content, card, cw, ch)
		"Workbench":
			build_Workbench(content, card, cw, ch)
		"PuzzleCables":
			build_PuzzleCables(content, card, cw, ch)
		"Radio":
			build_Radio(content, card, cw, ch)
		"StoryScene":
			build_StoryScene(card, cw, ch, d)
		"FinalNight":
			build_FinalNight(content, card, cw, ch, d)
		"PowerGrid":
			build_PowerGrid(content, card, cw, ch)
		"Events":
			build_Events(content, card, cw, ch)
		"Tutorial":
			build_Tutorial(content, card, cw, ch)

func _title_for(name: String) -> String:
	var t := {
		"Pause": tr("SETTINGS_GAME"), "Settings": tr("SETTINGS_GAME"), "Inventory": tr("INV_WEIGHT"),
		"CityMap": tr("MAP_TITLE"), "Journal": tr("JOURNAL_TAB_QUESTS"), "Achievements": tr("ACHIEVEMENTS_TITLE"),
		"Stats": tr("STATS_TITLE"), "Shop": tr("SHOP_COINS"), "Death": "",
		"Victory": tr("VICTORY_TITLE"), "Saves": tr("SAVE_SLOT"), "Loading": "",
		"MainMenu": "", "Bestiary": tr("BESTIARY_TITLE"), "Character": tr("CHAR_STATS"),
		"FlashlightUpgrade": tr("CRAFT_UPGRADE"), "PhotoMode": tr("PHOTO_MODE"),
		"ControlsTouch": tr("SETTINGS_CONTROLS"), "Weather": tr("WEATHER_RAIN"), "Workbench": tr("WORKBENCH_TITLE"),
		"PuzzleCables": tr("CABLE_PUZZLE"), "Radio": tr("RADIO_CHANNELS"), "StoryScene": tr("DIALOG_SKIP"),
		"FinalNight": tr("FINAL_NIGHT_TITLE"), "PowerGrid": tr("POWER_GRID_TITLE"), "Events": tr("EVENTS_TITLE"),
	}
	return t.get(name, name)

func _add_text(parent: Node, text: String, pos: Vector2, sz: int, col: Color, align: int = -1) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.size = Vector2(300, 24) if pos.x + 300 < parent.size.x else Vector2(parent.size.x - pos.x * 2, 24)
	lbl.position = pos
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_font_size_override("font_size", sz)
	if align == 1:
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_outline(lbl)
	parent.add_child(lbl)
	return lbl

func build_MainMenu(card: ColorRect, cw: float, ch: float, d: Dictionary) -> void:
	var content: ColorRect = d.content
	if content:
		content.queue_free()
		d.content = null
	d.title_lbl.text = ""
	card.color = Color(0.047, 0.063, 0.086)
	var bg := ColorRect.new()
	bg.name = "MenuBG"
	bg.color = BG_COLOR
	bg.size = Vector2(cw, ch)
	bg.position = Vector2(0, 0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(bg)
	var logo_small := Label.new()
	logo_small.text = "THE LAST"
	logo_small.size = Vector2(cw, 24)
	logo_small.position = Vector2(0, 50)
	logo_small.add_theme_color_override("font_color", STEEL_TEXT)
	logo_small.add_theme_font_size_override("font_size", 16)
	logo_small.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_outline(logo_small)
	card.add_child(logo_small)
	var logo_main := Label.new()
	logo_main.text = "STREETLIGHT"
	logo_main.size = Vector2(cw, 56)
	logo_main.position = Vector2(0, 72)
	logo_main.add_theme_color_override("font_color", BONE_TEXT)
	logo_main.add_theme_font_size_override("font_size", 42)
	logo_main.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo_main.add_theme_color_override("font_shadow_color", BRASS)
	logo_main.add_theme_constant_override("shadow_offset_x", 2)
	logo_main.add_theme_constant_override("shadow_offset_y", 2)
	_apply_outline(logo_main)
	card.add_child(logo_main)
	var subtitle := Label.new()
	subtitle.text = "SURVIVAL HORROR • 3D TOP-DOWN • OFFLINE"
	subtitle.size = Vector2(cw, 18)
	subtitle.position = Vector2(0, 130)
	subtitle.add_theme_color_override("font_color", STEEL_TEXT)
	subtitle.add_theme_font_size_override("font_size", 10)
	subtitle.add_theme_constant_override("letter_spacing", 2)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_outline(subtitle)
	card.add_child(subtitle)
	var version := Label.new()
	version.text = "v0.1 prototype"
	version.size = Vector2(80, 16)
	version.position = Vector2(cw - 90, ch - 30)
	version.add_theme_color_override("font_color", Color(0.541, 0.451, 0.220, 0.5))
	version.add_theme_font_size_override("font_size", 8)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	card.add_child(version)
	var btn_data := [
		["ИГРАТЬ", 170, _on_start],
		["ПРОДОЛЖИТЬ", 226, _on_resume],
		["НАСТРОЙКИ", 282, _on_settings],
		["МАГАЗИН", 338, _on_shop],
		["МУЛЬТИПЛЕЕР", 394, _on_multiplayer],
		["ВЫХОД", 450, _on_quit],
	]
	var btns_arr := []
	var stagger_tween := create_tween()
	for i in btn_data.size():
		var b: Array = btn_data[i]
		match b[0]:
			"ИГРАТЬ": b[0] = tr("new_game").to_upper()
			"ПРОДОЛЖИТЬ": b[0] = tr("continue").to_upper()
			"НАСТРОЙКИ": b[0] = tr("settings").to_upper()
			"МАГАЗИН": b[0] = tr("shop").to_upper()
			"МУЛЬТИПЛЕЕР": b[0] = tr("multiplayer").to_upper()
			"ВЫХОД": b[0] = tr("quit").to_upper()
		var btn_w := 260 if b[0] == "ИГРАТЬ" else 220
		var btn := _make_btn(b[0], Vector2(cw / 2.0 - btn_w / 2.0, b[1]), Vector2(btn_w, 44))
		if b[0] == "ИГРАТЬ":
			btn.add_theme_font_size_override("font_size", 15)
		btn.pressed.connect(b[2])
		btn.modulate = Color(1, 1, 1, 0)
		btn.position.y += 20
		card.add_child(btn)
		btns_arr.append(btn)
		stagger_tween.set_parallel(true)
		stagger_tween.tween_property(btn, "modulate:a", 1.0, 0.12).set_delay(i * 0.05)
		stagger_tween.tween_property(btn, "position:y", btn.position.y - 20, 0.12).set_delay(i * 0.05)
	var ash_method := "disabled"
	var ash_pass_removed := 1
	var ash_err := ""
	var ash: Node = null
	var try_ash := func():
		var a := GPUParticles2D.new()
		a.name = "AshParticles"
		a.amount = 40
		a.lifetime = 8.0
		a.one_shot = false
		a.explosiveness = 0.0
		a.preprocess = 2.0
		a.position = Vector2(cw * 0.5, 0)
		var apm := ParticleProcessMaterial.new()
		apm.color = Color(0.541, 0.451, 0.220, 0.15)
		apm.direction = Vector3(0, 1, 0)
		apm.spread = 45.0
		apm.gravity = Vector3(0, -2, 0)
		apm.initial_velocity_min = 5.0
		apm.initial_velocity_max = 15.0
		apm.scale_min = 0.3
		apm.scale_max = 0.8
		apm.lifetime_randomness = 0.5
		a.process_material = apm
		var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 1, 1, 1))
		a.texture = ImageTexture.create_from_image(img)
		card.add_child(a)
		ash = a
	if card.get_child_count() > 0:
		try_ash.call()
		if ash != null:
			ash_method = "texture"
		else:
			ash_method = "disabled"
			ash_err = "particles_not_created"

	var btn_conn := 0
	for b in btns_arr:
		btn_conn += b.get_signal_connection_list("pressed").size()
	var has_close := false
	for c in card.get_children():
		if c is Button and c.text.find("ЗАКРЫТЬ") >= 0:
			has_close = true
			break
	var layer_bg := find_child("MenuBG", true, false) as ColorRect
	var layer_covers := false
	if layer_bg:
		var vr2 := get_viewport().get_visible_rect()
		var mr2 := layer_bg.get_global_rect()
		layer_covers = (mr2.position.x <= vr2.position.x + 1 and mr2.position.y <= vr2.position.y + 1 and mr2.size.x >= vr2.size.x - 2 and mr2.size.y >= vr2.size.y - 2)
	var bg_fullrect := layer_covers



func build_Loading(content: ColorRect, card: ColorRect, cw: float, ch: float, d: Dictionary) -> void:
	var load_title := Label.new()
	load_title.text = "ЗАГРУЗКА.. 0%"
	load_title.size = Vector2(content.size.x, 24)
	load_title.position = Vector2(0, 10)
	load_title.add_theme_color_override("font_color", BONE_TEXT)
	load_title.add_theme_font_size_override("font_size", 16)
	load_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_outline(load_title)
	content.add_child(load_title)
	var bar_bg := ColorRect.new()
	bar_bg.color = PANEL_EDGE
	bar_bg.size = Vector2(200, 8)
	bar_bg.position = Vector2(content.size.x / 2.0 - 100, 44)
	content.add_child(bar_bg)
	var bar_fill := ColorRect.new()
	bar_fill.color = BRASS
	bar_fill.size = Vector2(0, 8)
	bar_fill.position = Vector2(content.size.x / 2.0 - 100, 44)
	content.add_child(bar_fill)
	var tip_data := [
		"Свет не только защищает вас от монстров, но и открывает новые пути.",
		"Чем больше света, тем меньше монстров.",
		"Тишина — твой союзник в темноте.",
	]
	var tip_lbl := Label.new()
	tip_lbl.text = tip_data[0]
	tip_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip_lbl.size = Vector2(content.size.x - 40, 60)
	tip_lbl.position = Vector2(20, 70)
	tip_lbl.add_theme_color_override("font_color", STEEL_TEXT)
	tip_lbl.add_theme_font_size_override("font_size", 11)
	tip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_outline(tip_lbl)
	content.add_child(tip_lbl)
	var loading_tween := create_tween()
	loading_tween.tween_method(func(v):
		bar_fill.size.x = v * 200
		load_title.text = "ЗАГРУЗКА.. " + str(int(v * 100)) + "%"
	, 0.0, 1.0, 1.4)
	loading_tween.tween_callback(_on_loading_done)
	var tip_idx := 0
	var tip_tween := create_tween()
	tip_tween.set_loops()
	tip_tween.tween_interval(4.0)
	tip_tween.tween_callback(func():
		tip_idx = (tip_idx + 1) % tip_data.size()
		tip_lbl.modulate = Color(1, 1, 1, 0)
		tip_lbl.text = tip_data[tip_idx]
		var cross := create_tween()
		cross.tween_property(tip_lbl, "modulate:a", 1.0, 0.5)
	)

func build_Pause(card: ColorRect, cw: float, ch: float) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.047, 0.063, 0.086, 0.6)
	overlay.size = Vector2(cw, ch)
	overlay.position = Vector2(0, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(overlay)
	var btn_data := [
		["ПРОДОЛЖИТЬ", _on_resume],
		["ЖУРНАЛ ЗАДАНИЙ", _on_quest_journal],
		["НАСТРОЙКИ", _on_settings],
		["ГЛАВНОЕ МЕНЮ", _on_mainmenu],
	]
	for i in btn_data.size():
		_add_btn(card, btn_data[i][0], Vector2(cw / 2.0 - 110, 80 + i * 55), Vector2(220, 42), btn_data[i][1])

## Список языков строится из LocalizationManager, а не из литерала на два пункта:
## поддерживается 13 локалей, и раньше 11 из них были недоступны из настроек.
func _lang_options() -> Array:
	var out: Array = []
	for code in LocalizationManager.SUPPORTED:
		out.append(String(LocalizationManager.LANG_NAMES.get(code, code)))
	return out

func _lang_label(code: String = "") -> String:
	if code == "":
		code = LocalizationManager.current_lang
	return String(LocalizationManager.LANG_NAMES.get(code, code))

func _lang_code(label: String) -> String:
	for code in LocalizationManager.SUPPORTED:
		if String(LocalizationManager.LANG_NAMES.get(code, code)) == label:
			return code
	return LocalizationManager.current_lang

func build_Settings(content: ColorRect, card: ColorRect, cw: float, ch: float) -> void:
	var tabs_data := [
		{
			"name": "ИГРА",
			"entries": [
				{"label": "Язык", "type": "dropdown", "value": _lang_label(), "options": _lang_options()},
				{"label": "Сложность", "type": "dropdown", "value": "Нормально", "options": ["Легко", "Нормально", "Сложно"]},
				{"label": "Автосохранение", "type": "toggle", "value": true},
				{"label": "Подсказки", "type": "toggle", "value": true},
			]
		},
		{
			"name": "УПРАВЛЕНИЕ",
			"entries": [
				{"label": "Чувствительность", "type": "slider", "value": 4.5, "min": 0.0, "max": 100.0, "step": 5.0, "suffix": "%"},
				{"label": "Инверсия Y", "type": "toggle", "value": false},
				{"label": "Угол камеры", "type": "dropdown", "value": "45°", "options": ["35°", "45°", "55°"]},
			]
		},
		{
			"name": "ГРАФИКА",
			"entries": [
				{"label": "Качество", "type": "dropdown", "value": "Высокое", "options": ["Низкое", "Среднее", "Высокое"]},
				{"label": "Разрешение", "type": "dropdown", "value": "100%", "options": ["75%", "100%", "150%"]},
				{"label": "Тени", "type": "dropdown", "value": "Высокие", "options": ["Низкие", "Средние", "Высокие"]},
				{"label": "Текстуры", "type": "dropdown", "value": "Высокие", "options": ["Низкие", "Средние", "Высокие"]},
				{"label": "Эффекты", "type": "dropdown", "value": "Высокие", "options": ["Низкие", "Средние", "Высокие"]},
				{"label": "Дальность прорисовки", "type": "slider", "value": 70.0, "min": 0.0, "max": 100.0, "step": 5.0, "suffix": "%"},
				{"label": "VSync", "type": "toggle", "value": true},
				{"label": "FPS", "type": "dropdown", "value": "60", "options": ["30", "60", "120"]},
			]
		},
		{
			"name": "ЗВУК",
			"entries": [
				{"label": "Мастер", "type": "slider", "value": 80.0, "min": 0.0, "max": 100.0, "step": 1.0, "suffix": "%"},
				{"label": "Музыка", "type": "slider", "value": 70.0, "min": 0.0, "max": 100.0, "step": 1.0, "suffix": "%"},
				{"label": "SFX", "type": "slider", "value": 85.0, "min": 0.0, "max": 100.0, "step": 1.0, "suffix": "%"},
				{"label": "Голоса", "type": "slider", "value": 70.0, "min": 0.0, "max": 100.0, "step": 1.0, "suffix": "%"},
			]
		},
	]
	var tc := TabContainer.new()
	tc.size = Vector2(content.size.x, content.size.y - 50)
	tc.position = Vector2(0, 0)
	tc.add_theme_color_override("font_color", BONE_TEXT)
	tc.add_theme_color_override("tab_fg", PANEL_COLOR)
	content.add_child(tc)
	var controls := {}
	for tab in tabs_data:
		var page := VBoxContainer.new()
		page.name = tab.name
		tc.add_child(page)
		for entry in tab.entries:
			var row := HBoxContainer.new()
			row.size = Vector2(tc.size.x - 20, 30)
			page.add_child(row)
			var lbl := Label.new()
			lbl.text = entry.label
			lbl.size = Vector2(150, 24)
			lbl.add_theme_color_override("font_color", STEEL_TEXT)
			lbl.add_theme_font_size_override("font_size", 13)
			_apply_outline(lbl)
			row.add_child(lbl)
			match entry.type:
				"toggle":
					var cb := CheckButton.new()
					cb.button_pressed = entry.value
					row.add_child(cb)
					controls[entry.label] = {"type": "toggle", "node": cb}
				"dropdown":
					var ob := OptionButton.new()
					ob.size = Vector2(140, 24)
					for opt in entry.options:
						ob.add_item(opt)
					var idx: int = 0
					for k in entry.options.size():
						if entry.options[k] == entry.value:
							idx = k
							break
					ob.select(idx)
					row.add_child(ob)
					controls[entry.label] = {"type": "dropdown", "node": ob}
					if entry.label == "Язык":
						ob.item_selected.connect(func(_idx: int):
							var code := _lang_code(ob.get_item_text(_idx))
							# Через LocalizationManager, а не голым set_locale():
							# иначе локаль сменится без загрузки словаря и весь
							# UI покажет сырые ключи.
							LocalizationManager.set_language(code)
							SettingsManager.apply_game({"language": code})
						)

				"slider":
					var hs := HSlider.new()
					hs.size = Vector2(100, 24)
					hs.min_value = entry.min
					hs.max_value = entry.max
					hs.step = entry.step
					hs.value = entry.value
					row.add_child(hs)
					var val_lbl := Label.new()
					var sfx: String = entry.get("suffix", "")
					val_lbl.text = str(entry.value) + sfx
					val_lbl.add_theme_color_override("font_color", BRASS)
					val_lbl.add_theme_font_size_override("font_size", 11)
					row.add_child(val_lbl)
					controls[entry.label] = {"type": "slider", "node": hs, "label": val_lbl}
					hs.value_changed.connect(func(v):
						val_lbl.text = str(v) + sfx
						if tab.name == "ЗВУК":
							SettingsManager.set_volume(entry.label, v / 100.0)
					)

	if controls.has("VSync"):
		var cb: CheckButton = controls["VSync"].node
		cb.toggled.connect(func(on):
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if on else DisplayServer.VSYNC_DISABLED)
		)

	if controls.has("FPS"):
		var ob: OptionButton = controls["FPS"].node
		ob.item_selected.connect(func(idx):
			Engine.max_fps = int(ob.get_item_text(idx))
		)

	if controls.has("Тени"):
		var ob: OptionButton = controls["Тени"].node
		ob.item_selected.connect(func(idx):
			var val := ob.get_item_text(idx)
			var moon := get_tree().root.find_child("Moon", true, false) as DirectionalLight3D
			if moon:
				moon.shadow_enabled = val in ["Средние", "Высокие"]
		)

	if controls.has("Качество"):
		var ob: OptionButton = controls["Качество"].node
		ob.item_selected.connect(func(idx):
			var val := ob.get_item_text(idx)
			var env := get_tree().root.get_node_or_null("WorldEnvironment")
			if env and env.environment:
				env.environment.glow_enabled = val in ["Среднее", "Высокое"]
				env.environment.ssao_enabled = val == "Высокое"
		)

	var btn_y := content.size.y - 44
	_add_btn(content, "ПРИМЕНИТЬ", Vector2(10, btn_y), Vector2(120, 34), func():
		# controls[] ключуется подписями ползунков, а не именами шин: раньше
		# список ["Master","Music","SFX","Голоса"] совпадал только с двумя из
		# четырёх, и громкость применялась частично.
		for bus_label in ["Мастер", "Музыка", "SFX", "Голоса"]:
			if controls.has(bus_label):
				SettingsManager.set_volume(bus_label, controls[bus_label].node.value / 100.0)
		var quality_val: String = controls["Качество"].node.get_item_text(controls["Качество"].node.selected)
		var shadows_val: String = controls["Тени"].node.get_item_text(controls["Тени"].node.selected)
		SettingsManager.apply_graphics({
			"quality": quality_val,
			"shadows": shadows_val,
			"vsync": controls["VSync"].node.button_pressed,
			"fps": int(controls["FPS"].node.get_item_text(controls["FPS"].node.selected)),
		})
		SettingsManager.apply_controls({
			"sensitivity": controls["Чувствительность"].node.value,
			"invert_y": controls["Инверсия Y"].node.button_pressed,
			"camera_angle": controls["Угол камеры"].node.get_item_text(controls["Угол камеры"].node.selected),
		})
		SettingsManager.apply_game({
			"language": _lang_code(controls["Язык"].node.get_item_text(controls["Язык"].node.selected)),
			"difficulty": controls["Сложность"].node.get_item_text(controls["Сложность"].node.selected),
			"autosave": controls["Автосохранение"].node.button_pressed,
			"hints": controls["Подсказки"].node.button_pressed,
		})
		SettingsManager.save_to_cfg()
		_show_toast("НАСТРОЙКИ ПРИМЕНЕНЫ")
	)

	_add_btn(content, "ПО УМОЛЧАНИЮ", Vector2(140, btn_y), Vector2(130, 34), func():
		var defaults := {
			"Язык": _lang_label(), "Сложность": "Нормально",
			"Автосохранение": true, "Подсказки": true,
			"Чувствительность": 4.5, "Инверсия Y": false, "Угол камеры": "45°",
			"Качество": "Высокое", "Разрешение": "100%", "Тени": "Высокие", "Текстуры": "Высокие",
			"Эффекты": "Высокие", "Дальность прорисовки": 70.0, "VSync": true, "FPS": "60",
			"Мастер": 80.0, "Музыка": 70.0, "SFX": 85.0, "Голоса": 70.0,
		}
		for label in defaults:
			if not controls.has(label):
				continue
			var c: Dictionary = controls[label]
			match c.type:
				"toggle":
					c.node.button_pressed = defaults[label]
				"dropdown":
					var ob: OptionButton = c.node
					var def_val: String = defaults[label]
					for i in ob.item_count:
						if ob.get_item_text(i) == def_val:
							ob.select(i)
							break
				"slider":
					c.node.value = defaults[label]
					c.label.text = str(defaults[label]) + "%"
		SettingsManager.set_volume("Master", 0.8)
		SettingsManager.set_volume("Music", 0.7)
		SettingsManager.set_volume("SFX", 0.85)
		SettingsManager.set_volume("Голоса", 0.7)
		var env := get_tree().root.get_node_or_null("WorldEnvironment")
		if env and env.environment:
			env.environment.glow_enabled = true
			env.environment.ssao_enabled = true
		var moon := get_tree().root.find_child("Moon", true, false) as DirectionalLight3D
		if moon:
			moon.shadow_enabled = true
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		Engine.max_fps = 60
		SettingsManager.save_to_cfg()
		_show_toast("НАСТРОЙКИ СБРОШЕНЫ")
	)

	_add_btn(content, "НАЗАД", Vector2(content.size.x - 120, btn_y), Vector2(110, 34), func():
		show_screen("Pause")
	)

func build_Inventory(content: ColorRect, card: ColorRect, cw: float, ch: float) -> void:
	var inv2 := get_tree().root.get_node_or_null("InventoryManager")
	var cur_w: float = inv2.current_weight if inv2 else 0.0
	var cap_w: float = inv2.stats.capacity_kg if (inv2 and inv2.stats) else 40.0
	var weight_header := Label.new()
	weight_header.text = "Вес: " + str(cur_w) + " / " + str(cap_w) + " кг"
	weight_header.size = Vector2(content.size.x, 20)
	weight_header.position = Vector2(0, 0)
	weight_header.add_theme_color_override("font_color", BRASS)
	weight_header.add_theme_font_size_override("font_size", 14)
	_apply_outline(weight_header)
	content.add_child(weight_header)
	var weight_bar_bg := ColorRect.new()
	weight_bar_bg.color = PANEL_EDGE
	weight_bar_bg.size = Vector2(content.size.x, 6)
	weight_bar_bg.position = Vector2(0, 22)
	content.add_child(weight_bar_bg)
	var weight_fill := ColorRect.new()
	weight_fill.color = STAMINA_GREEN
	weight_fill.size = Vector2(content.size.x * 0.71, 6)
	weight_fill.position = Vector2(0, 22)
	content.add_child(weight_fill)
	var inv_real := absf(cur_w - 0.0) < 0.01

	var slot_ids := ["фонарик", "батарейки", "аптечка", "ключ", "кабель", "предохранитель", "инструмент", "документ"]
	var cols := 4
	var slot_size := 64
	var gap := 8
	var start_x := (content.size.x - (slot_size * cols + gap * (cols - 1))) / 2.0
	var start_y := 40.0
	for i in slot_ids.size():
		var row := i / cols
		var col := i % cols
		var slot := ColorRect.new()
		slot.color = PANEL_COLOR
		slot.size = Vector2(slot_size, slot_size)
		slot.position = Vector2(start_x + col * (slot_size + gap), start_y + row * (slot_size + gap))
		slot.add_theme_color_override("frame_color", PANEL_EDGE)
		content.add_child(slot)
		var placeholder := ColorRect.new()
		placeholder.color = BRASS_DIM
		placeholder.size = Vector2(40, 40)
		placeholder.position = Vector2(12, 12)
		slot.add_child(placeholder)
		var badge := Label.new()
		badge.text = slot_ids[i][0]
		badge.size = Vector2(slot_size, 16)
		badge.position = Vector2(0, slot_size - 16)
		badge.add_theme_color_override("font_color", STEEL_TEXT)
		badge.add_theme_font_size_override("font_size", 8)
		slot.add_child(badge)
	var qa_y := start_y + 2 * (slot_size + gap) + 10
	var qa_label := Label.new()
	qa_label.text = "БЫСТРЫЙ ДОСТУП"
	qa_label.size = Vector2(content.size.x, 18)
	qa_label.position = Vector2(0, qa_y)
	qa_label.add_theme_color_override("font_color", BONE_TEXT)
	qa_label.add_theme_font_size_override("font_size", 12)
	_apply_outline(qa_label)
	content.add_child(qa_label)
	var qa_start_y := qa_y + 22
	var qa_slots := 6
	var qa_total_w := qa_slots * (slot_size + gap) - gap
	var qa_start_x := (content.size.x - qa_total_w) / 2.0
	for i in qa_slots:
		var slot := ColorRect.new()
		slot.color = PANEL_COLOR
		slot.size = Vector2(slot_size, slot_size)
		slot.position = Vector2(qa_start_x + i * (slot_size + gap), qa_start_y)
		content.add_child(slot)

func _hex_points(cx: float, cy: float, s: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 6:
		var a := deg_to_rad(60.0 * i - 30.0)
		pts.append(Vector2(cx + s * cos(a), cy + s * sin(a)))
	return pts

func build_CityMap(content: ColorRect, card: ColorRect, cw: float, ch: float, _data: Dictionary) -> void:
	var districts := [
		{"id": "suburb", "name": "Пригород", "percent": 72, "threat": "низкий", "connections": ["residential", "park"]},
		{"id": "residential", "name": "Жилые кварталы", "percent": 48, "threat": "средний", "connections": ["suburb", "park", "school", "hospital"]},
		{"id": "park", "name": "Парк", "percent": 35, "threat": "средний", "connections": ["suburb", "residential", "school"]},
		{"id": "school", "name": "Школа", "percent": 15, "threat": "высокий", "connections": ["residential", "park", "hospital"]},
		{"id": "hospital", "name": "Больница", "percent": 20, "threat": "высокий", "connections": ["residential", "school", "policestation"]},
		{"id": "policestation", "name": "Полицейский участок", "percent": 60, "threat": "средний", "connections": ["hospital", "warehouse", "gasstation"]},
		{"id": "gasstation", "name": "АЗС", "percent": 0, "threat": "критический", "connections": ["policestation", "warehouse"]},
		{"id": "warehouse", "name": "Складской комплекс", "percent": 10, "threat": "высокий", "connections": ["policestation", "industrial", "gasstation"]},
		{"id": "industrial", "name": "Промышленная зона", "percent": 5, "threat": "критический", "connections": ["warehouse", "substation", "powerplant"]},
		{"id": "substation", "name": "Подстанция", "percent": 25, "threat": "высокий", "connections": ["industrial", "powerplant"]},
		{"id": "powerplant", "name": "Электростанция", "percent": 0, "threat": "критический", "connections": ["industrial", "substation"]},
	]
	var map_container := Control.new()
	map_container.size = Vector2(content.size.x - 130, content.size.y)
	map_container.position = Vector2(0, 0)
	content.add_child(map_container)
	var hex_s := 32.0
	var positions := {
		"suburb": Vector2(80, 200), "residential": Vector2(180, 160), "park": Vector2(120, 80),
		"school": Vector2(230, 80), "hospital": Vector2(250, 200), "policestation": Vector2(360, 120),
		"gasstation": Vector2(300, 320), "warehouse": Vector2(410, 220), "industrial": Vector2(500, 140),
		"substation": Vector2(520, 280), "powerplant": Vector2(600, 200),
	}
	var by_id := {}
	for dist in districts:
		by_id[dist["id"]] = dist
	for dist in districts:
		var c: Vector2 = positions.get(dist["id"], Vector2.ZERO)
		for conn_id in dist["connections"]:
			if by_id.has(conn_id) and positions.has(conn_id):
				var t: Vector2 = positions.get(conn_id, Vector2.ZERO)
				var line := Line2D.new()
				line.points = PackedVector2Array([c, t])
				line.width = 2.0
				var pct: float = dist.get("percent", 0.0) as float
				if pct >= 60:
					line.default_color = Color(0.373, 0.541, 0.306)
				elif pct >= 20:
					line.default_color = Color(0.788, 0.635, 0.290, 0.5)
				else:
					line.default_color = Color(0.706, 0.271, 0.184, 0.4)
				map_container.add_child(line)
	for dist in districts:
		var c: Vector2 = positions.get(dist["id"], Vector2.ZERO)
		var poly := Polygon2D.new()
		poly.polygon = _hex_points(c.x, c.y, hex_s)
		var pct: float = dist.get("percent", 0.0) as float
		var fill: Color
		var border: Color
		if pct >= 60:
			fill = Color(0.373, 0.541, 0.306, 0.25)
			border = Color(0.373, 0.541, 0.306)
		elif pct >= 20:
			fill = Color(0.788, 0.635, 0.290, 0.25)
			border = Color(0.788, 0.635, 0.290)
		elif pct > 0:
			fill = Color(0.706, 0.271, 0.184, 0.25)
			border = Color(0.706, 0.271, 0.184)
		else:
			fill = Color(0.165, 0.200, 0.251, 0.25)
			border = Color(0.165, 0.200, 0.251)
		poly.color = fill
		map_container.add_child(poly)
		var border_line := Line2D.new()
		var hex_pts := _hex_points(c.x, c.y, hex_s)
		border_line.points = hex_pts
		border_line.closed = true
		border_line.width = 2.0
		border_line.default_color = border
		map_container.add_child(border_line)
		var pct_lbl := Label.new()
		pct_lbl.text = str(pct) + "%"
		pct_lbl.size = Vector2(40, 18)
		pct_lbl.position = c - Vector2(20, 8)
		pct_lbl.add_theme_color_override("font_color", Color(0.847, 0.824, 0.769))
		pct_lbl.add_theme_font_size_override("font_size", 11)
		pct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		map_container.add_child(pct_lbl)
		var nm_lbl := Label.new()
		nm_lbl.text = dist["name"]
		nm_lbl.size = Vector2(64, 14)
		nm_lbl.position = c - Vector2(32, 14)
		nm_lbl.add_theme_color_override("font_color", Color(0.682, 0.714, 0.749))
		nm_lbl.add_theme_font_size_override("font_size", 7)
		nm_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		map_container.add_child(nm_lbl)
	var player_marker := Polygon2D.new()
	var ms := 6.0
	var md := PackedVector2Array([Vector2(0, -ms), Vector2(ms, 0), Vector2(0, ms), Vector2(-ms, 0)])
	player_marker.polygon = md
	player_marker.color = Color(0.788, 0.635, 0.290)
	player_marker.position = positions["suburb"]
	player_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_container.add_child(player_marker)
	var legend_container := Control.new()
	legend_container.size = Vector2(120, content.size.y)
	legend_container.position = Vector2(content.size.x - 125, 0)
	content.add_child(legend_container)
	var legend_items := [
		["ВАШЕ ПОЛОЖЕНИЕ", Color(0.788, 0.635, 0.290)],
		["АКТИВНОЕ ЗАДАНИЕ", Color(0.541, 0.451, 0.220)],
		["ВОССТАНОВЛЕН", Color(0.373, 0.541, 0.306)],
		["ЧАСТИЧНО", Color(0.788, 0.635, 0.290)],
		["ТЁМНЫЙ", Color(0.706, 0.271, 0.184)],
		["ЗАБЛОКИРОВАН", Color(0.165, 0.200, 0.251)],
	]
	var li_y := 10.0
	for li in legend_items:
		var item: Array = li
		var dot := ColorRect.new()
		dot.color = item[1]
		dot.size = Vector2(8, 8)
		dot.position = Vector2(10, li_y)
		legend_container.add_child(dot)
		var lbl := Label.new()
		lbl.text = item[0]
		lbl.size = Vector2(100, 16)
		lbl.position = Vector2(22, li_y)
		lbl.add_theme_color_override("font_color", Color(0.682, 0.714, 0.749))
		lbl.add_theme_font_size_override("font_size", 8)
		legend_container.add_child(lbl)
		li_y += 18
	legend_container.add_child(player_marker)
	var hex0 := _hex_points(positions.get("suburb", Vector2.ZERO).x, positions.get("suburb", Vector2.ZERO).y, hex_s)
	var hex0_str := ""
	for i in min(6, hex0.size()):
		if i > 0: hex0_str += ","
		hex0_str += "(" + str(hex0[i].x) + "," + str(hex0[i].y) + ")"

	var legend_rect := Rect2(legend_container.position.x, legend_container.position.y, legend_container.size.x, legend_container.size.y)
	var overlap := false
	for dist in districts:
		var cp: Vector2 = positions.get(dist["id"], Vector2.ZERO)
		if legend_rect.has_point(cp):
			overlap = true
			break
	var toggle_y := content.size.y - 28
	_add_btn(content, "ПРОГРЕСС", Vector2(content.size.x / 2.0 - 100, toggle_y), Vector2(95, 24), func(): _show_toast("РЕЖИМ ПРОГРЕССА"))
	_add_btn(content, "УГРОЗА", Vector2(content.size.x / 2.0 + 5, toggle_y), Vector2(95, 24), func(): _show_toast("РЕЖИМ УГРОЗЫ"))

func build_Journal(content: ColorRect, card: ColorRect, cw: float, ch: float) -> void:
	var tab_data := [tr("JOURNAL_TAB_QUESTS"), tr("JOURNAL_TAB_DOCUMENTS"), tr("JOURNAL_TAB_NOTES")]
	var tab_bar := HBoxContainer.new()
	tab_bar.size = Vector2(content.size.x, 28)
	tab_bar.position = Vector2(0, 0)
	content.add_child(tab_bar)
	var active_tab := 0
	var tab_btns := []
	for i in tab_data.size():
		var btn := Button.new()
		btn.text = tab_data[i]
		btn.flat = true
		btn.add_theme_color_override("font_color", STEEL_TEXT)
		btn.add_theme_font_size_override("font_size", 11)
		btn.custom_minimum_size = Vector2(content.size.x / tab_data.size(), 24)
		tab_bar.add_child(btn)
		tab_btns.append(btn)
	var scroll_container := ScrollContainer.new()
	scroll_container.size = Vector2(content.size.x * 0.45, content.size.y - 40)
	scroll_container.position = Vector2(0, 32)
	scroll_container.mouse_filter = Control.MOUSE_FILTER_PASS
	content.add_child(scroll_container)
	var preview := ColorRect.new()
	preview.color = Color(0.847, 0.824, 0.769, 0.12)
	preview.size = Vector2(content.size.x * 0.45, content.size.y - 60)
	preview.position = Vector2(content.size.x * 0.5, 32)
	preview.mouse_filter = Control.MOUSE_FILTER_PASS
	content.add_child(preview)
	var preview_list := VBoxContainer.new()
	preview_list.size = Vector2(preview.size.x - 10, preview.size.y - 10)
	preview_list.position = Vector2(5, 5)
	preview.add_child(preview_list)
	var list_vbox := VBoxContainer.new()
	scroll_container.add_child(list_vbox)
	var quest_mgr := get_tree().root.get_node_or_null("QuestManager")
	var quest_entries := []
	var doc_entries := []
	var note_entries := []
	if quest_mgr:
		for qid in quest_mgr.quests:
			var q = quest_mgr.quests[qid]
			var status := " [DONE]" if q.done else " [" + str(q.progress) + "/" + str(q.target_count) + "]"
			quest_entries.append(q.title + status)
	doc_entries = ["doc_engineer_log", "doc_family_letter"]
	note_entries = [tr("JOURNAL_TAB_NOTES")]
	var all_lists := [quest_entries, doc_entries, note_entries]
	var page_count := 0
	for lst in all_lists:
		page_count += lst.size()
	var pagination_left_arrow := Button.new()
	pagination_left_arrow.text = "<"
	pagination_left_arrow.size = Vector2(28, 24)
	pagination_left_arrow.position = Vector2(content.size.x / 2.0 - 70, 6)
	_setup_btn_hover(pagination_left_arrow)
	content.add_child(pagination_left_arrow)
	var pagination := Label.new()
	pagination.text = str(1) + " / " + str(page_count)
	pagination.size = Vector2(80, 20)
	pagination.position = Vector2(content.size.x / 2.0 - 40, 8)
	pagination.add_theme_color_override("font_color", BRASS)
	pagination.add_theme_font_size_override("font_size", 12)
	pagination.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(pagination)
	var pagination_right_arrow := Button.new()
	pagination_right_arrow.text = ">"
	pagination_right_arrow.size = Vector2(28, 24)
	pagination_right_arrow.position = Vector2(content.size.x / 2.0 + 42, 6)
	_setup_btn_hover(pagination_right_arrow)
	content.add_child(pagination_right_arrow)
	var current_page := 0
	var rebuild_list := func():
		for c in list_vbox.get_children():
			c.queue_free()
		var entries = all_lists[active_tab]
		for e in entries:
			var row := ColorRect.new()
			row.color = Color(0, 0, 0, 0)
			row.size = Vector2(scroll_container.size.x, 32)
			list_vbox.add_child(row)
			var lbl := Label.new()
			lbl.text = e
			lbl.size = Vector2(row.size.x - 10, 28)
			lbl.position = Vector2(5, 2)
			lbl.add_theme_color_override("font_color", STEEL_TEXT)
			lbl.add_theme_font_size_override("font_size", 11)
			_apply_outline(lbl)
			row.add_child(lbl)
		pagination.text = str(1) + " / " + str(page_count)
		for c in preview_list.get_children():
			c.queue_free()
		if active_tab == 0 and quest_mgr:
			for qid in quest_mgr.quests:
				var q = quest_mgr.quests[qid]
				var desc_lbl := Label.new()
				desc_lbl.text = q.desc
				desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				desc_lbl.size = Vector2(preview_list.size.x, 40)
				desc_lbl.add_theme_color_override("font_color", STEEL_TEXT)
				desc_lbl.add_theme_font_size_override("font_size", 10)
				preview_list.add_child(desc_lbl)
	rebuild_list.call()
	for i in tab_btns.size():
		tab_btns[i].pressed.connect(func(idx := i):
			active_tab = idx
			rebuild_list.call()
		)

	var crossfade := false
	pagination_left_arrow.pressed.connect(func():
		current_page = maxi(0, current_page - 1)
		if crossfade:
			for c in preview_list.get_children():
				c.queue_free()
		pagination.text = str(current_page + 1) + " / " + str(page_count)
	)

	pagination_right_arrow.pressed.connect(func():
		current_page = mini(page_count - 1, current_page + 1)
		if crossfade:
			for c in preview_list.get_children():
				c.queue_free()
		pagination.text = str(current_page + 1) + " / " + str(page_count)
	)

func build_QuestJournal(content: ColorRect, card: ColorRect, cw: float, ch: float) -> void:
	var qj_script := load("res://scripts/ui/quest_journal.gd")
	if qj_script:
		var qj_instance: Control = qj_script.new()
		qj_instance.name = "QuestJournal"
		qj_instance.set_anchors_preset(Control.PRESET_FULL_RECT)
		content.add_child(qj_instance)

func build_Tutorial(content: ColorRect, card: ColorRect, cw: float, ch: float) -> void:
	var tut_script := load("res://scripts/ui/tutorial_system.gd")
	if tut_script:
		var tut_instance: Control = tut_script.new()
		tut_instance.name = "Tutorial"
		tut_instance.set_anchors_preset(Control.PRESET_FULL_RECT)
		content.add_child(tut_instance)

func build_Achievements(content: ColorRect, card: ColorRect, cw: float, ch: float) -> void:
	var header := Label.new()
	header.text = "ПРОГРЕСС ДОСТИЖЕНИЙ 28/56 (50%)"
	header.size = Vector2(content.size.x, 22)
	header.position = Vector2(0, 0)
	header.add_theme_color_override("font_color", BRASS)
	header.add_theme_font_size_override("font_size", 14)
	_apply_outline(header)
	content.add_child(header)
	var bar_bg := ColorRect.new()
	bar_bg.color = PANEL_EDGE
	bar_bg.size = Vector2(content.size.x, 6)
	bar_bg.position = Vector2(0, 24)
	content.add_child(bar_bg)
	var bar_fill := ColorRect.new()
	bar_fill.color = BRASS
	bar_fill.size = Vector2(content.size.x * 0.5, 6)
	bar_fill.position = Vector2(0, 24)
	content.add_child(bar_fill)
	var achievements := [
		{"title": "Первый свет", "desc": "Включите первый фонарь", "date": "21.05.2025", "unlocked": true},
		{"title": "Исследователь", "desc": "Найдите 10 документов", "date": "18.05.2025", "unlocked": true},
		{"title": "Электрик", "desc": "Запустите 3 генератора", "date": "17.05.2025", "unlocked": true},
		{"title": "Невидимость", "desc": "Пройдите мимо монстра", "date": "15.05.2025", "unlocked": true},
		{"title": "Выживший", "desc": "Переживите первую ночь", "date": "14.05.2025", "unlocked": true},
		{"title": "Мастер света", "desc": "Восстановите 100 фонарей", "date": "", "unlocked": false},
	]
	var scroll := ScrollContainer.new()
	scroll.size = Vector2(content.size.x, content.size.y - 70)
	scroll.position = Vector2(0, 36)
	content.add_child(scroll)
	var vbox := VBoxContainer.new()
	vbox.size = Vector2(scroll.size.x, achievements.size() * 44)
	scroll.add_child(vbox)
	for a in achievements:
		var row := ColorRect.new()
		row.color = PANEL_COLOR
		row.size = Vector2(vbox.size.x, 40)
		vbox.add_child(row)
		var icon := ColorRect.new()
		icon.color = BRASS if a.unlocked else BRASS_DIM
		icon.size = Vector2(24, 24)
		icon.position = Vector2(6, 8)
		row.add_child(icon)
		var lbl := Label.new()
		lbl.text = a.title
		lbl.size = Vector2(160, 20)
		lbl.position = Vector2(38, 2)
		lbl.add_theme_color_override("font_color", BONE_TEXT if a.unlocked else BRASS_DIM)
		lbl.add_theme_font_size_override("font_size", 12)
		_apply_outline(lbl)
		row.add_child(lbl)
		var desc_lbl := Label.new()
		desc_lbl.text = a.desc
		desc_lbl.size = Vector2(160, 16)
		desc_lbl.position = Vector2(38, 22)
		desc_lbl.add_theme_color_override("font_color", STEEL_TEXT)
		desc_lbl.add_theme_font_size_override("font_size", 9)
		row.add_child(desc_lbl)
		if a.date != "":
			var date_lbl := Label.new()
			date_lbl.text = a.date
			date_lbl.size = Vector2(80, 16)
			date_lbl.position = Vector2(row.size.x - 90, 12)
			date_lbl.add_theme_color_override("font_color", BRASS_DIM)
			date_lbl.add_theme_font_size_override("font_size", 9)
			row.add_child(date_lbl)
	var show_hidden_y := content.size.y - 28
	_add_btn(content, "ПОКАЗАТЬ СКРЫТЫЕ", Vector2(content.size.x / 2.0 - 80, show_hidden_y), Vector2(160, 24), func(): _show_toast("СКРЫТЫХ ДОСТИЖЕНИЙ НЕТ"))

func build_Stats(content: ColorRect, card: ColorRect, cw: float, ch: float) -> void:
	var metrics := [
		{"value": "12ч47м", "label": "ВРЕМЯ В ИГРЕ"},
		{"value": "4/11", "label": "РАЙОНОВ"},
		{"value": "18/42", "label": "ДОКУМЕНТОВ"},
		{"value": "12/36", "label": "СЕКРЕТОВ"},
		{"value": "3/8", "label": "ПОДСТАНЦИЙ"},
	]
	var cards_per_row := 3
	var card_w := (content.size.x - 30) / cards_per_row
	var card_h := 80.0
	for i in metrics.size():
		var row := i / cards_per_row
		var col := i % cards_per_row
		var cx := 5 + col * (card_w + 10)
		var cy := 10 + row * (card_h + 10)
		var frame := ColorRect.new()
		frame.color = PANEL_COLOR
		frame.size = Vector2(card_w, card_h)
		frame.position = Vector2(cx, cy)
		content.add_child(frame)
		var val_lbl := Label.new()
		val_lbl.text = metrics[i].value
		val_lbl.size = Vector2(card_w, 36)
		val_lbl.position = Vector2(0, 8)
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		val_lbl.add_theme_color_override("font_color", BRASS)
		val_lbl.add_theme_font_size_override("font_size", 22)
		frame.add_child(val_lbl)
		var lbl := Label.new()
		lbl.text = metrics[i].label
		lbl.size = Vector2(card_w, 20)
		lbl.position = Vector2(0, 50)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", STEEL_TEXT)
		lbl.add_theme_font_size_override("font_size", 9)
		frame.add_child(lbl)

func build_Shop(content: ColorRect, card: ColorRect, cw: float, ch: float) -> void:
	_populate_shop(content, card)

func build_Death(card: ColorRect, cw: float, ch: float, d: Dictionary) -> void:
	var content: ColorRect = d.content
	if content:
		content.queue_free()
		d.content = null
	d.title_lbl.add_theme_color_override("font_color", EMPER)
	d.title_lbl.add_theme_font_size_override("font_size", 28)
	d.title_lbl.text = "ВЫ ПОГИБЛИ"
	var death_info := Label.new()
	var tracker := get_tree().root.get_node_or_null("ProgressTracker")
	var play_sec: int = int(GameManager.play_time) if GameManager else 0
	var time_str := "%02d:%02d:%02d" % [play_sec / 3600, (play_sec / 60) % 60, play_sec % 60]
	var docs_found: int = tracker.count_docs() if tracker else 0
	var dist_restored: int = tracker.get_stats().get("districts", 0) if tracker else 0
	death_info.text = "Продержались %s / Документов найдено %d / Восстановлено районов %d/11" % [time_str, docs_found, dist_restored]
	death_info.size = Vector2(cw - 40, 30)
	death_info.position = Vector2(20, 80)
	death_info.add_theme_color_override("font_color", STEEL_TEXT)
	death_info.add_theme_font_size_override("font_size", 11)
	_apply_outline(death_info)
	card.add_child(death_info)
	_add_btn(card, "ЗАГРУЗИТЬ СОХРАНЕНИЕ", Vector2(cw / 2.0 - 140, 140), Vector2(280, 42), _on_load)
	_add_btn(card, "ГЛАВНОЕ МЕНЮ", Vector2(cw / 2.0 - 110, 200), Vector2(220, 42), _on_mainmenu)

func build_Victory(content: ColorRect, card: ColorRect, cw: float, ch: float) -> void:
	var title := Label.new()
	title.text = tr("VICTORY_TITLE")
	title.size = Vector2(cw - 40, 48)
	title.position = Vector2(20, 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", BRASS)
	title.add_theme_font_size_override("font_size", 32)
	_apply_outline(title)
	content.add_child(title)
	var progress := get_tree().root.get_node_or_null("ProgressTracker")
	var time_str := "0:00"
	var docs_found := 0
	var secrets_found := 0
	var districts_restored := 0
	if progress:
		var total_sec := int(progress.time_played)
		var mins := total_sec / 60
		var secs := total_sec % 60
		time_str = str(mins) + ":" + ("%02d" % secs)
		docs_found = progress._docs.keys().size()
		secrets_found = progress.secrets
		districts_restored = 0
		for d in PowerGrid.all_districts():
			if d.stage >= 3:
				districts_restored += 1
	var stats := [
		[tr("VICTORY_TIME"), time_str],
		[tr("VICTORY_DOCUMENTS"), str(docs_found)],
		[tr("VICTORY_SECRETS"), str(secrets_found)],
		[tr("VICTORY_DISTRICTS"), str(districts_restored) + "/11"],
	]
	var sy := 72.0
	for s in stats:
		var lbl := Label.new()
		lbl.text = s[0] + ": " + s[1]
		lbl.size = Vector2(cw - 40, 24)
		lbl.position = Vector2(20, sy)
		content.add_child(lbl)
		lbl.add_theme_color_override("font_color", STEEL_TEXT)
		lbl.add_theme_font_size_override("font_size", 14)
		_apply_outline(lbl)
		sy += 32.0
	var btn_y := ch - 90
	_add_btn(card, tr("VICTORY_MAIN_MENU"), Vector2(cw / 2.0 - 130, btn_y), Vector2(120, 42), _on_mainmenu)
	_add_btn(card, tr("VICTORY_NEW_GAME"), Vector2(cw / 2.0 + 10, btn_y), Vector2(120, 42), _on_start)
	var cfg := ConfigFile.new()
	cfg.set_value("victory", "unlocked", true)
	var err = cfg.save("user://victory.cfg")
	if err != OK:
		pass

func build_Saves(content: ColorRect, card: ColorRect, cw: float, ch: float) -> void:
	var sm: Node = SaveSystem
	var slots_info: Array = [sm.get_slot_info(1), sm.get_slot_info(2), sm.get_slot_info(3)]
	var slot_y := 10
	for slot in range(1, 4):
		var si: Dictionary = slots_info[slot - 1]
		var slot_card := ColorRect.new()
		slot_card.color = PANEL_COLOR
		slot_card.size = Vector2(content.size.x - 20, 80)
		slot_card.position = Vector2(10, slot_y)
		content.add_child(slot_card)
		var slot_border := ColorRect.new()
		slot_border.color = PANEL_EDGE
		slot_border.size = Vector2(slot_card.size.x + 2, slot_card.size.y + 2)
		slot_border.position = Vector2(-1, -1)
		slot_card.add_child(slot_border)
		var slot_title := Label.new()
		slot_title.text = "СЛОТ " + str(slot)
		slot_title.size = Vector2(200, 20)
		slot_title.position = Vector2(10, 8)
		slot_title.add_theme_color_override("font_color", BONE_TEXT)
		slot_title.add_theme_font_size_override("font_size", 14)
		slot_card.add_child(slot_title)
		if si.exists:
			var time_str := Time.get_datetime_string_from_unix_time(si.modified, false) if si.modified > 0 else ""
			var exists_lbl := Label.new()
			exists_lbl.text = "Есть сохранение | " + time_str
			exists_lbl.size = Vector2(300, 18)
			exists_lbl.position = Vector2(10, 32)
			exists_lbl.add_theme_color_override("font_color", STEEL_TEXT)
			exists_lbl.add_theme_font_size_override("font_size", 10)
			slot_card.add_child(exists_lbl)
			_add_btn(slot_card, "ЗАГРУЗИТЬ", Vector2(content.size.x - 290, 40), Vector2(80, 22), func(s = slot):
				sm.load_slot(s)
				_show_toast("Загружено")
			)

			_add_btn(slot_card, "ПЕРЕЗАПИСАТЬ", Vector2(content.size.x - 200, 40), Vector2(90, 22), func(s = slot):
				sm.save_slot(s)
				_show_toast("Сохранено")
			)

			_add_btn(slot_card, "УДАЛИТЬ", Vector2(content.size.x - 100, 40), Vector2(70, 22), func(s = slot):
				sm.delete_slot(s)
				_show_toast("Удалено")
				for c in content.get_children():
					c.queue_free()
				build_Saves(content, card, cw, ch)
			)

		else:
			var empty_lbl := Label.new()
			empty_lbl.text = "ПУСТОЙ СЛОТ"
			empty_lbl.size = Vector2(200, 18)
			empty_lbl.position = Vector2(10, 32)
			empty_lbl.add_theme_color_override("font_color", BRASS_DIM)
			empty_lbl.add_theme_font_size_override("font_size", 10)
			slot_card.add_child(empty_lbl)
			_add_btn(slot_card, "СОХРАНИТЬ", Vector2(content.size.x - 100, 40), Vector2(80, 22), func(s = slot):
				sm.save_slot(s)
				_show_toast("Сохранено")
			)

		slot_y += 90

func build_Bestiary(content: ColorRect, card: ColorRect, cw: float, ch: float) -> void:
	var creatures := [
		{"id": "Shadow", "desc": "Быстрый и скрытный. Активно реагирует на свет и шум. Избегает открытых пространств.", "health": 60, "speed": 90, "weakness": "Свет", "met": 7, "total": 15},
		{"id": "Crawler", "desc": "Передвигается на четырёх конечностях. Появляется из темноты, атакует внезапно.", "health": 40, "speed": 70, "weakness": "Свет", "met": 5, "total": 12},
		{"id": "Watcher", "desc": "Высокий, худой. Наблюдает издалека, атакует при приближении к свету. Боится яркого света.", "health": 80, "speed": 50, "weakness": "Свет", "met": 4, "total": 10},
		{"id": "Hunter", "desc": "Целенаправленно преследует жертву. Реагирует на шум на большом расстоянии.", "health": 100, "speed": 75, "weakness": "Свет", "met": 3, "total": 8},
		{"id": "Destroyer", "desc": "Массивная неуязвимая машина разрушения. Появляется при критической угрозе.", "health": 200, "speed": 30, "weakness": "Свет", "met": 1, "total": 3},
		{"id": "Boss", "desc": "Финальный противник. Встречается в центре электростанции в финальную ночь.", "health": 500, "speed": 60, "weakness": "Свет", "met": 0, "total": 1},
	]
	var scroll := ScrollContainer.new()
	scroll.size = Vector2(content.size.x, content.size.y)
	scroll.position = Vector2(0, 0)
	content.add_child(scroll)
	var vbox := VBoxContainer.new()
	vbox.size = Vector2(scroll.size.x, creatures.size() * 110)
	scroll.add_child(vbox)
	for c in creatures:
		var frame := ColorRect.new()
		frame.color = PANEL_COLOR
		frame.size = Vector2(vbox.size.x - 10, 100)
		vbox.add_child(frame)
		var silhouette := ColorRect.new()
		silhouette.color = PANEL_EDGE
		silhouette.size = Vector2(64, 80)
		silhouette.position = Vector2(8, 10)
		frame.add_child(silhouette)
		var eye := ColorRect.new()
		eye.color = EMPER
		eye.size = Vector2(12, 6)
		eye.position = Vector2(26, 38)
		silhouette.add_child(eye)
		var name_lbl := Label.new()
		name_lbl.text = c.id
		name_lbl.size = Vector2(200, 22)
		name_lbl.position = Vector2(82, 6)
		name_lbl.add_theme_color_override("font_color", BONE_TEXT)
		name_lbl.add_theme_font_size_override("font_size", 14)
		_apply_outline(name_lbl)
		frame.add_child(name_lbl)
		var desc_lbl := Label.new()
		desc_lbl.text = c.desc
		desc_lbl.size = Vector2(vbox.size.x - 100, 36)
		desc_lbl.position = Vector2(82, 30)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_color_override("font_color", STEEL_TEXT)
		desc_lbl.add_theme_font_size_override("font_size", 9)
		frame.add_child(desc_lbl)
		var stats_lbl := Label.new()
		stats_lbl.text = "Здоровье: %d  Скорость: %d  Слабые стороны: %s  |  Встречено %d/%d" % [c.health, c.speed, c.weakness, c.met, c.total]
		stats_lbl.size = Vector2(vbox.size.x - 100, 18)
		stats_lbl.position = Vector2(82, 72)
		stats_lbl.add_theme_color_override("font_color", BRASS_DIM)
		stats_lbl.add_theme_font_size_override("font_size", 8)
		frame.add_child(stats_lbl)

func build_Character(content: ColorRect, card: ColorRect, cw: float, ch: float) -> void:
	var char_script := load("res://scripts/ui/character_screen.gd")
	if not char_script:
		_show_toast("ERROR: character script not found")
		return
	var char_ctrl := Control.new()
	char_ctrl.set_script(char_script)
	char_ctrl.size = content.size
	content.add_child(char_ctrl)

func build_FlashlightUpgrade(content: ColorRect, card: ColorRect, cw: float, ch: float) -> void:
	var params := [
		{"name": "Яркость", "level": 3, "max": 5},
		{"name": "Дальность", "level": 2, "max": 5},
		{"name": "Угол света", "level": 4, "max": 5},
		{"name": "Расход батареи", "level": 2, "max": 5},
		{"name": "Стабильность", "level": 3, "max": 5},
		{"name": "Ёмкость", "level": 2, "max": 5},
	]
	for i in params.size():
		var py := 5 + i * 30
		var lbl := Label.new()
		lbl.text = params[i].name
		lbl.size = Vector2(100, 22)
		lbl.position = Vector2(5, py)
		lbl.add_theme_color_override("font_color", STEEL_TEXT)
		lbl.add_theme_font_size_override("font_size", 12)
		_apply_outline(lbl)
		content.add_child(lbl)
		var bar_bg := ColorRect.new()
		bar_bg.color = PANEL_EDGE
		bar_bg.size = Vector2(120, 10)
		bar_bg.position = Vector2(110, py + 6)
		content.add_child(bar_bg)
		var bar_fill := ColorRect.new()
		bar_fill.color = BRASS
		bar_fill.size = Vector2(120 * params[i].level / params[i].max, 10)
		bar_fill.position = Vector2(110, py + 6)
		content.add_child(bar_fill)
		var level_lbl := Label.new()
		level_lbl.text = "%d/%d" % [params[i].level, params[i].max]
		level_lbl.size = Vector2(40, 22)
		level_lbl.position = Vector2(240, py)
		level_lbl.add_theme_color_override("font_color", BRASS_DIM)
		level_lbl.add_theme_font_size_override("font_size", 10)
		content.add_child(level_lbl)
	var preview_x := content.size.x - 120.0
	var preview_y := 10.0
	var preview_frame := ColorRect.new()
	preview_frame.color = PANEL_EDGE
	preview_frame.size = Vector2(100, 80)
	preview_frame.position = Vector2(preview_x, preview_y)
	content.add_child(preview_frame)
	var preview_lbl := Label.new()
	preview_lbl.text = "ФОНАРЬ"
	preview_lbl.size = Vector2(100, 20)
	preview_lbl.position = Vector2(0, 30)
	preview_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_lbl.add_theme_color_override("font_color", BRASS_DIM)
	preview_lbl.add_theme_font_size_override("font_size", 10)
	preview_frame.add_child(preview_lbl)
	var level_info := Label.new()
	level_info.text = "ТЕКУЩИЙ УРОВЕНЬ 3"
	level_info.size = Vector2(160, 20)
	level_info.position = Vector2(5, 190)
	level_info.add_theme_color_override("font_color", BONE_TEXT)
	level_info.add_theme_font_size_override("font_size", 12)
	_apply_outline(level_info)
	content.add_child(level_info)
	var cost_info := Label.new()
	cost_info.text = "СТОИМОСТЬ 2500"
	cost_info.size = Vector2(160, 20)
	cost_info.position = Vector2(5, 212)
	cost_info.add_theme_color_override("font_color", BRASS)
	cost_info.add_theme_font_size_override("font_size", 12)
	_apply_outline(cost_info)
	content.add_child(cost_info)
	_add_btn(content, "УЛУЧШИТЬ", Vector2(content.size.x / 2.0 - 60, content.size.y - 36), Vector2(120, 30), func(): _show_toast("УЛУЧШЕНИЕ ПРИМЕНЕНО"))

func build_PhotoMode(content: ColorRect, card: ColorRect, cw: float, ch: float, d: Dictionary) -> void:
	var photo := get_node_or_null("PhotoModeOverlay")
	if not photo:
		var photo_script := load("res://scripts/systems/photo_mode.gd")
		if not photo_script:
			_show_toast("ERROR: photo_mode script not found")
			return
		photo = Control.new()
		photo.name = "PhotoModeOverlay"
		photo.set_script(photo_script)
		photo.size = get_viewport().get_visible_rect().size
		add_child(photo)
	if photo.has_method("toggle"):
		photo.toggle()

func build_ControlsTouch(content: ColorRect, card: ColorRect, cw: float, ch: float) -> void:
	var phone_frame := ColorRect.new()
	phone_frame.color = PANEL_EDGE
	phone_frame.size = Vector2(120, 200)
	phone_frame.position = Vector2(10, 10)
	content.add_child(phone_frame)
	var screen := ColorRect.new()
	screen.color = PANEL_COLOR
	screen.size = Vector2(108, 188)
	screen.position = Vector2(6, 6)
	phone_frame.add_child(screen)
	var screen_lbl := Label.new()
	screen_lbl.text = "ТЕЛЕФОН"
	screen_lbl.size = Vector2(108, 20)
	screen_lbl.position = Vector2(0, 84)
	screen_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_lbl.add_theme_color_override("font_color", BRASS_DIM)
	screen_lbl.add_theme_font_size_override("font_size", 10)
	screen.add_child(screen_lbl)
	var controls := [
		{"label": "Фонарик", "value": "Действие"},
		{"label": "Действие", "value": "Стойка"},
		{"label": "Погода", "value": "День"},
		{"label": "Угол камеры", "value": "45°"},
		{"label": "Фильтр", "value": "Авто"},
	]
	var cx := 145.0
	var cy := 10.0
	for i in controls.size():
		var lbl := Label.new()
		lbl.text = controls[i].label
		lbl.size = Vector2(100, 18)
		lbl.position = Vector2(cx, cy + i * 26)
		lbl.add_theme_color_override("font_color", STEEL_TEXT)
		lbl.add_theme_font_size_override("font_size", 10)
		content.add_child(lbl)
		var val := Label.new()
		val.text = controls[i].value
		val.size = Vector2(80, 18)
		val.position = Vector2(cx + 105, cy + i * 26)
		val.add_theme_color_override("font_color", BRASS_DIM)
		val.add_theme_font_size_override("font_size", 10)
		content.add_child(val)
	var tip := Label.new()
	tip.text = "Совет: настройте расположение кнопок"
	tip.size = Vector2(content.size.x - 10, 18)
	tip.position = Vector2(5, content.size.y - 24)
	tip.add_theme_color_override("font_color", STEEL_TEXT)
	tip.add_theme_font_size_override("font_size", 9)
	content.add_child(tip)

func build_Weather(content: ColorRect, card: ColorRect, cw: float, ch: float) -> void:
	var weathers := [
		{"name": "Дождь", "effect": "Уменьшает видимость, увеличивает шум"},
		{"name": "Туман", "effect": "Сильно снижает видимость"},
		{"name": "Гроза", "effect": "Молнии привлекают монстров"},
		{"name": "Ветер", "effect": "Увеличивает уровень шума"},
	]
	var card_w := (content.size.x - 20) / 2.0
	var card_h := (content.size.y - 10) / 2.0
	for i in weathers.size():
		var col := i % 2
		var row := i / 2
		var cx := 5 + col * (card_w + 10)
		var cy := 5 + row * (card_h + 10)
		var frame := ColorRect.new()
		frame.color = PANEL_COLOR
		frame.size = Vector2(card_w, card_h)
		frame.position = Vector2(cx, cy)
		content.add_child(frame)
		var name_lbl := Label.new()
		name_lbl.text = weathers[i].name
		name_lbl.size = Vector2(card_w, 24)
		name_lbl.position = Vector2(0, 8)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_color_override("font_color", BONE_TEXT)
		name_lbl.add_theme_font_size_override("font_size", 16)
		_apply_outline(name_lbl)
		frame.add_child(name_lbl)
		var effect_lbl := Label.new()
		effect_lbl.text = weathers[i].effect
		effect_lbl.size = Vector2(card_w - 20, 36)
		effect_lbl.position = Vector2(10, 40)
		effect_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effect_lbl.add_theme_color_override("font_color", STEEL_TEXT)
		effect_lbl.add_theme_font_size_override("font_size", 10)
		effect_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		frame.add_child(effect_lbl)

func build_Workbench(content: ColorRect, card: ColorRect, cw: float, ch: float) -> void:
	var wb_script := load("res://scripts/ui/workbench.gd")
	if not wb_script:
		_show_toast("ERROR: workbench script not found")
		return
	var wb := Control.new()
	wb.set_script(wb_script)
	wb.size = content.size
	content.add_child(wb)

func build_PuzzleCables(content: ColorRect, card: ColorRect, cw: float, ch: float) -> void:
	var puzzle_script := load("res://scripts/ui/puzzle_cables.gd")
	if not puzzle_script:
		_show_toast("ERROR: puzzle script not found")
		return
	var puzzle := Control.new()
	puzzle.set_script(puzzle_script)
	puzzle.size = Vector2(content.size.x, content.size.y - 28)
	content.add_child(puzzle)
	puzzle.puzzle_solved.connect(func():
		_show_toast(tr("CABLE_SUCCESS"))
		var ps := get_tree().root.get_node_or_null("/root/PuzzleSystem")
		if ps and ps.has_method("mark_solved"):
			ps.mark_solved("cables_suburb")
	)

	puzzle.puzzle_failed.connect(func():
		_show_toast(tr("CABLE_FAIL"))
	)

	var goal := Label.new()
	goal.text = tr("CABLE_PUZZLE")
	goal.size = Vector2(content.size.x, 20)
	goal.position = Vector2(10, content.size.y - 28)
	goal.add_theme_color_override("font_color", STEEL_TEXT)
	goal.add_theme_font_size_override("font_size", 11)
	_apply_outline(goal)
	content.add_child(goal)
	var hint_btn := Button.new()
	hint_btn.text = "?"
	hint_btn.size = Vector2(28, 28)
	hint_btn.position = Vector2(content.size.x - 32, content.size.y - 30)
	content.add_child(hint_btn)
	hint_btn.pressed.connect(func():
		var p = content.get_child(0)
		if p and p.has_method("show_hint"):
			p.show_hint()
	)

func build_Radio(content: ColorRect, card: ColorRect, cw: float, ch: float) -> void:
	var radio_script := load("res://scripts/ui/radio.gd")
	if not radio_script:
		_show_toast("ERROR: radio script not found")
		return
	var radio := Control.new()
	radio.set_script(radio_script)
	radio.size = Vector2(content.size.x, content.size.y - 10)
	content.add_child(radio)

func build_StoryScene(card: ColorRect, cw: float, ch: float, d: Dictionary) -> void:
	var content: ColorRect = d.content
	if content:
		content.queue_free()
		d.content = null
	var preview := ColorRect.new()
	preview.color = PANEL_EDGE
	preview.size = Vector2(cw - 40, ch - 120)
	preview.position = Vector2(20, 56)
	card.add_child(preview)
	var preview_lbl := Label.new()
	preview_lbl.text = "СЦЕНА"
	preview_lbl.size = Vector2(preview.size.x, 24)
	preview_lbl.position = Vector2(0, preview.size.y / 2.0 - 12)
	preview_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_lbl.add_theme_color_override("font_color", BRASS_DIM)
	preview_lbl.add_theme_font_size_override("font_size", 18)
	preview.add_child(preview_lbl)
	var dialog_bar := ColorRect.new()
	dialog_bar.color = PANEL_COLOR
	dialog_bar.size = Vector2(cw - 40, 56)
	dialog_bar.position = Vector2(20, preview.size.y + preview.position.y + 4)
	card.add_child(dialog_bar)
	var dialog_lbl := Label.new()
	dialog_lbl.text = "Неизвестный: Они говорили, что это временно... что система выдержит. Но система не выдержала нас."
	dialog_lbl.size = Vector2(dialog_bar.size.x - 20, 44)
	dialog_lbl.position = Vector2(10, 6)
	dialog_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_lbl.add_theme_color_override("font_color", STEEL_TEXT)
	dialog_lbl.add_theme_font_size_override("font_size", 11)
	dialog_bar.add_child(dialog_lbl)
	var skip_lbl := Label.new()
	skip_lbl.text = "ПРОПУСТИТЬ [SPACE]"
	skip_lbl.size = Vector2(180, 20)
	skip_lbl.position = Vector2(cw / 2.0 - 90, ch - 24)
	skip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip_lbl.add_theme_color_override("font_color", BRASS_DIM)
	skip_lbl.add_theme_font_size_override("font_size", 10)
	card.add_child(skip_lbl)

func build_FinalNight(content: ColorRect, card: ColorRect, cw: float, ch: float, d: Dictionary) -> void:
	var header := Label.new()
	header.text = tr("FINAL_NIGHT_TITLE")
	header.size = Vector2(content.size.x, 24)
	header.position = Vector2(0, 10)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", BONE_TEXT)
	header.add_theme_font_size_override("font_size", 16)
	_apply_outline(header)
	content.add_child(header)
	var mission := Label.new()
	mission.text = tr("FINAL_NIGHT_DESC")
	mission.size = Vector2(content.size.x, 40)
	mission.position = Vector2(0, 44)
	mission.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission.add_theme_color_override("font_color", STEEL_TEXT)
	mission.add_theme_font_size_override("font_size", 13)
	_apply_outline(mission)
	content.add_child(mission)
	var minimap := ColorRect.new()
	minimap.color = PANEL_EDGE
	minimap.size = Vector2(120, 120)
	minimap.position = Vector2(content.size.x - 130, content.size.y - 140)
	content.add_child(minimap)
	var mm_lbl := Label.new()
	mm_lbl.text = tr("FINAL_NIGHT_OBJECTIVE")
	mm_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mm_lbl.size = Vector2(120, 40)
	mm_lbl.position = Vector2(0, 40)
	mm_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mm_lbl.add_theme_color_override("font_color", BRASS_DIM)
	mm_lbl.add_theme_font_size_override("font_size", 10)
	minimap.add_child(mm_lbl)
	var objective := Label.new()
	objective.text = tr("FINAL_NIGHT_OBJECTIVE")
	objective.size = Vector2(content.size.x, 20)
	objective.position = Vector2(0, content.size.y - 24)
	objective.add_theme_color_override("font_color", BRASS)
	objective.add_theme_font_size_override("font_size", 11)
	_apply_outline(objective)
	content.add_child(objective)
	if PowerGrid != null and PowerGrid.all_restored():
		EventBus.final_night_started.emit()

func build_PowerGrid(content: ColorRect, card: ColorRect, cw: float, ch: float) -> void:
	var substations := [
		{"name": "ПС-1", "pos": Vector2(60, 120), "status": "green"},
		{"name": "ПС-2", "pos": Vector2(180, 60), "status": "amber"},
		{"name": "ПС-3", "pos": Vector2(180, 180), "status": "red"},
		{"name": "ПС-4", "pos": Vector2(300, 100), "status": "amber"},
		{"name": "ПС-5", "pos": Vector2(300, 200), "status": "green"},
		{"name": "ПС-6", "pos": Vector2(400, 140), "status": "red"},
		{"name": "ПС-7", "pos": Vector2(420, 50), "status": "green"},
		{"name": "ПС-8", "pos": Vector2(460, 200), "status": "red"},
	]
	var lines := [[0,1],[0,2],[1,3],[2,3],[2,4],[3,5],[4,5],[1,6],[3,6],[5,7],[6,7]]
	for l in lines:
		var line := Line2D.new()
		line.add_point(substations[l[0]].pos)
		line.add_point(substations[l[1]].pos)
		line.width = 1.5
		line.default_color = BRASS_DIM
		content.add_child(line)
	for s in substations:
		var status_col := STAMINA_GREEN if s.status == "green" else (BRASS if s.status == "amber" else EMPER)
		var dot := ColorRect.new()
		dot.color = status_col
		dot.size = Vector2(14, 14)
		dot.position = s.pos - Vector2(7, 7)
		content.add_child(dot)
		var lbl := Label.new()
		lbl.text = s.name
		lbl.size = Vector2(50, 14)
		lbl.position = s.pos + Vector2(-18, 16)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", STEEL_TEXT)
		lbl.add_theme_font_size_override("font_size", 8)
		content.add_child(lbl)
	var voltage := Label.new()
	voltage.text = "Напряжение в сети: 42%"
	voltage.size = Vector2(content.size.x, 20)
	voltage.position = Vector2(10, 10)
	voltage.add_theme_color_override("font_color", BRASS)
	voltage.add_theme_font_size_override("font_size", 14)
	_apply_outline(voltage)
	content.add_child(voltage)
	var active := Label.new()
	active.text = "Активные подстанции: 3/8"
	active.size = Vector2(content.size.x, 18)
	active.position = Vector2(10, 34)
	active.add_theme_color_override("font_color", STEEL_TEXT)
	active.add_theme_font_size_override("font_size", 11)
	content.add_child(active)
	var legend_y := content.size.y - 60
	var legend_items := [["Активна", STAMINA_GREEN], ["Частично", BRASS], ["Отключена", EMPER]]
	for i in legend_items.size():
		var dot := ColorRect.new()
		dot.color = legend_items[i][1]
		dot.size = Vector2(8, 8)
		dot.position = Vector2(10 + i * 110, legend_y)
		content.add_child(dot)
		var lbl := Label.new()
		lbl.text = legend_items[i][0]
		lbl.size = Vector2(100, 16)
		lbl.position = Vector2(22 + i * 110, legend_y)
		lbl.add_theme_color_override("font_color", STEEL_TEXT)
		lbl.add_theme_font_size_override("font_size", 9)
		content.add_child(lbl)

func build_Events(content: ColorRect, card: ColorRect, cw: float, ch: float) -> void:
	var weather_info := Label.new()
	weather_info.text = "Ночь | Дождь | Туман"
	weather_info.size = Vector2(content.size.x, 22)
	weather_info.position = Vector2(0, 5)
	weather_info.add_theme_color_override("font_color", BONE_TEXT)
	weather_info.add_theme_font_size_override("font_size", 14)
	_apply_outline(weather_info)
	content.add_child(weather_info)
	var events := [
		{"name": "Сигнал бедствия с крыши", "time": "00:12:34"},
		{"name": "Авария на подстанции", "time": "01:45:10"},
		{"name": "Внезапное отключение света в парке", "time": "02:20:05"},
	]
	var list_y := 36.0
	for e in events:
		var frame := ColorRect.new()
		frame.color = PANEL_COLOR
		frame.size = Vector2(content.size.x, 40)
		frame.position = Vector2(0, list_y)
		content.add_child(frame)
		var lbl := Label.new()
		lbl.text = e.name
		lbl.size = Vector2(content.size.x - 100, 22)
		lbl.position = Vector2(8, 4)
		lbl.add_theme_color_override("font_color", STEEL_TEXT)
		lbl.add_theme_font_size_override("font_size", 11)
		_apply_outline(lbl)
		frame.add_child(lbl)
		var timer_lbl := Label.new()
		timer_lbl.text = e.time
		timer_lbl.size = Vector2(90, 18)
		timer_lbl.position = Vector2(content.size.x - 98, 22)
		timer_lbl.add_theme_color_override("font_color", BRASS)
		timer_lbl.add_theme_font_size_override("font_size", 11)
		frame.add_child(timer_lbl)
		list_y += 46

func _populate_shop(content: ColorRect, card: ColorRect) -> void:
	var header := Label.new()
	header.text = "МОНЕТЫ: 0"
	header.name = "ShopCoinHeader"
	header.size = Vector2(content.size.x, 30)
	header.position = Vector2(0, 0)
	header.add_theme_color_override("font_color", Color(0.788, 0.635, 0.290))
	header.add_theme_font_size_override("font_size", 18)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(header)
	header.text = "МОНЕТЫ: " + str(CoinWallet.get_coins())
	EventBus.coins_changed.connect(func(v: int): header.text = "МОНЕТЫ: " + str(v), CONNECT_ONE_SHOT)
	var tab_h := HBoxContainer.new()
	tab_h.size = Vector2(content.size.x, 28)
	tab_h.position = Vector2(0, 34)
	tab_h.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(tab_h)
	var tabs := ["УЛУЧШЕНИЯ", "ПРЕДМЕТЫ", "МОНЕТЫ"]
	var current_tab := 0
	var tab_btns := []
	for t in tabs:
		var btn := Button.new()
		btn.text = t
		btn.flat = true
		btn.add_theme_color_override("font_color", Color(0.682, 0.714, 0.749))
		btn.add_theme_font_size_override("font_size", 11)
		btn.custom_minimum_size = Vector2(80, 24)
		tab_h.add_child(btn)
		tab_btns.append(btn)
	# Каталог: ShopService (CoinWallet-магазин). IAP-паки (Kind.COIN_PACK) исключены — донат/реклама отключены.
	var catalog = get_tree().root.get_node_or_null("ShopCatalog")
	var items: Array[Dictionary] = catalog.items if catalog else []
	if items.is_empty():
		for it in ShopService.catalog_by_kind(ShopItem.Kind.UPGRADE) + ShopService.catalog_by_kind(ShopItem.Kind.SKIN) + ShopService.catalog_by_kind(ShopItem.Kind.BUNDLE):
			var si: ShopItem = it as ShopItem
			if si != null:
				items.append({"id": si.id, "desc": si.display_name, "price_coins": si.final_price_coins()})
	var grid_container := GridContainer.new()
	grid_container.name = "ShopGrid"
	grid_container.columns = 2
	grid_container.size = Vector2(content.size.x, content.size.y - 70)
	grid_container.position = Vector2(0, 66)
	grid_container.mouse_filter = Control.MOUSE_FILTER_PASS
	content.add_child(grid_container)
	var item_icons := preload("res://scripts/ui/item_icons.gd")
	grid_container.size.y = maxi(grid_container.size.y, items.size() / 2 * 110)
	for it in items:
		var card_item := ColorRect.new()
		card_item.color = Color(0.047, 0.063, 0.086, 0.6)
		card_item.custom_minimum_size = Vector2((content.size.x - 10) / 2.0, 100)
		card_item.size = Vector2((content.size.x - 10) / 2.0, 100)
		card_item.mouse_filter = Control.MOUSE_FILTER_PASS
		grid_container.add_child(card_item)
		var icon_parent := Control.new()
		icon_parent.size = Vector2(32, 32)
		icon_parent.position = Vector2(card_item.size.x / 2.0 - 16, 6)
		icon_parent.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_item.add_child(icon_parent)
		item_icons.draw_icon(icon_parent, StringName(it.get("id", "")), 28.0)
		var name_lbl := Label.new()
		name_lbl.text = it.get("desc", it.id)
		name_lbl.size = Vector2(card_item.size.x - 10, 18)
		name_lbl.position = Vector2(5, 42)
		name_lbl.add_theme_color_override("font_color", Color(0.847, 0.824, 0.769))
		name_lbl.add_theme_font_size_override("font_size", 10)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_item.add_child(name_lbl)
		var price: float = it.get("price_coins", 0)
		# IAP-путь удалён — только монеты.
		var pl := Label.new()
		pl.text = str(price) + " монет"
		pl.size = Vector2(card_item.size.x - 10, 16)
		pl.position = Vector2(5, 60)
		pl.add_theme_color_override("font_color", Color(0.788, 0.635, 0.290))
		pl.add_theme_font_size_override("font_size", 11)
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_item.add_child(pl)
		var btn := _make_btn("КУПИТЬ", Vector2(card_item.size.x / 2.0 - 45, 76), Vector2(90, 22))
		btn.pressed.connect(_on_buy.bind(it.id, int(price)))
		card_item.add_child(btn)
	# Реклама отключена (кнопка удалена)



	var shop_is_grid := grid_container != null
	var shop_tabs := tab_btns.size() >= 3
	var shop_header := header != null
	var shop_icons := items.size() > 0

func _on_buy(item_id: String, price: int) -> void:
	if CoinWallet.try_spend(price):
		EventBus.purchase_done.emit(item_id, true)
		_show_toast("КУПЛЕНО!")
	else:
		_show_toast("НЕ ХВАТАЕТ МОНЕТ")

func _show_toast(msg: String) -> void:
	var existing := get_node_or_null("Toast")
	if existing:
		existing.queue_free()
	var toast := Label.new()
	toast.name = "Toast"
	toast.text = msg
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.size = Vector2(400, 30)
	var vp := get_viewport().get_visible_rect().size
	toast.position = Vector2(vp.x / 2.0 - 200, vp.y - 100)
	toast.add_theme_color_override("font_color", BRASS)
	toast.add_theme_font_size_override("font_size", 18)
	_apply_outline(toast)
	toast.modulate = Color(1, 1, 1, 0)
	add_child(toast)
	var tween := create_tween()
	tween.tween_property(toast, "modulate:a", 1.0, 0.2)
	tween.tween_interval(1.5)
	tween.tween_property(toast, "modulate:a", 0.0, 0.3)
	tween.tween_callback(toast.queue_free)

func _on_close() -> void:
	hide_all()

func _on_start() -> void:
	show_screen("Loading")

func _on_loading_done() -> void:
	if not is_any_open():
		return
	hide_all()
	var gm = get_tree().root.get_node_or_null("GameManager")
	if gm and gm.has_method("start_new_game"):
		gm.start_new_game()
	else:
		EventBus.game_started.emit()
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.process_mode = Node.PROCESS_MODE_INHERIT
	var p_mode = player.process_mode if player else -1

func _on_settings() -> void:
	show_screen("Settings")

func _on_shop() -> void:
	show_screen("Shop")

func _on_multiplayer() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/lobby.tscn")

func _on_quit() -> void:
	get_tree().quit()

func _on_resume() -> void:
	hide_all()
	var player := get_tree().get_first_node_in_group("player")
	if player:
		SaveSystem.load_slot(0)
	var gm = get_tree().root.get_node_or_null("GameManager")
	if gm and gm.has_method("continue_game"):
		gm.continue_game()
	elif gm and gm.has_method("start_new_game"):
		gm.start_new_game()
	else:
		EventBus.game_started.emit()
	if player:
		player.process_mode = Node.PROCESS_MODE_INHERIT

func _on_saves() -> void:
	show_screen("Saves")

func _on_quest_journal() -> void:
	show_screen("QuestJournal")

func _on_mainmenu() -> void:
	hide_all()

func _on_load() -> void:
	show_screen("Saves")

func get_screen_names() -> Array[String]:
	return SCREEN_LIST
