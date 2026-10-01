extends Node
class_name WeaponManager
## GDD §18 / §24.1: the player's firearms. They are found in the world (weapon_pickup.gd) and kept in
## ProgressTracker, so they survive a save; the two weapon quick slots draw them, one ammo reserve feeds them all.

signal weapon_switched(weapon: WeaponBase)
## (magazine, reserve) of the drawn weapon: the HUD's "12 / 36".
signal ammo_changed(current: int, reserve: int)

const SCENES: Dictionary = {
	&"pistol": preload("res://scenes/weapons/weapon_pistol.tscn"),
	&"rifle": preload("res://scenes/weapons/weapon_rifle.tscn"),
	&"shotgun": preload("res://scenes/weapons/weapon_shotgun.tscn"),
}
const MODEL: PackedScene = preload("res://scenes/weapons/weapon_model.tscn")
## Viewmodel length per weapon: the placeholder model is one pistol-sized set of boxes.
const MODEL_LENGTH: Dictionary = {&"pistol": 1.0, &"rifle": 2.4, &"shotgun": 2.1}
## Where the drawn weapon sits in the camera's frame: right hand, a little below the view.
const HOLD_OFFSET := Vector3(0.22, -0.2, -0.45)

var equipped: StringName = &""
var _weapons: Dictionary = {}
var _model_material := StandardMaterial3D.new()

func _ready() -> void:
	_model_material.albedo_color = Color(0.15, 0.16, 0.18)
	_model_material.metallic = 0.6
	_model_material.roughness = 0.5
	for id in ProgressTracker.get_weapons():
		_spawn(StringName(id))

func _process(_delta: float) -> void:
	var weapon := get_current_weapon()
	var cam := get_viewport().get_camera_3d()
	if weapon != null and cam != null:
		weapon.global_transform = cam.global_transform * Transform3D(Basis(), HOLD_OFFSET)

func _spawn(id: StringName) -> void:
	var weapon := (SCENES[id] as PackedScene).instantiate() as WeaponBase
	weapon.visible = false
	weapon.manager = self
	weapon.set_shooter(get_parent() as Node3D)
	weapon.ammo_changed.connect(func(_current: int, _mag: int) -> void:
		if weapon == get_current_weapon():
			_emit_ammo())
	add_child(weapon)
	var model := MODEL.instantiate() as Node3D
	model.scale = Vector3(1.0, 1.0, float(MODEL_LENGTH[id]))
	for part in model.get_children():
		if part is CSGShape3D:
			(part as CSGShape3D).material = _model_material
	weapon.add_child(model)
	_weapons[id] = weapon

## A weapon found in the world: kept for the run (and the save) and announced.
func unlock(id: StringName) -> bool:
	if not SCENES.has(id) or not ProgressTracker.unlock_weapon(String(id)):
		return false
	_spawn(id)
	EventBus.inventory_notice.emit(LocalizationManager.tf("WEAPON_FOUND", [_display_name(id)]))
	return true

func is_unlocked(id: StringName) -> bool:
	return _weapons.has(id)

func has_weapon_equipped() -> bool:
	return equipped != &""

func get_current_weapon() -> WeaponBase:
	return _weapons.get(equipped) as WeaponBase

func equip(id: StringName) -> bool:
	if not _weapons.has(id):
		return false
	var drawn := get_current_weapon()
	if drawn != null:
		drawn.visible = false
	equipped = id
	var weapon := get_current_weapon()
	weapon.weapon_name = StringName(_display_name(id))
	weapon.visible = true
	weapon_switched.emit(weapon)
	_emit_ammo()
	EventBus.inventory_notice.emit(LocalizationManager.tf("WEAPON_READY", [_display_name(id)]))
	return true

func holster() -> void:
	var drawn := get_current_weapon()
	if drawn != null:
		drawn.visible = false
	equipped = &""
	weapon_switched.emit(null)
	EventBus.inventory_notice.emit(LocalizationManager.t("WEAPON_HOLSTERED"))

## A weapon quick slot: draws the first of `ids` the player owns; pressed again, the next one,
## then the weapon is lowered and the hands are free for melee.
func cycle(ids: Array) -> void:
	var owned: Array = ids.filter(func(id: StringName) -> bool: return _weapons.has(id))
	if owned.is_empty():
		EventBus.inventory_notice.emit(LocalizationManager.t("WEAPON_NONE"))
		return
	var at: int = owned.find(equipped)
	if at < 0:
		equip(owned[0])
	elif at + 1 < owned.size():
		equip(owned[at + 1])
	else:
		holster()

## One trigger pull from the camera; an empty magazine reloads from the reserve, or says there is none.
func fire() -> bool:
	var weapon := get_current_weapon()
	var cam := get_viewport().get_camera_3d()
	if weapon == null or cam == null:
		return false
	if weapon.current_ammo <= 0 and not weapon.is_reloading() and not reload():
		EventBus.inventory_notice.emit(LocalizationManager.t("WEAPON_NO_AMMO"))
		return false
	return weapon.fire(cam.global_position, -cam.global_transform.basis.z)

func reload() -> bool:
	var weapon := get_current_weapon()
	return weapon != null and weapon.try_reload()

func reserve() -> int:
	return ProgressTracker.ammo

## Hands over up to `count` rounds from the reserve (a reload).
func take_ammo(count: int) -> int:
	var got := mini(count, ProgressTracker.ammo)
	ProgressTracker.add_ammo(-got)
	return got

func add_ammo(count: int) -> void:
	ProgressTracker.add_ammo(count)
	_emit_ammo()

func _emit_ammo() -> void:
	var weapon := get_current_weapon()
	var current: int = weapon.current_ammo if weapon != null else 0
	ammo_changed.emit(current, reserve())
	EventBus.ammo_changed.emit(current, reserve())

func _display_name(id: StringName) -> String:
	return LocalizationManager.name_for("ITEM_", id, String(id).capitalize())
