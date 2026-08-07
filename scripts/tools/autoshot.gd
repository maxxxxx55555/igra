extends SceneTree

var t: float = 0.0
var done: bool = false

func _init() -> void:
	change_scene_to_file("res://scenes/main_3d.tscn")

func _process(delta: float) -> bool:
	t += delta
	if t > 4.0 and not done:
		done = true
		var img := root.get_texture().get_image()
		img.save_png("C:/Users/Maxsim/Desktop/shot1.png")
		return true
	return false