extends Node
## LightLimiter: no more than MAX_VISIBLE omni lights are shown at once, the nearest to the camera. Autoload.
## Every CHECK_INTERVAL seconds the lights that give light are sorted by their distance to the camera: the farther ones are hidden, and what this limiter hid itself comes back when it is among the nearest. A light of no
## energy gives none and costs a slot of the lighting loop of every object it touches, so it is hidden as well (an owner that flashes a light from 0 shows it itself, as the exploding barrel does). A light its owner has put out
## is never touched: the limiter used to set `visible` of EVERY omni light by its rank, so the glow of the six nearest unlit lamps came back on in a dark district, lit it and held six of the eight slots (5 ms of a frame at
## the High tier, v10 R2).

const MAX_VISIBLE: int = 8
const CHECK_INTERVAL: float = 0.25  # секунды между проверками
## Every OmniLight3D that enters the tree joins this group, so a check sorts the lights instead of walking the whole tree (about 1800 nodes) four times a second.
const GROUP: StringName = &"omni_lights"
const LIT_MIN: float = 0.001

var _timer: float = 0.0
var _hidden: Dictionary = {}  # instance id -> true: the lights this limiter has hidden

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node is OmniLight3D:
		node.add_to_group(GROUP)

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
	var lit: Array = []
	var seen: Dictionary = {}
	for node: Node in get_tree().get_nodes_in_group(GROUP):
		var light := node as OmniLight3D
		if light == null:
			continue
		var id: int = light.get_instance_id()
		seen[id] = true
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
		var light: OmniLight3D = lit[i]
		if i < MAX_VISIBLE:
			if _hidden.erase(light.get_instance_id()):
				light.visible = true
		else:
			_hide(light)
	for id: int in _hidden.keys():
		if not seen.has(id):
			_hidden.erase(id)

func _hide(light: OmniLight3D) -> void:
	if light.visible:
		light.visible = false
		_hidden[light.get_instance_id()] = true

func _get_camera() -> Camera3D:
	var vp := get_viewport()
	if vp == null:
		return null
	return vp.get_camera_3d()
