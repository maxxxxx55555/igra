class_name SettingsScreen
extends CanvasLayer

@onready var master_slider: HSlider = %MasterSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var resolution_option: OptionButton = %ResolutionOption
@onready var fullscreen_check: CheckButton = %FullscreenCheck
@onready var close_button: Button = %CloseButton

var _original_bus_map: Dictionary = {}
var _original_resolution: Vector2i
var _original_fullscreen: bool


func _ready() -> void:
	visible = false
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS
	_build_bus_map()
	close_button.pressed.connect(_on_close)
	master_slider.value_changed.connect(_on_master_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	music_slider.value_changed.connect(_on_music_changed)
	resolution_option.item_selected.connect(_on_resolution_selected)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	_populate_resolutions()


func _build_bus_map() -> void:
	_original_bus_map["Master"] = AudioServer.get_bus_index("Master")
	_original_bus_map["SFX"] = AudioServer.get_bus_index("SFX")
	_original_bus_map["Music"] = AudioServer.get_bus_index("Music")


func _populate_resolutions() -> void:
	resolution_option.clear()
	resolution_option.add_item("1920x1080")
	resolution_option.add_item("2560x1440")
	resolution_option.add_item("3840x2160")
	var current: Vector2i = DisplayServer.window_get_size()
	var idx: int = 0
	match current:
		Vector2i(1920, 1080):
			idx = 0
		Vector2i(2560, 1440):
			idx = 1
		Vector2i(3840, 2160):
			idx = 2
	resolution_option.select(idx)


func show_settings() -> void:
	visible = true
	_original_resolution = DisplayServer.window_get_size()
	_original_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN


func _on_close() -> void:
	visible = false


func _on_master_changed(value: float) -> void:
	var bus_idx: int = AudioServer.get_bus_index("Master")
	var db: float = linear_to_db(value)
	AudioServer.set_bus_volume_db(bus_idx, db)


func _on_sfx_changed(value: float) -> void:
	var bus_idx: int = AudioServer.get_bus_index("SFX")
	var db: float = linear_to_db(value)
	AudioServer.set_bus_volume_db(bus_idx, db)


func _on_music_changed(value: float) -> void:
	var bus_idx: int = AudioServer.get_bus_index("Music")
	var db: float = linear_to_db(value)
	AudioServer.set_bus_volume_db(bus_idx, db)


func _on_resolution_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_size(Vector2i(1920, 1080))
		1:
			DisplayServer.window_set_size(Vector2i(2560, 1440))
		2:
			DisplayServer.window_set_size(Vector2i(3840, 2160))


func _on_fullscreen_toggled(button_pressed: bool) -> void:
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		_on_close()
