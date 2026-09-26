extends Node
class_name BehaviorTree

@export var root: BehaviorNode
@export var tick_rate: float = 10.0  # ticks per second

var _blackboard: Dictionary = {}
var _timer: float = 0.0
var _agent: Node = null

func set_agent(agent: Node) -> void:
	_agent = agent
	_blackboard["agent"] = agent
	_blackboard["target"] = null
	_blackboard["last_known_pos"] = Vector3.ZERO

func set_target(target: Node3D) -> void:
	_blackboard["target"] = target

func get_blackboard() -> Dictionary:
	return _blackboard

func _process(delta: float) -> void:
	if not root or not _agent:
		return
	
	_timer += delta
	if _timer >= 1.0 / tick_rate:
		_timer = 0.0
		root.tick(delta, _blackboard)