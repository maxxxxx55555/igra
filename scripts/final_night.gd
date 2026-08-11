extends Node

signal victory()
var is_active: bool = false
var is_won: bool = false
var _timer: float = 0.0
var _survive: float = 300.0

func _ready() -> void:
	var grid := get_node_or_null("/root/PowerGridManager")
	if grid and grid.has_signal("all_restored"):
		grid.all_restored.connect(start)


func start() -> void:
	if is_active:
		return
	is_active = true
	_timer = 0.0


func _process(delta: float) -> void:
	if not is_active or is_won:
		return
	_timer += delta
	if _timer >= _survive:
		win()

func win() -> void:
	is_won = true
	is_active = false

	victory.emit()