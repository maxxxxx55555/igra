extends Control
const DOCS := {
	"doc_engineer_log": {"title": "Отчёт инженера #1",
		"text": "«…цепь не выдержала. Свет погас не из-за аварии — его будто отключили намеренно. В темноте что-то двигалось…»"},
	"doc_family_letter": {"title": "Письмо семье",
		"text": "«Если вы читаете это — я не вернулся с подстанции. Не ищите меня в темноте. Ищите свет.»"},
}
var _list: VBoxContainer
func _ready() -> void:
	EventBus.document_unlocked.connect(func(_id: StringName) -> void: _refresh())
	_build()
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
	panel.custom_minimum_size = Vector2(540, 460)
	add_child(panel)
	var vb := VBoxContainer.new()
	panel.add_child(vb)
	var t := Label.new()
	t.text = "ЖУРНАЛ"
	t.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_TITLE)
	t.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	vb.add_child(_list)
	var back := Button.new()
	back.text = "Закрыть"
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(func() -> void: UIManager.close(&"journal"))
	vb.add_child(back)
	_refresh()
func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	for id in DOCS.keys():
		var unlocked := ProgressTracker.is_doc_unlocked(id)
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.text = DOCS[id]["title"] if unlocked else "???"
		b.disabled = not unlocked
		var txt: String = DOCS[id]["text"]
		b.pressed.connect(func() -> void: EventBus.inventory_notice.emit(txt))
		_list.add_child(b)