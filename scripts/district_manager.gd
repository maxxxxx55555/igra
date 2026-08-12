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

var current_district: String = "suburbs"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

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
		return &"suburbs"
	return StringName(DISTRICTS[index])

func transition_to(district_id: String) -> void:
	if district_id == current_district:
		return
	if not DISTRICTS.has(district_id):
		return
	current_district = district_id
	EventBus.district_entered.emit(StringName(district_id))
