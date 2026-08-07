extends Node

var _open := false
var _map: Control = null

func _ready() -> void:
	call_deferred("_find_or_create")

func _find_or_create() -> void:
	_map = _search(get_tree().root) as Control
	if _map == null:
		var s := load("res://scripts/ui/city_map.gd")
		if s != null:
			_map = s.new()
			_map.name = "CityMap"
			get_tree().root.add_child(_map)
	if _map != null:
		_map.visible = false

func _search(n: Node) -> Node:
	if String(n.name) == "CityMap":
		return n
	for c in n.get_children():
		var r := _search(c)
		if r != null:
			return r
	return null

func _process(_d: float) -> void:
	if _map != null and not _open:
		_map.visible = false

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("city_map_toggle"):
		_open = not _open
		if _map != null:
			_map.visible = _open
			if _open:
				_map.queue_redraw()