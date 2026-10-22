extends Area3D
class_name ItemPickup3D
## Подбираемый предмет в 3D-мире.
##
## Здесь было три ошибки, из-за которых предмет нельзя было поднять:
## 1) get_node_or_null("InventoryManager") — без ведущего "/root/" от Area3D
##    это искало дочерний узел и всегда возвращало null;
## 2) tween по "modulate" — у Area3D такого свойства нет, анимация исчезновения
##    приводила к ошибке вместо эффекта;
## 3) сама сцена состояла из одного Area3D без коллайдера и меша: предмет был
##    невидим и физически не существовал.
##
## C1-C3 (v1.0.0-ship): the item lies on the ground and looks like what it is (scripts/art/pickup_meshes.gd dresses the
## mesh; the scene holds none, and no light: a district holds a dozen of these, and a real light each was a dozen lights).

@export var item_id: StringName = &""
@export var amount: int = 1

const _Meshes := preload("res://scripts/art/pickup_meshes.gd")

var _picked_up: bool = false
## Where this pickup sits in its district's loot list (DistrictLoot): taken keys are not spawned again, the rest are.
var loot_key: String = ""

const _PICKUP_BLIP := preload("res://assets/audio/sfx/ui_hover.wav")

func _ready() -> void:
	# WAVE 6 P4: nothing ever added pickups to this group - radar.gd's
	# minimap pickup blips (a live gameplay feature) and _game_test_3d.gd's
	# own check were both silently reading an always-empty group.
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	monitorable = true
	monitoring = true
	if item_id != &"":
		_dress()

func _dress() -> void:
	var piece := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if piece != null:
		_Meshes.dress(self, piece, item_id)

func _on_body_entered(body: Node) -> void:
	if _picked_up:
		return
	if not body.is_in_group("player"):
		return
	var inventory := get_tree().root.get_node_or_null("/root/InventoryManager")
	if inventory == null or not inventory.has_method("try_add"):
		return
	if not inventory.try_add(item_id, amount):
		# Рюкзак перегружен — предмет остаётся лежать, уведомление шлёт инвентарь.
		return
	_picked_up = true
	if loot_key != "":
		ProgressTracker.mark_loot_taken(loot_key)
	set_deferred("monitoring", false)
	var data := ItemDatabase.get_item(item_id)
	if data != null:
		UIManager.fly_pickup_icon(global_position, data.icon)
	AudioManager.play_sfx(_PICKUP_BLIP, -8.0, &"UI")

	# Сигнал item_picked_up уже отправлен внутри InventoryManager.try_add(),
	# который сам же занимается и сетевой синхронизацией инвентаря.
	# Раньше здесь было rpc_id(1, "_server_pickup", ...): по умолчанию
	# multiplayer_peer — это OfflineMultiplayerPeer с id = 1, поэтому
	# has_multiplayer_peer() истинно и в одиночной игре, а вызов уходил
	# самому себе -> "RPC '_server_pickup' on yourself is not allowed".
	# Ветка else дублировала сигнал, из-за чего звук подбора и счётчики
	# квестов срабатывали дважды.

	# Всплываем и гаснем: масштаб вместо несуществующего modulate.
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position:y", global_position.y + 0.6, 0.28)
	tween.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.28)
	tween.chain().tween_callback(queue_free)

func set_item(item: StringName, qty: int) -> void:
	item_id = item
	amount = qty
	_dress()
