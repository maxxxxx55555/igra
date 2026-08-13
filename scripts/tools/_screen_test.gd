extends Node

var _idx: int = 0
var _ids: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SaveSystem.reset_all()
	GameManager._change_state(GameManager.GameState.PLAYING)
	add_child(load("res://scenes/main_3d.tscn").instantiate())
	_ids = UIManager.SCREENS.keys()
	await get_tree().create_timer(3.0).timeout
	_next()

func _next() -> void:
	if _idx >= _ids.size():
		print("[stest] ALL SCREENS OK: ", _idx)
		get_tree().quit(0)
		return
	var id: StringName = _ids[_idx]
	_idx += 1
	UIManager.open(id)
	await get_tree().process_frame
	await get_tree().process_frame
	UIManager.close(id)
	print("[stest] ok: ", id)
	call_deferred("_next")

func _process(_d: float) -> void:
	pass
