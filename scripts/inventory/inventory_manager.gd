extends Node
@export var stats: InventoryStats
var slots: Array = []
var current_weight: float = 0.0
var _net_active: bool = false

## GDD §V.5 9.5: слоты экипировки. Однослотовые, без мультистайлов.
## Значение — { "item_id": StringName, "count": int } или null.
var equipment: Dictionary = {
	ItemData.EquipSlot.HEAD: null,
	ItemData.EquipSlot.BODY: null,
	ItemData.EquipSlot.LEGS: null,
	ItemData.EquipSlot.HOLSTER: null,
	ItemData.EquipSlot.BACKPACK: null,
}

## Сеть считается активной только при РЕАЛЬНОМ подключении.
## multiplayer_peer != null истинно всегда: по умолчанию там висит
## OfflineMultiplayerPeer, и в одиночной игре _sync_inventory.rpc() улетал
## сам себе ("RPC on yourself is not allowed"). Проверяем настоящий пир.
func _is_networked() -> bool:
	if multiplayer == null:
		return false
	var peer := multiplayer.multiplayer_peer
	if peer == null or peer is OfflineMultiplayerPeer:
		return false
	return peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED

func _ready() -> void:
	_net_active = _is_networked()
	if stats == null:
		var loaded_stats := load("res://data/balance/inventory_stats.tres") as InventoryStats
		if loaded_stats != null:
			stats = loaded_stats
		else:
			push_warning("InventoryManager: falling back to a new InventoryStats instance")
			stats = InventoryStats.new()
	_init_empty_slots()
func _init_empty_slots() -> void:
	slots.clear()
	for i in stats.base_slots:
		slots.append(null)
	_recompute_weight()
## Навык "inventory_space" расширяет сумку. Существующие слоты не трогаем —
## только дописываем пустые в конец, иначе содержимое сместится.
func add_slots(amount: int) -> void:
	if amount <= 0:
		return
	for i in amount:
		slots.append(null)
	EventBus.inventory_changed.emit()

func try_add(item_id: StringName, amount: int = 1) -> bool:
	var data := ItemDatabase.get_item(item_id)
	if data == null or amount <= 0:
		return false
	if current_weight + data.weight * amount > stats.capacity_kg + 0.0001:
		EventBus.inventory_notice.emit(LocalizationManager.t("INV_OVERWEIGHT"))
		return false
	var remaining := amount
	if data.stackable:
		for i in slots.size():
			if remaining <= 0:
				break
			var s = slots[i]
			if s != null and s["item_id"] == item_id and s["count"] < data.max_stack:
				var can_add := mini(data.max_stack - s["count"], remaining)
				s["count"] += can_add
				remaining -= can_add
	while remaining > 0:
		var free_idx := _first_empty_slot()
		if free_idx == -1:
			EventBus.inventory_notice.emit(LocalizationManager.t("INV_NO_SLOTS"))
			_recompute_weight()
			EventBus.inventory_changed.emit()
			return false
		var put := mini(remaining, data.max_stack if data.stackable else 1)
		slots[free_idx] = {"item_id": item_id, "count": put}
		remaining -= put
	_recompute_weight()
	EventBus.inventory_changed.emit()
	EventBus.item_picked_up.emit(item_id)
	if _is_networked() and is_multiplayer_authority():
		_sync_inventory.rpc(to_dict())
	elif _is_networked():
		_request_add.rpc_id(1, item_id, amount)
	return true
func remove(item_id: StringName, amount: int = 1) -> bool:
	var remaining := amount
	for i in slots.size():
		if remaining <= 0:
			break
		var s = slots[i]
		if s != null and s["item_id"] == item_id:
			var take := mini(s["count"], remaining)
			s["count"] -= take
			remaining -= take
			if s["count"] <= 0:
				slots[i] = null
	if remaining > 0:
		return false
	_recompute_weight()
	EventBus.inventory_changed.emit()
	if _is_networked() and is_multiplayer_authority():
		_sync_inventory.rpc(to_dict())
	elif _is_networked():
		_request_remove.rpc_id(1, item_id, amount)
	return true
func use_item(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return false
	var s = slots[slot_index]
	if s == null:
		return false
	var data := ItemDatabase.get_item(s["item_id"])
	if data == null or not data.consumable:
		EventBus.inventory_notice.emit(LocalizationManager.t("INV_NOT_USABLE"))
		return false
	EventBus.item_consumed.emit(s["item_id"], _effect_name(data.effect), data.effect_value)
	s["count"] -= 1
	if s["count"] <= 0:
		slots[slot_index] = null
	_recompute_weight()
	EventBus.inventory_changed.emit()
	if _is_networked() and is_multiplayer_authority():
		_sync_inventory.rpc(to_dict())
	elif _is_networked():
		_request_use.rpc_id(1, slot_index)
	return true
func has(item_id: StringName, amount: int = 1) -> bool:
	return count_of(item_id) >= amount
func count_of(item_id: StringName) -> int:
	var total := 0
	for s in slots:
		if s != null and s["item_id"] == item_id:
			total += s["count"]
	return total
func weight_ratio() -> float:
	return clampf(current_weight / maxf(0.001, stats.capacity_kg), 0.0, 1.0)

## GDD §V.5 9.8 — сортировка предметов.
## mode: "type" | "weight" | "rarity" | "recent"
func sort_slots(mode: String = "type") -> void:
	var keyed: Array = []
	for i in slots.size():
		var s = slots[i]
		if s == null:
			continue
		var d := ItemDatabase.get_item(s["item_id"])
		var key: float = 0.0
		match mode:
			"weight":
				key = (0.0 - (d.weight if d else 0.0)) * 1000.0
			"rarity":
				key = (float(int(d.rarity if d else 0)) * 1000.0) + (0.0 - (d.weight if d else 0.0))
			"recent":
				pass # ponytail: пока не храним timestamp входа; сортировка по «новизне» запоминаем как возможность.
			_: # "type"
				key = float(_type_priority(d))
		keyed.append({"key": key, "slot_idx": i, "item": s})
	keyed.sort_custom(func(a, b): return a["key"] < b["key"])
	var new_slots: Array = []
	for i in slots.size(): new_slots.append(null)
	var tgt := 0
	for e in keyed:
		new_slots[tgt] = e["item"]
		tgt += 1
	slots = new_slots
	_recompute_weight()
	EventBus.inventory_changed.emit()

func _type_priority(d: ItemData) -> int:
	if d == null:
		return 999
	if d.consumable:
		return 0
	match d.equip_slot:
		ItemData.EquipSlot.HEAD: return 10
		ItemData.EquipSlot.BODY: return 11
		ItemData.EquipSlot.LEGS: return 12
		ItemData.EquipSlot.HOLSTER: return 13
		ItemData.EquipSlot.BACKPACK: return 14
	return 50
func to_dict() -> Dictionary:
	var data: Array = []
	for s in slots:
		if s == null:
			data.append(null)
		else:
			data.append({"item_id": String(s["item_id"]), "count": s["count"]})
	# Сериализация экипировки: int(slot) → item_id
	var equip_ids: Dictionary = {}
	for slot in equipment:
		if equipment[slot] != null:
			equip_ids[str(int(slot))] = String(equipment[slot]["item_id"])
	return {"slots": data, "equipment": equip_ids}

func from_dict(d: Dictionary) -> void:
	_init_empty_slots()
	var saved: Array = d.get("slots", []) as Array
	for i in mini(saved.size(), slots.size()):
		var s = saved[i]
		if s == null:
			slots[i] = null
		elif s is Dictionary:
			slots[i] = {"item_id": StringName(s.get("item_id", "")), "count": int(s.get("count", 0))}
	# Восстановление экипировки
	for k in d.get("equipment", {}).keys():
		for slot in equipment:
			if str(int(slot)) == str(k):
				var item_id: StringName = StringName(String(d["equipment"][k]))
				if ItemDatabase.get_item(item_id):
					equipment[slot] = {"item_id": item_id, "count": 1}
	_recompute_weight()
	EventBus.inventory_changed.emit()
func equip_item(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return false
	var s = slots[slot_index]
	if s == null:
		return false
	var data := ItemDatabase.get_item(s["item_id"])
	if data == null or data.equip_slot == ItemData.EquipSlot.NONE:
		EventBus.inventory_notice.emit("Przedmet nie może być ekwipowany")
		return false
	# Если в слоте что-то есть — убрать в инвентарь.
	var cur = equipment.get(data.equip_slot)
	if cur != null and cur is Dictionary:
		var cur_id: StringName = cur.get("item_id", &"")
		var cur_data := ItemDatabase.get_item(cur_id)
		if cur_data != null:
			var ok := try_add(cur_id, int(cur.get("count", 1)))
			if not ok:
				EventBus.inventory_notice.emit(LocalizationManager.t("INV_NO_ROOM_UNEQUIP"))
				return false
	equipment[data.equip_slot] = {"item_id": s["item_id"], "count": s["count"]}
	slots[slot_index] = null
	_recompute_weight()
	EventBus.inventory_changed.emit()
	if _is_networked() and is_multiplayer_authority():
		_sync_inventory.rpc(to_dict())
	elif _is_networked():
		_request_equip.rpc_id(1, slot_index)
	return true

func unequip_item(slot: ItemData.EquipSlot) -> bool:
	var cur = equipment.get(slot)
	if cur == null:
		return false
	var cur_id: StringName = cur.get("item_id", &"")
	var ok := try_add(cur_id, int(cur.get("count", 1)))
	if not ok:
		EventBus.inventory_notice.emit(LocalizationManager.t("INV_NO_ROOM"))
		return false
	equipment[slot] = null
	_recompute_weight()
	EventBus.inventory_changed.emit()
	if _is_networked() and is_multiplayer_authority():
		_sync_inventory.rpc(to_dict())
	elif _is_networked():
		_request_unequip.rpc_id(1, int(slot))
	return true

func get_equipped(slot: ItemData.EquipSlot) -> Dictionary:
	var cur = equipment.get(slot)
	return (cur as Dictionary) if cur is Dictionary else {}

func _first_empty_slot() -> int:
	for i in slots.size():
		if slots[i] == null:
			return i
	return -1
func _recompute_weight() -> void:
	var w := 0.0
	for s in slots:
		if s == null:
			continue
		var data := ItemDatabase.get_item(s["item_id"])
		if data != null:
			w += data.weight * s["count"]
	current_weight = w
	EventBus.inventory_weight_changed.emit(weight_ratio())
func _effect_name(e: int) -> StringName:
	match e:
		ItemData.Effect.HEAL: return &"HEAL"
		ItemData.Effect.RECHARGE: return &"RECHARGE"
		_: return &"NONE"

@rpc("any_peer", "reliable")
func _request_add(item_id: StringName, amount: int) -> void:
	if not is_multiplayer_authority():
		return
	if not try_add(item_id, amount):
		_sync_inventory.rpc(to_dict())

@rpc("any_peer", "reliable")
func _request_remove(item_id: StringName, amount: int) -> void:
	if not is_multiplayer_authority():
		return
	remove(item_id, amount)
	_sync_inventory.rpc(to_dict())

@rpc("any_peer", "reliable")
func _request_use(slot_index: int) -> void:
	if not is_multiplayer_authority():
		return
	use_item(slot_index)
	_sync_inventory.rpc(to_dict())

@rpc("any_peer", "reliable")
func _request_equip(slot_index: int) -> void:
	if not is_multiplayer_authority():
		return
	equip_item(slot_index)
	_sync_inventory.rpc(to_dict())

@rpc("any_peer", "reliable")
func _request_unequip(slot: int) -> void:
	if not is_multiplayer_authority():
		return
	unequip_item(slot as ItemData.EquipSlot)
	_sync_inventory.rpc(to_dict())

@rpc("any_peer", "reliable")
func _sync_inventory(payload: Dictionary) -> void:
	if is_multiplayer_authority():
		return
	from_dict(payload)