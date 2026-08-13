extends Node2D

func _ready() -> void:
	GameManager._change_state(GameManager.GameState.PLAYING)
	var main: Node = load("res://scenes/main_3d.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(2.5).timeout
	_save_shot("res://assets/art/shot_game.png")
	UIManager.open(&"main_menu")
	await get_tree().create_timer(0.8).timeout
	_save_shot("res://assets/art/shot_menu.png")
	print("[SHOT] done")
	get_tree().quit()

func _save_shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	img.save_png(path)
	print("[SHOT] saved: ", path)
