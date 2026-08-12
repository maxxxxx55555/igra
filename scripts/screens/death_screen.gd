extends Control

@onready var panel: Panel = $Panel
@onready var title: Label = $Panel/Title
@onready var retry_button: Button = $Panel/Retry
@onready var menu_button: Button = $Panel/Menu


func _ready() -> void:
	visible = false
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS
	if not retry_button.pressed.is_connected(_on_continue):
		retry_button.pressed.connect(_on_continue)
	if not menu_button.pressed.is_connected(_on_menu):
		menu_button.pressed.connect(_on_menu)

func set_reason(reason: String) -> void:
	title.text = "Ты пал: " + reason

func show_death() -> void:
	visible = true
	Engine.time_scale = 0.0
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func hide_death() -> void:
	visible = false
	Engine.time_scale = 1.0

func _on_continue() -> void:
	hide_death()
	InputService.refresh_mouse_mode()
	var lm := get_tree().root.get_node_or_null("/root/LevelManager")
	if lm and lm.has_method("respawn_or_reload"):
		lm.respawn_or_reload()

func _on_menu() -> void:
	hide_death()
	var gm := get_tree().root.get_node_or_null("/root/GameManager")
	if gm and gm.has_method("goto_main_menu"):
		gm.goto_main_menu()
