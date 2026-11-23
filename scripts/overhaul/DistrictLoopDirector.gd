class_name DistrictLoopDirector
extends Node

## Clear 3-stage district loop: Gather parts -> Power Streetlight Fusebox -> Exit via Illuminated Gate to next district.

signal objective_updated(objective_text: String)
signal district_gate_unlocked(gate_id: String, next_scene_path: String)
signal district_transition_requested(next_scene_path: String)

enum LoopStage { SCAVENGE_SCRAP, RESTORE_FUSEBOX, EXIT_TO_NEXT_DISTRICT }

@export var district_display_name_ru: String = "РАЙОН I — ДВОР"
@export var district_display_name_en: String = "DISTRICT I — COURTYARD"
@export var scrap_required: int = 6
@export var next_district_scene_path: String = ""
@export var next_district_name_ru: String = "РАЙОН II — ПРОСПЕКТ"
@export var next_district_name_en: String = "DISTRICT II — AVENUE"

var current_stage: LoopStage = LoopStage.SCAVENGE_SCRAP
var scrap_collected: int = 0
var fusebox_restored: bool = false


func _ready() -> void:
	_emit_objective()


func get_district_name() -> String:
	return district_display_name_ru if _is_ru() else district_display_name_en


func get_next_district_name() -> String:
	return next_district_name_ru if _is_ru() else next_district_name_en


func add_scrap(amount: int = 1) -> void:
	if amount <= 0 or fusebox_restored:
		return
	scrap_collected = mini(scrap_required, scrap_collected + amount)
	if scrap_collected >= scrap_required and current_stage == LoopStage.SCAVENGE_SCRAP:
		current_stage = LoopStage.RESTORE_FUSEBOX
	_emit_objective()


func try_restore_fusebox() -> bool:
	if fusebox_restored:
		return true
	if scrap_collected < scrap_required:
		_emit_objective()
		return false
	fusebox_restored = true
	current_stage = LoopStage.EXIT_TO_NEXT_DISTRICT
	_emit_objective()
	district_gate_unlocked.emit("district_exit_gate", next_district_scene_path)
	return true


func try_enter_exit_gate() -> bool:
	if current_stage != LoopStage.EXIT_TO_NEXT_DISTRICT:
		return false
	if not next_district_scene_path.is_empty():
		district_transition_requested.emit(next_district_scene_path)
	return true


func get_current_objective_text() -> String:
	if _is_ru():
		match current_stage:
			LoopStage.SCAVENGE_SCRAP:
				return "Детали: %d/%d → Починить щиток фонаря" % [scrap_collected, scrap_required]
			LoopStage.RESTORE_FUSEBOX:
				return "Включить щиток фонаря → открыть проход"
			LoopStage.EXIT_TO_NEXT_DISTRICT:
				return "Проход открыт → %s" % next_district_name_ru
	else:
		match current_stage:
			LoopStage.SCAVENGE_SCRAP:
				return "Parts: %d/%d → Repair streetlight relay" % [scrap_collected, scrap_required]
			LoopStage.RESTORE_FUSEBOX:
				return "Power streetlight relay → unlock gate"
			LoopStage.EXIT_TO_NEXT_DISTRICT:
				return "Gate open → %s" % next_district_name_en
	return ""


func _emit_objective() -> void:
	objective_updated.emit(get_current_objective_text())


func _is_ru() -> bool:
	return TranslationServer.get_locale().to_lower().begins_with("ru")
