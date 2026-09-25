extends Node
## Где сейчас игрок и переходы между районами.
##
## Раньше здесь жила вторая, независимая копия стадий восстановления
## (district_stages). Её никто не двигал: PowerGrid поднимал свои стадии,
## а этот словарь оставался нулевым — только transition_to() ставил 1
## просто за факт входа в район. От этой копии зависело освещение
## (world_env_setup, streetlight_3d) и достижения, поэтому улицы не
## загорались после ремонта, а «весь город» не открывался никогда.
##
## Теперь стадии не дублируются: источник правды — PowerGrid, здесь
## остаётся только текущий район и переход.

const DISTRICTS: Array[String] = [
	"suburbs", "residential", "park", "school", "hospital",
	"gas_station", "police", "warehouses", "industrial", "substation", "power_station"
]
const START_DISTRICT: String = "suburbs"

var current_district: String = START_DISTRICT

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

## GDD.md:341 (G24): "Точка невозврата: вход в D10". The finale needs all 11
## districts FULL (power_grid.gd _check_victory), so locking the way back the
## moment a player steps into D10 would strand anyone who arrived early with
## an unfinished district behind them. The gate closes only once D1-D9 are
## all FULL: from then on, D10/D11 cannot travel back.
const NO_RETURN_DISTRICT: String = "substation"

func is_past_no_return(target: String) -> bool:
	var gate: int = DISTRICTS.find(NO_RETURN_DISTRICT)
	if DISTRICTS.find(current_district) < gate or DISTRICTS.find(target) >= gate:
		return false
	var pg := _grid()
	if pg == null:
		return false
	for i in gate:
		if int(pg.get_stage(StringName(DISTRICTS[i]))) < DistrictData.Stage.FULL:
			return false
	return true

func _grid() -> Node:
	return get_node_or_null("/root/PowerGrid")

## Оставлено для инструментов и отладки: пишет напрямую в PowerGrid.
func set_stage(district_id: String, stage: int) -> void:
	var pg := _grid()
	if pg == null:
		return
	pg.advance_district(StringName(district_id), clampi(stage, 0, 3))

func get_stage(district_id: String) -> int:
	var pg := _grid()
	return pg.get_stage(StringName(district_id)) if pg != null else 0

func all_restored() -> bool:
	var pg := _grid()
	return pg.all_restored() if pg != null else false

func count_restored() -> int:
	var pg := _grid()
	if pg == null:
		return 0
	var n := 0
	for d in DISTRICTS:
		if pg.get_stage(StringName(d)) >= 3:
			n += 1
	return n

func get_district_count() -> int:
	return DISTRICTS.size()

func get_district_id(index: int) -> StringName:
	if index < 0 or index >= DISTRICTS.size():
		return StringName(START_DISTRICT)
	return StringName(DISTRICTS[index])

func transition_to(district_id: String) -> void:
	if district_id == current_district:
		return
	if not DISTRICTS.has(district_id):
		return
	var pg := _grid()
	if pg != null and not pg.is_unlocked(StringName(district_id)):
		return
	if is_past_no_return(district_id):
		EventBus.inventory_notice.emit(LocalizationManager.t("NO_RETURN_BLOCKED"))
		return
	current_district = district_id
	EventBus.district_entered.emit(StringName(district_id))
