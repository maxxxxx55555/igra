extends Control
## Экран достижений.
##
## Здесь лежал свой словарь из четырёх достижений с русскими названиями,
## а настоящих в игре двадцать (AchievementManager.ACHIEVEMENTS, уже с
## ключами локализации). Игрок видел четыре строки по-русски на любом языке
## и не знал об остальных шестнадцати. Теперь список берётся у менеджера
## через get_all() — он же отдаёт переведённые name/description.

var _list: VBoxContainer
var _counter: Label
func _ready() -> void:
	EventBus.achievement_unlocked.connect(func(_id: StringName) -> void: _refresh())
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
	panel.custom_minimum_size = Vector2(520, 460)
	add_child(panel)
	var vb := VBoxContainer.new()
	panel.add_child(vb)
	var t := Label.new()
	t.text = LocalizationManager.t("ACHIEVEMENTS_TITLE")
	t.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_TITLE)
	t.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	_counter = Label.new()
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_counter.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
	vb.add_child(_counter)
	# Двадцать достижений с описаниями в фиксированную панель не помещаются.
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(440, 330)
	vb.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	var back := Button.new()
	back.text = LocalizationManager.t("ui_close")
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(func() -> void: UIManager.close(&"achievements"))
	vb.add_child(back)
	_refresh()
func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	var am := get_node_or_null("/root/AchievementManager")
	if am == null or not am.has_method("get_all"):
		return
	var all: Array = am.get_all()
	var done := 0
	for entry in all:
		var unlocked: bool = bool(entry.get("unlocked", false))
		if unlocked:
			done += 1
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 0)
		var l := Label.new()
		var mark: String = "[+]" if unlocked else "[ ]"
		# Секретные достижения не раскрываются до получения.
		var is_secret: bool = bool(entry.get("secret", false)) and not unlocked
		var title: String = "???" if is_secret else String(entry.get("name", ""))
		l.text = "%s  %s" % [mark, title]
		l.add_theme_color_override("font_color",
			ThemeProvider.COLOR_AMBER if unlocked else ThemeProvider.COLOR_TEXT_DIM)
		row.add_child(l)
		if not is_secret:
			var d := Label.new()
			d.text = "        %s" % String(entry.get("description", ""))
			d.add_theme_font_size_override("font_size", 12)
			d.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
			row.add_child(d)
		_list.add_child(row)
	_counter.text = LocalizationManager.tf("ACH_PROGRESS", [done, all.size()])