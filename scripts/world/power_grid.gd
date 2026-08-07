extends Node
## Autoload "PowerGrid". Owns the 11 district progress stages, victory and
## the binary switch view used by PowerSwitch/puzzle interactables.

signal power_changed(district_id: StringName, on: bool)

const _DISTRICTS: Array = [
    preload("res://data/districts/district_suburbs.tres"),
    preload("res://data/districts/district_residential.tres"),
    preload("res://data/districts/district_park.tres"),
    preload("res://data/districts/district_school.tres"),
    preload("res://data/districts/district_hospital.tres"),
    preload("res://data/districts/district_gas_station.tres"),
    preload("res://data/districts/district_police.tres"),
    preload("res://data/districts/district_warehouses.tres"),
    preload("res://data/districts/district_industrial.tres"),
    preload("res://data/districts/district_substation.tres"),
    preload("res://data/districts/district_power_station.tres"),
]
var _by_id: Dictionary = {}
func _ready() -> void:
    for d in _DISTRICTS:
        if d is DistrictData:
            _by_id[(d as DistrictData).id] = d
func get_district(id: StringName) -> DistrictData:
    return _by_id.get(id, null)
func get_stage(id: StringName) -> int:
    var d := get_district(id)
    return d.stage if d != null else DistrictData.Stage.DARK
func all_districts() -> Array:
    return _by_id.values()
func is_unlocked(id: StringName) -> bool:
    var d := get_district(id)
    if d == null:
        return false
    for parent_id in d.powered_by:
        if get_stage(parent_id) < DistrictData.Stage.FULL:
            return false
    return true
func missing_prerequisite_name(id: StringName) -> String:
    var d := get_district(id)
    if d == null:
        return ""
    for parent_id in d.powered_by:
        if get_stage(parent_id) < DistrictData.Stage.FULL:
            var p := get_district(parent_id)
            return p.display_name if p != null else String(parent_id)
    return ""
func advance_district(id: StringName, new_stage: int) -> bool:
    var d := get_district(id)
    if d == null or not is_unlocked(id) or new_stage <= d.stage:
        if d != null and not is_unlocked(id):
            EventBus.inventory_notice.emit(tr("FIRST_RESTORE") % missing_prerequisite_name(id))
        return false
    d.stage = new_stage
    EventBus.district_stage_changed.emit(id, new_stage)
    EventBus.power_grid_updated.emit()
    # Фонари на улицах загораются на стадии STREETS — этого события ждёт
    # обучение, чтобы закрыть последнюю фазу.
    if new_stage >= DistrictData.Stage.STREETS:
        EventBus.streetlight_activated.emit(id)
    if new_stage >= DistrictData.Stage.FULL:
        EventBus.district_restored.emit(id)
    EventBus.emit_district_powered(id)
    power_changed.emit(id, new_stage > DistrictData.Stage.DARK)
    _check_victory()
    return true
## Публичная проверка «весь город восстановлен» — её спрашивает UI (экран
## финальной ночи), поэтому она не может остаться приватной.
func all_restored() -> bool:
    for d in _by_id.values():
        if d.stage < DistrictData.Stage.FULL:
            return false
    return true
func _check_victory() -> void:
    if all_restored():
        GameManager.trigger_win()

## Бинарный взгляд на стадию: район «под напряжением», если улицы горят.
func is_powered(id: StringName) -> bool:
    return get_stage(id) >= DistrictData.Stage.STREETS

## Вкл/выкл района рубильником: STREETS <-> DARK. Вызов из power_switch/puzzle_base.
func toggle_district(id: StringName) -> bool:
    var d := get_district(id)
    if d == null:
        return false
    if is_powered(id):
        _set_stage_direct(id, DistrictData.Stage.DARK)
        return false
    return advance_district(id, DistrictData.Stage.STREETS)

func toggle(id: StringName) -> void:
    toggle_district(id)

func _set_stage_direct(id: StringName, new_stage: int) -> void:
    var d := get_district(id)
    if d == null:
        return
    d.stage = new_stage
    EventBus.district_stage_changed.emit(id, new_stage)
    EventBus.power_grid_updated.emit()
    power_changed.emit(id, new_stage > DistrictData.Stage.DARK)

func get_progress() -> Dictionary:
    return {"powered": powered_count(), "total": total_count()}

func powered_count() -> int:
    var n := 0
    for d in _by_id.values():
        if d.stage >= DistrictData.Stage.STREETS:
            n += 1
    return n

func total_count() -> int:
    return _by_id.size()
func reset() -> void:
    for d in _by_id.values():
        d.stage = DistrictData.Stage.DARK
    EventBus.power_grid_updated.emit()
func to_dict() -> Dictionary:
    var stages: Dictionary = {}
    for d in _by_id.values():
        stages[String(d.id)] = d.stage
    return {"stages": stages}
func from_dict(d: Dictionary) -> void:
    var stages: Dictionary = d.get("stages", {}) as Dictionary
    for d2 in _by_id.values():
        d2.stage = int(stages.get(String(d2.id), DistrictData.Stage.DARK))
    EventBus.power_grid_updated.emit()