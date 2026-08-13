extends Node3D

@export var loot_table: LootTable
@export var drop_radius: float = 1.0

func drop_loot() -> void:
	if not loot_table:
		return
	var items = loot_table.roll()
	for item in items:
		spawn_item(item)

func spawn_item(item_data: Dictionary) -> void:
	var pickup := Area3D.new()
	pickup.name = "LootPickup"
	pickup.position = position + Vector3(randf() * drop_radius, 0.5, randf() * drop_radius)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.4
	shape.shape = sphere
	pickup.add_child(shape)
	# gdtoolkit (gdparse/gdlint) не умеет разбирать многострочные лямбды и
	# ругается на строку ниже. Для Godot 4 это корректный синтаксис —
	# ограничение инструмента, а не ошибка кода. Проверять файл нужно движком.
	pickup.body_entered.connect(func(body: Node3D) -> void:
		if body.is_in_group("player"):
			var inv := get_tree().root.get_node_or_null("/root/InventoryManager")
			if inv and inv.has_method("add_item"):
				inv.add_item(item_data)
			pickup.queue_free())
	get_tree().current_scene.add_child(pickup)
