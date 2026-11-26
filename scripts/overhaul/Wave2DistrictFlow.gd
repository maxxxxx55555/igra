class_name Wave2DistrictFlow
extends Node

## Deterministic 3-Step District Loop & Safe-Zone Director across all 11 districts.
## Step 1: Collect 6 relay parts (anti-dupe tokens).
## Step 2: Repair the main district fusebox (lights warm sodium safe zone).
## Step 3: Pass through the physical illuminated exit gate to the next district (or Victory on District 11).

signal state_changed(new_state: StringName, district_index: int)
signal relay_parts_changed(collected: int, required: int)
signal fusebox_repaired(district_index: int)
signal exit_gate_unlocked(district_index: int)
signal district_transition_requested(next_district_index: int)
signal game_victory_reached
signal safe_zone_toggled(is_inside: bool)

const STATE_SCAVENGE: StringName = &"SCAVENGE_PARTS"
const STATE_FUSEBOX: StringName = &"REPAIR_FUSEBOX"
const STATE_GATE: StringName = &"REACH_EXIT_GATE"
const STATE_TRANSITION: StringName = &"TRANSITIONING"
const STATE_VICTORY: StringName = &"VICTORY"

const TOTAL_DISTRICTS: int = 11
const REQUIRED_PARTS_PER_DISTRICT: int = 6
const SAFE_ZONE_BATTERY_RATE_PER_SEC: float = 14.0
const SAFE_ZONE_WARMTH_RATE_PER_SEC: float = 18.0
const MAX_SAFE_DELTA_SEC: float = 0.05
const MIN_MOB_SPAWN_DIST_M: float = 18.0
const INTERACT_DEBOUNCE_MSEC: int = 200

var _state: StringName = STATE_SCAVENGE
var _district_index: int:
	get: return SecurityVault.get_guarded_int(StringName("runtime_flow_%d_district_index" % get_instance_id()), 0)
	set(value): SecurityVault.set_guarded_int(StringName("runtime_flow_%d_district_index" % get_instance_id()), clampi(value, 0, TOTAL_DISTRICTS - 1))
var _collected_parts: int:
	get: return SecurityVault.get_guarded_int(StringName("runtime_flow_%d_collected_parts" % get_instance_id()), 0)
	set(value): SecurityVault.set_guarded_int(StringName("runtime_flow_%d_collected_parts" % get_instance_id()), clampi(value, 0, REQUIRED_PARTS_PER_DISTRICT))
var _consumed_tokens: Dictionary = {}
var _completed_districts: Dictionary = {}
var _in_safe_zone: bool = false
var _transition_lock: bool = false
var _last_interact_msec: int = -INTERACT_DEBOUNCE_MSEC


func start_district(district_index: int, completed_list: Array = []) -> void:
	_transition_lock = false
	_district_index = clampi(district_index, 0, TOTAL_DISTRICTS - 1)
	_collected_parts = _part_count(_district_index)
	_state = STATE_FUSEBOX if _collected_parts == REQUIRED_PARTS_PER_DISTRICT else STATE_SCAVENGE
	_completed_districts.clear()
	for idx in completed_list:
		if typeof(idx) in [TYPE_INT, TYPE_FLOAT] and float(idx) == int(idx) and int(idx) >= 0 and int(idx) < TOTAL_DISTRICTS:
			_completed_districts[int(idx)] = true
	if _completed_districts.has(_district_index):
		_state = STATE_GATE
	state_changed.emit(_state, _district_index)
	relay_parts_changed.emit(_collected_parts, REQUIRED_PARTS_PER_DISTRICT)


func _exit_tree() -> void:
	for key in ["district_index", "collected_parts"]:
		SecurityVault.forget_runtime_guard(StringName("runtime_flow_%d_%s" % [get_instance_id(), key]))

func has_relay_part(part_id: String) -> bool:
	return _consumed_tokens.has("d%d_%s" % [_district_index, part_id.strip_edges()])

func _part_count(idx: int) -> int:
	var prefix := "d%d_" % idx
	var count := 0
	for token: String in _consumed_tokens:
		if token.begins_with(prefix):
			count += 1
	return count

func to_dict() -> Dictionary:
	return {"district":_district_index, "parts":_collected_parts,
		"tokens":_consumed_tokens.keys(), "completed":get_completed_districts()}

func restore(data: Dictionary) -> void:
	_consumed_tokens.clear()
	var tokens: Variant = data.get("tokens", [])
	if tokens is Array and tokens.size() <= TOTAL_DISTRICTS * REQUIRED_PARTS_PER_DISTRICT:
		for token: Variant in tokens:
			if not token is String or token.length() > 84:
				continue
			var prefix := String(token).get_slice("_", 0)
			var idx := prefix.substr(1).to_int()
			if prefix == "d%d" % idx and idx >= 0 and idx < TOTAL_DISTRICTS and _part_count(idx) < REQUIRED_PARTS_PER_DISTRICT:
				_consumed_tokens[token] = true
	var completed: Variant = data.get("completed", [])
	_last_interact_msec = -INTERACT_DEBOUNCE_MSEC
	start_district(int(data.get("district", 0)), completed if completed is Array else [])

func get_state() -> StringName:
	return _state


func get_district_index() -> int:
	return _district_index


func get_step_number() -> int:
	if _state == STATE_SCAVENGE:
		return 1
	if _state == STATE_FUSEBOX:
		return 2
	return 3


func get_completed_districts() -> Array[int]:
	var out: Array[int] = []
	for k in _completed_districts.keys():
		out.append(int(k))
	out.sort()
	return out


func is_gate_unlocked() -> bool:
	return _state == STATE_GATE or _state == STATE_TRANSITION or _state == STATE_VICTORY


func try_collect_relay_part(unique_part_id: String) -> bool:
	if _state != STATE_SCAVENGE:
		return false
	if not _allow_interact():
		return false
	var clean_id: String = unique_part_id.strip_edges()
	if clean_id.is_empty() or clean_id.length() > 80:
		return false
	var token_key: String = "d%d_%s" % [_district_index, clean_id]
	if _consumed_tokens.has(token_key):
		return false
	_consumed_tokens[token_key] = Time.get_ticks_msec()
	_collected_parts = clampi(_collected_parts + 1, 0, REQUIRED_PARTS_PER_DISTRICT)
	relay_parts_changed.emit(_collected_parts, REQUIRED_PARTS_PER_DISTRICT)
	if _collected_parts >= REQUIRED_PARTS_PER_DISTRICT:
		_state = STATE_FUSEBOX
		state_changed.emit(_state, _district_index)
	return true


func try_repair_fusebox() -> bool:
	if _state != STATE_FUSEBOX:
		return false
	if not _allow_interact():
		return false
	_state = STATE_GATE
	_completed_districts[_district_index] = true
	fusebox_repaired.emit(_district_index)
	exit_gate_unlocked.emit(_district_index)
	state_changed.emit(_state, _district_index)
	return true


func try_enter_exit_gate() -> bool:
	if _state != STATE_GATE or _transition_lock:
		return false
	if not _allow_interact():
		return false
	_transition_lock = true
	if _district_index + 1 >= TOTAL_DISTRICTS:
		_state = STATE_VICTORY
		state_changed.emit(_state, _district_index)
		game_victory_reached.emit()
		return true
	_state = STATE_TRANSITION
	state_changed.emit(_state, _district_index)
	district_transition_requested.emit(_district_index + 1)
	return true


func tick_offline_safe_zone(delta: float, is_inside_lit_lamp: bool, battery_pct: float, warmth_pct: float) -> Dictionary:
	var dt: float = 0.0 if (is_nan(delta) or is_inf(delta)) else clampf(delta, 0.0, MAX_SAFE_DELTA_SEC)
	var b: float = 0.0 if (is_nan(battery_pct) or is_inf(battery_pct)) else clampf(battery_pct, 0.0, 100.0)
	var w: float = 0.0 if (is_nan(warmth_pct) or is_inf(warmth_pct)) else clampf(warmth_pct, 0.0, 100.0)

	if is_inside_lit_lamp != _in_safe_zone:
		_in_safe_zone = is_inside_lit_lamp
		safe_zone_toggled.emit(_in_safe_zone)

	if _in_safe_zone and dt > 0.0:
		b = clampf(b + SAFE_ZONE_BATTERY_RATE_PER_SEC * dt, 0.0, 100.0)
		w = clampf(w + SAFE_ZONE_WARMTH_RATE_PER_SEC * dt, 0.0, 100.0)
	return {"battery_pct": b, "warmth_pct": w, "in_safe_zone": _in_safe_zone}


func get_objective_key_and_args() -> Dictionary:
	if _state == STATE_SCAVENGE:
		return {"key": "OBJ_STEP1_PARTS", "args": {"have": _collected_parts, "need": REQUIRED_PARTS_PER_DISTRICT}}
	if _state == STATE_FUSEBOX:
		return {"key": "OBJ_STEP2_FUSEBOX", "args": {}}
	if _state == STATE_GATE:
		return {"key": "OBJ_STEP3_GATE", "args": {"next": mini(_district_index + 2, TOTAL_DISTRICTS)}}
	return {"key": "OBJ_VICTORY", "args": {}}


static func filter_safe_mob_spawns(candidates: Array[Vector3], player_start: Vector3, desired_count: int = 3) -> Array[Vector3]:
	var valid: Array[Vector3] = []
	var min_d2: float = MIN_MOB_SPAWN_DIST_M * MIN_MOB_SPAWN_DIST_M
	for p in candidates:
		if p.distance_squared_to(player_start) >= min_d2:
			valid.append(p)
		if valid.size() >= maxi(2, desired_count):
			break
	return valid


func _allow_interact() -> bool:
	var now: int = Time.get_ticks_msec()
	if now - _last_interact_msec < INTERACT_DEBOUNCE_MSEC:
		return false
	_last_interact_msec = now
	return true
