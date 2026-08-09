extends Node

const DISTRICTS: Array[String] = [
	"suburbs", "residential", "park", "school", "hospital",
	"gas_station", "police", "warehouses", "industrial", "substation", "power_station"
]

var current_district: String = "suburbs"
var district_stages: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for d in DISTRICTS:
		district_stages[d] = 0

func set_stage(district_id: String, stage: int) -> void:
	if district_stages.has(district_id):
		district_stages[district_id] = clampi(stage, 0, 3)
		EventBus.district_stage_changed.emit(StringName(district_id), district_stages[district_id])


func get_stage(district_id: String) -> int:
	return district_stages.get(district_id, 0)

func all_restored() -> bool:
	for d in DISTRICTS:
		if district_stages.get(d, 0) < 3:
			return false
	return true

func count_restored() -> int:
	var n := 0
	for d in DISTRICTS:
		if district_stages.get(d, 0) >= 3:
			n += 1
	return n

func transition_to(district_id: String) -> void:
	if district_id == current_district:
		return
	if not DISTRICTS.has(district_id):
		return
	var prev := current_district
	current_district = district_id
	EventBus.district_entered.emit(StringName(district_id))

	if district_stages.get(district_id, 0) == 0:
		set_stage(district_id, 1)
