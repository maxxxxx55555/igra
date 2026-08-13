
extends Area3D

@export 
var key_id: String = "key"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	# Две ошибки в четырёх строках: InventoryManager — автозагрузка в /root,
	# а не ребёнок игрока, и метода add_key() у него нет (API — try_add()).
	# Условие никогда не выполнялось, а queue_free() стоял ЗА ним: ключ
	# бесследно исчезал с земли, так и не попав в рюкзак.
	var inv := get_node_or_null("/root/InventoryManager")
	if inv == null or not inv.has_method("try_add"):
		return
	if not inv.try_add(StringName(key_id), 1):
		# Рюкзак переполнен — ключ остаётся лежать, уведомление шлёт инвентарь.
		return
	queue_free()
