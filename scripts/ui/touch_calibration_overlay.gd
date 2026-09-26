extends Control
## FINAL HARDENING PASS (BLOCKER 3): one-time "feel it before you play it"
## pass over the same 3 things this pass added timing budgets for -
## joystick drag, interact tap, haptic pulse. Shown once (has_touch_ui()
## AND not SettingsManager touch_calibration_done), from hud_3d.gd's
## _ready(). Built in code, matching settings_screen.gd/help_ui.gd's own
## convention rather than a hand-authored .tscn.

signal finished

const STEPS := 3
var _step: int = 0
var _joy: Control = null
var _label: Label = null
var _btn: Button = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = ThemeProvider.build_theme()

	var bg := ColorRect.new()
	bg.color = Color(0.0471, 0.0627, 0.0863, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.custom_minimum_size = Vector2(440, 0)
	vb.add_theme_constant_override("separation", 18)
	add_child(vb)

	var title := Label.new()
	title.text = LocalizationManager.t("TOUCH_CAL_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	title.add_theme_font_size_override("font_size", ThemeProvider.FONT_SIZE_TITLE)
	vb.add_child(title)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vb.add_child(_label)

	var js_script: Script = load("res://scripts/ui/virtual_joystick.gd")
	_joy = Control.new()
	_joy.set_script(js_script)
	_joy.custom_minimum_size = Vector2(160, 160)
	_joy.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(_joy)

	_btn = Button.new()
	_btn.pressed.connect(_on_step_button)
	vb.add_child(_btn)

	# A drag on the embedded joystick is a real InputService.set_joy_move_dir
	# call (virtual_joystick.gd's own _emit_dir()) - poll it like the rest of
	# the game does, rather than re-deriving movement from raw touch here.
	set_process(true)
	_show_step()

func _process(_delta: float) -> void:
	if _step == 0 and InputService.get_move_dir().length() > 0.3:
		_advance()

func _on_step_button() -> void:
	match _step:
		1:
			InputService.request_interact()
			_advance()
		2:
			_finish()

func _advance() -> void:
	_step += 1
	if _step >= STEPS:
		_finish()
	else:
		_show_step()

func _show_step() -> void:
	match _step:
		0:
			_label.text = LocalizationManager.t("TOUCH_CAL_STEP_DRAG")
			_joy.visible = true
			_btn.visible = false
		1:
			_label.text = LocalizationManager.t("TOUCH_CAL_STEP_INTERACT")
			_joy.visible = false
			_btn.visible = true
			_btn.text = LocalizationManager.t("TOUCH_CAL_BTN_INTERACT")
		2:
			_label.text = LocalizationManager.t("TOUCH_CAL_STEP_HAPTIC")
			_joy.visible = false
			_btn.visible = true
			_btn.text = LocalizationManager.t("TOUCH_CAL_BTN_CONTINUE")
			if OS.has_feature("mobile") and SettingsManager.haptics_enabled():
				Input.vibrate_handheld(60)

func _finish() -> void:
	SettingsManager.set_setting("touch_calibration_done", true)
	finished.emit()
	queue_free()
