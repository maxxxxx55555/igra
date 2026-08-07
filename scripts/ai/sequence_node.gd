extends BehaviorNode
class_name SequenceNode

func tick(delta: float, blackboard: Dictionary) -> Status:
	for child in _children:
		var status = child.tick(delta, blackboard)
		if status != Status.SUCCESS:
			return status
	return Status.SUCCESS