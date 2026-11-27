extends Control
class_name QuestTrackerHUD

## Unslop pass: the old top-right QUEST panel (title, checkboxes, 1 px amber
## frame, direction arrows) is gone. Exactly one compact centered objective
## line remains, driven by Wave2DistrictFlow's three-step loop:
## relay parts -> fusebox -> illuminated gate. RU/EN comes from the existing
## OBJ_STEP* keys; no new i18n keys are introduced.

const _LINE_W: float = 560.0
const _LINE_H: float = 34.0
const _TOP: float = 76.0

var _panel: PanelContainer
var _label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_line()
	get_viewport().size_changed.connect(_layout_line)
	EventBus.game_state_changed.connect(_on_game_state)
	EventBus.hud_visibility_changed.connect(_on_hud_visibility)
	LocalizationManager.language_changed.connect(func(_l: String) -> void: _refresh())
	if I18nSync.has_signal(&"locale_changed"):
		I18nSync.locale_changed.connect(func(_l: String) -> void: _refresh())
	Wave2Flow.state_changed.connect(func(_s: StringName, _i: int) -> void: _refresh())
	Wave2Flow.relay_parts_changed.connect(func(_c: int, _r: int) -> void: _refresh())
	_refresh()
	_apply_visibility()

func _build_line() -> void:
	_panel = PanelContainer.new()
	_panel.name = "ObjectiveLine"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# One glass backing from the installed theme: no 1 px bright amber box.
	_panel.add_theme_stylebox_override("panel", UnslopVisualTheme.make_glass_panel(false, 4))
	add_child(_panel)
	_label = Label.new()
	_label.name = "ObjectiveText"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 17)
	_label.add_theme_color_override("font_color", UnslopVisualTheme.COL_MOON)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_label)
	_layout_line()

func _layout_line() -> void:
	if _panel == null or not is_instance_valid(_panel):
		return
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var inset: Vector4 = UiScale.insets(vp)
	var w: float = minf(_LINE_W, maxf(120.0, vp.x - 32.0))
	_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_panel.offset_left = -w * 0.5
	_panel.offset_right = w * 0.5
	_panel.offset_top = _TOP + inset.y
	_panel.offset_bottom = _TOP + _LINE_H + inset.y

func _refresh() -> void:
	if _label == null or not is_instance_valid(_label):
		return
	var info: Dictionary = Wave2Flow.get_objective_key_and_args()
	var key: String = String(info.get("key", "OBJ_STEP1_PARTS"))
	var args: Dictionary = info.get("args", {})
	_label.text = I18nSync.t(key, args)

func _on_game_state(_state: int) -> void:
	_apply_visibility()

func _on_hud_visibility(_shown: bool) -> void:
	_apply_visibility()

func _apply_visibility() -> void:
	visible = GameManager.is_playing() and not UIManager.is_hud_blocked()
