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
			current_ammo = max_ammo
			ammo_changed.emit(current_ammo, max_ammo)

func get_ammo_ratio() -> float:
	return float(current_ammo) / max_ammo

func is_reloading() -> bool:
	return _reloading

func get_reload_progress() -> float:
	if not _reloading:
		return 1.0
	return 1.0 - (_reload_timer / reload_time)
