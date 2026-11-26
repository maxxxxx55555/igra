extends Node
## Reserve a shared budget for the sun, the player flashlight and the nearest
## local lights. Lamp glass remains emissive even outside its dynamic slot.
const MAX_VISIBLE: int = 4
const CHECK_INTERVAL: float = 0.12
const GROUP := &"budgeted_world_lights"
const LIT_MIN := 0.001

var _timer: float = 0.0
var _hidden: Dictionary = {}  # instance id -> true: the lights this limiter has hidden

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node is Light3D:
		node.add_to_group(GROUP)
		if node is OmniLight3D:
			node.add_to_group(&"omni_lights")
		_timer = 0.0

func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = CHECK_INTERVAL
	_update_lights()

func _update_lights() -> void:
	var cam: Camera3D = _get_camera()
	if cam == null:
		return
	var cam_pos: Vector3 = cam.global_position
	var lit: Array[Light3D] = []
	var reserved := 0
	var player := GameManager.player
	var seen: Dictionary = {}
	for node: Node in get_tree().get_nodes_in_group(GROUP):
		var light := node as Light3D
		if light == null:
			continue
		var id: int = light.get_instance_id()
		seen[id] = true
		if light is DirectionalLight3D or (is_instance_valid(player) and player.is_ancestor_of(light)):
			if light.is_visible_in_tree() and light.light_energy > LIT_MIN:
				reserved += 1
			continue
		if not (light.is_visible_in_tree() or _hidden.has(id)):
			continue  # put out by its owner
		if light.light_energy > LIT_MIN:
			lit.append(light)
		else:
			_hide(light)
	lit.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return a.global_position.distance_squared_to(cam_pos) < b.global_position.distance_squared_to(cam_pos)
	)
	for i in lit.size():
		var light: Light3D = lit[i]
		if i < MAX_VISIBLE - reserved:
			if _hidden.erase(light.get_instance_id()):
				light.visible = true
		else:
			_hide(light)
	for id: int in _hidden.keys():
		if not seen.has(id):
			_hidden.erase(id)

func _hide(light: Light3D) -> void:
	if light.visible:
		light.visible = false
		_hidden[light.get_instance_id()] = true

func _get_camera() -> Camera3D:
	var vp := get_viewport()
	if vp == null:
		return null
	return vp.get_camera_3d()
