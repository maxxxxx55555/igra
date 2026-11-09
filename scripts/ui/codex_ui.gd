extends Control
## Full-screen archive with quiet section navigation; pages remain lazy.
const TABS: Array[Dictionary] = [
	{"id": &"journal", "label": "JOURNAL_TITLE", "script": "res://scripts/ui/journal_ui.gd"},
	{"id": &"quests", "label": "CODEX_TAB_QUESTS", "script": "res://scripts/ui/quest_journal.gd"},
	{"id": &"achievements", "label": "ACHIEVEMENTS_TITLE", "script": "res://scripts/ui/achievements_ui.gd"},
	{"id": &"stats", "label": "STATS_TITLE", "script": "res://scripts/ui/stats_ui.gd"},
	{"id": &"bestiary", "label": "enc_title", "script": "res://scripts/ui/encyclopedia_ui.gd"},
	{"id": &"help", "label": "Help", "script": "res://scripts/ui/help_ui.gd"},
	{"id": &"collection", "label": "COLLECTION_TITLE", "script": "res://scripts/ui/collection_ui.gd"},
	{"id": &"photos", "label": "PHOTO_ALBUM_TITLE", "script": "res://scripts/ui/photo_album_ui.gd"},
]


var _content: Control
var _buttons: Array[Button] = []
var _pages: Dictionary = {}
var _current: int = -1
var _title_label: Label
var _close_btn: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = ThemeProvider.build_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = ThemeProvider.COLOR_BG_DARK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 64
	root.offset_right = -64
	root.offset_top = 42
	root.offset_bottom = -42
	root.add_theme_constant_override("separation", 28)
	add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 36)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)
	_close_btn = Button.new()
	_close_btn.text = LocalizationManager.t("ui_close")
	ThemeProvider.style_control(_close_btn, &"ghost")
	_close_btn.pressed.connect(_close)
	header.add_child(_close_btn)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 48)
	root.add_child(body)
	var nav := HFlowContainer.new()
	nav.add_theme_constant_override("separation", 4)
	_content = Control.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.resized.connect(_fit_pages)
	body.add_child(_content)
	root.add_child(nav)
	for i: int in TABS.size():
		var button := Button.new()
		button.text = LocalizationManager.t(String(TABS[i]["label"]))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 48)
		button.pressed.connect(_show_tab.bind(i))
		nav.add_child(button)
		_buttons.append(button)
	_show_tab(0)
	LocalizationManager.language_changed.connect(func(_language: String) -> void:
		_title_label.text = LocalizationManager.t(String(TABS[_current]["label"]))
		_close_btn.text = LocalizationManager.t("ui_close")
		for i: int in TABS.size():
			_buttons[i].text = LocalizationManager.t(String(TABS[i]["label"])))

func _show_tab(index: int) -> void:
	if index < 0 or index >= TABS.size() or index == _current:
		return
	_current = index
	_title_label.text = LocalizationManager.t(String(TABS[index]["label"]))
	for page: Control in _pages.values():
		page.hide()
	var id: StringName = TABS[index]["id"]
	var page: Control = _pages.get(id)
	if page == null:
		page = load(String(TABS[index]["script"])).new()
		page.set("embedded", true)
		_pages[id] = page
		_content.add_child(page)
		page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_fit_pages()
		for label: Node in page.find_children("*", "Label", true, false):
			if (label as Label).text == _title_label.text and (label as Label).get_theme_font_size("font_size") >= 22:
				(label as Label).hide()
				break
	page.show()
	for i: int in _buttons.size():
		ThemeProvider.style_control(_buttons[i], &"ghost", i == index)

func _fit_pages() -> void:
	for id: StringName in _pages:
		var page: Control = _pages[id]
		var margin: float = 0.0 if id == &"journal" else maxf((_content.size.x - 1080.0) * 0.5, 0.0)
		page.offset_left = margin
		page.offset_right = -margin

func current_tab() -> StringName:
	return TABS[_current]["id"] if _current >= 0 else &""

func open_tab(id: StringName) -> void:
	for i: int in TABS.size():
		if TABS[i]["id"] == id:
			_show_tab(i)
			return

func _close() -> void:
	UIManager.close(&"codex")
