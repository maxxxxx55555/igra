extends ColorRect
## The fog and the grain over the backdrop of the main menu (V2 of Session 27, assets/shaders/menu_fog.gdshader): drawn between the hero art and the lamp's flicker, under the title and the buttons.
## Not drawn at the Low tier; with Reduce UI Motion the fog stands still and the grain does not change.

const _SHADER := preload("res://assets/shaders/menu_fog.gdshader")

var _mat := ShaderMaterial.new()

func _ready() -> void:
	name = "MenuFog"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mat.shader = _SHADER
	material = _mat
	_apply()
	EventBus.settings_changed.connect(_on_setting_changed)

func _apply() -> void:
	visible = int(SettingsManager.get_setting("graphics_tier", 2)) > 0
	_mat.set_shader_parameter("motion", 0.0 if bool(SettingsManager.get_setting("reduce_ui_motion", false)) else 1.0)

func _on_setting_changed(key: String, _value: Variant) -> void:
	if key == "graphics_tier" or key == "reduce_ui_motion":
		_apply()
