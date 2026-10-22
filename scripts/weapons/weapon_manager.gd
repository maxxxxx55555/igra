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
## C6: each gun has its own viewmodel (weapon_meshes.gd); the part that works on a shot, the slide, the bolt or the pump, goes back RACK_M and forward again in RACK_SEC.
const _Weapons := preload("res://scripts/art/weapon_meshes.gd")
const RACK_M: float = 0.035
const RACK_SEC: float = 0.12
## Where the drawn weapon sits in the camera's frame: right hand, a little below the view.
const HOLD_OFFSET := Vector3(0.22, -0.2, -0.45)
## The muzzle turns a little toward the middle of the view, which shows the side of the gun and not only its back.
const HOLD_YAW: float = 0.14
const _Motion := preload("res://scripts/weapons/viewmodel_motion.gd")

var equipped: StringName = &""
var _weapons: Dictionary = {}
var _motion := _Motion.new()

func _ready() -> void:
	for id in ProgressTracker.get_weapons():
		_spawn(StringName(id))

func _process(delta: float) -> void:
	var weapon := get_current_weapon()
	var cam := get_viewport().get_camera_3d()
	if weapon != null and cam != null:
		weapon.global_transform = cam.global_transform * Transform3D(Basis(Vector3.UP, HOLD_YAW), HOLD_OFFSET) * _motion.offset(delta, cam.global_transform.basis, weapon.is_reloading())

## The moving part of a gun (Slide, Bolt or Pump, the second child of its model) works back and forward; still with Motion Comfort and Reduce UI Motion.
func _rack(model: Node3D) -> void:
	var part := model.get_child(1) as Node3D
	if _Motion.calm() or part == null:
		return
	if part.has_meta(&"rack"):
		var old: Variant = part.get_meta(&"rack")
		if old is Tween:
			(old as Tween).kill()
	var tween := part.create_tween()
	tween.tween_property(part, "position:z", RACK_M, RACK_SEC * 0.3)
	tween.tween_property(part, "position:z", 0.0, RACK_SEC * 0.7)
	part.set_meta(&"rack", tween)

func _spawn(id: StringName) -> void:
	var weapon := (SCENES[id] as PackedScene).instantiate() as WeaponBase
	weapon.visible = false
	weapon.manager = self
	weapon.set_shooter(get_parent() as Node3D)
	var model := _Weapons.model(id)
	weapon.fired.connect(func() -> void:
		ProgressTracker.shots += 1
		_motion.kick(weapon.recoil)
		_rack(model))
	weapon.reloaded.connect(_rack.bind(model))
	weapon.ammo_changed.connect(func(_current: int, _mag: int) -> void:
		if weapon == get_current_weapon():
			_emit_ammo())
	add_child(weapon)
	weapon.add_child(model)
	_weapons[id] = weapon

## A weapon found in the world: kept for the run (and the save) and announced.
func unlock(id: StringName) -> bool:
	if not SCENES.has(id) or not ProgressTracker.unlock_weapon(String(id)):
		return false
	_spawn(id)
	EventBus.inventory_notice.emit(LocalizationManager.tf("WEAPON_FOUND", [_display_name(id)]))
	EventBus.inventory_changed.emit()  # the bar shows the slot of a gun from now on
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
