extends Control

const MUSIC_CREDITS := ["CREDITS_COMBAT_TRACKS", "CREDITS_HYMN", "CREDITS_MOONLIGHT", "CREDITS_MUSIC_CHANGES"]

func _ready() -> void:
	add_to_group("ui_root")
	theme = ThemeProvider.build_theme()
	var scroll := ScrollContainer.new()
	scroll.name = "MusicLicences"
	scroll.custom_minimum_size.y = 220.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	$VBox.add_child(scroll)
	$VBox.move_child(scroll, $VBox/L3.get_index() + 1)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 16)
	scroll.add_child(column)
	for credit: String in MUSIC_CREDITS:
		var label := Label.new()
		label.text = credit
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 20)
		column.add_child(label)
	for label: Label in $VBox.find_children("*", "Label", true, false):
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	$VBox/Back.custom_minimum_size.y = 48.0
	resized.connect(_fit_column)
	_fit_column()
	$VBox/Back.pressed.connect(func(): Routes.to_menu())

func _fit_column() -> void:
	var half: float = minf(540.0, maxf(120.0, (size.x - 64.0) * 0.5))
	$VBox.offset_left = -half
	$VBox.offset_right = half
	$VBox.offset_top = -minf(320.0, (size.y - 64.0) * 0.5)
	$VBox.offset_bottom = minf(320.0, (size.y - 64.0) * 0.5)
