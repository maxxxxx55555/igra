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

@export var item_id: StringName = &""
@export var amount: int = 1
@export var bob_height: float = 0.2
@export var bob_speed: float = 2.0
@export var rotation_speed: float = 1.0

var _base_y: float = 0.0
var _time: float = 0.0
var _picked_up: bool = false

func _ready() -> void:
	_base_y = global_position.y
	body_entered.connect(_on_body_entered)
	monitorable = true
	monitoring = true
	_apply_tint()
	# DistrictLoot сначала делает add_child() (тут срабатывает _ready), и только
	# потом задаёт global_position. Высоту для покачивания поэтому фиксируем
	# кадром позже, иначе _process утаскивал предмет к чужому _base_y = 0.
	call_deferred("_capture_base_y")

func _capture_base_y() -> void:
	_base_y = global_position.y

## Цвет предмета подсказывает тип: батарея янтарная, аптечка красная,
## ключ стальной. Иначе всё выглядит одинаковыми ящиками.
func _apply_tint() -> void:
	var col := Color(0.788, 0.635, 0.290)
	match item_id:
		&"medkit", &"bandage", &"serum":
			col = Color(0.706, 0.271, 0.184)
		&"key", &"ancient_key", &"lockpick":
			col = Color(0.682, 0.714, 0.749)
		&"cable", &"wiring", &"transistor", &"circuit":
			col = Color(0.373, 0.541, 0.306)
		&"document", &"audio_log", &"photo":
			col = Color(0.847, 0.824, 0.769)
	var mesh := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh != null:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = col
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 1.6
		mesh.material_override = mat
	var light := get_node_or_null("GlowOmniLight3D") as OmniLight3D
	if light != null:
		light.light_color = col

func _process(delta: float) -> void:
	if _picked_up:
		return
	_time += delta
	global_position.y = _base_y + sin(_time * bob_speed) * bob_height
	rotate_y(rotation_speed * delta)

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
	set_deferred("monitoring", false)

	# Сигнал item_picked_up уже отправлен внутри InventoryManager.try_add(),
	# который сам же занимается и сетевой синхронизацией инвентаря.
	# Раньше здесь было rpc_id(1, "_server_pickup", ...): по умолчанию
	# multiplayer_peer — это OfflineMultiplayerPeer с id = 1, поэтому
	# has_multiplayer_peer() истинно и в одиночной игре, а вызов уходил
	# самому себе -> "RPC '_server_pickup' on yourself is not allowed".
	# Ветка else дублировала сигнал, из-за чего звук подбора и счётчики
	# квестов срабатывали дважды.

	# Всплываем и гаснем: масштаб и свет вместо несуществующего modulate.
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position:y", global_position.y + 0.6, 0.28)
	tween.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.28)
	var light := get_node_or_null("GlowOmniLight3D") as OmniLight3D
	if light != null:
		tween.tween_property(light, "light_energy", 0.0, 0.28)
	tween.chain().tween_callback(queue_free)

func set_item(item: StringName, qty: int) -> void:
	item_id = item
	amount = qty
	_apply_tint()
