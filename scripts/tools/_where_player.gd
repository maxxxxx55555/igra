extends Node

func _scan(n: Node, found: Array) -> void:
	if n.name == "Player":
		found.append(str(n.get_class()) + ":" + str(n.name) + " @ " + str(n.get_path()))
	for c in n.get_children():
		_scan(c, found)

func _ready() -> void:
	var GM = get_node_or_null("/root/GameManager")
	if GM and GM.has_method("_change_state"):
		GM._change_state(GM.GameState.PLAYING)
	var main = load("res://scenes/main_3d.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	print("  group 'player': ", get_tree().get_nodes_in_group("player"))
	print("  root find_child Player: ", get_tree().root.find_child("Player", true, false))
	var found: Array = []
	_scan(get_tree().root, found)
	print("  Player nodes in tree: ", found)
	print("  main children:")
	for c in main.get_children():
		print("    ", c.get_class(), " : ", c.name)
	print("===== DONE =====")
	get_tree().quit()
