class_name MobileHudController
extends CanvasLayer

## Bespoke Free Fire-style HUD for The Last Streetlight:
## - Replaces 15+ scattered/overlapping buttons & hanging Wi-Fi bonus widget.
## - Clean top-left Battery/Warmth/Visibility card, top-center Objective pill,
##   bottom-left thumb joystick, 4 clean right-thumb actions (USE/LIGHT/SNEAK/RUN),
##   quick MAP button, clean non-overlapping 3-slot quick belt, and Free Fire drawer (☰) with full Edit HUD.

signal action_triggered(action_name: StringName)
signal hotbar_slot_selected(slot_index: int)
signal move_vector_changed(move_vec: Vector2)
signal hud_drawer_toggled(is_open: bool)

const SAVE_PATH: String = "user://hud_layout_v3.json"
const SAVE_SALT: String = "tls_hud_v3_f92a7c14"
const MIN_TOUCH_MM: float = 9.2
const PRIMARY_TOUCH_MM: float = 11.8
const JOYSTICK_MM: float = 24.5
const DRAWER_ANIM_SEC: float = 0.16
const SCALE_MIN: float = 0.75
const SCALE_MAX: float = 1.40
const ALPHA_MIN: float = 0.40
const ALPHA_MAX: float = 1.00

const COLOR_BG: Color = Color(0.067, 0.090, 0.114, 0.84)
const COLOR_BG_ELEVATED: Color = Color(0.098, 0.133, 0.169, 0.94)
const COLOR_BRASS: Color = Color(0.784, 0.608, 0.329, 1.0)
const COLOR_BRASS_ACTIVE: Color = Color(0.910, 0.745, 0.447, 1.0)
const COLOR_TEXT: Color = Color(0.929, 0.902, 0.839, 1.0)
const COLOR_WARM: Color = Color(0.890, 0.635, 0.282, 1.0)
const COLOR_STEALTH_LOW: Color = Color(0.365, 0.643, 0.569, 1.0)
const COLOR_DANGER: Color = Color(0.816, 0.310, 0.204, 1.0)

const LABELS_RU: Dictionary = {
	"interact": "ВЗЯТЬ",
	"flashlight": "ФОНАРЬ",
	"crouch": "ТИХО",
	"sprint": "БЕГ",
	"map": "КАРТА",
	"inventory": "СУМКА",
	"log": "ЖУРНАЛ",
	"audio_mute": "ЗВУК",
	"hud_edit": "НАСТРОИТЬ HUD",
	"settings": "ПАУЗА",
	"save": "СОХРАНИТЬ",
	"reset": "СБРОС",
	"scale": "РАЗМЕР",
	"alpha": "ПРОЗР.",
	"warmth_ok": "ТЕПЛО",
	"warmth_cold": "ХОЛОД",
}

const LABELS_EN: Dictionary = {
	"interact": "USE",
	"flashlight": "LIGHT",
	"crouch": "SNEAK",
	"sprint": "RUN",
	"map": "MAP",
	"inventory": "BAG",
	"log": "LOG",
	"audio_mute": "AUDIO",
	"hud_edit": "EDIT HUD",
	"settings": "PAUSE",
	"save": "SAVE",
	"reset": "RESET",
	"scale": "SIZE",
	"alpha": "ALPHA",
	"warmth_ok": "WARM",
	"warmth_cold": "COLD",
}

var _safe_root: Control
var _backdrop_blocker: Control
var _status_panel: PanelContainer
var _battery_bar: ProgressBar
var _visibility_bar: ProgressBar
var _warmth_label: Label
var _district_label: Label
var _objective_pill: PanelContainer
var _objective_label: Label
var _context_prompt_panel: PanelContainer
var _context_prompt_label: Label
var _hotbar_panel: PanelContainer
var _hotbar_buttons: Array[Button] = []
var _drawer_panel: PanelContainer
var _drawer_toggle_btn: Button
var _map_quick_btn: Button
var _edit_banner: PanelContainer
var _scale_slider: HSlider
var _alpha_slider: HSlider
var _edit_selected_label: Label
var _joystick_base: Panel
var _joystick_knob: Panel

var _drawer_open: bool = false
var _edit_mode: bool = false
var _drawer_tween: Tween = null
var _joystick_touch_idx: int = -1
var _joystick_center: Vector2 = Vector2.ZERO
var _joystick_radius: float = 64.0
var _move_vec: Vector2 = Vector2.ZERO

var _editable_controls: Dictionary = {}
var _base_sizes: Dictionary = {}
var _control_prefs: Dictionary = {}
var _selected_edit_key: String = ""
var _drag_target: Control = null
var _drag_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	layer = 25
	_control_prefs = _load_layout_verified()
	_build_hud()
	_apply_safe_area_and_dpi()
	refresh_localization()
	if get_viewport() != null and not get_viewport().size_changed.is_connected(_apply_safe_area_and_dpi):
		get_viewport().size_changed.connect(_apply_safe_area_and_dpi)


func _exit_tree() -> void:
	if is_instance_valid(_drawer_tween):
		_drawer_tween.kill()
		_drawer_tween = null
	if get_viewport() != null and get_viewport().size_changed.is_connected(_apply_safe_area_and_dpi):
		get_viewport().size_changed.disconnect(_apply_safe_area_and_dpi)


func update_vitals(battery_01: float, visibility_01: float, is_warm: bool, district_name: String = "") -> void:
	if is_instance_valid(_battery_bar):
		_battery_bar.value = clampf(battery_01, 0.0, 1.0) * 100.0
	if is_instance_valid(_visibility_bar):
		var vis_pct: float = clampf(visibility_01, 0.0, 1.0) * 100.0
		_visibility_bar.value = vis_pct
		var fill_sb: StyleBoxFlat = _visibility_bar.get_theme_stylebox("fill") as StyleBoxFlat
		if fill_sb != null:
			fill_sb.bg_color = COLOR_DANGER if vis_pct >= 70.0 else (COLOR_WARM if vis_pct >= 35.0 else COLOR_STEALTH_LOW)
	if is_instance_valid(_warmth_label):
		_warmth_label.text = _loc("warmth_ok") if is_warm else _loc("warmth_cold")
		_warmth_label.add_theme_color_override("font_color", COLOR_WARM if is_warm else COLOR_DANGER)
	if not district_name.is_empty() and is_instance_valid(_district_label):
		_district_label.text = district_name


func set_objective_text(text_val: String) -> void:
	if is_instance_valid(_objective_label):
		_objective_label.text = text_val
		_objective_pill.visible = not text_val.strip_edges().is_empty()


func set_context_prompt(prompt_text: String) -> void:
	if is_instance_valid(_context_prompt_panel) and is_instance_valid(_context_prompt_label):
		var has_text: bool = not prompt_text.strip_edges().is_empty()
		_context_prompt_panel.visible = has_text
		_context_prompt_label.text = prompt_text


func set_hotbar_slot(slot_idx: int, label_text: String, count: int) -> void:
	if slot_idx < 0 or slot_idx >= _hotbar_buttons.size():
		return
	var btn: Button = _hotbar_buttons[slot_idx]
	if count > 0:
		btn.text = "%s
×%d" % [label_text, count]
		btn.disabled = false
	else:
		btn.text = "—"
		btn.disabled = true


func set_toggle_visual(action_key: String, active: bool) -> void:
	if _editable_controls.has(action_key) and _editable_controls[action_key] is Button:
		var b: Button = _editable_controls[action_key] as Button
		var fill: Color = Color(0.784, 0.608, 0.329, 0.30) if active else COLOR_BG
		var border: Color = COLOR_BRASS_ACTIVE if active else COLOR_BRASS
		b.add_theme_stylebox_override("normal", _make_chamfer_style(fill, border, 2))


func refresh_localization() -> void:
	for k in ["interact", "flashlight", "crouch", "sprint", "map"]:
		if _editable_controls.has(k) and _editable_controls[k] is Button:
			(_editable_controls[k] as Button).text = _loc(k)
	if is_instance_valid(_drawer_panel):
		for child in _drawer_panel.get_child(0).get_children():
			if child is Button and child.has_meta("action_key"):
				(child as Button).text = _loc(String(child.get_meta("action_key")))


func set_drawer_open(open_state: bool) -> void:
	if _drawer_open == open_state:
		return
	_drawer_open = open_state
	_backdrop_blocker.visible = open_state
	if is_instance_valid(_drawer_tween):
		_drawer_tween.kill()
	_drawer_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if _drawer_open:
		_drawer_panel.visible = true
		_drawer_panel.modulate.a = 0.0
		_drawer_tween.tween_property(_drawer_panel, "modulate:a", 1.0, DRAWER_ANIM_SEC)
	else:
		_drawer_tween.tween_property(_drawer_panel, "modulate:a", 0.0, DRAWER_ANIM_SEC)
		_drawer_tween.tween_callback(func() -> void:
			if is_instance_valid(_drawer_panel):
				_drawer_panel.visible = false
		)
	_drawer_toggle_btn.text = "✕" if _drawer_open else "☰"
	hud_drawer_toggled.emit(_drawer_open)


func toggle_edit_mode(enabled: bool) -> void:
	_edit_mode = enabled
	_edit_banner.visible = enabled
	if enabled:
		set_drawer_open(false)
		_select_edit_control("interact")
	else:
		_drag_target = null
		_selected_edit_key = ""
		_save_layout_signed()


func reset_layout() -> void:
	_control_prefs.clear()
	_apply_safe_area_and_dpi()
	if _edit_mode:
		_select_edit_control("interact")
	_save_layout_signed()


func _build_hud() -> void:
	_backdrop_blocker = Control.new()
	_backdrop_blocker.name = "DrawerBackdrop"
	_backdrop_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop_blocker.visible = false
	_backdrop_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_backdrop_blocker.gui_input.connect(func(ev: InputEvent) -> void:
		if (ev is InputEventScreenTouch and (ev as InputEventScreenTouch).pressed) or (ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed):
			set_drawer_open(false)
	)
	add_child(_backdrop_blocker)

	_safe_root = Control.new()
	_safe_root.name = "SafeAreaRoot"
	_safe_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_safe_root)

	_status_panel = PanelContainer.new()
	_status_panel.name = "VitalsCard"
	_status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_panel.add_theme_stylebox_override("panel", _make_chamfer_style(COLOR_BG, COLOR_BRASS, 1))
	_safe_root.add_child(_status_panel)

	var v_box: VBoxContainer = VBoxContainer.new()
	v_box.add_theme_constant_override("separation", 4)
	_status_panel.add_child(v_box)

	var top_line: HBoxContainer = HBoxContainer.new()
	top_line.add_theme_constant_override("separation", 10)
	v_box.add_child(top_line)

	_district_label = Label.new()
	_district_label.text = "РАЙОН I"
	_district_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_district_label.add_theme_color_override("font_color", COLOR_BRASS_ACTIVE)
	top_line.add_child(_district_label)

	_warmth_label = Label.new()
	_warmth_label.text = _loc("warmth_ok")
	_warmth_label.add_theme_color_override("font_color", COLOR_WARM)
	top_line.add_child(_warmth_label)

	_battery_bar = _make_bar(COLOR_BRASS_ACTIVE)
	_battery_bar.value = 100.0
	v_box.add_child(_battery_bar)

	_visibility_bar = _make_bar(COLOR_STEALTH_LOW)
	_visibility_bar.value = 15.0
	v_box.add_child(_visibility_bar)

	_objective_pill = PanelContainer.new()
	_objective_pill.name = "ObjectivePill"
	_objective_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objective_pill.add_theme_stylebox_override("panel", _make_chamfer_style(COLOR_BG, COLOR_BRASS, 1))
	_safe_root.add_child(_objective_pill)

	_objective_label = Label.new()
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_label.add_theme_color_override("font_color", COLOR_TEXT)
	_objective_label.text = "Собрать детали: 0/6 → Щиток фонаря"
	_objective_pill.add_child(_objective_label)

	_context_prompt_panel = PanelContainer.new()
	_context_prompt_panel.name = "ContextPrompt"
	_context_prompt_panel.visible = false
	_context_prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_context_prompt_panel.add_theme_stylebox_override("panel", _make_chamfer_style(COLOR_BG_ELEVATED, COLOR_BRASS_ACTIVE, 2))
	_safe_root.add_child(_context_prompt_panel)

	_context_prompt_label = Label.new()
	_context_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_context_prompt_label.add_theme_color_override("font_color", COLOR_BRASS_ACTIVE)
	_context_prompt_panel.add_child(_context_prompt_label)

	_joystick_base = Panel.new()
	_joystick_base.name = "JoystickBase"
	_joystick_base.mouse_filter = Control.MOUSE_FILTER_STOP
	_joystick_base.add_theme_stylebox_override("panel", _make_circle_style(COLOR_BG, COLOR_BRASS, 2))
	_joystick_base.gui_input.connect(_on_joystick_gui_input)
	_safe_root.add_child(_joystick_base)

	_joystick_knob = Panel.new()
	_joystick_knob.name = "JoystickKnob"
	_joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_joystick_knob.add_theme_stylebox_override("panel", _make_circle_style(COLOR_BRASS_ACTIVE, COLOR_TEXT, 2))
	_joystick_base.add_child(_joystick_knob)
	_editable_controls["joystick"] = _joystick_base

	for spec in [["interact", true], ["flashlight", false], ["crouch", false], ["sprint", false]]:
		var key: String = String(spec[0])
		var is_pri: bool = bool(spec[1])
		var btn: Button = _create_action_button(key, is_pri)
		_safe_root.add_child(btn)
		_editable_controls[key] = btn

	_map_quick_btn = _create_action_button("map", false)
	_safe_root.add_child(_map_quick_btn)
	_editable_controls["map"] = _map_quick_btn

	_drawer_toggle_btn = _create_action_button("drawer_toggle", false)
	_drawer_toggle_btn.text = "☰"
	_drawer_toggle_btn.pressed.connect(func() -> void:
		if not _edit_mode:
			set_drawer_open(not _drawer_open)
	)
	_safe_root.add_child(_drawer_toggle_btn)
	_editable_controls["drawer_toggle"] = _drawer_toggle_btn

	_hotbar_panel = PanelContainer.new()
	_hotbar_panel.name = "QuickBelt"
	_hotbar_panel.add_theme_stylebox_override("panel", _make_chamfer_style(COLOR_BG, COLOR_BRASS, 1))
	_safe_root.add_child(_hotbar_panel)

	var hb: HBoxContainer = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	_hotbar_panel.add_child(hb)
	for i in range(3):
		var slot_btn: Button = Button.new()
		slot_btn.text = "—"
		slot_btn.focus_mode = Control.FOCUS_NONE
		slot_btn.add_theme_color_override("font_color", COLOR_TEXT)
		slot_btn.add_theme_stylebox_override("normal", _make_chamfer_style(COLOR_BG_ELEVATED, COLOR_BRASS, 1))
		slot_btn.add_theme_stylebox_override("pressed", _make_chamfer_style(COLOR_BRASS, COLOR_BG, 2))
		var idx: int = i
		slot_btn.pressed.connect(func() -> void:
			if not _edit_mode:
				hotbar_slot_selected.emit(idx)
		)
		hb.add_child(slot_btn)
		_hotbar_buttons.append(slot_btn)

	_drawer_panel = PanelContainer.new()
	_drawer_panel.name = "SecondaryDrawer"
	_drawer_panel.visible = false
	_drawer_panel.add_theme_stylebox_override("panel", _make_chamfer_style(COLOR_BG_ELEVATED, COLOR_BRASS, 2))
	_safe_root.add_child(_drawer_panel)

	var drawer_box: VBoxContainer = VBoxContainer.new()
	drawer_box.add_theme_constant_override("separation", 8)
	_drawer_panel.add_child(drawer_box)
	for sk in ["inventory", "log", "audio_mute", "hud_edit", "settings"]:
		drawer_box.add_child(_create_drawer_button(sk))

	_edit_banner = PanelContainer.new()
	_edit_banner.name = "HudEditBanner"
	_edit_banner.visible = false
	_edit_banner.add_theme_stylebox_override("panel", _make_chamfer_style(COLOR_BG_ELEVATED, COLOR_BRASS_ACTIVE, 2))
	_safe_root.add_child(_edit_banner)

	var edit_vbox: VBoxContainer = VBoxContainer.new()
	edit_vbox.add_theme_constant_override("separation", 8)
	_edit_banner.add_child(edit_vbox)

	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	edit_vbox.add_child(top_row)

	_edit_selected_label = Label.new()
	_edit_selected_label.text = "HUD"
	_edit_selected_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_edit_selected_label.add_theme_color_override("font_color", COLOR_BRASS_ACTIVE)
	top_row.add_child(_edit_selected_label)

	var btn_save: Button = _create_simple_button(_loc("save"), COLOR_BRASS_ACTIVE)
	btn_save.pressed.connect(func() -> void: toggle_edit_mode(false))
	var btn_reset: Button = _create_simple_button(_loc("reset"), COLOR_DANGER)
	btn_reset.pressed.connect(reset_layout)
	top_row.add_child(btn_save)
	top_row.add_child(btn_reset)

	var sliders_row: HBoxContainer = HBoxContainer.new()
	sliders_row.add_theme_constant_override("separation", 10)
	edit_vbox.add_child(sliders_row)

	var lbl_s: Label = Label.new()
	lbl_s.text = _loc("scale")
	lbl_s.add_theme_color_override("font_color", COLOR_TEXT)
	sliders_row.add_child(lbl_s)

	_scale_slider = HSlider.new()
	_scale_slider.min_value = SCALE_MIN
	_scale_slider.max_value = SCALE_MAX
	_scale_slider.step = 0.05
	_scale_slider.value = 1.0
	_scale_slider.custom_minimum_size = Vector2(120.0, 28.0)
	_scale_slider.value_changed.connect(_on_edit_scale_changed)
	sliders_row.add_child(_scale_slider)

	var lbl_a: Label = Label.new()
	lbl_a.text = _loc("alpha")
	lbl_a.add_theme_color_override("font_color", COLOR_TEXT)
	sliders_row.add_child(lbl_a)

	_alpha_slider = HSlider.new()
	_alpha_slider.min_value = ALPHA_MIN
	_alpha_slider.max_value = ALPHA_MAX
	_alpha_slider.step = 0.05
	_alpha_slider.value = 1.0
	_alpha_slider.custom_minimum_size = Vector2(120.0, 28.0)
	_alpha_slider.value_changed.connect(_on_edit_alpha_changed)
	sliders_row.add_child(_alpha_slider)


func _make_bar(fill_color: Color) -> ProgressBar:
	var pb: ProgressBar = ProgressBar.new()
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(184.0, 10.0)
	var bg_sb: StyleBoxFlat = StyleBoxFlat.new()
	bg_sb.bg_color = Color(0.03, 0.04, 0.05, 0.85)
	bg_sb.set_corner_radius_all(2)
	var fg_sb: StyleBoxFlat = StyleBoxFlat.new()
	fg_sb.bg_color = fill_color
	fg_sb.set_corner_radius_all(2)
	pb.add_theme_stylebox_override("background", bg_sb)
	pb.add_theme_stylebox_override("fill", fg_sb)
	return pb


func _create_action_button(id_key: String, is_primary: bool) -> Button:
	var btn: Button = Button.new()
	btn.name = "Btn_" + id_key
	btn.text = _loc(id_key)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_color_override("font_color", COLOR_TEXT)
	btn.add_theme_color_override("font_pressed_color", COLOR_BG)
	var border_col: Color = COLOR_BRASS_ACTIVE if is_primary else COLOR_BRASS
	btn.add_theme_stylebox_override("normal", _make_chamfer_style(COLOR_BG, border_col, 2))
	btn.add_theme_stylebox_override("hover", _make_chamfer_style(COLOR_BG_ELEVATED, COLOR_BRASS_ACTIVE, 2))
	btn.add_theme_stylebox_override("pressed", _make_chamfer_style(COLOR_BRASS_ACTIVE, COLOR_TEXT, 2))
	btn.gui_input.connect(func(ev: InputEvent) -> void: _on_editable_gui_input(id_key, btn, ev))
	if id_key != "drawer_toggle":
		btn.pressed.connect(func() -> void:
			if not _edit_mode:
				if _drawer_open:
					set_drawer_open(false)
				action_triggered.emit(StringName(id_key))
		)
	return btn


func _create_drawer_button(action_key: String) -> Button:
	var btn: Button = Button.new()
	btn.text = _loc(action_key)
	btn.set_meta("action_key", action_key)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_color_override("font_color", COLOR_TEXT)
	btn.add_theme_stylebox_override("normal", _make_chamfer_style(COLOR_BG, COLOR_BRASS, 1))
	btn.add_theme_stylebox_override("hover", _make_chamfer_style(COLOR_BG_ELEVATED, COLOR_BRASS_ACTIVE, 2))
	btn.add_theme_stylebox_override("pressed", _make_chamfer_style(COLOR_BRASS, COLOR_BG, 2))
	btn.pressed.connect(func() -> void:
		if action_key == "hud_edit":
			toggle_edit_mode(true)
			return
		set_drawer_open(false)
		action_triggered.emit(StringName(action_key))
	)
	return btn


func _create_simple_button(label_txt: String, border_col: Color) -> Button:
	var btn: Button = Button.new()
	btn.text = label_txt
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(96.0, 44.0)
	btn.add_theme_color_override("font_color", COLOR_TEXT)
	btn.add_theme_stylebox_override("normal", _make_chamfer_style(COLOR_BG, border_col, 2))
	btn.add_theme_stylebox_override("pressed", _make_chamfer_style(border_col, COLOR_BG, 2))
	return btn


func _apply_safe_area_and_dpi() -> void:
	var vp: Viewport = get_viewport()
	if vp == null:
		return
	var vp_size: Vector2 = vp.get_visible_rect().size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		return

	var win_size: Vector2i = DisplayServer.window_get_size()
	var safe_px: Rect2i = DisplayServer.get_display_safe_area()
	var il: float = 0.0
	var it: float = 0.0
	var ir: float = 0.0
	var ib: float = 0.0
	if win_size.x > 0 and win_size.y > 0 and safe_px.size.x > 0 and safe_px.size.y > 0:
		var sx: float = vp_size.x / float(win_size.x)
		var sy: float = vp_size.y / float(win_size.y)
		il = maxf(0.0, float(safe_px.position.x) * sx)
		it = maxf(0.0, float(safe_px.position.y) * sy)
		ir = maxf(0.0, float(win_size.x - safe_px.end.x) * sx)
		ib = maxf(0.0, float(win_size.y - safe_px.end.y) * sy)

	var pad: float = 16.0
	_safe_root.position = Vector2(il + pad, it + pad)
	_safe_root.size = Vector2(
		maxf(320.0, vp_size.x - il - ir - pad * 2.0),
		maxf(240.0, vp_size.y - it - ib - pad * 2.0)
	)

	var dpi: float = float(DisplayServer.screen_get_dpi())
	if dpi <= 0.0:
		dpi = 320.0
	var phys_scale: float = vp_size.y / float(win_size.y) if win_size.y > 0 else 1.0
	var px_per_mm: float = clampf((dpi / 25.4) * phys_scale, 7.5, 13.5)

	var sec_sz: float = _snap8(maxf(80.0, MIN_TOUCH_MM * px_per_mm))
	var pri_sz: float = _snap8(maxf(112.0, PRIMARY_TOUCH_MM * px_per_mm))
	var joy_sz: float = _snap8(maxf(192.0, JOYSTICK_MM * px_per_mm))
	var font_sz: int = clampi(int(roundf(sec_sz * 0.22)), 17, 26)
	var sr: Vector2 = _safe_root.size

	_status_panel.position = Vector2(8.0, 8.0)
	_status_panel.size = Vector2(232.0, 80.0)
	_district_label.add_theme_font_size_override("font_size", font_sz - 2)
	_warmth_label.add_theme_font_size_override("font_size", font_sz - 2)

	var obj_w: float = clampf(sr.x * 0.34, 240.0, 420.0)
	_objective_pill.size = Vector2(obj_w, 48.0)
	_objective_pill.position = Vector2((sr.x - obj_w) * 0.5, 8.0)
	_objective_label.add_theme_font_size_override("font_size", font_sz - 1)

	var ctx_w: float = clampf(sr.x * 0.38, 260.0, 460.0)
	_context_prompt_panel.size = Vector2(ctx_w, 52.0)
	_context_prompt_panel.position = Vector2((sr.x - ctx_w) * 0.5, sr.y - 160.0)
	_context_prompt_label.add_theme_font_size_override("font_size", font_sz)

	var slot_sz: float = _snap8(maxf(64.0, sec_sz * 0.80))
	for b in _hotbar_buttons:
		b.custom_minimum_size = Vector2(slot_sz, slot_sz)
		b.add_theme_font_size_override("font_size", font_sz - 3)
	var belt_w: float = slot_sz * 3.0 + 36.0
	_hotbar_panel.size = Vector2(belt_w, slot_sz + 18.0)
	_hotbar_panel.position = Vector2((sr.x - belt_w) * 0.5, sr.y - _hotbar_panel.size.y - 12.0)

	_base_sizes["joystick"] = Vector2(joy_sz, joy_sz)
	_base_sizes["interact"] = Vector2(pri_sz, pri_sz)
	_base_sizes["flashlight"] = Vector2(sec_sz, sec_sz)
	_base_sizes["crouch"] = Vector2(sec_sz, sec_sz)
	_base_sizes["sprint"] = Vector2(sec_sz, sec_sz)
	_base_sizes["map"] = Vector2(sec_sz, sec_sz)
	_base_sizes["drawer_toggle"] = Vector2(sec_sz, sec_sz)

	var defaults: Dictionary = {
		"joystick": Vector2(20.0, sr.y - joy_sz - 20.0),
		"interact": Vector2(sr.x - pri_sz - 20.0, sr.y - pri_sz - 20.0),
		"flashlight": Vector2(sr.x - pri_sz - sec_sz - 36.0, sr.y - sec_sz - 20.0),
		"crouch": Vector2(sr.x - pri_sz - sec_sz - 36.0, sr.y - sec_sz * 2.0 - 36.0),
		"sprint": Vector2(sr.x - sec_sz - 20.0, sr.y - pri_sz - sec_sz - 36.0),
		"map": Vector2(sr.x - sec_sz * 2.0 - 20.0, 8.0),
		"drawer_toggle": Vector2(sr.x - sec_sz - 8.0, 8.0),
	}

	for key in _editable_controls.keys():
		var ctrl: Control = _editable_controls[key]
		var pref: Dictionary = _control_prefs.get(key, {})
		var sc: float = clampf(float(pref.get("scale", 1.0)), SCALE_MIN, SCALE_MAX)
		var al: float = clampf(float(pref.get("alpha", 1.0)), ALPHA_MIN, ALPHA_MAX)
		var sz: Vector2 = (_base_sizes[key] as Vector2) * sc
		ctrl.size = Vector2(_snap8(sz.x), _snap8(sz.y))
		ctrl.modulate.a = al
		ctrl.position = _saved_pos_or(key, defaults[key] as Vector2, sr, ctrl.size)
		if ctrl is Button:
			(ctrl as Button).add_theme_font_size_override("font_size", clampi(int(roundf(float(font_sz) * sc)), 15, 30))

	_update_joystick_geometry()

	var drawer_w: float = _snap8(maxf(216.0, sec_sz * 2.5))
	_drawer_panel.size = Vector2(drawer_w, sec_sz * 4.0)
	_drawer_panel.position = Vector2(sr.x - drawer_w - 8.0, _drawer_toggle_btn.size.y + 20.0)
	for child in _drawer_panel.get_child(0).get_children():
		if child is Button:
			var db: Button = child as Button
			db.custom_minimum_size = Vector2(drawer_w - 20.0, maxf(56.0, sec_sz * 0.65))
			db.add_theme_font_size_override("font_size", font_sz)

	_edit_banner.size = Vector2(minf(sr.x - 16.0, 560.0), 112.0)
	_edit_banner.position = Vector2((sr.x - _edit_banner.size.x) * 0.5, 8.0)


func _update_joystick_geometry() -> void:
	_joystick_radius = _joystick_base.size.x * 0.38
	var knob_sz: float = _snap8(_joystick_base.size.x * 0.38)
	_joystick_knob.size = Vector2(knob_sz, knob_sz)
	_reset_joystick_knob()


func _select_edit_control(key: String) -> void:
	if not _editable_controls.has(key):
		return
	_selected_edit_key = key
	_edit_selected_label.text = _loc(key) if key != "joystick" else "JOYSTICK"
	var pref: Dictionary = _control_prefs.get(key, {})
	_scale_slider.set_value_no_signal(clampf(float(pref.get("scale", 1.0)), SCALE_MIN, SCALE_MAX))
	_alpha_slider.set_value_no_signal(clampf(float(pref.get("alpha", 1.0)), ALPHA_MIN, ALPHA_MAX))


func _on_edit_scale_changed(new_scale: float) -> void:
	if not _edit_mode or _selected_edit_key.is_empty():
		return
	var pref: Dictionary = _control_prefs.get(_selected_edit_key, {})
	pref["scale"] = snappedf(clampf(new_scale, SCALE_MIN, SCALE_MAX), 0.05)
	_control_prefs[_selected_edit_key] = pref
	var ctrl: Control = _editable_controls[_selected_edit_key]
	var base: Vector2 = _base_sizes[_selected_edit_key]
	ctrl.size = Vector2(_snap8(base.x * float(pref["scale"])), _snap8(base.y * float(pref["scale"])))
	if _selected_edit_key == "joystick":
		_update_joystick_geometry()


func _on_edit_alpha_changed(new_alpha: float) -> void:
	if not _edit_mode or _selected_edit_key.is_empty():
		return
	var pref: Dictionary = _control_prefs.get(_selected_edit_key, {})
	pref["alpha"] = snappedf(clampf(new_alpha, ALPHA_MIN, ALPHA_MAX), 0.05)
	_control_prefs[_selected_edit_key] = pref
	(_editable_controls[_selected_edit_key] as Control).modulate.a = float(pref["alpha"])


func _on_joystick_gui_input(event: InputEvent) -> void:
	if _edit_mode:
		_on_editable_gui_input("joystick", _joystick_base, event)
		return
	if event is InputEventScreenTouch:
		var t: InputEventScreenTouch = event as InputEventScreenTouch
		if t.pressed and _joystick_touch_idx == -1:
			_joystick_touch_idx = t.index
			_joystick_center = _joystick_base.size * 0.5
			_update_joystick(t.position)
		elif not t.pressed and t.index == _joystick_touch_idx:
			_joystick_touch_idx = -1
			_reset_joystick_knob()
	elif event is InputEventScreenDrag:
		var d: InputEventScreenDrag = event as InputEventScreenDrag
		if d.index == _joystick_touch_idx:
			_update_joystick(d.position)


func _update_joystick(local_pos: Vector2) -> void:
	var delta: Vector2 = local_pos - _joystick_center
	var clamped: Vector2 = delta.limit_length(_joystick_radius)
	_joystick_knob.position = _joystick_center + clamped - (_joystick_knob.size * 0.5)
	var new_vec: Vector2 = clamped / maxf(1.0, _joystick_radius)
	if new_vec.length() < 0.12:
		new_vec = Vector2.ZERO
	if new_vec != _move_vec:
		_move_vec = new_vec
		move_vector_changed.emit(_move_vec)


func _reset_joystick_knob() -> void:
	_joystick_knob.position = (_joystick_base.size - _joystick_knob.size) * 0.5
	if _move_vec != Vector2.ZERO:
		_move_vec = Vector2.ZERO
		move_vector_changed.emit(Vector2.ZERO)


func _on_editable_gui_input(key: String, target: Control, event: InputEvent) -> void:
	if not _edit_mode:
		return
	if event is InputEventScreenTouch:
		var t: InputEventScreenTouch = event as InputEventScreenTouch
		if t.pressed:
			_select_edit_control(key)
			_drag_target = target
			_drag_offset = t.position
		elif _drag_target == target:
			_drag_target = null
	elif event is InputEventScreenDrag and _drag_target == target:
		var d: InputEventScreenDrag = event as InputEventScreenDrag
		var next_pos: Vector2 = target.position + (d.position - _drag_offset)
		var max_pos: Vector2 = _safe_root.size - target.size
		target.position = Vector2(
			clampf(_snap8(next_pos.x), 0.0, maxf(0.0, max_pos.x)),
			clampf(_snap8(next_pos.y), 0.0, maxf(0.0, max_pos.y))
		)


func _saved_pos_or(key: String, fallback: Vector2, bounds: Vector2, sz: Vector2) -> Vector2:
	if _control_prefs.has(key) and _control_prefs[key] is Dictionary:
		var entry: Dictionary = _control_prefs[key]
		if entry.has("nx") and entry.has("ny"):
			var nx: float = clampf(float(entry["nx"]), 0.0, 1.0)
			var ny: float = clampf(float(entry["ny"]), 0.0, 1.0)
			return Vector2(
				clampf(nx * bounds.x, 0.0, maxf(0.0, bounds.x - sz.x)),
				clampf(ny * bounds.y, 0.0, maxf(0.0, bounds.y - sz.y))
			)
	return fallback


func _save_layout_signed() -> void:
	var sr: Vector2 = _safe_root.size
	if sr.x <= 0.0 or sr.y <= 0.0:
		return
	var payload: Dictionary = {}
	for k in _editable_controls.keys():
		var c: Control = _editable_controls[k]
		var old_pref: Dictionary = _control_prefs.get(k, {})
		payload[k] = {
			"nx": snappedf(c.position.x / sr.x, 0.001),
			"ny": snappedf(c.position.y / sr.y, 0.001),
			"scale": snappedf(clampf(float(old_pref.get("scale", 1.0)), SCALE_MIN, SCALE_MAX), 0.05),
			"alpha": snappedf(clampf(c.modulate.a, ALPHA_MIN, ALPHA_MAX), 0.05),
		}
	_control_prefs = payload
	var envelope: Dictionary = {"v": 3, "payload": payload, "mac": _compute_hmac(JSON.stringify(payload))}
	var tmp_path: String = SAVE_PATH + ".tmp"
	var f: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(envelope))
	f.flush()
	f.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp_path), ProjectSettings.globalize_path(SAVE_PATH))


func _load_layout_verified() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not (parsed is Dictionary):
		return {}
	var env: Dictionary = parsed as Dictionary
	if int(env.get("v", 0)) != 3 or not (env.get("payload") is Dictionary):
		return {}
	var payload: Dictionary = env["payload"]
	if String(env.get("mac", "")) != _compute_hmac(JSON.stringify(payload)):
		return {}
	return payload


func _compute_hmac(msg: String) -> String:
	var ctx: HMACContext = HMACContext.new()
	if ctx.start(HashingContext.HASH_SHA256, SAVE_SALT.to_utf8_buffer()) != OK:
		return ""
	ctx.update(msg.to_utf8_buffer())
	return ctx.finish().hex_encode()


func _loc(key: String) -> String:
	if TranslationServer.get_locale().to_lower().begins_with("ru"):
		return String(LABELS_RU.get(key, key.to_upper()))
	return String(LABELS_EN.get(key, key.to_upper()))


func _snap8(v: float) -> float:
	return roundf(v / 8.0) * 8.0


func _make_chamfer_style(fill: Color, border: Color, border_w: int) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(6)
	sb.corner_detail = 1
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


func _make_circle_style(fill: Color, border: Color, border_w: int) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(999)
	sb.corner_detail = 16
	return sb
