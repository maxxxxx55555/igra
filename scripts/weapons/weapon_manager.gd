extends Node
class_name WeaponManager

signal weapon_switched(weapon: WeaponBase)
signal ammo_changed(current: int, max: int)

@export var weapon_slots: Array[WeaponBase] = []
var _current_index: int = 0
## Индексы найденного оружия. Стартовый пистолет выдаётся сразу, остальное
## приносят weapon_pickup-и (GDD §18: «Пикапы: weapon_pickup.gd — unlock в
## WeaponManager»).
var _unlocked: Array[int] = []

func _ready() -> void:
	_collect_children()
	# _ready детей исполняется раньше _ready родителя, а в группу "player"
	# игрок добавляет себя сам (player_3d.gd, add_to_group) — на этом кадре
	# группы ещё нет, и поиск по группе вернул бы null. Владелец оружия — это
	# наш родитель; группа остаётся запасным путём.
	var shooter := get_parent() as Node3D
	if shooter == null:
		shooter = get_tree().get_first_node_in_group("player") as Node3D
	for i in weapon_slots.size():
		if weapon_slots[i]:
			weapon_slots[i].set_shooter(shooter)
			weapon_slots[i].ammo_changed.connect(_on_ammo_changed)
	
	_unlocked.clear()
	if weapon_slots.size() > 0:
		_unlocked.append(0)
		if not _restore_from_save():
			weapon_switched.emit(get_current_weapon())
			_apply_visibility()
			_push_ammo()

## weapon_slots не обязан быть заполнен в сцене: менеджер подбирает оружие из
## собственных детей, поэтому узлы оружия видны в редакторе и не требуют
## экспортируемого массива ссылок.
func _collect_children() -> void:
	if not weapon_slots.is_empty():
		return
	for c in get_children():
		if c is WeaponBase:
			weapon_slots.append(c as WeaponBase)

func get_current_weapon() -> WeaponBase:
	if weapon_slots.is_empty() or _current_index >= weapon_slots.size():
		return null
	if not _unlocked.has(_current_index):
		return null
	return weapon_slots[_current_index]

## Игрок смотрит камерой (у неё собственный питч), а оружие висит на теле.
## Держим текущее оружие развёрнутым вдоль взгляда — иначе лучи RayCast3D
## летели бы по -Z тела, то есть всегда в горизонт, — и заодно получаем
## вьюмодель в кадре. Вне вида от первого лица модель прячем.
func _process(_delta: float) -> void:
	var weapon := get_current_weapon()
	if weapon == null:
		return
	var cam := get_viewport().get_camera_3d() if get_viewport() != null else null
	if cam == null:
		return
	var owner_body := get_parent() as Node3D
	if owner_body != null and cam.global_position.distance_to(owner_body.global_position) > 2.5:
		weapon.visible = false
		return
	weapon.visible = true
	weapon.aim_at(cam.global_position, -cam.global_transform.basis.z)

func _apply_visibility() -> void:
	for i in weapon_slots.size():
		if weapon_slots[i] != null:
			weapon_slots[i].visible = (i == _current_index) and _unlocked.has(i)

func _push_ammo() -> void:
	var weapon := get_current_weapon()
	if weapon == null:
		return
	_on_ammo_changed(weapon.current_ammo, weapon.max_ammo)

## ── Резерв патронов ────────────────────────────────────────────────────────
## GDD §17: патроны универсальные — обычный предмет инвентаря `ammo`.
## Отдельного счётчика не заводим: источник истины один (InventoryManager),
## поэтому патроны переживают сохранение вместе со всем рюкзаком.
const AMMO_ITEM: StringName = &"ammo"

func get_reserve() -> int:
	var inv := get_node_or_null("/root/InventoryManager")
	if inv == null or not inv.has_method("count_of"):
		return 0
	return int(inv.count_of(AMMO_ITEM))

## Возвращает, сколько патронов реально легло в рюкзак (рюкзак может быть полон).
func add_reserve(amount: int) -> int:
	if amount <= 0:
		return 0
	var inv := get_node_or_null("/root/InventoryManager")
	if inv == null or not inv.has_method("try_add"):
		return 0
	var before: int = get_reserve()
	inv.try_add(AMMO_ITEM, amount)
	return get_reserve() - before

## ── Открытие оружия ────────────────────────────────────────────────────────
func _index_of(id: String) -> int:
	var want := id.to_lower()
	for i in weapon_slots.size():
		var w := weapon_slots[i]
		if w != null and String(w.weapon_name).to_lower() == want:
			return i
	return -1

## Открывает оружие по имени (pistol/rifle/shotgun) и берёт его в руки.
func unlock_weapon(id: String) -> bool:
	var idx := _index_of(id)
	if idx < 0 or _unlocked.has(idx):
		return false
	_unlocked.append(idx)
	_current_index = idx
	weapon_switched.emit(get_current_weapon())
	_apply_visibility()
	_push_ammo()
	return true

## Найденное оружие переживает сохранение: SaveSystem копит словарь до
## появления игрока (тот же приём, что и с consume_pending_player_pos()).
func to_dict() -> Dictionary:
	var names: Array = []
	for i in _unlocked:
		var w := weapon_slots[i]
		if w != null:
			names.append(String(w.weapon_name).to_lower())
	var cur := get_current_weapon()
	return {
		"unlocked": names,
		"current": String(cur.weapon_name).to_lower() if cur != null else "",
	}

func from_dict(d: Dictionary) -> void:
	_unlocked.clear()
	for nm in d.get("unlocked", []):
		var idx := _index_of(String(nm))
		if idx >= 0 and not _unlocked.has(idx):
			_unlocked.append(idx)
	if _unlocked.is_empty() and not weapon_slots.is_empty():
		_unlocked.append(0)
	var cur := String(d.get("current", ""))
	if not cur.is_empty():
		var ci := _index_of(cur)
		if ci >= 0 and _unlocked.has(ci):
			_current_index = ci
	weapon_switched.emit(get_current_weapon())
	_apply_visibility()
	_push_ammo()

func _restore_from_save() -> bool:
	var ss := get_node_or_null("/root/SaveSystem")
	if ss == null or not ss.has_method("consume_pending_weapons"):
		return false
	var pending: Dictionary = ss.consume_pending_weapons()
	if pending.is_empty():
		return false
	from_dict(pending)
	return true

func switch_weapon(index: int) -> bool:
	if index < 0 or index >= weapon_slots.size():
		return false
	if not weapon_slots[index]:
		return false
	if not _unlocked.has(index):
		return false
	
	_current_index = index
	weapon_switched.emit(get_current_weapon())
	_apply_visibility()
	_push_ammo()
	return true

func next_weapon() -> void:
	_cycle(1)

func previous_weapon() -> void:
	_cycle(-1)

## Листаем только найденное оружие: переключение на запертый слот оставило бы
## игрока с пустыми руками.
func _cycle(step: int) -> void:
	if weapon_slots.size() < 2 or _unlocked.size() < 2:
		return
	var idx := _current_index
	for _i in weapon_slots.size():
		idx = (idx + step + weapon_slots.size()) % weapon_slots.size()
		if _unlocked.has(idx):
			break
	switch_weapon(idx)

func fire(from_pos: Vector3, direction: Vector3) -> bool:
	var weapon = get_current_weapon()
	if weapon:
		weapon.aim_at(from_pos, direction)
		return weapon.fire(from_pos, direction)
	return false

## Перезарядка берёт патроны из рюкзака: сколько есть, столько и дошлётся в
## магазин (см. WeaponBase._finish_reload).
func reload() -> bool:
	var weapon = get_current_weapon()
	if weapon == null:
		return false
	var reserve := get_reserve()
	if not weapon.try_reload(reserve):
		return false
	var need: int = weapon.max_ammo - weapon.current_ammo
	var take: int = mini(need, reserve)
	if take > 0:
		var inv := get_node_or_null("/root/InventoryManager")
		if inv != null and inv.has_method("remove"):
			inv.remove(AMMO_ITEM, take)
	return true

func _on_ammo_changed(current: int, max: int) -> void:
	ammo_changed.emit(current, max)
	EventBus.ammo_changed.emit(current, max)

func add_weapon(weapon: WeaponBase, slot: int = -1) -> void:
	if slot >= 0 and slot < weapon_slots.size():
		weapon_slots[slot] = weapon
	else:
		weapon_slots.append(weapon)
	
	weapon.set_shooter(get_tree().get_first_node_in_group("player"))
	weapon.ammo_changed.connect(_on_ammo_changed)