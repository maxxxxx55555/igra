extends Node

func _ready() -> void:
	if "--shot" in OS.get_cmdline_args():
		_run()

func _run() -> void:
	await get_tree().create_timer(4.0).timeout
	var img := get_tree().root.get_texture().get_image()
	img.save_png("C:/Users/Maxsim/Desktop/shot1.png")
	get_tree().quit()