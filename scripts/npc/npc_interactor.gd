extends Node3D
class_name NPCInteractor

@export var npc_id: StringName = &""
@export var npc_name: String = "NPC"
@export var dialogue_lines: Array[String] = []
@export var quest_giver: bool = false
@export var quest_id: StringName = &""
@export var reward_item: StringName = &""
@export var reward_amount: int = 1

@onready var interaction_area: Area3D = $InteractionArea
@onready var label: Label3D = $Label3D

var _player_near: bool = false
var _dialogue_active: bool = false

signal dialogue_started(npc_id: StringName, lines: Array[String])
signal dialogue_ended(npc_id: StringName)
signal quest_offered(quest_id: StringName)
signal quest_completed(npc_id: StringName)

func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	label.visible = false
	label.text = npc_name

func _process(delta: float) -> void:
	if _player_near and Input.is_action_just_pressed("interact"):
		if _dialogue_active:
			_next_dialogue_line()
		else:
			_start_dialogue()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = true
		label.visible = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = false
		label.visible = false
		_dialogue_active = false

func _start_dialogue() -> void:
	if dialogue_lines.is_empty():
		return
	
	_dialogue_active = true
	
	if quest_giver and quest_id != &"":
		var qm = get_tree().root.get_node_or_null("/root/QuestManager")
		if qm and qm.get_quest_status(quest_id) == QuestManager.STATUS_NOT_STARTED:
			quest_offered.emit(quest_id)
			dialogue_started.emit(npc_id, dialogue_lines)
			return
		elif qm and qm.get_quest_status(quest_id) == QuestManager.STATUS_ACTIVE:
			var progress = qm.get_progress(quest_id)
			var obj_idx = 0
			for i in range(qm._quests[quest_id]["data"]["objectives"].size()):
				var obj = qm._quests[quest_id]["data"]["objectives"][i]
				var current = progress.get(obj["id"], 0)
				var target = obj["target"]
				if current < target:
					obj_idx = i
					break
			var obj_data = qm._quests[quest_id]["data"]["objectives"][obj_idx]
			var lines = [dialogue_lines[0] if dialogue_lines.size() > 0 else "", "Objective: %s (%d/%d)" % [obj_data.get("description", ""), progress.get(obj_data["id"], 0), obj_data["target"]]]
			dialogue_started.emit(npc_id, lines)
			return
		elif qm and qm.get_quest_status(quest_id) == QuestManager.STATUS_COMPLETED:
			dialogue_started.emit(npc_id, ["Thank you for your help!", "You are truly a hero of this city."])
			return
	
	dialogue_started.emit(npc_id, dialogue_lines)

func _next_dialogue_line() -> void:
	# Simple: end dialogue on next interaction
	_dialogue_active = false
	dialogue_ended.emit(npc_id)
	
	# Check if quest should be awarded
	if quest_giver and quest_id != &"":
		var qm = get_tree().root.get_node_or_null("/root/QuestManager")
		if qm and qm.get_quest_status(quest_id) == QuestManager.STATUS_NOT_STARTED:
			qm.start_quest(quest_id)

func interact() -> void:
	_start_dialogue()

func get_interaction_text() -> String:
	if quest_giver:
		var qm = get_tree().root.get_node_or_null("/root/QuestManager")
		if qm:
			var status = qm.get_quest_status(quest_id)
			match status:
				QuestManager.STATUS_NOT_STARTED: return "Talk to %s (Quest available)" % npc_name
				QuestManager.STATUS_ACTIVE: return "Talk to %s (Quest in progress)" % npc_name
				QuestManager.STATUS_COMPLETED: return "Talk to %s (Quest complete)" % npc_name
	return "Talk to %s" % npc_name