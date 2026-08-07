extends Area3D
class_name ItemPickup3D

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

func _process(delta: float) -> void:
	if _picked_up:
		return
	_time += delta
	# Bobbing animation
	global_position.y = _base_y + sin(_time * bob_speed) * bob_height
	# Rotation
	rotate_y(rotation_speed * delta)

func _on_body_entered(body: Node) -> void:
	if _picked_up:
		return
	if body.is_in_group("player"):
		var inventory = get_tree().root.get_node_or_null("InventoryManager")
		if inventory and inventory.try_add(item_id, amount):
			_picked_up = true
			
			# Network sync - emit on authority only
			if multiplayer.has_multiplayer_peer():
				rpc_id(1, "_server_pickup", item_id, amount)
			else:
				EventBus.item_picked_up.emit(item_id)
			
			# Pickup effect
			var tween = create_tween()
			tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.3)
			tween.tween_property(self, "global_position:y", global_position.y + 0.5, 0.3)
			tween.finished.connect(queue_free.bind())

@rpc("any_peer", "reliable")
func _server_pickup(item_id: StringName, amount: int) -> void:
	if is_multiplayer_authority():
		EventBus.item_picked_up.emit(item_id)

func set_item(item: StringName, qty: int) -> void:
	item_id = item
	amount = qty