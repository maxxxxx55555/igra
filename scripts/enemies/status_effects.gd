class_name StatusEffects
extends Node

## P7-data2 · минимальный движок статусов. Держит на мобе active-эффекты:
## dot (BLEED/BURN/POISON), SLOW (множитель скорости), STUN (стоп действий), FEAR (отступление).
## Канон: docs/GDD.md §6 (SS. inflicts). После окончания эффекта — 2 s иммунитет к тому же статусу.

const Status := EnemyRosterData.Status
const TICK: float = 1.0
const IMMUNITY: float = 2.0

## {int: {"t": float, "dps": float, "power": float}}
var active: Dictionary = {}
var _immune: Dictionary = {}
var _tick_timer: float = 0.0
var mob: CharacterBody3D = null

func apply(status: int, duration: float, dps: float = 0.0, power: float = 0.0) -> void:
	if status in [Status.STUN, Status.FEAR] and mob and mob.ai_state == BaseMonster.State.DEAD:
		return
	if _immune.get(status, 0.0) > 0.0:
		return
	if active.has(status):
		var e: Dictionary = active[status]
		e["t"] = maxf(float(e["t"]), duration)
		e["dps"] = maxf(float(e["dps"]), dps)
		e["power"] = maxf(float(e["power"]), power)
	else:
		active[status] = {"t": duration, "dps": dps, "power": power}
	_apply_now(status)

func is_active(status: int) -> bool:
	return active.has(status)

func speed_multiplier() -> float:
	if active.has(Status.SLOW):
		return maxf(0.1, 1.0 - float(active[Status.SLOW]["power"]))
	return 1.0

func _physics_process(delta: float) -> void:
	if mob == null or mob.ai_state == BaseMonster.State.DEAD:
		return
	if active.is_empty():
		return
	_tick_timer += delta
	var expired: Array = []
	for s in active.keys():
		active[s]["t"] = float(active[s]["t"]) - delta
		if float(active[s]["t"]) <= 0.0:
			expired.append(s)
	if _tick_timer >= TICK:
		_tick_timer -= TICK
		for s in [Status.BLEED, Status.BURN, Status.POISON]:
			if active.has(s):
				var dmg: float = float(active[s]["dps"])
				if dmg > 0.0:
					mob.take_damage(dmg, Vector3.ZERO, _dot_damage_type(s))
	for s in expired:
		_expire(s)

func _process(delta: float) -> void:
	for s in _immune.keys():
		_immune[s] = float(_immune[s]) - delta
		if float(_immune[s]) <= 0.0:
			_immune.erase(s)

func _dot_damage_type(s: int) -> int:
	match s:
		Status.BURN: return EnemyRosterData.DamageType.FIRE
		Status.POISON: return EnemyRosterData.DamageType.POISON
		_: return EnemyRosterData.DamageType.BLUNT

func _expire(s: int) -> void:
	active.erase(s)
	_immune[s] = IMMUNITY
	if mob == null:
		return
	match s:
		Status.STUN:
			if mob.ai_state == BaseMonster.State.STUN:
				mob._change_state(BaseMonster.State.PATROL)
		Status.FEAR:
			if mob.ai_state == BaseMonster.State.FLEE:
				mob._change_state(BaseMonster.State.PATROL)

func _apply_now(s: int) -> void:
	if mob == null or mob.ai_state == BaseMonster.State.DEAD:
		return
	match s:
		Status.STUN:
			mob.stun(float(active[s]["t"]))
		Status.FEAR:
			mob._trigger_flee()
