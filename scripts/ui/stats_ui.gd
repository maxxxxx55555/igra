extends Control
## Встроен во вкладку «Кодекса»: тогда экран не рисует свой затемняющий фон
## и кнопку закрытия — их даёт общая рамка, — а панель растягивается на всю
## вкладку вместо центрирования.
var embedded: bool = false
const DIFFICULTY_KEYS: Array[String] = ["diff_easy", "diff_normal", "diff_hard"]

func _ready() -> void:
	_build()
	# Static audit 2026-09-08: title/close-button text was built once, never
	# retranslated on a live language switch. Same rebuild pattern as
	# settings_screen.gd/quest_journal.gd.
	LocalizationManager.language_changed.connect(func(_l: String) -> void:
		for c in get_children():
			c.queue_free()
		_build())
func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = ThemeProvider.build_theme()
	if not embedded:
		# V2 SKIN WIRING P4: real background art over the old flat tint.
		var bg_path := "res://assets/textures/screens_v2/character_dim.png"
		if ResourceLoader.exists(bg_path):
			var bg_tex := TextureRect.new()
			bg_tex.texture = load(bg_path)
			bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			bg_tex.stretch_mode = TextureRect.STRETCH_SCALE
			bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
			add_child(bg_tex)
			var tint := ColorRect.new()
			tint.color = Color(0.04, 0.05, 0.07, 0.5)
			tint.set_anchors_preset(Control.PRESET_FULL_RECT)
			add_child(tint)
		else:
			var bg := ColorRect.new()
			bg.color = Color(0.04, 0.05, 0.07, 0.94)
			bg.set_anchors_preset(Control.PRESET_FULL_RECT)
			add_child(bg)
	var panel := PanelContainer.new()
	if embedded:
		panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	else:
		panel.set_anchors_preset(Control.PRESET_CENTER)
		panel.grow_horizontal = Control.GROW_DIRECTION_BOTH  # centre anchor + grow both = centred
		panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(460, 360)
	add_child(panel)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	panel.add_child(hb)
	# P2 (FINAL INTEGRATION wave): real player render, side panel next to
	# the stats column - delivered mid-session (REPORT_UNBLOCK_V2.md),
	# this was logged as blocked/missing earlier in this same session.
	var render_path := "res://assets/textures/renders_v2/player_512x768.png"
	if ResourceLoader.exists(render_path):
		var render := TextureRect.new()
		render.custom_minimum_size = Vector2(128, 192)
		render.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		render.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hb.add_child(render)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(vb)
	var t := Label.new()
	t.text = LocalizationManager.t("STATS_TITLE")
	t.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_TITLE)
	t.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(tabs)
	var s := ProgressTracker.get_stats()
	var overall := _tab(tabs, "STATS_TAB_OVERALL")
	_line(overall, LocalizationManager.t("STATS_LEVEL"), "%d" % XpManager.get_level())
	_line(overall, LocalizationManager.t("STATS_COINS"), "%d" % CoinWallet.get_coins())
	_line(overall, LocalizationManager.t("STATS_TIME"), LocalizationManager.tf("STATS_SECONDS", [int(s["time_played"])]), "clock")
	_line(overall, LocalizationManager.t("STATS_DIFFICULTY"), LocalizationManager.t(DIFFICULTY_KEYS[clampi(int(SettingsManager.get_setting("difficulty", 1)), 0, 2)]))
	_line(overall, LocalizationManager.t("STATS_NGPLUS"), "%d" % NewGamePlus.get_current_ng_plus())
	_line(overall, LocalizationManager.t("STATS_DISTRICTS"), "%d / %d" % [s["districts"], PowerGrid.all_districts().size()], "district")
	_line(overall, LocalizationManager.t("STATS_DEATHS"), "%d" % ProgressTracker.deaths)
	var combat := _tab(tabs, "STATS_TAB_COMBAT")
	_line(combat, LocalizationManager.t("STATS_KILLS"), "%d" % s["kills"], "skull")
	_line(combat, LocalizationManager.t("STATS_SHADOWS"), "%d" % ProgressTracker.shadow_kills)
	_line(combat, LocalizationManager.t("STATS_SHOTS"), "%d" % ProgressTracker.shots)
	_line(combat, LocalizationManager.t("STATS_DAMAGE_TAKEN"), "%d" % int(ProgressTracker.damage_taken))
	for id in ProgressTracker.kills_by:
		_line(combat, LocalizationManager.name_for("MONSTER_", StringName(id), String(id).capitalize()), "%d" % ProgressTracker.kills_by[id])
	var explore := _tab(tabs, "STATS_TAB_EXPLORATION")
	_line(explore, LocalizationManager.t("STATS_SECRETS"), "%d / %d" % [s["secrets"], ProgressTracker.MAX_SECRETS], "document")
	_line(explore, LocalizationManager.t("STATS_PUZZLES"), "%d" % s["puzzles"])
	_line(explore, LocalizationManager.t("STATS_DISTANCE"), LocalizationManager.tf("STATS_METERS", [int(ProgressTracker.distance)]))
	_line(explore, LocalizationManager.t("STATS_JUMPS"), "%d" % ProgressTracker.jumps)
	_line(explore, LocalizationManager.t("STATS_ITEMS"), "%d" % ProgressTracker.items_picked)
	var collection := _tab(tabs, "STATS_TAB_COLLECTION")
	_line(collection, LocalizationManager.t("STATS_CRAFTED"), "%d" % ProgressTracker.crafted)
	_line(collection, LocalizationManager.t("STATS_DOCUMENTS"), "%d / %d" % [ProgressTracker.count_docs(), Endings.get_total_documents()])
	_line(collection, LocalizationManager.t("STATS_PHOTOS"), "%d / %d" % [SaveSystem.get_photo_count(), ProgressTracker.photo_total()])
	_line(collection, LocalizationManager.t("STATS_BLUEPRINTS"), "%d / %d" % [ProgressTracker.blueprints_known(), ProgressTracker.BLUEPRINT_IDS.size()])
	_line(collection, LocalizationManager.t("STATS_WEAPONS"), "%d / %d" % [ProgressTracker.get_weapons().size(), ProgressTracker.WEAPON_IDS.size()])
	var seen := 0
	for id in Encyclopedia.all_ids():
		seen += int(Encyclopedia.is_unlocked(id))
	_line(collection, LocalizationManager.t("STATS_BESTIARY"), "%d / %d" % [seen, Encyclopedia.all_ids().size()])
	_line(collection, LocalizationManager.t("STATS_SKILLS"), "%d" % SkillTreeManager.get_unlocked_skills().size())

	# GOLD MASTER v5 hooks pass: local leaderboard — top runs by fastest
	# win, independent of SaveSystem's save/reset cycle (a New Game must
	# not erase past records).
	if LocalLeaderboard != null and LocalLeaderboard.has_runs():
		var lb_title := Label.new()
		lb_title.text = LocalizationManager.t("LEADERBOARD_TITLE")
		lb_title.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
		overall.add_child(lb_title)
		var i := 1
		for run in LocalLeaderboard.get_top_runs(5):
			var mins := int(run["time"]) / 60
			var secs := int(run["time"]) % 60
			_line(overall, "#%d" % i, "%02d:%02d — %d districts, %d kills" %
				[mins, secs, run["districts"], run["kills"]], "")
			i += 1

	if not embedded:
		var b := Button.new()
		b.text = LocalizationManager.t("ui_close")
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func() -> void: UIManager.close(&"stats"))
		vb.add_child(b)
## One tab page: a scrolling column of rows, named by its translated title.
func _tab(tabs: TabContainer, title_key: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = LocalizationManager.t(title_key)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	return column

## icon_id: V2 SKIN WIRING P1: icons_v2/stat_[id]_64.png, drawn before the
## label when present on disk.
func _line(p: Node, k: String, v: String, icon_id: String = "") -> void:
	var row := HBoxContainer.new()
	p.add_child(row)
	if icon_id != "":
		var icon_path := "res://assets/textures/icons_v2/stat_%s_64.png" % icon_id
		if ResourceLoader.exists(icon_path):
			var icon := TextureRect.new()
			icon.custom_minimum_size = Vector2(18, 18)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.texture = load(icon_path)
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			row.add_child(icon)
	var lk := Label.new()
	lk.text = k
	lk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lk)
	var lv := Label.new()
	lv.text = v
	lv.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	row.add_child(lv)