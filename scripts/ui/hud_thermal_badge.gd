extends Label
## District power restores warmth; this is not a separate survival meter.

const _FADE := preload("res://scripts/ui/hud_fade.gd")
const HOLD_SEC: float = 8.0

var comfort_state: StringName = &""

func _ready() -> void:
	theme = ThemeProvider.build_theme()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 18)
	add_theme_color_override("font_outline_color", ThemeProvider.COLOR_BG_DARK)
	add_theme_constant_override("outline_size", 2)
	EventBus.district_entered.connect(_on_district_entered)
	EventBus.district_stage_changed.connect(_on_stage_changed)
	EventBus.hud_visibility_changed.connect(_on_hud_visibility)
	LocalizationManager.language_changed.connect(_on_language_changed)
	_refresh(true)

func _on_district_entered(_id: StringName) -> void:
	_refresh(true)

func _on_stage_changed(id: StringName, _stage: int) -> void:
	if id == StringName(DistrictManager.current_district):
		_refresh()

func _on_hud_visibility(shown: bool) -> void:
	if shown:
		_refresh(true)

func _on_language_changed(_language: String) -> void:
	_refresh(true)

func _refresh(force: bool = false) -> void:
	if not is_inside_tree():
		return
	var current: StringName = PowerGrid.get_thermal_comfort(StringName(DistrictManager.current_district))
	var changed: bool = current != comfort_state
	comfort_state = current
	var state_text: String = LocalizationManager.t("THERMAL_COLD")
	var ink: Color = ThemeProvider.COLOR_TEXT_DIM
	if current == &"warming":
		state_text = LocalizationManager.t("THERMAL_WARMING")
		ink = ThemeProvider.COLOR_TEXT
	elif current == &"warm":
		state_text = LocalizationManager.t("THERMAL_WARM")
		ink = ThemeProvider.COLOR_AMBER
	text = LocalizationManager.t("THERMAL_LABEL") + ": " + state_text
	tooltip_text = text
	add_theme_color_override("font_color", ink)
	if changed or force:
		_FADE.show_for([self], HOLD_SEC, 0.0, false, "self_modulate:a")
