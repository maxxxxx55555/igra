extends Node

func _ready() -> void:
    await get_tree().process_frame
    if get_tree().current_scene == null or get_tree().current_scene.name == "":
        get_tree().change_scene_to_file("res://scenes/ui/splash.tscn")