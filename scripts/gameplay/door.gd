
extends StaticBody3D

@export 
var required_key: String = "key"

@export 
var is_open: bool = false

@onready 
var mesh: MeshInstance3D = $MeshInstance3D

@onready 
var collision: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	# Без этой группы Interactor дверь не видел: он опрашивает
	# get_tree().get_nodes_in_group("interactable"), а дверь туда не вставала —
	# подойти и открыть её было невозможно.
	add_to_group("interactable")

func interact(_player: Node3D) -> void:
	if is_open:
		return
	# InventoryManager — автозагрузка, он лежит в /root, а не внутри игрока:
	# player.get_node_or_null("InventoryManager") всегда возвращал null,
	# поэтому дверь считалась запертой даже с нужным ключом в рюкзаке.
	# Метода has_item() в инвентаре тоже нет — API называется has().
	var inv := get_node_or_null("/root/InventoryManager")
	if inv != null and inv.has_method("has") and inv.has(StringName(required_key)):
		_open()
	else:
		_show_locked()

## Подсказка в HUD. Ключи берём из существующего словаря (13 локалей),
## новых не заводим.
func interact_prompt() -> String:
	if is_open:
		return ""
	return LocalizationManager.t("Locked")

## Открытую дверь больше не предлагаем открыть повторно.
func can_interact() -> bool:
	return not is_open

func _open() -> void:
	is_open = true
	
	var tween := create_tween()
	tween.tween_property(mesh, "position:y", -2.0, 1.0).set_trans(Tween.TRANS_QUAD)
	collision.disabled = true

func _show_locked() -> void:
	
	var tween := create_tween()
	tween.tween_property(mesh, "position:z", 0.2, 0.1)
	tween.tween_property(mesh, "position:z", 0.0, 0.1)
