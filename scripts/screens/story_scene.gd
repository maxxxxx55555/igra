class_name StoryScene
extends CanvasLayer

@onready var story_label: RichTextLabel = %StoryLabel
@onready var continue_hint: Label = %ContinueHint
@onready var skip_button: Button = %SkipButton

var current_lines: Array[String] = []
var current_index: int = 0
var _typing_speed: float = 0.04

signal story_finished()


func _ready() -> void:
	visible = false
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS
	skip_button.pressed.connect(_skip_all)
	continue_hint.text = "Click to continue..."


func play_story(lines: Array[String]) -> void:
	current_lines = lines
	current_index = 0
	visible = true
	_show_line()


func _show_line() -> void:
	if current_index >= current_lines.size():
		_finish_story()
		return
	story_label.text = ""
	continue_hint.visible = false
	_type_line(current_lines[current_index])


func _type_line(line: String) -> void:
	var tween: Tween = create_tween()
	tween.tween_method(_set_text.bind(line), 0.0, 1.0, _typing_speed * line.length())
	await tween.finished
	continue_hint.visible = true


func _set_text(progress: float, full_line: String) -> void:
	story_label.text = full_line.substr(0, int(full_line.length() * progress))


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		if continue_hint.visible:
			current_index += 1
			_show_line()
		else:
			_skip_all()
		get_viewport().set_input_as_handled()


func _skip_all() -> void:
	if current_index < current_lines.size():
		story_label.text = current_lines[current_index]
		continue_hint.visible = true


func _finish_story() -> void:
	visible = false
	story_finished.emit()
