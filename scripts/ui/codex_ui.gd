extends Control
## «Кодекс» — единый экран для пяти справочных разделов игры.
##
## Раньше журнал документов, задания, достижения, характеристики и
## энциклопедия существ были пятью отдельными полноэкранными окнами. Между
## ними нельзя было переключиться: чтобы из достижений попасть в статистику,
## игрок закрывал одно окно и искал кнопку второго. На телефоне это особенно
## неудобно — половина разделов вообще открывалась только с клавиатуры.
##
## Здесь они собраны под общей рамкой с рядом вкладок снизу. Сами экраны не
## переписаны и не продублированы: каждый инстанцируется своим же скриптом с
## флагом embedded = true, из-за которого он не рисует собственный фон и
## кнопку закрытия. Правка в журнале по-прежнему меняет журнал в одном месте.

## Вкладки в порядке показа: ключ подписи -> скрипт раздела.
const TABS: Array[Dictionary] = [
	{"id": &"journal", "label": "JOURNAL_TITLE", "script": "res://scripts/ui/journal_ui.gd"},
	{"id": &"quests", "label": "CODEX_TAB_QUESTS", "script": "res://scripts/ui/quest_journal.gd"},
	{"id": &"achievements", "label": "ACHIEVEMENTS_TITLE", "script": "res://scripts/ui/achievements_ui.gd"},
	{"id": &"stats", "label": "STATS_TITLE", "script": "res://scripts/ui/stats_ui.gd"},
	{"id": &"bestiary", "label": "enc_title", "script": "res://scripts/ui/encyclopedia_ui.gd"},
]

var _content: Control = null
var _tab_row: HBoxContainer = null
var _buttons: Array[Button] = []
## Разделы создаются лениво — при первом открытии вкладки, а не все сразу:
## энциклопедия и журнал строят десятки узлов, и на слабом телефоне открытие
## экрана заметно подтормаживало бы.
var _pages: Dictionary = {}
var _current: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = ThemeProvider.build_theme()

	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.07, 0.94)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 24
	root.offset_top = 18
	root.offset_right = -24
	root.offset_bottom = -18
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	# Шапка: заголовок слева, крестик справа.
	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = LocalizationManager.t("CODEX_TITLE")
	title.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_TITLE)
	title.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_btn := Button.new()
	close_btn.text = LocalizationManager.t("ui_close")
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.custom_minimum_size = Vector2(140, 40)
	close_btn.pressed.connect(_close)
	header.add_child(close_btn)

	# Содержимое активной вкладки.
	_content = Control.new()
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.clip_contents = true
	root.add_child(_content)

	# Ряд вкладок внизу — большие кнопки, рассчитанные на палец.
	_tab_row = HBoxContainer.new()
	_tab_row.add_theme_constant_override("separation", 6)
	root.add_child(_tab_row)
	for i in TABS.size():
		var btn := Button.new()
		btn.text = LocalizationManager.t(String(TABS[i]["label"]))
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(0, 52)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_show_tab.bind(i))
		_tab_row.add_child(btn)
		_buttons.append(btn)

	_show_tab(0)

## Переключает вкладку, создавая её раздел при первом обращении.
func _show_tab(index: int) -> void:
	if index < 0 or index >= TABS.size() or index == _current:
		return
	_current = index
	for page in _pages.values():
		if is_instance_valid(page):
			(page as Control).visible = false
	var id: StringName = TABS[index]["id"]
	var page: Control = _pages.get(id, null)
	if page == null or not is_instance_valid(page):
		page = _make_page(String(TABS[index]["script"]))
		if page == null:
			return
		_pages[id] = page
		_content.add_child(page)
	page.visible = true
	_highlight(index)

## Инстанцирует раздел в встроенном режиме: свой фон и кнопку закрытия он
## рисовать не должен — рамка общая.
func _make_page(script_path: String) -> Control:
	var scr: Script = load(script_path)
	if scr == null:
		return null
	var node: Control = scr.new() as Control
	if node == null:
		return null
	# embedded ставится до входа в дерево: _build() раздела вызывается из
	# _ready(), то есть уже после add_child().
	node.set("embedded", true)
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	return node

## Активная вкладка подсвечивается янтарным, остальные приглушены.
func _highlight(index: int) -> void:
	for i in _buttons.size():
		var col: Color = ThemeProvider.COLOR_AMBER if i == index else ThemeProvider.COLOR_TEXT_DIM
		_buttons[i].add_theme_color_override("font_color", col)

## Какая вкладка сейчас открыта (id, а не индекс) — нужно UIManager, чтобы
## повторное нажатие клавиши раздела закрывало экран.
func current_tab() -> StringName:
	if _current < 0 or _current >= TABS.size():
		return &""
	return TABS[_current]["id"]

func _close() -> void:
	UIManager.close(&"codex")

## Позволяет открыть «Кодекс» сразу на нужном разделе: старые клавиши
## («Журнал», «Энциклопедия») ведут в свои вкладки, а не в первую попавшуюся.
func open_tab(id: StringName) -> void:
	for i in TABS.size():
		if TABS[i]["id"] == id:
			_show_tab(i)
			return
