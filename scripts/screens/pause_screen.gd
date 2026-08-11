class_name PauseScreen
extends CanvasLayer

@onready var resume_button: Button = %ResumeButton
@onready var settings_button: Button = %SettingsButton
@onready var save_quit_button: Button = %SaveQuitButton
@onready var quit_button: Button = %QuitButton
@onready var pause_panel: Panel = %PausePanel

var is_paused: bool = false


func _ready() -> void:
	visible = false
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS
	resume_button.pressed.connect(_on_resume)
	settings_button.pressed.connect(_on_settings)
	save_quit_button.pressed.connect(_on_save_quit)
	quit_button.pressed.connect(_on_quit)


func toggle_pause() -> void:
	if is_paused:
		_resume_game()
	else:
		_pause_game()


func _pause_game() -> void:
	is_paused = true
	visible = true
	Engine.time_scale = 0.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _resume_game() -> void:
	is_paused = false
	Engine.time_scale = 1.0
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_resume() -> void:
	_resume_game()


func _on_settings() -> void:
	var settings_screen: SettingsScreen = get_tree().root.get_node_or_null("SettingsScreen")
	if settings_screen:
		settings_screen.show_settings()


func _on_save_quit() -> void:
	_resume_game()
	SaveSystem.save_all()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_quit() -> void:
	_resume_game()
	get_tree().quit()
