extends CanvasLayer
## EndingScreen: shown when game ends.  kind = "win" | "lose".
## Self-dismisses on input; advances the ending-shown save flag.

const COLOR_WIN_BG := Color(0.02, 0.05, 0.10, 0.92)
const COLOR_LOSE_BG := Color(0.10, 0.02, 0.04, 0.92)
const COLOR_AMBER := Color(1.0, 0.75, 0.30)
const COLOR_TEXT := Color(0.96, 0.95, 0.90)

@export var kind: String = "win"
var _bg: ColorRect
var _title: Label
var _sub: Label
var _hint: Label
var _tween: Tween

func _ready() -> void:
	layer = 100
	_build()

func show_ending(k: String) -> void:
	kind = k
	if _bg == null:
		_build()
	_apply_kind()

func _build() -> void:
	_bg = ColorRect.new()
	_bg.color = COLOR_WIN_BG
	_bg.anchor_right = 1.0
	_bg.anchor_bottom = 1.0
	_bg.modulate.a = 0.0
	add_child(_bg)

	var center := CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	center.add_child(box)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 64)
	_title.add_theme_color_override("font_color", COLOR_AMBER)
	box.add_child(_title)

	_sub = Label.new()
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.add_theme_font_size_override("font_size", 22)
	_sub.add_theme_color_override("font_color", COLOR_TEXT)
	box.add_child(_sub)

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 16)
	_hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	_hint.text = "[ESC]  /  [TAP]"
	box.add_child(_hint)

	_apply_kind()
	_tween = create_tween()
	_tween.tween_property(_bg, "modulate:a", 1.0, 1.2)

func _apply_kind() -> void:
	if _title == null:
		return
	var key_title: StringName = &"msg_win" if kind == "win" else &"msg_lose"
	var key_msg: StringName = &"msg_win" if kind == "win" else &"msg_lose"
	# Единый источник переводов — LocalizationManager (data/i18n/*.json).
	_title.text = LocalizationManager.t(String(key_title))
	_sub.text = LocalizationManager.t(String(key_msg))
	if _bg != null:
		_bg.color = COLOR_WIN_BG if kind == "win" else COLOR_LOSE_BG

func _unhandled_input(event: InputEvent) -> void:
	if _tween != null and _tween.is_running():
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventScreenTouch and event.pressed):
		var sl := get_tree().root.get_node_or_null("SaveLoad")
		if sl != null and sl.has_method("mark_ending_shown"):
			sl.mark_ending_shown()
		Routes.to_menu()