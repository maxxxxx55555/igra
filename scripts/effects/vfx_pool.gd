extends RefCounted
## Hit sparks, blood and muzzle flashes used to be instantiated and freed per call, each one building its own particle material
## and quad mesh. spawn() replays a finished burst of the same scene instead. At most MAX_PER_SCENE bursts of one scene exist;
## when every one of them is still playing, the oldest is replayed (stolen) rather than a new one made.

const MAX_PER_SCENE: int = 24

## PackedScene -> its bursts, oldest spawn first. Entries freed with the tree are dropped on the next spawn.
static var _bursts: Dictionary = {}

static func spawn(scene: PackedScene, pos: Vector3, tree: SceneTree) -> Node3D:
	var list: Array = []
	var fx: VFXBurst = null
	for b in _bursts.get(scene, []):
		if is_instance_valid(b) and not b.is_queued_for_deletion():
			list.append(b)
			if fx == null and b.parked:
				fx = b
	if fx == null and list.size() >= MAX_PER_SCENE:
		fx = list[0]
	if fx == null:
		fx = scene.instantiate() as VFXBurst
		fx.pooled = true
		tree.root.add_child(fx)
		fx.global_position = pos
	else:
		fx.global_position = pos
		fx.replay()
		list.erase(fx)
	list.append(fx)
	_bursts[scene] = list
	return fx
