extends Node3D

@export var district_id: StringName = &"test_zone"
@export var result_stage: int = 1
@export var action_name: String = ""  # пусто = ACTION_START_GENERATOR из локализации

var _player_nearby: bool = false

func _ready() -> void:
	$TriggerArea.body_entered.connect(_on_enter)
	$TriggerArea.body_exited.connect(_on_exit)
	InputService.interact_requested.connect(_on_interact)

func _on_enter(body: Node) -> void:
	if body.is_in_group("player"):
		_player_nearby = true
		EventBus.player_interact_available.emit(true)

func _on_exit(body: Node) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		EventBus.player_interact_available.emit(false)

func _on_interact() -> void:
	if not _player_nearby:
		return
	PowerGrid.advance_district(district_id, result_stage)
	# action_name пустой у большинства головоломок — подставляем локализованное
	# название действия, иначе игрок видел бы "ГОТОВО: " без предмета.
	var action: String = action_name if not action_name.is_empty() else LocalizationManager.t("ACTION_START_GENERATOR")
	EventBus.puzzle_solved.emit(StringName("%s_%s" % [district_id, action]), district_id)
	EventBus.inventory_notice.emit(LocalizationManager.tf("ACTION_READY", [action]))
	queue_free()
