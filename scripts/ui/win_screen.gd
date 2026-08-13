extends Control
## Экран победы. Показывает ту концовку, которую игрок действительно
## заслужил, а не один фиксированный текст.
##
## EndingsManager считает пять концовок (Свет / Надежда / Выживший /
## Тьма / Истина) по восстановленным районам, документам и секретам —
## и его результат нигде не показывался: экран всегда писал «Свет
## вернулся в город». Теперь берём выбранную концовку и её описание,
## а заодно показываем итоговую статистику забега.

var _title: Label = null
var _subtitle: Label = null
var _stats: Label = null

func _ready() -> void:
	_build()
	visibility_changed.connect(func() -> void:
		if visible:
			_refresh())
	_refresh()

func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = ThemeProvider.build_theme()
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.09, 0.02, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.add_theme_constant_override("separation", 16)
	add_child(vb)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_title)

	_subtitle = Label.new()
	_subtitle.custom_minimum_size = Vector2(620, 0)
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
	vb.add_child(_subtitle)

	_stats = Label.new()
	_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
	vb.add_child(_stats)

	var b := Button.new()
	b.text = LocalizationManager.t("BTN_MAIN_MENU")
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(220, 44)
	b.pressed.connect(func() -> void: GameManager.return_to_menu())
	vb.add_child(b)

func _refresh() -> void:
	if _title == null:
		return
	var em := get_node_or_null("/root/EndingsManager")
	var data: Dictionary = {}
	if em != null and em.has_method("get_ending_data"):
		data = em.get_ending_data()
	_title.text = String(data.get("title", LocalizationManager.t("VICTORY_TITLE")))
	_subtitle.text = String(data.get("description", ""))
	if data.has("color"):
		_title.add_theme_color_override("font_color", data["color"])

	var pt := get_node_or_null("/root/ProgressTracker")
	var pg := get_node_or_null("/root/PowerGrid")
	var docs: int = pt.count_docs() if pt != null else 0
	var total_docs: int = Endings.TOTAL_DOCUMENTS
	var districts: int = 0
	if pg != null:
		for d in pg.all_districts():
			if d.stage >= DistrictData.Stage.FULL:
				districts += 1
	_stats.text = LocalizationManager.tf("WIN_SUMMARY",
		[districts, Endings.TOTAL_DISTRICTS, docs, total_docs])
