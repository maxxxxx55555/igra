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
## Shots that leave the barrel per trigger pull (the shotgun's pellets), each doing `damage`.
@export var pellets: int = 1
## Holding the trigger keeps firing (the rifle).
@export var automatic: bool = false
@export var muzzle_flash_scene: PackedScene
@export var fire_sound: AudioStream
@export var reload_sound: AudioStream

## How far a shot is heard (EventBus.noise_emitted): monsters inside it come to investigate.
const NOISE_RADIUS: float = 22.0

var current_ammo: int = 30
## WeaponManager: keeps the reserve every weapon draws from (GDD §18: universal ammo).
var manager: Node = null
var _fire_timer: float = 0.0
var _reloading: bool = false
var _reload_timer: float = 0.0
var _reload_duration: float = 0.0
var _owner: Node3D = null

func _ready() -> void:
	current_ammo = max_ammo
	ammo_changed.emit(current_ammo, max_ammo)

func set_shooter(owner: Node3D) -> void:
	_owner = owner

func can_fire() -> bool:
	return not _reloading and current_ammo > 0 and _fire_timer <= 0.0

func fire(from_pos: Vector3, direction: Vector3) -> bool:
	if not can_fire():
		return false

	_fire_timer = fire_rate * _fire_rate_multiplier()
	current_ammo -= 1
	ammo_changed.emit(current_ammo, max_ammo)
	direction = _apply_auto_aim(from_pos, direction)
	for i in pellets:
		_hitscan(from_pos, _spread_direction(direction), _effective_damage())

	# Muzzle flash
	if muzzle_flash_scene:
		var flash = muzzle_flash_scene.instantiate()
		get_tree().root.add_child(flash)
		flash.global_position = from_pos
	else:
		_muzzle_flash(from_pos)

	# Sound
	if fire_sound:
		AudioManager.play_sound_3d(fire_sound, from_pos)
	if _owner != null and _owner.is_in_group("player"):
		EventBus.noise_emitted.emit(Vector2(_owner.global_position.x, _owner.global_position.z), NOISE_RADIUS)

	# Visual recoil
	if _owner and _owner.has_method("apply_recoil"):
		_owner.apply_recoil(recoil)

	fired.emit()
	# WAVE 6 P4: crosshair_state_changed was never emitted anywhere - the
	# HUD crosshair was a static, always-the-same-color ColorRect for the
	# entire game. "aim" (ADS) has no real trigger site: no aim-down-
	# sights mechanic exists anywhere in the weapon system to hook into,
	# so it's left wired in the HUD but genuinely unused rather than
	# faking a state change nothing in the game actually does.
	if EventBus.has_signal(&"crosshair_state_changed"):
		EventBus.crosshair_state_changed.emit(&"default")
	return true

## One ray from the camera: the first body it meets that can take damage is hurt (GDD §18 range 50 m).
func _hitscan(from_pos: Vector3, dir: Vector3, dmg: float) -> void:
	var query := PhysicsRayQueryParameters3D.create(from_pos, from_pos + dir * range)
	if _owner is CollisionObject3D:
		query.exclude = [(_owner as CollisionObject3D).get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var target := hit["collider"] as Object
	if target != null and target.has_method("take_damage"):
		target.take_damage(dmg, from_pos, EnemyRosterData.DamageType.BULLET)

## A random direction inside a cone of half-angle `spread` (radians) around `dir`.
func _spread_direction(dir: Vector3) -> Vector3:
	if spread <= 0.0:
		return dir
	var up := Vector3.UP if absf(dir.normalized().y) < 0.99 else Vector3.FORWARD
	var aim := Basis.looking_at(dir, up)
	return (aim * Vector3(tan(randf_range(-spread, spread)), tan(randf_range(-spread, spread)), -1.0)).normalized()

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

func try_reload() -> bool:
	if _reloading or current_ammo >= max_ammo:
		return false
	if manager != null and int(manager.call("reserve")) <= 0:
		return false

	_reloading = true
	_reload_duration = reload_time * _reload_time_multiplier()
	_reload_timer = _reload_duration

	if reload_sound:
		AudioManager.play_sound_3d(reload_sound, global_position)

	reloaded.emit()
	return true

## The cooldown and the reload tick with the physics step that polls the trigger, so the rate of fire no longer
## follows the frame rate (the pistol shot 3.00 / 3.16 / 3.50 times a second at 30 / 60 / 120 FPS).
func _physics_process(delta: float) -> void:
	if _fire_timer > 0.0:
		_fire_timer -= delta

	if _reloading:
		_reload_timer -= delta
		if _reload_timer <= 0.0:
			_reloading = false
			var need := max_ammo - current_ammo
			current_ammo += need if manager == null else int(manager.call("take_ammo", need))
			ammo_changed.emit(current_ammo, max_ammo)

func get_ammo_ratio() -> float:
	return float(current_ammo) / max_ammo

func is_reloading() -> bool:
	return _reloading

func get_reload_progress() -> float:
	if not _reloading:
		return 1.0
	return 1.0 - (_reload_timer / _reload_duration)

## Static audit 2026-09-08: damage_boost_1/2, crit_chance, fire_rate and
## reload_speed were purchasable (real skill-point cost, shown as unlocked
## in the UI) but nothing in the game ever read them - buying them did
## nothing. Wired at the point each stat is actually used; only applies to
## the player's own weapon (an enemy could theoretically hold a WeaponBase
## too, and skills are player-only).
## GDD.md:378 (C03): auto-aim accessibility toggle. Off by default (only
## the player fires through this shared path - enemies don't use
## WeaponBase). Biases toward the nearest living enemy within a narrow
## cone rather than a hard snap, so it reads as assistance, not an aimbot.
const _AUTO_AIM_CONE_DEG: float = 12.0
## Aim at the middle of the monster's collider, not at the feet its origin stands on.
const _AIM_FALLBACK_HEIGHT: float = 1.0
func _apply_auto_aim(from_pos: Vector3, direction: Vector3) -> Vector3:
	if _owner == null or not _owner.is_in_group("player"):
		return direction
	if not bool(SettingsManager.get_setting("auto_aim", false)):
		return direction
	var best: Node3D = null
	var best_dot: float = cos(deg_to_rad(_AUTO_AIM_CONE_DEG))
	for e in _owner.get_tree().get_nodes_in_group("enemies"):
		if not (e is Node3D) or not is_instance_valid(e):
			continue
		if "ai_state" in e and int(e.ai_state) == BaseMonster.State.DEAD:
			continue
		var to_e: Vector3 = _aim_point(e as Node3D) - from_pos
		if to_e.length() > range or to_e.length() < 0.01:
			continue
		var dot := direction.normalized().dot(to_e.normalized())
		if dot > best_dot:
			best_dot = dot
			best = e
	if best == null:
		return direction
	return (_aim_point(best) - from_pos).normalized()

func _aim_point(monster: Node3D) -> Vector3:
	var body := monster.get_node_or_null("CollisionShape3D") as Node3D
	return body.global_position if body != null else monster.global_position + Vector3.UP * _AIM_FALLBACK_HEIGHT

func _effective_damage() -> float:
	if _owner == null or not _owner.is_in_group("player"):
		return damage
	var mult := 1.0
	mult += 0.1 * SkillTreeManager.get_skill_level(&"damage_boost_1")
	mult += 0.1 * SkillTreeManager.get_skill_level(&"damage_boost_2")
	var dmg := damage * mult
	# Design decision (not in GDD): crit multiplier x2, since SKILL_TREES
	# only defines the per-level chance (5%/level, up to 15% at max).
	if randf() < 0.05 * SkillTreeManager.get_skill_level(&"crit_chance"):
		dmg *= 2.0
	return dmg

func _fire_rate_multiplier() -> float:
	if _owner == null or not _owner.is_in_group("player"):
		return 1.0
	return 1.0 - 0.15 * SkillTreeManager.get_skill_level(&"fire_rate")

func _reload_time_multiplier() -> float:
	if _owner == null or not _owner.is_in_group("player"):
		return 1.0
	return 1.0 - 0.25 * SkillTreeManager.get_skill_level(&"reload_speed")
