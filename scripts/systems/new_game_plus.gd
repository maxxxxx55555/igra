extends Node

signal ng_plus_activated(new_level: int)
signal difficulty_scaled(multiplier: float)
## Выбран модификатор NG+ (content/ngp_modifiers.json).
signal modifier_selected(modifier_id: String)

## Модификаторы NG+: чистые данные, код читает только effects.
## Один выбор на каждый уровень NG+, поэтому активных может быть до
## MAX_NG_PLUS штук — из-за этого stacking.same_knob = "multiply" в контракте
## вообще имеет смысл, и из-за этого же exclusive_with надо проверять против
## уже выбранных, а не против пустоты.
const MODIFIERS_PATH: String = "res://content/ngp_modifiers.json"

const MAX_NG_PLUS = 3
const XP_MULTIPLIER_PER_NG = 0.25
const ENEMY_DAMAGE_MULTIPLIER_PER_NG = 0.15
const ENEMY_HP_MULTIPLIER_PER_NG = 0.2
const PLAYER_DAMAGE_MULTIPLIER_PER_NG = 0.1
const LOOT_CHANCE_MULTIPLIER_PER_NG = 0.1

var _current_ng_plus: int = 0
var _is_ng_plus_active: bool = false
var _modifiers: Array = []
var _active_modifiers: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_modifiers()
	_load_save()

func _load_modifiers() -> void:
	if not ResourceLoader.exists(MODIFIERS_PATH):
		return
	var f := FileAccess.open(MODIFIERS_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		_modifiers = parsed.get("modifiers", [])

func get_modifiers() -> Array:
	return _modifiers

func get_active_modifiers() -> Array:
	return _active_modifiers.duplicate()

func get_modifier(id: String) -> Dictionary:
	for m in _modifiers:
		if String(m.get("id", "")) == id:
			return m
	return {}

## Взять можно, пока выборов меньше, чем уровней NG+, и пока модификатор не
## конфликтует с уже взятым. Списки exclusive_with симметричны, но проверяем
## обе стороны — данные правит контент, симметрию лучше не считать данностью.
func can_select(id: String) -> bool:
	if _current_ng_plus < 1:
		return false
	if id in _active_modifiers:
		return false
	if _active_modifiers.size() >= _current_ng_plus:
		return false
	var m := get_modifier(id)
	if m.is_empty():
		return false
	for other in _active_modifiers:
		if other in m.get("exclusive_with", []):
			return false
		if id in get_modifier(other).get("exclusive_with", []):
			return false
	return true

func select_modifier(id: String) -> bool:
	if not can_select(id):
		return false
	_active_modifiers.append(id)
	modifier_selected.emit(id)
	_save_save()
	return true

## Числовые ручки перемножаются между активными модификаторами (контракт
## stacking.same_knob = "multiply"); отсутствующая ручка не трогает значение.
func get_modifier_multiplier(knob: String) -> float:
	var v := 1.0
	for id in _active_modifiers:
		var mult: Dictionary = get_modifier(id).get("effects", {}).get("multipliers", {})
		if mult.has(knob):
			v *= float(mult[knob])
	return v

## Переключатели: любой активный модификатор, задающий ручку, выигрывает.
func get_modifier_toggle(knob: String, default_value: bool = false) -> bool:
	for id in _active_modifiers:
		var tog: Dictionary = get_modifier(id).get("effects", {}).get("toggles", {})
		if tog.has(knob):
			return bool(tog[knob])
	return default_value

func get_current_ng_plus() -> int:
	return _current_ng_plus

func get_max_ng_plus() -> int:
	return MAX_NG_PLUS

func is_ng_plus_active() -> bool:
	return _is_ng_plus_active

func activate_ng_plus() -> bool:
	if _current_ng_plus >= MAX_NG_PLUS:
		return false
	_current_ng_plus += 1
	_is_ng_plus_active = true
	ng_plus_activated.emit(_current_ng_plus)
	difficulty_scaled.emit(get_difficulty_multiplier())
	_save_save()
	return true

func get_difficulty_multiplier() -> Dictionary:
	var ng = _current_ng_plus
	return {
		"xp_multiplier": 1.0 + ng * XP_MULTIPLIER_PER_NG,
		"enemy_damage_multiplier": 1.0 + ng * ENEMY_DAMAGE_MULTIPLIER_PER_NG,
		"enemy_hp_multiplier": 1.0 + ng * ENEMY_HP_MULTIPLIER_PER_NG,
		"player_damage_multiplier": 1.0 + ng * PLAYER_DAMAGE_MULTIPLIER_PER_NG,
		"loot_chance_multiplier": 1.0 + ng * LOOT_CHANCE_MULTIPLIER_PER_NG,
	}

## Ручка "lore" (Keeper's Pact) складывается прямо сюда: инсайт/XP с
## документов идёт через XpManager, поэтому все существующие вызовы
## получают эффект без правок на местах (тот же приём, что для "loot").
func get_xp_multiplier() -> float:
	return (1.0 + _current_ng_plus * XP_MULTIPLIER_PER_NG) * get_modifier_multiplier("lore")

func get_enemy_damage_multiplier() -> float:
	return 1.0 + _current_ng_plus * ENEMY_DAMAGE_MULTIPLIER_PER_NG

func get_enemy_hp_multiplier() -> float:
	return 1.0 + _current_ng_plus * ENEMY_HP_MULTIPLIER_PER_NG

func get_player_damage_multiplier() -> float:
	return 1.0 + _current_ng_plus * PLAYER_DAMAGE_MULTIPLIER_PER_NG

## Ручка "loot" из модификаторов складывается прямо сюда, чтобы все уже
## существующие вызовы получили эффект без правок на местах.
func get_loot_chance_multiplier() -> float:
	return (1.0 + _current_ng_plus * LOOT_CHANCE_MULTIPLIER_PER_NG) * get_modifier_multiplier("loot")

## Ручка "hints" (Keeper's Pact): false гасит подсказки. Читающие системы
## берут значение отсюда, а не из эффектов модификатора напрямую.
func are_hints_enabled() -> bool:
	return get_modifier_toggle("hints", true)

## Ручка "cycle" (Sprint): множитель длины ночного цикла (0.85 = короче).
func get_night_cycle_multiplier() -> float:
	return get_modifier_multiplier("cycle")

## Ручка "time_pressure" (Sprint): включает обратный отсчёт для временных
## событий.
func is_time_pressure_enabled() -> bool:
	return get_modifier_toggle("time_pressure", false)

## Третий режим чтения эффектов рядом с множителями и переключателями:
## по контракту контента некоторые ручки — additive-счётчики в форме числа
## (например, "extra_dark_districts"), их значения суммируются, а не
## перемножаются.
func get_modifier_additive(knob: String) -> int:
	var n := 0
	for id in _active_modifiers:
		var mult: Dictionary = get_modifier(id).get("effects", {}).get("multipliers", {})
		if mult.has(knob):
			n += int(float(mult[knob]))
	return n

## Ручка "extra_dark_districts" (Blackout+): сколько дополнительных районов
## стартуют в DARK.
func get_extra_dark_districts() -> int:
	return get_modifier_additive("extra_dark_districts")

func reset_for_new_game() -> void:
	_current_ng_plus = 0
	_is_ng_plus_active = false
	_active_modifiers.clear()
	_save_save()

func _load_save() -> void:
	var path = "user://ng_plus_data.json"
	if not FileAccess.file_exists(path):
		return
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	var txt = file.get_as_text()
	file.close()
	var outer := JSON.new()
	if outer.parse(txt) != OK or not (outer.data is Dictionary):
		return
	var envelope: Dictionary = outer.data
	# SECURITY_PATCH_SPEC P-03: this file was entirely unsigned plain JSON -
	# ng_plus/active/modifiers control real difficulty, rewards, battery and
	# time-pressure scaling (get_*_multiplier() below), so a hand edit could
	# set ng_plus=3 and active=true with zero real playthroughs. Same clean
	# policy as daily_challenge_manager.gd's own B6 fix: reject outright, no
	# legacy-plain-JSON trust-once compat (no real installed base to
	# protect). Doesn't prove the level was legitimately earned - only that
	# the file wasn't hand-edited after this game itself last wrote it.
	if not envelope.has("hmac") or not envelope.has("data_json"):
		return
	if String(envelope["hmac"]) != String(SaveSystem.call("_sign", String(envelope["data_json"]))):
		return
	var inner := JSON.new()
	if inner.parse(String(envelope["data_json"])) != OK or not (inner.data is Dictionary):
		return
	var data: Dictionary = inner.data
	# QA_SWARM_FINDINGS.md P2 (cheater): a hand-edited/forged ng_plus_data.json
	# with an absurd level had nothing clamping it back down - every
	# get_*_multiplier() below scales off this value, so an unclamped level
	# well past MAX_NG_PLUS turns into runaway enemy HP/damage scaling.
	_current_ng_plus = clampi(int(data.get("ng_plus", 0)), 0, MAX_NG_PLUS)
	_is_ng_plus_active = data.get("active", false)
	# BREAK_REPORT B5: a hand-edited modifiers array bypassed can_select()
	# entirely - a forged file could list more modifiers than levels
	# unlocked, or two mutually-exclusive ones together. Re-validate through
	# the same gate a real pick uses, one at a time so each check sees only
	# the ids already accepted (matches how select_modifier() builds the
	# list normally - exclusivity/count checks are meaningless against an
	# empty-then-growing list if seeded with the whole forged array at once).
	var loaded: Array = data.get("modifiers", [])
	_active_modifiers.clear()
	for id in loaded:
		var sid := String(id)
		if can_select(sid):
			_active_modifiers.append(sid)

func _save_save() -> void:
	var path = "user://ng_plus_data.json"
	var data = {
		"ng_plus": _current_ng_plus,
		"active": _is_ng_plus_active,
		"modifiers": _active_modifiers,
	}
	var body := JSON.stringify(data)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"hmac": SaveSystem.call("_sign", body), "data_json": body}))
		file.close()