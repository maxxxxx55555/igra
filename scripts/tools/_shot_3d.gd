extends Node3D

## Снимает два кадра ровно по тому пути, которым идёт настоящий запуск игры:
## сплэш держит экран 3 с, затем UIManager открывает main_menu по событию
## game_state_changed(MENU). Раньше тут дёргался Screens.show_screen("MainMenu") —
## это ВТОРАЯ, параллельная система меню, и снимок показывал не то, что видит игрок.

func _ready() -> void:
	var main: Node = load("res://scenes/main_3d.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(4.5).timeout
	_save_shot("res://assets/art/shot_menu_3d.png")
	await get_tree().create_timer(0.5).timeout
	GameManager._change_state(GameManager.GameState.PLAYING)
	await get_tree().create_timer(2.5).timeout
	_save_shot("res://assets/art/shot_game_3d.png")
	print("[SHOT3D] done")
	get_tree().quit()

func _save_shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	img.save_png(path)
	print("[SHOT3D] saved: ", path)
