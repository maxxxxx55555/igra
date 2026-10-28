extends Control
const _LAYOUT := preload("res://scripts/ui/terminal_layout.gd")
var _summary: Dictionary = {}
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	LocalizationManager.language_changed.connect(_apply_localization.unbind(1))

var _t: Label
var _s: Label
var _d: Label
var _b: Button
var _b2: Button

func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vb: VBoxContainer = _LAYOUT.build(self)
	_t = Label.new()
	_t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_t.add_theme_font_size_override("font_size", 28)
	_t.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_t)
	_s = Label.new()
	_s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_s.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
	vb.add_child(_s)
	_d = Label.new()
	_d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_d.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
	vb.add_child(_d)
	# The screen is built once and shown on every death: the figures are read when it appears.
	visibility_changed.connect(func() -> void:
		if visible:
			_capture_summary()
			_apply_localization())
	_b = Button.new()
	_b.focus_mode = Control.FOCUS_ALL
	# respawn_after_death() (G16) не трогает дерево сцен, поэтому одного его
	# мало: без перезагрузки на экране оставался бы тот же мёртвый игрок с
	# 0 HP. Перезагружаем игровую сцену, как делает меню.
	_b.pressed.connect(func() -> void:
		GameManager.respawn_after_death()
		Routes.restart_game())
	vb.add_child(_b)
	_b2 = Button.new()
	_b2.focus_mode = Control.FOCUS_ALL
	_b2.pressed.connect(func() -> void: GameManager.return_to_menu())
	vb.add_child(_b2)
	_capture_summary()
	_apply_localization()

func _capture_summary() -> void:
	_summary = {"killer": ProgressTracker.last_hit_by, "seconds": int(GameManager.play_time),
		"districts": int(ProgressTracker.get_stats()["districts"]), "total": PowerGrid.all_districts().size(),
		"docs": ProgressTracker.count_docs()}
	_LAYOUT.set_ending(self, EndingsManager.get_ending())

func _apply_localization() -> void:
	_t.text = LocalizationManager.t("DEATH_TITLE")
	var killer: StringName = _summary.get("killer", &"")
	_s.text = LocalizationManager.tf("DEATH_KILLED_BY", [LocalizationManager.name_for("MONSTER_", killer, String(killer).capitalize())]) if killer != &"" else LocalizationManager.t("DEATH_BY")
	var seconds: int = _summary.get("seconds", 0)
	var districts: int = _summary.get("districts", 0)
	var total: int = _summary.get("total", 0)
	_d.text = "\n".join([
		LocalizationManager.tf("DEATH_TIME", ["%d:%02d" % [seconds / 60, seconds % 60]]),
		LocalizationManager.tf("DEATH_DISTRICTS", [districts, total, 100 * districts / maxi(total, 1)]),
		LocalizationManager.tf("DEATH_DOCS", [_summary.get("docs", 0), Endings.get_total_documents()])])
	_b.text = LocalizationManager.t("retry")
	_b2.text = LocalizationManager.t("back_menu")
