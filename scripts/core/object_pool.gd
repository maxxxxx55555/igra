extends Node

@export var pool_size: int = 50
@export var prefab: PackedScene
var _available: Array[Node] = []
var _in_use: Array[Node] = []

func _ready() -> void:
	if not prefab:
		# push_error("ObjectPool: No prefab assigned!")
		return
	for i in range(pool_size):
		var instance = prefab.instantiate()
		instance.set_deferred("visible", false)
		instance.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
		add_child(instance)
		_available.append(instance)

func acquire() -> Node:
	if _available.is_empty():
		if prefab:
			var instance = prefab.instantiate()
			add_child(instance)
			_in_use.append(instance)
			instance.visible = true
			instance.process_mode = Node.PROCESS_MODE_INHERIT
			if instance.has_method("on_acquire"):
				instance.on_acquire()
			return instance
		return null
	
	var instance = _available.pop_back()
	_in_use.append(instance)
	instance.visible = true
	instance.process_mode = Node.PROCESS_MODE_INHERIT
	if instance.has_method("on_acquire"):
		instance.on_acquire()
	return instance

func release(obj: Node) -> void:
	if not _in_use.has(obj):
		return
	_in_use.erase(obj)
	_available.append(obj)
	obj.visible = false
	obj.process_mode = Node.PROCESS_MODE_DISABLED
	if obj.has_method("on_release"):
		obj.on_release()

func release_all() -> void:
	for obj in _in_use.duplicate():
		release(obj)

func get_available_count() -> int:
	return _available.size()

func get_in_use_count() -> int:
	return _in_use.size()