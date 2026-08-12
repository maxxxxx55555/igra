extends Area2D
@export var text: String = ""  # пусто = EXAMINE_DEFAULT из локализации
func _ready() -> void:
	add_to_group("interactable")
	monitorable = true
func interact(_player: Node) -> void:
	EventBus.examine_text.emit(text if not text.is_empty() else LocalizationManager.t("EXAMINE_DEFAULT"))