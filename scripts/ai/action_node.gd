extends BehaviorNode
class_name ActionNode

@export var action_name: StringName = &""

func tick(delta: float, blackboard: Dictionary) -> Status:
	var agent = blackboard.get("agent")
	if not agent:
		return Status.FAILURE
	
	if agent.has_method(action_name):
		var result = agent.call(action_name, delta, blackboard)
		if result is int:
			return result
		return Status.SUCCESS if result else Status.FAILURE
	
	return Status.FAILURE