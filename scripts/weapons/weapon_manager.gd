extends Node
class_name WeaponManager

signal weapon_switched(weapon: WeaponBase)
signal ammo_changed(current: int, max: int)

@export var weapon_slots: Array[WeaponBase] = []
var _current_index: int = 0

func _ready() -> void:
	for i in weapon_slots.size():
		if weapon_slots[i]:
			weapon_slots[i].set_shooter(get_tree().get_first_node_in_group("player"))
			weapon_slots[i].ammo_changed.connect(_on_ammo_changed)
	
	if weapon_slots.size() > 0:
		weapon_switched.emit(get_current_weapon())

func get_current_weapon() -> WeaponBase:
	if weapon_slots.is_empty() or _current_index >= weapon_slots.size():
		return null
	return weapon_slots[_current_index]

func switch_weapon(index: int) -> bool:
	if index < 0 or index >= weapon_slots.size():
		return false
	if not weapon_slots[index]:
		return false
	
	_current_index = index
	weapon_switched.emit(get_current_weapon())
	return true

func next_weapon() -> void:
	if weapon_slots.is_empty():
		return
	_current_index = (_current_index + 1) % weapon_slots.size()
	if get_current_weapon():
		weapon_switched.emit(get_current_weapon())

func previous_weapon() -> void:
	if weapon_slots.is_empty():
		return
	_current_index = (_current_index - 1 + weapon_slots.size()) % weapon_slots.size()
	if get_current_weapon():
		weapon_switched.emit(get_current_weapon())

func fire(from_pos: Vector3, direction: Vector3) -> bool:
	var weapon = get_current_weapon()
	if weapon:
		return weapon.fire(from_pos, direction)
	return false

func reload() -> bool:
	var weapon = get_current_weapon()
	if weapon:
		return weapon.try_reload()
	return false

func _on_ammo_changed(current: int, max: int) -> void:
	ammo_changed.emit(current, max)

func add_weapon(weapon: WeaponBase, slot: int = -1) -> void:
	if slot >= 0 and slot < weapon_slots.size():
		weapon_slots[slot] = weapon
	else:
		weapon_slots.append(weapon)
	
	weapon.set_shooter(get_tree().get_first_node_in_group("player"))
	weapon.ammo_changed.connect(_on_ammo_changed)