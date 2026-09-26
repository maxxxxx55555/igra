extends BehaviorNode
class_name ConditionNode

@export var condition_name: StringName = &""
@export var invert: bool = false

func tick(delta: float, blackboard: Dictionary) -> Status:
	var agent = blackboard.get("agent")
	if not agent:
		return Status.FAILURE
	
	var result = false
	if agent.has_method(condition_name):
		result = agent.call(condition_name, blackboard)
	elif blackboard.has(condition_name):
		result = blackboard[condition_name]
	
	if invert:
		result = not result
	
	return Status.SUCCESS if result else Status.FAILURE