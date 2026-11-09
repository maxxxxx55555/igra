extends Control
## Physical evidence and its transcription, without a wall of locked placeholders.
const CATALOG_PATH: String = "res://data/documents/documents_catalog.json"
var embedded: bool = false
var _catalog: Dictionary = {}
var _list: VBoxContainer
var _title: Label
var _status: Label
var _locked: Label
var _reader_title: Label
var _reader_text: RichTextLabel
var _selected: String = ""

func _ready() -> void:
	theme = ThemeProvider.build_theme()
	_build()
	_load_catalog()
	_refresh()
	EventBus.document_unlocked.connect(func(_id: StringName) -> void: _refresh())
	LocalizationManager.language_changed.connect(func(_language: String) -> void:
		_load_catalog()
		_refresh())

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
			# Content-authored entries (e.g. suburbs lore) ship i18n keys
			# instead of raw text so they translate; legacy entries keep
			# raw text as-is.
			var title := LocalizationManager.t(String(entry["title_key"])) \
				if entry.has("title_key") else String(entry.get("title", ""))
			var text := LocalizationManager.t(String(entry["content_key"])) \
				if entry.has("content_key") else String(entry.get("content", ""))
			_catalog[String(entry["doc_id"])] = {
				"title": title, "text": text,
				"world_refs": entry.get("world_refs", []),
			}

func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 26)
	add_child(root)
	_title = Label.new()
	_title.visible = not embedded
	_title.add_theme_font_size_override("font_size", 36)
	_title.add_theme_font_override("font", ThemeProvider.heading_font())
	root.add_child(_title)
	_status = Label.new()
	_status.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
	root.add_child(_status)
	var spread := HBoxContainer.new()
	spread.add_theme_constant_override("separation", 36)
	spread.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spread)
	var index := VBoxContainer.new()
	index.custom_minimum_size.x = 0
	index.add_theme_constant_override("separation", 12)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	index.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)
	_locked = Label.new()
	_locked.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
	_locked.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	index.add_child(_locked)
	var art := TextureRect.new()
	art.texture = load("res://assets/textures/screens_v2/journal_paper.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var reading := PanelContainer.new()
	var paper := StyleBoxFlat.new()
	paper.bg_color = ThemeProvider.COLOR_BG_DARK
	paper.set_content_margin_all(0.0)
	reading.add_theme_stylebox_override("panel", paper)
	reading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reading.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", 22)
	reading.add_child(copy)
	_reader_title = Label.new()
	_reader_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reader_title.add_theme_font_size_override("font_size", 30)
	_reader_title.add_theme_font_override("font", ThemeProvider.heading_font())
	_reader_title.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT)
	copy.add_child(_reader_title)
	_reader_text = RichTextLabel.new()
	_reader_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_reader_text.scroll_active = true
	_reader_text.add_theme_font_size_override("normal_font_size", 20)
	_reader_text.add_theme_color_override("default_color", ThemeProvider.COLOR_TEXT)
	copy.add_child(_reader_text)
	spread.add_child(art)
	art.size_flags_stretch_ratio = 1.8
	var editorial := VBoxContainer.new()
	editorial.custom_minimum_size.x = 530
	editorial.add_theme_constant_override("separation", 24)
	spread.add_child(editorial)
	index.custom_minimum_size.y = 180
	editorial.add_child(index)
	editorial.add_child(reading)
	if not embedded:
		var close := Button.new()
		close.text = LocalizationManager.t("ui_close")
		ThemeProvider.style_control(close, &"ghost")
		close.pressed.connect(func() -> void: UIManager.close(&"journal"))
		root.add_child(close)

func _refresh() -> void:
	_title.text = LocalizationManager.t("JOURNAL_TITLE")
	for child: Node in _list.get_children():
		child.queue_free()
	var ids: Array = _catalog.keys()
	ids.sort()
	var found: int = 0
	var first_unlocked: String = ""
	for id: Variant in ids:
		if not ProgressTracker.is_doc_unlocked(String(id)):
			continue
		found += 1
		if first_unlocked.is_empty():
			first_unlocked = String(id)
		var row := Button.new()
		row.text = String(_catalog[id]["title"])
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ThemeProvider.style_control(row, &"row", String(id) == _selected)
		row.pressed.connect(_open.bind(String(id)))
		_list.add_child(row)
	_status.text = LocalizationManager.tf("JOURNAL_FOUND", [found, Endings.get_total_documents()])
	_locked.text = "%s · %d" % [LocalizationManager.t("SKILL_LOCKED"), maxi(Endings.get_total_documents() - found, 0)]
	if _selected.is_empty():
		_selected = first_unlocked
	if not _selected.is_empty():
		_open(_selected)
	elif found == 0:
		_reader_title.text = LocalizationManager.t("JOURNAL_TAB_DOCUMENTS")
		_reader_text.text = LocalizationManager.t("TUT_JOURNAL")

func _open(doc_id: String) -> void:
	_selected = doc_id
	var entry: Dictionary = _catalog.get(doc_id, {})
	_reader_title.text = String(entry.get("title", ""))
	_reader_text.text = String(entry.get("text", "")) + _related_line(entry.get("world_refs", []))
	for child: Node in _list.get_children():
		if child is Button:
			ThemeProvider.style_control(child as Button, &"row", (child as Button).text == _reader_title.text)

func _related_line(world_refs: Array) -> String:
	var names: Array = []
	for ref_id in world_refs:
		var id := String(ref_id)
		var entry: Dictionary = {}
		if id.begins_with("char_"):
			entry = WorldBible.get_character(id)
		elif id.begins_with("faction_"):
			entry = WorldBible.get_faction(id)
		if entry.is_empty() or not WorldBible.is_revealed(entry.get("reveal", {})):
			continue
		var keys: Dictionary = entry.get("i18n_keys", {})
		if keys.has("title"):
			names.append(LocalizationManager.t(String(keys["title"])))
	if names.is_empty():
		return ""
	return "\n\n" + LocalizationManager.tf("JOURNAL_RELATED", [", ".join(names)])
