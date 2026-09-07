extends Node3D
class_name WeaponBase

signal fired
signal reloaded
signal ammo_changed(current: int, max: int)

@export var weapon_name: StringName = &""
@export var damage: float = 25.0
@export var fire_rate: float = 0.15
@export var range: float = 50.0
@export var max_ammo: int = 30
@export var reload_time: float = 2.0
@export var spread: float = 0.02
@export var recoil: float = 0.5
@export var bullet_scene: PackedScene
@export var muzzle_flash_scene: PackedScene
@export var fire_sound: AudioStream
@export var reload_sound: AudioStream

var current_ammo: int = 30
var _fire_timer: float = 0.0
var _reloading: bool = false
var _reload_timer: float = 0.0
var _owner: Node3D = null
var _owner_excluded: bool = false
## Сколько патронов в резерве на момент начала перезарядки. -1 = «резерв
## бесконечный» (старое поведение для вызовов без аргумента).
var _reload_reserve: int = -1

## Монстры во всех сценах врагов сидят на 2-м слое (collision_layer = 2),
## а маска у RayCast3D по умолчанию = 1 — без этой правки лучи проходили бы
## сквозь них насквозь. 1-й слой оставляет попадание по миру и пропсам.
const HITSCAN_MASK: int = 3

func _ready() -> void:
	current_ammo = max_ammo
	_apply_ray_masks(self)
	ammo_changed.emit(current_ammo, max_ammo)

func _apply_ray_masks(n: Node) -> void:
	for c in n.get_children():
		if c is RayCast3D:
			(c as RayCast3D).collision_mask = HITSCAN_MASK
		_apply_ray_masks(c)

func set_shooter(owner: Node3D) -> void:
	_owner = owner

func can_fire() -> bool:
	return not _reloading and current_ammo > 0 and _fire_timer <= 0.0

func fire(from_pos: Vector3, direction: Vector3) -> bool:
	if not can_fire():
		return false
	
	_fire_timer = fire_rate
	current_ammo -= 1
	ammo_changed.emit(current_ammo, max_ammo)
	
	# Spawn bullet
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = from_pos
		bullet.look_at(from_pos + direction)
		if bullet.has_method("initialize"):
			bullet.initialize(damage, range, _owner)
		get_tree().root.add_child(bullet)
	else:
		# IDEA.md: «hitscan shooting via RayCast3D», физических пуль нет.
		# Без bullet_scene оружие обязано наносить урон лучом — раньше базовый
		# fire() в этом случае просто тратил патрон в пустоту.
		hitscan_ray(_main_ray(), spread, damage)

	_spawn_muzzle(from_pos)

	# Sound
	if fire_sound:
		AudioManager.play_sound_3d(fire_sound, from_pos)
	
	# Visual recoil
	if _owner and _owner.has_method("apply_recoil"):
		_owner.apply_recoil(recoil)
	
	fired.emit()
	# WAVE 6 P4 вешал сюда emit(&"default"), потому что crosshair_state_changed
	# не слал никто и прицел был статичным. Теперь постоянное состояние
	# («default»/«enemy») считает игрок по лучу из камеры — см.
	# player_3d.gd::_update_crosshair_state(). Эмит отсюда перебивал бы его
	# каждый выстрел: прицел гас бы на враге до следующего изменения состояния.
	# «hit» (вспышка хитмаркера) по-прежнему шлёт base_monster при попадании.
	# «aim» (ADS) не используется: механики прицеливания в проекте нет.
	return true

func _muzzle_flash(pos: Vector3) -> void:
	var flash := OmniLight3D.new()
	flash.light_color = Color(1.0, 0.8, 0.4)
	flash.light_energy = 8.0
	flash.omni_range = 3.0
	flash.shadow_enabled = false
	flash.position = Vector3.ZERO
	flash.global_position = pos
	get_tree().root.add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "light_energy", 0.0, 0.05)
	tw.tween_callback(flash.queue_free.bind())

func _spawn_muzzle(from_pos: Vector3) -> void:
	if muzzle_flash_scene:
		var flash = muzzle_flash_scene.instantiate()
		get_tree().root.add_child(flash)
		flash.global_position = from_pos
	else:
		_muzzle_flash(from_pos)

## Луч оружия из сцены. У пистолета/автомата это `RayCast3D`, у дробовика —
## пучок в `Rays/`; подклассы берут свой узел сами и передают его в hitscan_ray().
func _main_ray() -> RayCast3D:
	return get_node_or_null("RayCast3D") as RayCast3D

## Хитскан одним лучом. WeaponManager перед выстрелом разворачивает узел оружия
## вдоль взгляда камеры, поэтому локальный -Z луча и есть направление выстрела.
## Возвращает true, если луч во что-то попал.
func hitscan_ray(ray: RayCast3D, spread: float, dmg: float) -> bool:
	if ray == null:
		return false
	_exclude_owner(ray)
	var jitter := Vector3(randf() - 0.5, randf() - 0.5, 0.0) * spread
	ray.target_position = (jitter + Vector3(0.0, 0.0, -1.0)).normalized() * range
	ray.force_raycast_update()
	if not ray.is_colliding():
		return false
	apply_hit(ray.get_collider(), dmg)
	return true

## Урон по цели: сначала «родной» take_damage(amount, src_pos, type) врагов,
## затем компонент здоровья у пропсов (бочки, турели).
func apply_hit(target: Node, dmg: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	var src: Vector3 = global_position
	if target.has_method("take_damage"):
		target.take_damage(dmg, src, EnemyRosterData.DamageType.BULLET)
	elif target.has_node("HealthComponent"):
		target.get_node("HealthComponent").take_damage(int(round(dmg)))

## Игрок стоит на пути собственного луча (камера на высоте глаз внутри
## капсулы) — без исключения каждый выстрел попадал бы в себя.
func _exclude_owner(ray: RayCast3D) -> void:
	if _owner_excluded:
		return
	if _owner is CollisionObject3D:
		ray.add_exception(_owner as CollisionObject3D)
		_owner_excluded = true

## Перезарядка по таймеру (GDD §18). `reserve` — сколько патронов реально
## лежит в рюкзаке: WeaponManager передаёт счётчик универсального предмета
## `ammo`, и магазин добирается только из него. Без аргумента поведение
## прежнее (резерв не ограничен) — для вызовов вне WeaponManager.
func try_reload(reserve: int = -1) -> bool:
	if _reloading or current_ammo >= max_ammo:
		return false
	if reserve == 0:
		return false
	_reload_reserve = reserve
	_reloading = true
	_reload_timer = reload_time
	
	if reload_sound:
		AudioManager.play_sound_3d(reload_sound, global_position)
	
	reloaded.emit()
	return true

func _process(delta: float) -> void:
	if _fire_timer > 0.0:
		_fire_timer -= delta
	
	if _reloading:
		_reload_timer -= delta
		if _reload_timer <= 0.0:
			_reloading = false
			_finish_reload()

## Добирает магазин из резерва; если патронов не хватило — заряжает сколько есть.
func _finish_reload() -> void:
	var take: int = max_ammo - current_ammo
	if _reload_reserve >= 0:
		take = mini(take, _reload_reserve)
	_reload_reserve = -1
	current_ammo += take
	ammo_changed.emit(current_ammo, max_ammo)

func get_ammo_ratio() -> float:
	return float(current_ammo) / max_ammo

func is_reloading() -> bool:
	return _reloading

func get_reload_progress() -> float:
	if not _reloading:
		return 1.0
	return 1.0 - (_reload_timer / reload_time)
