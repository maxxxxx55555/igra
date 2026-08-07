extends Node
@export var stats: InventoryStats
var slots: Array = []
var current_weight: float = 0.0
var _net_active: bool = false
func _ready() -> void:
    _net_active = multiplayer != null and multiplayer.multiplayer_peer != null
    if stats == null:
        var loaded_stats := load("res://data/balance/inventory_stats.tres") as InventoryStats
        if loaded_stats != null:
            stats = loaded_stats
        else:
            # push_warning("InventoryManager: falling back to a new InventoryStats instance")
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
        EventBus.inventory_notice.emit("Рюкзак перегружен — нельзя поднять")
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
            EventBus.inventory_notice.emit("Нет свободных слотов")
            _recompute_weight()
            EventBus.inventory_changed.emit()
            return false
        var put := mini(remaining, data.max_stack if data.stackable else 1)
        slots[free_idx] = {"item_id": item_id, "count": put}
        remaining -= put
    _recompute_weight()
    EventBus.inventory_changed.emit()
    EventBus.item_picked_up.emit(item_id)
    if _net_active and is_multiplayer_authority():
        _sync_inventory.rpc(to_dict())
    elif _net_active:
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
    if _net_active and is_multiplayer_authority():
        _sync_inventory.rpc(to_dict())
    elif _net_active:
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
        EventBus.inventory_notice.emit("Этот предмет нельзя использовать")
        return false
    EventBus.item_consumed.emit(s["item_id"], _effect_name(data.effect), data.effect_value)
    s["count"] -= 1
    if s["count"] <= 0:
        slots[slot_index] = null
    _recompute_weight()
    EventBus.inventory_changed.emit()
    if _net_active and is_multiplayer_authority():
        _sync_inventory.rpc(to_dict())
    elif _net_active:
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
func to_dict() -> Dictionary:
    var data: Array = []
    for s in slots:
        if s == null:
            data.append(null)
        else:
            data.append({"item_id": String(s["item_id"]), "count": s["count"]})
    return {"slots": data}
func from_dict(d: Dictionary) -> void:
    _init_empty_slots()
    var saved: Array = d.get("slots", []) as Array
    for i in mini(saved.size(), slots.size()):
        var s = saved[i]
        if s == null:
            slots[i] = null
        elif s is Dictionary:
            slots[i] = {"item_id": StringName(s.get("item_id", "")), "count": int(s.get("count", 0))}
    _recompute_weight()
    EventBus.inventory_changed.emit()
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
func _sync_inventory(payload: Dictionary) -> void:
    if is_multiplayer_authority():
        return
    from_dict(payload)