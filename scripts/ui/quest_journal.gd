extends Control
class_name QuestJournal

var _tab_bar: HBoxContainer
var _quest_list: VBoxContainer
var _detail_panel: VBoxContainer
var _current_tab: int = 0
var _selected_quest: StringName = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	QuestManager.quest_started.connect(_on_quest_changed)
	QuestManager.quest_completed.connect(_on_quest_changed)
	QuestManager.quest_progress.connect(_on_quest_progress)

func _build_ui() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = ThemeProvider.build_theme()

	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.07, 0.94)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(760, 520)
	add_child(panel)

	var main_hb := HBoxContainer.new()
	panel.add_child(main_hb)

	# Left side - tabs + list
	var left_vb := VBoxContainer.new()
	left_vb.custom_minimum_size = Vector2(360, 0)
	main_hb.add_child(left_vb)

	_tab_bar = HBoxContainer.new()
	_tab_bar.add_theme_constant_override("separation", 4)
	left_vb.add_child(_tab_bar)

	var tabs := [LocalizationManager.t("QUEST_TAB_ACTIVE"), LocalizationManager.t("QUEST_TAB_DONE"), LocalizationManager.t("QUEST_TAB_ALL")]
	for i in range(tabs.size()):
		var btn := Button.new()
		btn.text = tabs[i]
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(100, 36)
		btn.pressed.connect(_on_tab_pressed.bind(i))
		_tab_bar.add_child(btn)
		if i == 0:
			btn.add_theme_class_override("TabSelected", "Button")

	_quest_list = VBoxContainer.new()
	_quest_list.add_theme_constant_override("separation", 6)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 400)
	scroll.add_child(_quest_list)
	left_vb.add_child(scroll)

	# Right side - detail panel
	var right_vb := VBoxContainer.new()
	right_vb.custom_minimum_size = Vector2(360, 0)
	main_hb.add_child(right_vb)

	var detail_title := Label.new()
	detail_title.text = LocalizationManager.t("QUEST_DETAILS")
	detail_title.add_theme_font_size_override("font_size", 18)
	detail_title.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_vb.add_child(detail_title)

	_detail_panel = VBoxContainer.new()
	_detail_panel.add_theme_constant_override("separation", 8)
	var detail_scroll := ScrollContainer.new()
	detail_scroll.custom_minimum_size = Vector2(0, 400)
	detail_scroll.add_child(_detail_panel)
	right_vb.add_child(detail_scroll)

	var close_btn := Button.new()
	close_btn.text = LocalizationManager.t("SCR_ZAKRYT")
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(func() -> void: UIManager.close(&"quest_journal"))
	right_vb.add_child(close_btn)

	_refresh_list()

func _on_tab_pressed(index: int) -> void:
	_current_tab = index
	_refresh_list()

func _on_quest_changed(quest_id: StringName) -> void:
	_refresh_list()

func _on_quest_progress(quest_id: StringName, current: int, target: int) -> void:
	if _selected_quest == quest_id:
		_show_quest_detail(quest_id)

func _refresh_list() -> void:
	for c in _quest_list.get_children():
		c.queue_free()

	var filter_active = _current_tab == 0
	var filter_completed = _current_tab == 1

	for quest_id in QuestManager.quests:
		var quest: Dictionary = QuestManager.quests[quest_id]
		var status := QuestManager.get_status(quest)
		if filter_active and status == QuestManager.STATUS_COMPLETED:
			continue
		if filter_completed and status != QuestManager.STATUS_COMPLETED:
			continue

		var btn := Button.new()
		btn.text = QuestManager.get_title(quest)
		btn.focus_mode = Control.FOCUS_NONE
		btn.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 40)
		if status == QuestManager.STATUS_ACTIVE:
			btn.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
		elif status == QuestManager.STATUS_COMPLETED:
			btn.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
		btn.pressed.connect(_show_quest_detail.bind(quest_id))
		_quest_list.add_child(btn)

func _show_quest_detail(quest_id: StringName) -> void:
	_selected_quest = quest_id
	for c in _detail_panel.get_children():
		c.queue_free()

	var quest: Dictionary = QuestManager.quests.get(String(quest_id), {})
	if quest.is_empty():
		return

	var title := Label.new()
	title.text = QuestManager.get_title(quest)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_panel.add_child(title)

	var desc := Label.new()
	desc.text = QuestManager.get_desc(quest)
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_panel.add_child(desc)

	var status_lbl := Label.new()
	var status_text := LocalizationManager.t("QUEST_STATUS_NEW")
	match QuestManager.get_status(quest):
		QuestManager.STATUS_ACTIVE:
			status_text = LocalizationManager.t("QUEST_STATUS_ACTIVE")
		QuestManager.STATUS_COMPLETED:
			status_text = LocalizationManager.t("QUEST_STATUS_DONE")
	status_lbl.text = LocalizationManager.t("QUEST_STATUS") + ": " + status_text
	status_lbl.add_theme_font_size_override("font_size", 14)
	status_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.4))
	_detail_panel.add_child(status_lbl)

	var sep := HSeparator.new()
	_detail_panel.add_child(sep)

	var obj_title := Label.new()
	obj_title.text = LocalizationManager.t("QUEST_OBJECTIVES")
	obj_title.add_theme_font_size_override("font_size", 16)
	obj_title.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	_detail_panel.add_child(obj_title)

	var current := int(quest.get("progress", 0))
	var target := int(quest.get("target_count", 1))
	for _i in 1:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)

		var checkbox := CheckBox.new()
		checkbox.disabled = true
		checkbox.button_pressed = current >= target
		hb.add_child(checkbox)

		var obj_lbl := Label.new()
		obj_lbl.text = "%s (%d/%d)" % [QuestManager.get_desc(quest), current, target]
		obj_lbl.add_theme_font_size_override("font_size", 14)
		obj_lbl.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT)
		obj_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hb.add_child(obj_lbl)

		_detail_panel.add_child(hb)

	var rewards: Dictionary = {}
	if int(quest.get("reward_coins", 0)) > 0:
		rewards[LocalizationManager.t("SCR_MONETY")] = int(quest["reward_coins"])
	for ri in quest.get("reward_items", []):
		rewards[String(ri[0])] = int(ri[1])
	if not rewards.is_empty():
		var r_sep := HSeparator.new()
		_detail_panel.add_child(r_sep)

		var r_title := Label.new()
		r_title.text = LocalizationManager.t("QUEST_REWARDS")
		r_title.add_theme_font_size_override("font_size", 16)
		r_title.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
		_detail_panel.add_child(r_title)

		for key in rewards:
			var r_lbl := Label.new()
			r_lbl.text = "  %s: %s" % [key, str(rewards[key])]
			r_lbl.add_theme_font_size_override("font_size", 14)
			r_lbl.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT)
			_detail_panel.add_child(r_lbl)