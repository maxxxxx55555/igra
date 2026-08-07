extends Node

func _ready() -> void:
	call_deferred("_wire_all")

func _wire_all() -> void:
	var districts: Array[Node] = []
	for d in get_tree().get_nodes_in_group(&"district"):
		districts.append(d)
	var root: Node = get_tree().current_scene
	if root != null:
		_collect(root, districts)
	for d in districts:
		_wire(d)

func _collect(n: Node, out: Array[Node]) -> void:
	if n.is_in_group(&"district") or String(n.name).begins_with("district_"):
		if not out.has(n):
			out.append(n)
	for c in n.get_children():
		_collect(c, out)

func _wire(d: Node) -> void:
	var sb: Node = _find(d, &"StreetBuilder")
	if sb == null:
		return
	if _find(d, &"Props") == null:
		var ps: Script = load("res://scripts/world/street_props.gd")
		var props: Node = ps.new()
		props.name = "Props"
		props.set("street_builder_path", sb.get_path())
		d.add_child(props)
	if _find(d, &"Windows") == null:
		var ws: Script = load("res://scripts/world/emissive_windows.gd")
		var win: Node = ws.new()
		win.name = "Windows"
		d.add_child(win)
	if _find(d, &"Grading") == null:
		var gs: Script = load("res://scripts/world/district_grading.gd")
		var grading: Node = gs.new()
		grading.name = "Grading"
		grading.set("district_root_path", d.get_path())
		d.add_child(grading)

func _find(n: Node, nm: StringName) -> Node:
	for c in n.get_children():
		if c.name == nm:
			return c
	return null