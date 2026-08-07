
extends CanvasLayer

@onready 
var rect: ColorRect = $ColorRect

func _ready() -> void:
	rect.color = Color(0, 0, 0, 0)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func fade_to_black(duration: float = 0.5) -> void:
	
	var tween := create_tween()
	tween.tween_property(rect, "color:a", 1.0, duration)
	await tween.finished

func fade_from_black(duration: float = 0.5) -> void:
	
	var tween := create_tween()
	tween.tween_property(rect, "color:a", 0.0, duration)
	await tween.finished

func change_scene(path: String) -> void:
	await fade_to_black()
	get_tree().change_scene_to_file(path)
	await get_tree().create_timer(0.1).timeout
	await fade_from_black()
