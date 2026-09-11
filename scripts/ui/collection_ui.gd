extends Control
## Collection Album (GOLD MASTER v5 hooks pass): one card per district,
## district-accent-colored, each with a found/total progress bar for that
## district's secrets (lore notes + its one main document) — the same
## unlock data journal_ui.gd already lists as text, reframed as a
## collectible-album read. Reuses DistrictLoot.LORE_DOCS/DOCUMENTS and
## ProgressTracker.is_doc_unlocked() (source of truth) rather than
## tracking a second copy of "what's found".

var embedded: bool = false

func _ready() -> void:
	_build()
	LocalizationManager.language_changed.connect(func(_l: String) -> void:
		for c in get_children():
			c.queue_free()
		_build())

func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = ThemeProvider.build_theme()
	if not embedded:
		var bg := ColorRect.new()
		bg.color = Color(0.04, 0.05, 0.07, 0.94)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(bg)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 12)
	scroll.add_child(col)

	if not embedded:
		var t := Label.new()
		t.text = LocalizationManager.t("COLLECTION_TITLE")
		t.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_TITLE)
		t.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(t)

	var overall_found := 0
	var overall_total := 0
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	col.add_child(grid)

	for district_id in DistrictSceneFactory.DISTRICTS:
		var ids: Array = []
		if DistrictLoot.DOCUMENTS.has(district_id):
			ids.append(String(DistrictLoot.DOCUMENTS[district_id]))
		if DistrictLoot.LORE_DOCS.has(district_id):
			for lid in (DistrictLoot.LORE_DOCS[district_id] as Array):
				ids.append(String(lid))
		var found := 0
		for doc_id in ids:
			if ProgressTracker.is_doc_unlocked(doc_id):
				found += 1
		overall_found += found
		overall_total += ids.size()
		grid.add_child(_district_card(district_id, found, ids.size()))

	if not embedded:
		var summary := Label.new()
		summary.text = LocalizationManager.tf("JOURNAL_FOUND", [overall_found, overall_total])
		summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		summary.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
		col.add_child(summary)
		var close_btn := Button.new()
		close_btn.text = LocalizationManager.t("ui_close")
		close_btn.focus_mode = Control.FOCUS_NONE
		close_btn.pressed.connect(func() -> void: UIManager.close(&"collection"))
		col.add_child(close_btn)

func _district_card(district_id: StringName, found: int, total: int) -> Control:
	var theme_data: Dictionary = DistrictThemes.THEMES.get(district_id, {})
	var accent: Color = theme_data.get("accent", ThemeProvider.COLOR_AMBER)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(230, 84)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(accent.r, accent.g, accent.b, 0.10)
	sb.border_color = accent
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", sb)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	panel.add_child(vb)

	var name_lbl := Label.new()
	name_lbl.text = LocalizationManager.name_for("DISTRICT_NAME_", district_id, String(district_id))
	name_lbl.add_theme_color_override("font_color", accent)
	vb.add_child(name_lbl)

	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = maxf(1, total)
	bar.value = found
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 12)
	var fg := StyleBoxFlat.new()
	fg.bg_color = accent
	fg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fg)
	vb.add_child(bar)

	var count_lbl := Label.new()
	count_lbl.text = "%d / %d" % [found, total]
	count_lbl.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vb.add_child(count_lbl)

	return panel
