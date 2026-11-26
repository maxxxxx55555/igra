class_name HorrorTensionDirector
extends Node

## Playtest-Driven High-Tension Horror Mechanics Director for Last Streetlight.
## Zero new media assets, zero extra HUD buttons (preserves 7/7 phone layouts & <= 45 MiB budget).
## Implements 3 risk-reward mechanics locked to canon palette (#0f1314, #060f13, #c9a24a, #d4a94e):
##   1. Flashlight Overdrive Pulse (double-tap existing Flashlight button -> staggers nearby stalkers,
##      burns 18% battery + 4.0s thermal dim cooldown).
##   2. Grid Surge Climax (repairing district fusebox triggers streetlamp flicker + frantic escape dash
##      toward the lit exit gate while keeping safe-zone sanctuary inviolable).
##   3. 11-District Escalating Tactical Mutators (distinct fog, cold, lamp flicker & stalker hearing).

signal overdrive_triggered(origin: Vector3, radius: float, duration_sec: float)
signal grid_surge_started(district_index: int, intensity: float)
signal district_mutator_applied(district_index: int, mutator: Dictionary)

const OVERDRIVE_BATTERY_COST: float = 18.0
const OVERDRIVE_COOLDOWN_SEC: float = 12.0
const OVERDRIVE_PULSE_SEC: float = 1.6
const OVERDRIVE_DIM_RECOVERY_SEC: float = 4.0
const OVERDRIVE_STUN_RADIUS_M: float = 9.5
const OVERDRIVE_STUN_SEC: float = 2.6
const DOUBLE_TAP_WINDOW_MSEC: int = 340
const MAX_SAFE_DT: float = 0.05

const DISTRICT_MUTATORS: Array[Dictionary] = [
    {"id": "d01_dusk", "key": "MUT_D01", "fog_mult": 0.90, "cold_mult": 0.85, "lamp_flicker": 0.08, "hearing_mult": 0.90, "speed_mult": 0.95},
    {"id": "d02_echo", "key": "MUT_D02", "fog_mult": 0.96, "cold_mult": 0.92, "lamp_flicker": 0.14, "hearing_mult": 1.08, "speed_mult": 0.98},
    {"id": "d03_flicker", "key": "MUT_D03", "fog_mult": 1.02, "cold_mult": 0.96, "lamp_flicker": 0.28, "hearing_mult": 1.05, "speed_mult": 1.00},
    {"id": "d04_coldsnap", "key": "MUT_D04", "fog_mult": 1.05, "cold_mult": 1.22, "lamp_flicker": 0.18, "hearing_mult": 1.06, "speed_mult": 1.02},
    {"id": "d05_blindfog", "key": "MUT_D05", "fog_mult": 1.26, "cold_mult": 1.05, "lamp_flicker": 0.22, "hearing_mult": 1.12, "speed_mult": 1.04},
    {"id": "d06_pack", "key": "MUT_D06", "fog_mult": 1.10, "cold_mult": 1.10, "lamp_flicker": 0.25, "hearing_mult": 1.20, "speed_mult": 1.08},
    {"id": "d07_brownout", "key": "MUT_D07", "fog_mult": 1.16, "cold_mult": 1.15, "lamp_flicker": 0.42, "hearing_mult": 1.16, "speed_mult": 1.09},
    {"id": "d08_freeze", "key": "MUT_D08", "fog_mult": 1.20, "cold_mult": 1.34, "lamp_flicker": 0.30, "hearing_mult": 1.18, "speed_mult": 1.11},
    {"id": "d09_cascade", "key": "MUT_D09", "fog_mult": 1.24, "cold_mult": 1.25, "lamp_flicker": 0.48, "hearing_mult": 1.24, "speed_mult": 1.14},
    {"id": "d10_blackout", "key": "MUT_D10", "fog_mult": 1.32, "cold_mult": 1.32, "lamp_flicker": 0.56, "hearing_mult": 1.28, "speed_mult": 1.16},
    {"id": "d11_finale", "key": "MUT_D11", "fog_mult": 1.35, "cold_mult": 1.38, "lamp_flicker": 0.62, "hearing_mult": 1.32, "speed_mult": 1.18},
]

const MUTATOR_FALLBACK_RU: Dictionary = {
    "MUT_D01": "СУМЕРКИ ОКРАИНЫ",
    "MUT_D02": "СЫРОЕ ЭХО",
    "MUT_D03": "МЕРЦАЮЩАЯ СЕТЬ",
    "MUT_D04": "РЕЗКИЙ МОРОЗ",
    "MUT_D05": "СЛЕПОЙ ТУМАН",
    "MUT_D06": "ОХОТНИЧЬЯ СТАЯ",
    "MUT_D07": "ВОЛНЫ ОТКЛЮЧЕНИЙ",
    "MUT_D08": "ЛЕДЯНОЙ ДОЖДЬ",
    "MUT_D09": "КАСКАДНЫЙ СБОЙ",
    "MUT_D10": "ПОЛНЫЙ БЛЭКАУТ",
    "MUT_D11": "ПОСЛЕДНИЙ ФОНАРЬ",
}

const MUTATOR_FALLBACK_EN: Dictionary = {
    "MUT_D01": "OUTSKIRTS DUSK",
    "MUT_D02": "WET ECHOES",
    "MUT_D03": "FLICKER GRID",
    "MUT_D04": "COLD SNAP",
    "MUT_D05": "BLIND FOG",
    "MUT_D06": "STALKER PACK",
    "MUT_D07": "BROWNOUT WAVES",
    "MUT_D08": "FREEZING RAIN",
    "MUT_D09": "SURGE CASCADE",
    "MUT_D10": "BLACKOUT GAUNTLET",
    "MUT_D11": "LAST STREETLIGHT",
}

var _district_index: int = 0
var _active_mutator: Dictionary = {}
var _overdrive_active_sec: float = 0.0
var _overdrive_dim_sec: float = 0.0
var _overdrive_cooldown_sec: float = 0.0
var _last_flashlight_tap_msec: int = -10000
var _grid_surge_active: bool = false
var _grid_surge_time: float = 0.0
var _flicker_phase: float = 0.0

var _cd_salt: int = 0x5A3C
var _cd_shadow_ms: int = 0


func _ready() -> void:
	apply_district_mutator(0)


func _exit_tree() -> void:
	reset_district_state()


func _process(delta: float) -> void:
	var dt: float = 0.0 if (is_nan(delta) or is_inf(delta)) else clampf(delta, 0.0, MAX_SAFE_DT)
	_flicker_phase = fmod(_flicker_phase + dt * 6.5, TAU * 16.0)

	if _overdrive_active_sec > 0.0:
		_overdrive_active_sec = maxf(0.0, _overdrive_active_sec - dt)
		if _overdrive_active_sec <= 0.0:
			_overdrive_dim_sec = OVERDRIVE_DIM_RECOVERY_SEC
	elif _overdrive_dim_sec > 0.0:
		_overdrive_dim_sec = maxf(0.0, _overdrive_dim_sec - dt)

	if _overdrive_cooldown_sec > 0.0:
		_verify_cooldown_integrity()
		_overdrive_cooldown_sec = maxf(0.0, _overdrive_cooldown_sec - dt)
		_store_cooldown_shadow(_overdrive_cooldown_sec)

	if _grid_surge_active:
		_grid_surge_time += dt


func reset_district_state() -> void:
	_overdrive_active_sec = 0.0
	_overdrive_dim_sec = 0.0
	_overdrive_cooldown_sec = 0.0
	_store_cooldown_shadow(0.0)
	_grid_surge_active = false
	_grid_surge_time = 0.0


func apply_district_mutator(district_index: int) -> Dictionary:
	reset_district_state()
	_district_index = clampi(district_index, 0, DISTRICT_MUTATORS.size() - 1)
	_active_mutator = DISTRICT_MUTATORS[_district_index].duplicate()
	district_mutator_applied.emit(_district_index, _active_mutator.duplicate())
	return _active_mutator.duplicate()


func get_active_mutator() -> Dictionary:
	if _active_mutator.is_empty():
		return apply_district_mutator(_district_index)
	return _active_mutator.duplicate()


func get_mutator_display_name() -> String:
	return get_mutator_display_name_for(_district_index)


## Pure lookup: lets the transition card name the NEXT district's mutator
## before the live mutator itself is applied on district entry.
func get_mutator_display_name_for(district_index: int) -> String:
	var idx: int = clampi(district_index, 0, DISTRICT_MUTATORS.size() - 1)
	var key: String = str(DISTRICT_MUTATORS[idx].get("key", "MUT_D01"))
	var tr_val: String = TranslationServer.translate(key)
	if not tr_val.is_empty() and tr_val != key:
		return tr_val
	var is_ru: bool = TranslationServer.get_locale().to_lower().begins_with("ru")
	return str(MUTATOR_FALLBACK_RU.get(key, key)) if is_ru else str(MUTATOR_FALLBACK_EN.get(key, key))


func register_flashlight_tap(player_pos: Vector3, current_battery: float) -> Dictionary:
	var now: int = Time.get_ticks_msec()
	var is_double: bool = (now - _last_flashlight_tap_msec) <= DOUBLE_TAP_WINDOW_MSEC
	_last_flashlight_tap_msec = now
	if not is_double:
		return {"triggered": false, "battery_cost": 0.0}
	return trigger_flashlight_overdrive(player_pos, current_battery)


func trigger_flashlight_overdrive(player_pos: Vector3, current_battery: float) -> Dictionary:
	_verify_cooldown_integrity()
	var bat: float = 0.0 if (is_nan(current_battery) or is_inf(current_battery)) else clampf(current_battery, 0.0, 100.0)
	if _overdrive_cooldown_sec > 0.05 or bat < OVERDRIVE_BATTERY_COST + 2.0:
		return {"triggered": false, "battery_cost": 0.0, "cooldown_left": _overdrive_cooldown_sec}

	_overdrive_active_sec = OVERDRIVE_PULSE_SEC
	_overdrive_dim_sec = 0.0
	_overdrive_cooldown_sec = OVERDRIVE_COOLDOWN_SEC
	_store_cooldown_shadow(_overdrive_cooldown_sec)

	overdrive_triggered.emit(player_pos, OVERDRIVE_STUN_RADIUS_M, OVERDRIVE_STUN_SEC)
	_stagger_nearby_enemies(player_pos)
	return {
		"triggered": true,
		"battery_cost": OVERDRIVE_BATTERY_COST,
		"stun_radius": OVERDRIVE_STUN_RADIUS_M,
		"stun_sec": OVERDRIVE_STUN_SEC,
	}


func trigger_grid_surge_climax(district_index: int) -> void:
	if _grid_surge_active:
		return
	_grid_surge_active = true
	_grid_surge_time = 0.0
	var intensity: float = clampf(0.55 + float(clampi(district_index, 0, 10)) * 0.045, 0.55, 1.0)
	grid_surge_started.emit(clampi(district_index, 0, 10), intensity)


func is_grid_surge_active() -> bool:
	return _grid_surge_active


func get_flashlight_beam_multiplier() -> float:
	if _overdrive_active_sec > 0.0:
		return 2.15
	if _overdrive_dim_sec > 0.0:
		var t: float = 1.0 - (_overdrive_dim_sec / OVERDRIVE_DIM_RECOVERY_SEC)
		return clampf(lerpf(0.45, 1.0, t), 0.45, 1.0)
	return 1.0


func get_streetlamp_flicker_multiplier() -> float:
	var base_flicker: float = float(get_active_mutator().get("lamp_flicker", 0.1))
	var surge_boost: float = 0.35 if _grid_surge_active else 0.0
	var amp: float = clampf(base_flicker + surge_boost, 0.05, 0.72)
	var wave: float = 0.5 + 0.5 * sin(_flicker_phase + 0.5 * sin(_flicker_phase * 2.3))
	return clampf(1.0 - amp * 0.52 * (1.0 - wave), 0.42, 1.0)


func get_enemy_speed_multiplier() -> float:
	var base_spd: float = float(get_active_mutator().get("speed_mult", 1.0))
	return base_spd * (1.14 if _grid_surge_active else 1.0)


func get_enemy_hearing_multiplier() -> float:
	var base_hear: float = float(get_active_mutator().get("hearing_mult", 1.0))
	return base_hear * (1.20 if _grid_surge_active else 1.0)


func _stagger_nearby_enemies(origin: Vector3) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	for group_name in ["enemies", "mobs", "stalkers"]:
		for node in tree.get_nodes_in_group(group_name):
			if not is_instance_valid(node) or not (node is Node3D):
				continue
			var n3: Node3D = node as Node3D
			var dist: float = n3.global_position.distance_to(origin)
			if dist <= OVERDRIVE_STUN_RADIUS_M:
				if n3.has_method("apply_light_stagger"):
					n3.call("apply_light_stagger", OVERDRIVE_STUN_SEC, origin)
				elif n3.has_method("stun"):
					n3.call("stun", OVERDRIVE_STUN_SEC)
				elif n3.has_method("retreat_from_light"):
					n3.call("retreat_from_light", origin, OVERDRIVE_STUN_SEC)


func _store_cooldown_shadow(val: float) -> void:
	var ms: int = int(roundf(clampf(val, 0.0, OVERDRIVE_COOLDOWN_SEC) * 1000.0))
	_cd_shadow_ms = ms ^ _cd_salt


func _verify_cooldown_integrity() -> void:
	var expected_ms: int = _cd_shadow_ms ^ _cd_salt
	var actual_ms: int = int(roundf(_overdrive_cooldown_sec * 1000.0))
	if abs(expected_ms - actual_ms) > 150:
		_overdrive_cooldown_sec = OVERDRIVE_COOLDOWN_SEC
		_store_cooldown_shadow(_overdrive_cooldown_sec)
