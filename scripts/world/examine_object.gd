extends Area2D
@export var text: String = "Следы катастрофы. Мир хранит ответы — нужно лишь смотреть внимательнее."
func _ready() -> void:
    add_to_group("interactable")
    monitorable = true
func interact(_player: Node) -> void:
    EventBus.examine_text.emit(text)