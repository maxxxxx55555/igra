extends Control
## Журнал найденных документов.
##
## Раньше здесь был жёстко зашитый словарь из двух документов, причём
## по-русски. Игрок при этом может найти 13 штук: 11 разложены по районам
## из data/documents/documents_catalog.json (33 записи с готовыми текстами)
## плюс два выдаются за события. Одиннадцать из них не отображались нигде —
## подобрал и потерял. Теперь журнал читает тот же каталог, что и подбор,
## и показывает полный текст в отдельной панели, а не всплывающим уведомлением
## на пару секунд.

const CATALOG_PATH: String = "res://data/documents/documents_catalog.json"

var _list: VBoxContainer = null
var _reader: PanelContainer = null
var _reader_title: Label = null
var _reader_text: RichTextLabel = null
var _catalog: Dictionary = {}

func _ready() -> void:
	_load_catalog()
	EventBus.document_unlocked.connect(func(_id: StringName) -> void: _refresh())
	_build()

## Каталог — список {doc_id,title,content}; переводим в словарь по id.
## Файл читается с utf-8-sig: у него BOM, и без этого первый ключ битый.
func _load_catalog() -> void:
	if not FileAccess.file_exists(CATALOG_PATH):
		return
	var f := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Array):
		return
	for entry in parsed:
		if entry is Dictionary and entry.has("doc_id"):
			_catalog[String(entry["doc_id"])] = {
				"title": String(entry.get("title", "")),
				"text": String(entry.get("content", "")),
			}

func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = ThemeProvider.build_theme()
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.07, 0.94)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(860, 500)
	add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)

	var t := Label.new()
	t.text = LocalizationManager.t("JOURNAL_TITLE")
	t.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_TITLE)
	t.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 12)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(cols)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(330, 390)
	cols.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 6)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

	_reader = PanelContainer.new()
	_reader.custom_minimum_size = Vector2(490, 390)
	cols.add_child(_reader)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 8)
	_reader.add_child(rv)
	_reader_title = Label.new()
	_reader_title.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	_reader_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rv.add_child(_reader_title)
	_reader_text = RichTextLabel.new()
	_reader_text.fit_content = false
	_reader_text.scroll_active = true
	_reader_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_reader_text.add_theme_color_override("default_color", ThemeProvider.COLOR_TEXT)
	rv.add_child(_reader_text)

	var back := Button.new()
	back.text = LocalizationManager.t("ui_close")
	back.focus_mode = Control.FOCUS_NONE
	back.custom_minimum_size = Vector2(160, 38)
	back.pressed.connect(func() -> void: UIManager.close(&"journal"))
	vb.add_child(back)
	_refresh()

func _refresh() -> void:
	if _list == null:
		return
	for c in _list.get_children():
		c.queue_free()
	var found := 0
	var ids := _catalog.keys()
	ids.sort()
	for id in ids:
		var unlocked: bool = ProgressTracker.is_doc_unlocked(String(id))
		if unlocked:
			found += 1
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.text = String(_catalog[id]["title"]) if unlocked else "???"
		b.disabled = not unlocked
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if unlocked:
			b.pressed.connect(_open.bind(String(id)))
		_list.add_child(b)
	_reader_title.text = LocalizationManager.tf("JOURNAL_FOUND", [found, _catalog.size()])
	_reader_text.text = ""

func _open(doc_id: String) -> void:
	var entry: Dictionary = _catalog.get(doc_id, {})
	_reader_title.text = String(entry.get("title", ""))
	_reader_text.text = String(entry.get("text", ""))
