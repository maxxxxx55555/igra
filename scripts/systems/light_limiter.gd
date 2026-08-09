extends Node
## LightLimiter — не более MAX_VISIBLE OmniLight3D одновременно.
## Автозагрузка или добавляется в основную сцену.
## Каждые CHECK_INTERVAL секунд сортирует все OmniLight3D по расстоянию до камеры
## и скрывает дальние, оставляя только MAX_VISIBLE ближайших.

const MAX_VISIBLE: int = 8
const CHECK_INTERVAL: float = 0.25  # секунды между проверками

var _timer: float = 0.0

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
	var lights: Array = get_tree().get_nodes_in_group("omni_lights")
	if lights.is_empty():
		# Fallback: find all OmniLight3D in scene
		lights = []
		_collect_lights(get_tree().root, lights)
	if lights.is_empty():
		return
	# Sort by distance to camera
	lights.sort_custom(func(a: Node, b: Node) -> bool:
		return a.global_position.distance_squared_to(cam_pos) < b.global_position.distance_squared_to(cam_pos)
	)
	for i in range(lights.size()):
		var light: OmniLight3D = lights[i] as OmniLight3D
		if light == null:
			continue
		light.visible = i < MAX_VISIBLE

func _collect_lights(node: Node, result: Array) -> void:
	if node is OmniLight3D:
		result.append(node)
	for child in node.get_children():
		_collect_lights(child, result)

func _get_camera() -> Camera3D:
	var vp := get_viewport()
	if vp == null:
		return null
	return vp.get_camera_3d()
