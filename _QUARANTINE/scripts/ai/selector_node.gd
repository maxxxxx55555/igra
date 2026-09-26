extends BehaviorNode
class_name SelectorNode

func tick(delta: float, blackboard: Dictionary) -> Status:
	for child in _children:
		var status = child.tick(delta, blackboard)
		if status != Status.FAILURE:
			return status
	return Status.FAILURE