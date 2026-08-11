extends CanvasLayer
## D34: Nastrojki - gromkost, jarkost, kachestvo, jazyk, upravlenie, vibracija

@onready var panel: Panel = $Panel
@onready var sfx_slider: HSlider = $Panel/VBox/SFXSlider
@onready var music_slider: HSlider = $Panel/VBox/MusicSlider
@onready var brightness_slider: HSlider = $Panel/VBox/BrightnessSlider
@onready var sens_slider: HSlider = $Panel/VBox/SensSlider
@onready var quality_option: OptionButton = $Panel/VBox/QualityOption
@onready var lang_option: OptionButton = $Panel/VBox/LangOption
@onready var vibration_check: CheckBox = $Panel/VBox/VibrationCheck
@onready var back_btn: Button = $Panel/VBox/BackButton

var _is_open: bool = false

func _ready() -> void:
	visible = false
	quality_option.add_item("Nizkoe")
	quality_option.add_item("Srednee")
	quality_option.add_item("Vysokoe")
	quality_option.selected = 1
	if LocalizationManager:
		for lang in LocalizationManager.SUPPORTED:
			lang_option.add_item(LocalizationManager.LANG_NAMES.get(lang, lang))
	back_btn.pressed.connect(_close)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("settings"):
		_toggle()

func _toggle() -> void:
	_is_open = !_is_open
	visible = _is_open
	get_tree().paused = _is_open
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _is_open else Input.MOUSE_MODE_CAPTURED

func _on_sfx_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(value / 100.0))

func _on_music_changed(value: float) -> void:
	var bus = AudioServer.get_bus_index("Music")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(value / 100.0))

func _on_brightness_changed(value: float) -> void:
	var env = get_viewport().get_camera_3d()
	if env:
		var world_env = get_tree().current_scene.get_node_or_null("WorldEnvironment")
		if world_env and world_env.environment:
			world_env.environment.adjustment_brightness = value / 50.0

func _on_sens_changed(value: float) -> void:
	if GameManager.player:
		GameManager.player.mouse_sensitivity = value / 10000.0 + 0.001

func _on_quality_changed(index: int) -> void:
	match index:
		0:
			get_viewport().msaa_3d = Viewport.MSAA_DISABLED
		1:
			get_viewport().msaa_3d = Viewport.MSAA_2X
		2:
			get_viewport().msaa_3d = Viewport.MSAA_4X

func _on_lang_changed(index: int) -> void:
	if LocalizationManager and index < LocalizationManager.SUPPORTED.size():
		LocalizationManager.set_language(LocalizationManager.SUPPORTED[index])

func _close() -> void:
	_toggle()