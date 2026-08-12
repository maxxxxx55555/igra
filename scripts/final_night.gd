extends Node

signal victory()
var is_active: bool = false
var is_won: bool = false
var _timer: float = 0.0
var _survive: float = 300.0

func _ready() -> void:
	# PowerGridManager не существует (синглтон — PowerGrid), а сигнала
	# all_restored у него нет: финальная ночь не запускалась никогда.
	# Триггер — восстановление последнего района.
	EventBus.district_restored.connect(func(_id: StringName, _stage: int) -> void:
		if PowerGrid.all_restored():
			start())


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