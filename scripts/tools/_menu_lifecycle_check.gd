extends Node
## A language change may queue layout just before routing removes the menu.

var _fails: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager._change_state(GameManager.GameState.MENU)
	var menu := (load("res://scenes/ui/main_menu.tscn") as PackedScene).instantiate() as Control
	add_child(menu)
	await get_tree().process_frame
	await get_tree().process_frame
	var column := menu.get_node("VBox") as VBoxContainer
	var kept_position: Vector2 = column.position
	var kept_size: Vector2 = column.size
	var kept_scale: Vector2 = column.scale
	menu._apply_localization()
	remove_child(menu)
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(not menu.is_inside_tree(), "menu is detached before deferred layout runs")
	_ok(column.position.is_equal_approx(kept_position), "detached menu keeps its layout position")
	_ok(column.size.is_equal_approx(kept_size), "detached menu keeps its layout size")
	_ok(column.scale.is_equal_approx(kept_scale), "detached menu keeps its layout scale")
	add_child(menu)
	menu._layout_menu()
	_ok(column.size.x > 0.0 and column.scale.x > 0.0, "live menu still fits its viewport")
	menu.queue_free()
	await get_tree().process_frame
	print("[menu-lifecycle] DONE fails=%d" % _fails)
	get_tree().quit(0 if _fails == 0 else 1)

func _ok(condition: bool, label: String) -> void:
	if not condition:
		_fails += 1
	print("[menu-lifecycle] %s %s" % ["OK" if condition else "FAIL", label])
