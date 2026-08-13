extends Node

signal cutscene_started
signal cutscene_ended

var _is_playing: bool = false
var _camera: Camera3D
var _original_camera: Camera3D

## Катсцена ставит дерево на паузу, а потом ждёт свои твины и таймеры.
## С режимом по умолчанию (PAUSABLE) они останавливаются вместе с деревом,
## await не завершается никогда, и игра зависает намертво — снять паузу
## некому, потому что снимает её как раз конец катсцены.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func play_cutscene(camera_path: NodePath, actions: Array[Dictionary]) -> void:
	if _is_playing:
		return
	_is_playing = true
	cutscene_started.emit()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_camera = get_node(camera_path) as Camera3D
	_original_camera = get_viewport().get_camera_3d()
	if _camera:
		_camera.current = true
		for action in actions:
			await _execute_action(action)
	_end_cutscene()

func _execute_action(action: Dictionary) -> void:
	var type = action.get("type", "")
	match type:
		"move":
			var target = action.target as Node3D
			var duration = action.get("duration", 2.0)
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(_camera, "global_position", target.global_position, duration)
			await tween.finished
		"wait":
			await get_tree().create_timer(action.get("duration", 1.0)).timeout
		"dialog":
			await get_tree().create_timer(action.get("duration", 3.0)).timeout
		"shake":
			var intensity = action.get("intensity", 0.5)
			var duration = action.get("duration", 0.5)
			_shake_camera(intensity, duration)
			await get_tree().create_timer(duration).timeout

func _shake_camera(intensity: float, duration: float) -> void:
	var base_pos = _camera.global_position
	var timer = 0.0
	while timer < duration:
		_camera.global_position = base_pos + Vector3(randf()-0.5, randf()-0.5, randf()-0.5) * intensity
		timer += get_process_delta_time()
		await get_tree().process_frame
	_camera.global_position = base_pos

func _end_cutscene() -> void:
	if _original_camera:
		_original_camera.current = true
	_is_playing = false
	get_tree().paused = false
	InputService.refresh_mouse_mode()
	cutscene_ended.emit()
