extends Control
## Captions (docs/A11Y_PLAN.md). With Subtitles on, the Keeper's lines (a caption of the Keeper's log, an examined note, a broadcast) are
## also drawn in a bar above the quick slots; with Sound Cues on, the sounds the game makes get a bracketed line, and the loud ones a flash at the
## screen edge. Subtitle Size, Subtitle Background and Subtitle Color style the bar; Reduce Flash holds the flash back.

const SIZES: Array[int] = [18, 24, 32]
const BG_ALPHA: Array[float] = [0.0, 0.5, 1.0]
const COLORS: Array[Color] = [Color("#d8d2c4"), Color("#e6cf6e"), Color("#7fc4d9")]  # white (bone), yellow, cyan: lifted from the palette
const INK := Color("#0c1016")
const FLASH_COLOR := Color("#c9a24a")
const FLASH_EDGE_PX: int = 10
const FLASH_ALPHA: float = 0.55
const FLASH_SEC: float = 0.45
const HOLD_BASE_SEC: float = 1.5
const HOLD_PER_CHAR_SEC: float = 0.06
const HOLD_MIN_SEC: float = 2.5
const HOLD_MAX_SEC: float = 8.0
const CUE_REPEAT_MSEC: int = 1500  # the same cue is not captioned again inside this
const BAR_MAX_W: float = 1000.0
const BAR_BOTTOM_PX: float = -300.0  # above the quick slots, the tutorial hint and the notice line
const PAD := Vector2(16.0, 8.0)

var _bar: PanelContainer
var _label: Label
var _edge: Panel
var _hold: Timer
var _last_cue_msec: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_edge = Panel.new()
	_edge.name = "CueEdge"
	_edge.set_anchors_preset(Control.PRESET_FULL_RECT)
	_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rim := StyleBoxFlat.new()
	rim.draw_center = false
	rim.border_color = FLASH_COLOR
	rim.set_border_width_all(FLASH_EDGE_PX)
	_edge.add_theme_stylebox_override("panel", rim)
	_edge.modulate.a = 0.0
	add_child(_edge)
	_bar = PanelContainer.new()
	_bar.name = "Bar"
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_bar.offset_top = BAR_BOTTOM_PX
	_bar.offset_bottom = BAR_BOTTOM_PX
	_bar.visible = false
	add_child(_bar)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.add_child(_label)
	_hold = Timer.new()
	_hold.one_shot = true
	_hold.process_mode = Node.PROCESS_MODE_ALWAYS
	_hold.timeout.connect(func() -> void: _bar.visible = false)
	add_child(_hold)
	# EventBus is the autoload before the UI manager; the settings and the language arrive after it, so they are met when a line is shown.
	EventBus.toast_requested.connect(func(text: String, type: String) -> void:
		if type == "caption":
			say(text))
	EventBus.examine_text.connect(say)
	EventBus.voice_line.connect(say)
	EventBus.player_detected.connect(func(_id: StringName) -> void: cue(&"SND_NOTICED", true))
	EventBus.enemy_attack.connect(func(_damage: int) -> void: cue(&"SND_STRIKE", true))
	EventBus.boss_spawned.connect(func() -> void: cue(&"SND_ROAR", true))
	EventBus.hallucination_heard.connect(func() -> void: cue(&"SND_WHISPER", true))
	EventBus.light_disrupted.connect(func() -> void: cue(&"SND_FLICKER"))
	EventBus.flashlight_depleted.connect(func() -> void: cue(&"SND_BATTERY_DEAD"))
	EventBus.district_restored.connect(func(_id: StringName, _stage: int) -> void: cue(&"SND_GRID_ON"))
	EventBus.settings_changed.connect(_on_setting_changed)
	call_deferred("_connect_language")

func _connect_language() -> void:
	LocalizationManager.language_changed.connect(func(_lang: String) -> void: _clear())

## A line the Keeper says. Nothing shows with Subtitles off.
func say(text: String) -> void:
	if bool(SettingsManager.get_setting("subtitles", false)) and not text.strip_edges().is_empty():
		_show(text)

## A sound the game makes, as a bracketed line (the locale string carries the brackets). `loud` also flashes the screen edge.
func cue(key: StringName, loud: bool = false) -> void:
	if not bool(SettingsManager.get_setting("sound_cues", false)):
		return
	var now: int = Time.get_ticks_msec()
	if now - int(_last_cue_msec.get(key, -CUE_REPEAT_MSEC)) < CUE_REPEAT_MSEC:
		return
	_last_cue_msec[key] = now
	_show(LocalizationManager.t(String(key)))
	if loud and not bool(SettingsManager.get_setting("reduce_flash", false)):
		_edge.modulate.a = FLASH_ALPHA
		create_tween().tween_property(_edge, "modulate:a", 0.0, FLASH_SEC)

func shown_text() -> String:
	return _label.text if _bar.visible else ""

func flash_alpha() -> float:
	return _edge.modulate.a

func _show(line: String) -> void:
	_style()
	_label.text = line
	var font: Font = _label.get_theme_font("font")
	var px: float = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _label.get_theme_font_size("font_size")).x
	_label.custom_minimum_size.x = minf(px + 4.0, BAR_MAX_W)
	_bar.size = Vector2.ZERO
	_bar.visible = true
	_hold.start(clampf(HOLD_BASE_SEC + HOLD_PER_CHAR_SEC * line.length(), HOLD_MIN_SEC, HOLD_MAX_SEC))

## Size, background and color are read as the line is shown, so a change in Settings reaches the next line.
func _style() -> void:
	var size_pick: int = clampi(int(SettingsManager.get_setting("subtitle_size", 1)), 0, SIZES.size() - 1)
	var bg_pick: int = clampi(int(SettingsManager.get_setting("subtitle_bg", 1)), 0, BG_ALPHA.size() - 1)
	var color_pick: int = clampi(int(SettingsManager.get_setting("subtitle_color", 0)), 0, COLORS.size() - 1)
	_label.add_theme_font_size_override("font_size", SIZES[size_pick])
	_label.add_theme_color_override("font_color", COLORS[color_pick])
	_label.add_theme_color_override("font_outline_color", INK)
	_label.add_theme_constant_override("outline_size", 6 if bg_pick == 0 else 0)  # no backing: an outline carries the letters
	var box := StyleBoxFlat.new()
	box.bg_color = Color(INK, BG_ALPHA[bg_pick])
	box.content_margin_left = PAD.x
	box.content_margin_right = PAD.x
	box.content_margin_top = PAD.y
	box.content_margin_bottom = PAD.y
	_bar.add_theme_stylebox_override("panel", box)

func _on_setting_changed(key: String, _value: Variant) -> void:
	if key == "subtitles" or key == "sound_cues":
		_clear()

func _clear() -> void:
	_hold.stop()
	_bar.visible = false
