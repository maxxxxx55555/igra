extends CanvasLayer

const UI_MANAGER_IDS: Dictionary = {}

signal panel_ready(name: String)
## Экраны, которыми владеет UIManager (главное меню, пауза, настройки, смерть,
## победа, карта, журналы, достижения, статистика, верстак, туториал). Раньше
## Screens строил СВОИ копии всех этих экранов поверх экранов UIManager —
## два одинаковых меню в одной сцене, оба перехватывали ввод.
const OWNED_BY_UI_MANAGER: Array[String] = [
	"MainMenu", "Pause", "Settings", "Death", "Victory",
	"CityMap", "Journal", "QuestJournal", "Achievements", "Stats", "Workbench",
	"Tutorial", "Inventory", "Character",
]

## За Screens остаётся то, чего в UIManager нет вовсе: головоломки, радио,
## сюжетные сцены, финальная ночь, погода, щиток, события, магазин и т.п.
const SCREEN_LIST: Array[String] = [
	"Loading", "Shop", "Saves", "Bestiary",
	"FlashlightUpgrade", "PhotoMode", "ControlsTouch",
	"Weather", "PuzzleCables", "Radio",
	"StoryScene", "FinalNight", "PowerGrid", "Events",
]
const BRASS: Color = Color(0.788, 0.635, 0.290)
const BRASS_DIM: Color = Color(0.541, 0.451, 0.220)
const STEEL_TEXT: Color = Color(0.682, 0.714, 0.749)
const BONE_TEXT: Color = Color(0.847, 0.824, 0.769)
const EMPER: Color = Color(0.706, 0.271, 0.184)
const STAMINA_GREEN: Color = Color(0.373, 0.541, 0.306)
const PANEL_COLOR: Color = Color(0.078, 0.106, 0.141, 0.94)
const PANEL_EDGE: Color = Color(0.165, 0.200, 0.251)
const OUTLINE_COLOR: Color = Color(0.047, 0.063, 0.086, 1.0)
const SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)
var _active_screen: String = ""
var _screen_data: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 25
	_build_menu_bg()
	_build_all_screens()

func _build_menu_bg() -> void:
	var bg_full := ColorRect.new()
	bg_full.name = "MenuBG"
	bg_full.color = Color(0.047, 0.063, 0.086, 1.0)
	bg_full.mouse_filter = Control.MOUSE_FILTER_STOP
	bg_full.visible = false
	add_child(bg_full)
	bg_full.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

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
		close_btn = _make_btn(LocalizationManager.t("SCR_ZAKRYT"), Vector2(card_w / 2.0 - 80, card_h - 46), Vector2(160, 36))
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

func show_screen(name: String) -> void:
	# Экраны, отданные UIManager, открываем у него, а не строим второй раз.
	if OWNED_BY_UI_MANAGER.has(name):
		var id: StringName = UI_MANAGER_IDS.get(name, &"")
		if id != &"" and UIManager != null:
			UIManager.open(id)
		return
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
		"Loading":
			build_Loading(content, card, cw, ch, d)
		"Shop":
			build_Shop(content, card, cw, ch)
		"Saves":
			build_Saves(content, card, cw, ch)
		"Bestiary":
			build_Bestiary(content, card, cw, ch)
		"FlashlightUpgrade":
			build_FlashlightUpgrade(content, card, cw, ch)
		"PhotoMode":
			build_PhotoMode(content, card, cw, ch, d)
		"ControlsTouch":
			build_ControlsTouch(content, card, cw, ch)
		"Weather":
			build_Weather(content, card, cw, ch)
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

func build_Loading(content: ColorRect, card: ColorRect, cw: float, ch: float, d: Dictionary) -> void:
	var load_title := Label.new()
	load_title.text = LocalizationManager.t("SCR_ZAGRUZKA_0")
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
		LocalizationManager.t("SCR_SVET_NE_TOLKO_ZASCHISCHAET_VAS_OT_MONSTROV_N"),
		LocalizationManager.t("SCR_CHEM_BOLSHE_SVETA_TEM_MENSHE_MONSTROV"),
		LocalizationManager.t("SCR_TISHINA_TVOY_SOYUZNIK_V_TEMNOTE"),
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
		load_title.text = LocalizationManager.t("SCR_ZAGRUZKA") + str(int(v * 100)) + "%"
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

func build_Shop(content: ColorRect, card: ColorRect, cw: float, ch: float) -> void:
	_populate_shop(content, card)

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
		slot_title.text = LocalizationManager.t("SCR_SLOT") + str(slot)
		slot_title.size = Vector2(200, 20)
		slot_title.position = Vector2(10, 8)
		slot_title.add_theme_color_override("font_color", BONE_TEXT)
		slot_title.add_theme_font_size_override("font_size", 14)
		slot_card.add_child(slot_title)
		if si.exists:
			var time_str := Time.get_datetime_string_from_unix_time(si.modified, false) if si.modified > 0 else ""
			var exists_lbl := Label.new()
			exists_lbl.text = LocalizationManager.t("SCR_EST_SOHRANENIE") + time_str
			exists_lbl.size = Vector2(300, 18)
			exists_lbl.position = Vector2(10, 32)
			exists_lbl.add_theme_color_override("font_color", STEEL_TEXT)
			exists_lbl.add_theme_font_size_override("font_size", 10)
			slot_card.add_child(exists_lbl)
			_add_btn(slot_card, LocalizationManager.t("SCR_ZAGRUZIT"), Vector2(content.size.x - 290, 40), Vector2(80, 22), func(s = slot):
				sm.load_slot(s)
				_show_toast(LocalizationManager.t("SCR_ZAGRUZHENO"))
			)

			_add_btn(slot_card, LocalizationManager.t("SCR_PEREZAPISAT"), Vector2(content.size.x - 200, 40), Vector2(90, 22), func(s = slot):
				sm.save_slot(s)
				_show_toast(LocalizationManager.t("SCR_SOHRANENO"))
				EventBus.game_saved.emit()
			)

			_add_btn(slot_card, LocalizationManager.t("SCR_UDALIT"), Vector2(content.size.x - 100, 40), Vector2(70, 22), func(s = slot):
				sm.delete_slot(s)
				_show_toast(LocalizationManager.t("SCR_UDALENO"))
				for c in content.get_children():
					c.queue_free()
				build_Saves(content, card, cw, ch)
			)

		else:
			var empty_lbl := Label.new()
			empty_lbl.text = LocalizationManager.t("SCR_PUSTOY_SLOT")
			empty_lbl.size = Vector2(200, 18)
			empty_lbl.position = Vector2(10, 32)
			empty_lbl.add_theme_color_override("font_color", BRASS_DIM)
			empty_lbl.add_theme_font_size_override("font_size", 10)
			slot_card.add_child(empty_lbl)
			_add_btn(slot_card, LocalizationManager.t("SCR_SOHRANIT"), Vector2(content.size.x - 100, 40), Vector2(80, 22), func(s = slot):
				sm.save_slot(s)
				_show_toast(LocalizationManager.t("SCR_SOHRANENO"))
				EventBus.game_saved.emit()
			)

		slot_y += 90

func build_Bestiary(content: ColorRect, card: ColorRect, cw: float, ch: float) -> void:
	var creatures := [
		{"id": "Shadow", "desc": LocalizationManager.t("SCR_BYSTRYY_I_SKRYTNYY_AKTIVNO_REAGIRUET_NA_SVET"), "health": 60, "speed": 90, "weakness": LocalizationManager.t("SCR_SVET"), "met": 7, "total": 15},
		{"id": "Crawler", "desc": LocalizationManager.t("SCR_PEREDVIGAETSYA_NA_CHETYREH_KONECHNOSTYAH_POY"), "health": 40, "speed": 70, "weakness": LocalizationManager.t("SCR_SVET"), "met": 5, "total": 12},
		{"id": "Watcher", "desc": LocalizationManager.t("SCR_VYSOKIY_HUDOY_NABLYUDAET_IZDALEKA_ATAKUET_PR"), "health": 80, "speed": 50, "weakness": LocalizationManager.t("SCR_SVET"), "met": 4, "total": 10},
		{"id": "Hunter", "desc": LocalizationManager.t("SCR_CELENAPRAVLENNO_PRESLEDUET_ZHERTVU_REAGIRUET"), "health": 100, "speed": 75, "weakness": LocalizationManager.t("SCR_SVET"), "met": 3, "total": 8},
		{"id": "Destroyer", "desc": LocalizationManager.t("SCR_MASSIVNAYA_NEUYAZVIMAYA_MASHINA_RAZRUSHENIYA"), "health": 200, "speed": 30, "weakness": LocalizationManager.t("SCR_SVET"), "met": 1, "total": 3},
		{"id": "Boss", "desc": LocalizationManager.t("SCR_FINALNYY_PROTIVNIK_VSTRECHAETSYA_V_CENTRE_EL"), "health": 500, "speed": 60, "weakness": LocalizationManager.t("SCR_SVET"), "met": 0, "total": 1},
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
		stats_lbl.text = LocalizationManager.t("SCR_ZDOROVE_D_SKOROST_D_SLABYE_STORONY_S_VSTRECH") % [c.health, c.speed, c.weakness, c.met, c.total]
		stats_lbl.size = Vector2(vbox.size.x - 100, 18)
		stats_lbl.position = Vector2(82, 72)
		stats_lbl.add_theme_color_override("font_color", BRASS_DIM)
		stats_lbl.add_theme_font_size_override("font_size", 8)
		frame.add_child(stats_lbl)

func build_FlashlightUpgrade(content: ColorRect, card: ColorRect, cw: float, ch: float) -> void:
	# Раньше здесь были шесть выдуманных строк с уровнями вида 3/5: экран
	# не имел отношения к настоящим улучшениям и кнопка ничего не покупала.
	# Теперь список строится из FlashlightUpgradeManager (5 веток), а кнопка
	# рядом с веткой действительно тратит монеты и повышает уровень.
	for c in content.get_children():
		content.remove_child(c)
		c.queue_free()
	var branches: Array = FlashlightUpgradeManager.get_all_data()
	var coins_lbl := Label.new()
	coins_lbl.text = LocalizationManager.tf("COINS_AMOUNT", [CoinWallet.get_coins()])
	coins_lbl.size = Vector2(160, 20)
	coins_lbl.position = Vector2(content.size.x - 165, 4)
	coins_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coins_lbl.add_theme_color_override("font_color", BRASS)
	coins_lbl.add_theme_font_size_override("font_size", 12)
	_apply_outline(coins_lbl)
	content.add_child(coins_lbl)
	for i in branches.size():
		var b: Dictionary = branches[i]
		var py := 30 + i * 34
		var lbl := Label.new()
		lbl.text = String(b["name"])
		lbl.size = Vector2(110, 22)
		lbl.position = Vector2(5, py)
		lbl.add_theme_color_override("font_color", STEEL_TEXT)
		lbl.add_theme_font_size_override("font_size", 12)
		_apply_outline(lbl)
		content.add_child(lbl)
		var lvl: int = int(b["level"])
		var mx: int = maxi(1, int(b["max"]))
		var bar_bg := ColorRect.new()
		bar_bg.color = PANEL_EDGE
		bar_bg.size = Vector2(110, 10)
		bar_bg.position = Vector2(120, py + 6)
		content.add_child(bar_bg)
		var bar_fill := ColorRect.new()
		bar_fill.color = BRASS
		bar_fill.size = Vector2(110.0 * float(lvl) / float(mx), 10)
		bar_fill.position = Vector2(120, py + 6)
		content.add_child(bar_fill)
		var level_lbl := Label.new()
		level_lbl.text = "%d/%d" % [lvl, mx]
		level_lbl.size = Vector2(36, 22)
		level_lbl.position = Vector2(236, py)
		level_lbl.add_theme_color_override("font_color", BRASS_DIM)
		level_lbl.add_theme_font_size_override("font_size", 10)
		content.add_child(level_lbl)
		var can_buy: bool = bool(b["can_buy"])
		var cost: int = int(b["cost"])
		var caption: String = ("%d" % cost) if can_buy else LocalizationManager.t("UPG_MAXED")
		var branch_id: String = String(b["id"])
		var btn_pos := Vector2(276, py)
		if can_buy:
			_add_btn(content, caption, btn_pos, Vector2(74, 24), func() -> void:
				if FlashlightUpgradeManager.try_purchase(branch_id):
					_show_toast(LocalizationManager.t("SCR_ULUCHSHENIE_PRIMENENO"))
					# Перестраиваем после кадра: кнопка, из которой пришёл вызов,
					# сама попадает под queue_free() при пересборке списка.
					call_deferred("build_FlashlightUpgrade", content, card, cw, ch)
				else:
					_show_toast(LocalizationManager.t("NOT_ENOUGH_COINS"))
			)
		else:
			var maxed := Label.new()
			maxed.text = caption
			maxed.size = Vector2(74, 24)
			maxed.position = btn_pos
			maxed.add_theme_color_override("font_color", BRASS_DIM)
			maxed.add_theme_font_size_override("font_size", 10)
			content.add_child(maxed)
	var hint := Label.new()
	hint.text = LocalizationManager.t("UPG_HINT")
	hint.size = Vector2(content.size.x - 10, 20)
	hint.position = Vector2(5, content.size.y - 26)
	hint.add_theme_color_override("font_color", BONE_TEXT)
	hint.add_theme_font_size_override("font_size", 10)
	_apply_outline(hint)
	content.add_child(hint)

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
	screen_lbl.text = LocalizationManager.t("SCR_TELEFON")
	screen_lbl.size = Vector2(108, 20)
	screen_lbl.position = Vector2(0, 84)
	screen_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_lbl.add_theme_color_override("font_color", BRASS_DIM)
	screen_lbl.add_theme_font_size_override("font_size", 10)
	screen.add_child(screen_lbl)
	var controls := [
		{"label": LocalizationManager.t("SCR_FONARIK"), "value": LocalizationManager.t("SCR_DEYSTVIE")},
		{"label": LocalizationManager.t("SCR_DEYSTVIE"), "value": LocalizationManager.t("SCR_STOYKA")},
		{"label": LocalizationManager.t("SCR_POGODA"), "value": LocalizationManager.t("SCR_DEN")},
		{"label": LocalizationManager.t("SCR_UGOL_KAMERY"), "value": "45°"},
		{"label": LocalizationManager.t("SCR_FILTR"), "value": LocalizationManager.t("SCR_AVTO")},
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
	tip.text = LocalizationManager.t("SCR_SOVET_NASTROYTE_RASPOLOZHENIE_KNOPOK")
	tip.size = Vector2(content.size.x - 10, 18)
	tip.position = Vector2(5, content.size.y - 24)
	tip.add_theme_color_override("font_color", STEEL_TEXT)
	tip.add_theme_font_size_override("font_size", 9)
	content.add_child(tip)

func build_Weather(content: ColorRect, card: ColorRect, cw: float, ch: float) -> void:
	var weathers := [
		{"name": LocalizationManager.t("SCR_DOZHD"), "effect": LocalizationManager.t("SCR_UMENSHAET_VIDIMOST_UVELICHIVAET_SHUM")},
		{"name": LocalizationManager.t("SCR_TUMAN"), "effect": LocalizationManager.t("SCR_SILNO_SNIZHAET_VIDIMOST")},
		{"name": LocalizationManager.t("SCR_GROZA"), "effect": LocalizationManager.t("SCR_MOLNII_PRIVLEKAYUT_MONSTROV")},
		{"name": LocalizationManager.t("SCR_VETER"), "effect": LocalizationManager.t("SCR_UVELICHIVAET_UROVEN_SHUMA")},
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
	preview_lbl.text = LocalizationManager.t("SCR_SCENA")
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
	dialog_lbl.text = LocalizationManager.t("SCR_NEIZVESTNYY_ONI_GOVORILI_CHTO_ETO_VREMENNO_C")
	dialog_lbl.size = Vector2(dialog_bar.size.x - 20, 44)
	dialog_lbl.position = Vector2(10, 6)
	dialog_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_lbl.add_theme_color_override("font_color", STEEL_TEXT)
	dialog_lbl.add_theme_font_size_override("font_size", 11)
	dialog_bar.add_child(dialog_lbl)
	var skip_lbl := Label.new()
	skip_lbl.text = LocalizationManager.t("SCR_PROPUSTIT_SPACE")
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
		{"name": LocalizationManager.t("SCR_PS_1"), "pos": Vector2(60, 120), "status": "green"},
		{"name": LocalizationManager.t("SCR_PS_2"), "pos": Vector2(180, 60), "status": "amber"},
		{"name": LocalizationManager.t("SCR_PS_3"), "pos": Vector2(180, 180), "status": "red"},
		{"name": LocalizationManager.t("SCR_PS_4"), "pos": Vector2(300, 100), "status": "amber"},
		{"name": LocalizationManager.t("SCR_PS_5"), "pos": Vector2(300, 200), "status": "green"},
		{"name": LocalizationManager.t("SCR_PS_6"), "pos": Vector2(400, 140), "status": "red"},
		{"name": LocalizationManager.t("SCR_PS_7"), "pos": Vector2(420, 50), "status": "green"},
		{"name": LocalizationManager.t("SCR_PS_8"), "pos": Vector2(460, 200), "status": "red"},
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
	voltage.text = LocalizationManager.t("SCR_NAPRYAZHENIE_V_SETI_42")
	voltage.size = Vector2(content.size.x, 20)
	voltage.position = Vector2(10, 10)
	voltage.add_theme_color_override("font_color", BRASS)
	voltage.add_theme_font_size_override("font_size", 14)
	_apply_outline(voltage)
	content.add_child(voltage)
	var active := Label.new()
	active.text = LocalizationManager.t("SCR_AKTIVNYE_PODSTANCII_3_8")
	active.size = Vector2(content.size.x, 18)
	active.position = Vector2(10, 34)
	active.add_theme_color_override("font_color", STEEL_TEXT)
	active.add_theme_font_size_override("font_size", 11)
	content.add_child(active)
	var legend_y := content.size.y - 60
	var legend_items := [[LocalizationManager.t("SCR_AKTIVNA"), STAMINA_GREEN], [LocalizationManager.t("SCR_CHASTICHNO_2"), BRASS], [LocalizationManager.t("SCR_OTKLYUCHENA"), EMPER]]
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
	weather_info.text = LocalizationManager.t("SCR_NOCH_DOZHD_TUMAN")
	weather_info.size = Vector2(content.size.x, 22)
	weather_info.position = Vector2(0, 5)
	weather_info.add_theme_color_override("font_color", BONE_TEXT)
	weather_info.add_theme_font_size_override("font_size", 14)
	_apply_outline(weather_info)
	content.add_child(weather_info)
	var events := [
		{"name": LocalizationManager.t("SCR_SIGNAL_BEDSTVIYA_S_KRYSHI"), "time": "00:12:34"},
		{"name": LocalizationManager.t("SCR_AVARIYA_NA_PODSTANCII"), "time": "01:45:10"},
		{"name": LocalizationManager.t("SCR_VNEZAPNOE_OTKLYUCHENIE_SVETA_V_PARKE"), "time": "02:20:05"},
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
	header.text = LocalizationManager.t("SCR_MONETY_0")
	header.name = "ShopCoinHeader"
	header.size = Vector2(content.size.x, 30)
	header.position = Vector2(0, 0)
	header.add_theme_color_override("font_color", Color(0.788, 0.635, 0.290))
	header.add_theme_font_size_override("font_size", 18)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(header)
	header.text = LocalizationManager.t("SCR_MONETY_2") + str(CoinWallet.get_coins())
	EventBus.coins_changed.connect(func(v: int): header.text = LocalizationManager.t("SCR_MONETY_2") + str(v), CONNECT_ONE_SHOT)
	var tab_h := HBoxContainer.new()
	tab_h.size = Vector2(content.size.x, 28)
	tab_h.position = Vector2(0, 34)
	tab_h.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(tab_h)
	var tabs := [LocalizationManager.t("SCR_ULUCHSHENIYA"), LocalizationManager.t("SCR_PREDMETY"), LocalizationManager.t("SCR_MONETY")]
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
		pl.text = str(price) + LocalizationManager.t("SCR_MONET")
		pl.size = Vector2(card_item.size.x - 10, 16)
		pl.position = Vector2(5, 60)
		pl.add_theme_color_override("font_color", Color(0.788, 0.635, 0.290))
		pl.add_theme_font_size_override("font_size", 11)
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_item.add_child(pl)
		var btn := _make_btn(LocalizationManager.t("SCR_KUPIT"), Vector2(card_item.size.x / 2.0 - 45, 76), Vector2(90, 22))
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
		_show_toast(LocalizationManager.t("SCR_KUPLENO"))
	else:
		_show_toast(LocalizationManager.t("SCR_NE_HVATAET_MONET"))

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

func get_screen_names() -> Array[String]:
	return SCREEN_LIST
