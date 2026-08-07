extends Node
class_name BehaviorNode

enum Status { RUNNING, SUCCESS, FAILURE }

var _children: Array[BehaviorNode] = []

func add_child_node(node: BehaviorNode) -> void:
	_children.append(node)

func tick(delta: float, blackboard: Dictionary) -> Status:
	return Status.FAILURE

func _get_child(index: int) -> BehaviorNode:
	if index < _children.size():
		return _children[index]
	return null