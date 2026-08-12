extends SceneTree
func _init():
	var paths = [
		"res://scenes/gameplay/checkpoint.tscn",
	]
	for p in paths:
		var r = ResourceLoader.load(p)
	quit()
