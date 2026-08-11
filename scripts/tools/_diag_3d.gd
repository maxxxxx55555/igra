extends Node3D

func _ready() -> void:
	var main: Node = load("res://scenes/main_3d.tscn").instantiate()
	add_child(main)
	print("[diag] main type=", main.get_class(), " children=", main.get_child_count())
	for c in main.get_children():
		var sc: Object = c.get_script() if c.get_script() else null
		print("[diag]   child: ", c.name, " type=", c.get_class(), " script=", sc.resource_path if sc else "NONE")
	var p := get_tree().root.find_child("Player", true, false)
	print("[diag] player found: ", p, " script=", (p.get_script().resource_path if p and p.get_script() else "NONE"))
	if p:
		print("[diag] player groups: ", p.get_groups())
	await get_tree().process_frame
	for g in ["shadow", "crawlers", "watchers", "hunters", "destroyers", "pickups", "nav_region", "objectives"]:
		var arr := get_tree().get_nodes_in_group(g)
		print("[diag] group ", g, " = ", arr.size())
	var sb := get_tree().root.find_child("StreetBuilder", true, false)
	print("[diag] streetbuilder static_bodies=", sb.get_child_count() if sb else -1)
	get_tree().quit()
