extends Node
## ObjectPool — универсальный пул объектов для врагов, пикапов, частиц.
## Использование:
##   ObjectPool.register("enemy", preload("res://scenes/enemies/zombie.tscn"), 8)
##   var inst = ObjectPool.get_instance("enemy")
##   ObjectPool.return_instance("enemy", inst)

var _pools: Dictionary = {}  # key → { scene, free: Array, active: Array }

func register(key: StringName, scene: PackedScene, initial_count: int = 4) -> void:
	if _pools.has(key):
		return
	_pools[key] = {"scene": scene, "free": [], "active": []}
	for i in range(initial_count):
		var inst: Node = scene.instantiate()
		inst.process_mode = Node.PROCESS_MODE_DISABLED
		inst.visible = false
		add_child(inst)
		_pools[key]["free"].append(inst)

func get_instance(key: StringName) -> Node:
	if not _pools.has(key):
		push_warning("ObjectPool: key '%s' not registered" % key)
		return null
	var pool: Dictionary = _pools[key]
	var inst: Node
	if pool["free"].is_empty():
		# Grow pool
		inst = (pool["scene"] as PackedScene).instantiate()
		add_child(inst)
	else:
		inst = pool["free"].pop_back()
	inst.process_mode = Node.PROCESS_MODE_INHERIT
	inst.visible = true
	pool["active"].append(inst)
	return inst

func return_instance(key: StringName, inst: Node) -> void:
	if not _pools.has(key):
		return
	var pool: Dictionary = _pools[key]
	if pool["active"].has(inst):
		pool["active"].erase(inst)
	inst.process_mode = Node.PROCESS_MODE_DISABLED
	inst.visible = false
	if inst.has_method("reset"):
		inst.reset()
	pool["free"].append(inst)

func active_count(key: StringName) -> int:
	if not _pools.has(key):
		return 0
	return _pools[key]["active"].size()

func free_count(key: StringName) -> int:
	if not _pools.has(key):
		return 0
	return _pools[key]["free"].size()
