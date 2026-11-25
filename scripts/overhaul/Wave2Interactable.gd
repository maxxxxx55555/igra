class_name Wave2Interactable
extends Node3D

## Thin interaction adapter for the Wave 2 district loop.
## It never implements game rules itself - all state changes go through the
## supplied Wave2DistrictFlow singleton (anti-dupe tokens, debounce, stages).

@export var kind: StringName = &"relay"
@export var part_id: String = ""
@export var district_index: int = 0

var _spent: bool = false

func can_interact() -> bool:
	if _spent:
		return false
	var flow := get_node_or_null("/root/Wave2Flow")
	if flow == null:
		return false
	var state: StringName = StringName(flow.call("get_state"))
	match kind:
		&"relay":
			return state == StringName("SCAVENGE_PARTS")
		&"fusebox":
			return state == StringName("REPAIR_FUSEBOX")
		&"gate":
			return bool(flow.call("is_gate_unlocked"))
	return false

func interact(_player: Node = null) -> void:
	if _spent:
		return
	var flow := get_node_or_null("/root/Wave2Flow")
	if flow == null:
		return
	var ok: bool = false
	match kind:
		&"relay":
			ok = bool(flow.call("try_collect_relay_part", part_id))
		&"fusebox":
			ok = bool(flow.call("try_repair_fusebox"))
		&"gate":
			if bool(flow.call("is_gate_unlocked")):
				ok = bool(flow.call("try_enter_exit_gate"))
	if ok:
		_spent = true
		if kind == &"relay":
			queue_free()

func interact_prompt() -> String:
	var i18n := get_node_or_null("/root/I18nSync")
	var state: StringName = StringName()
	var flow := get_node_or_null("/root/Wave2Flow")
	if flow != null:
		state = StringName(flow.call("get_state"))
	match kind:
		&"relay":
			return i18n.call("t", "PROMPT_PICKUP_RELAY") if i18n != null else "Take relay part"
		&"fusebox":
			if state == StringName("REPAIR_FUSEBOX"):
				return i18n.call("t", "PROMPT_REPAIR_FUSEBOX") if i18n != null else "Repair fusebox"
			var args := {"have": _parts_count(flow), "need": 6}
			return i18n.call("t", "PROMPT_FUSEBOX_NEED_PARTS", args) if i18n != null else "Need relay parts"
		&"gate", _:
			if flow != null and bool(flow.call("is_gate_unlocked")):
				return i18n.call("t", "PROMPT_GATE_OPEN", {"name": str(district_index + 2)}) if i18n != null else "Enter next district"
			return i18n.call("t", "PROMPT_GATE_LOCKED") if i18n != null else "Gate locked"
	return ""

func _parts_count(flow: Node) -> int:
	if flow == null:
		return 0
	var info: Dictionary = flow.call("get_objective_key_and_args")
	var a: Dictionary = info.get("args", {})
	return clampi(int(a.get("have", 0)), 0, 6)
