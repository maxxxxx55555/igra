extends Node

## P0 (EMISSIVE FIX wave): this used to also spawn a "Windows" node running
## scripts/world/emissive_windows.gd, whose populate() searched its own
## subtree for wall MeshInstance3D children to project window quads onto.
## That subtree was always empty - not because of a wrong search path, but
## because no script anywhere in the project spawns wall/building geometry
## (CityStreetProps.make_wall_mesh() exists but is never called). The
## dynamic node did nothing in every district, every session. Real window
## lighting was already delivered a different way: each district .tscn
## hand-wires its own MultiMeshInstance3D running scripts/visual/
## emissive_windows.gd, which builds a self-contained lit/dark window grid
## in _ready() with no dependency on wall geometry. Deleted the dead
## duplicate instead of inventing wall-tagging for meshes that don't exist.
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