extends CanvasLayer
## The Key Bindings dialog of the Settings screen (a layer of its own, like the reset confirmation): one row per action; a click on the key
## waits for the next key press (Escape cancels); a key another action holds swaps places with this one. Choices go to the setting "keybinds".

const _InputRemap := preload("res://scripts/systems/input_remap.gd")
const DIALOG_MIN := Vector2(520.0, 520.0)
const LIST_MIN_H: float = 380.0
const KEY_BUTTON_W: float = 170.0

var _waiting: StringName = &""
var _buttons: Dictionary = {}

func _ready() -> void:
	layer = 130
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.047, 0.063, 0.086, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var panel := PanelContainer.new()
	panel.name = "Dialog"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = DIALOG_MIN
	dim.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var title := Label.new()
	title.text = LocalizationManager.t("Key Bindings")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_TITLE)
	title.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	box.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = LIST_MIN_H
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var rows := GridContainer.new()
	rows.columns = 2
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("v_separation", 8)
	scroll.add_child(rows)
	for action: StringName in _InputRemap.LABELS:
		var label := Label.new()
		label.text = LocalizationManager.t(String(_InputRemap.LABELS[action]))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rows.add_child(label)
		var key_button := Button.new()
		key_button.name = String(action)
		key_button.custom_minimum_size.x = KEY_BUTTON_W
		key_button.focus_mode = Control.FOCUS_NONE
		key_button.pressed.connect(_wait_for.bind(action))
		rows.add_child(key_button)
		_buttons[action] = key_button
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	box.add_child(foot)
	var reset := Button.new()
	reset.name = "Reset"
	reset.text = LocalizationManager.t("KEYS_RESET")
	reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset.focus_mode = Control.FOCUS_NONE
	reset.pressed.connect(_reset)
	foot.add_child(reset)
	var back := Button.new()
	back.name = "Back"
	back.text = LocalizationManager.t("Back")
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(queue_free)
	foot.add_child(back)
	_refresh()

func _wait_for(action: StringName) -> void:
	_waiting = action
	_refresh()

func _reset() -> void:
	_InputRemap.reset()
	SettingsManager.set_setting("keybinds", {})
	_waiting = &""
	_refresh()

func _refresh() -> void:
	for action: StringName in _buttons:
		(_buttons[action] as Button).text = LocalizationManager.t("KEYS_PRESS") if action == _waiting else _InputRemap.key_text(_InputRemap.key_of(action))

## Escape answers the dialog before the screen under it: it cancels a wait, and closes the dialog when nothing waits.
func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	get_viewport().set_input_as_handled()
	var code: int = int(key.physical_keycode) if key.physical_keycode != KEY_NONE else int(key.keycode)
	if code == KEY_ESCAPE:
		if _waiting == &"":
			queue_free()
		_waiting = &""
	elif _waiting != &"":
		SettingsManager.set_setting("keybinds", _InputRemap.bind(_waiting, code))
		_waiting = &""
	_refresh()
