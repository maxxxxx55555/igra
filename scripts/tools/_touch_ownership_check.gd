extends Node3D
## Isolated routing regression using the real player and camera. Direct _input calls
## isolate ownership; --touch-dispatch exercises viewport delivery for windowed QA.

var _fails: int = 0
var _player: CharacterBody3D
var _camera: Camera3D
var _dispatch: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	_dispatch = "--touch-dispatch" in OS.get_cmdline_user_args()
	GameManager._change_state(GameManager.GameState.PLAYING)
	UIManager.close_all_blocking()
	_camera = Camera3D.new()
	_camera.set_script(load("res://scripts/core/camera_follow_3d.gd"))
	add_child(_camera)
	_camera.make_current()
	_player = (load("res://scenes/player/player_3d.tscn") as PackedScene).instantiate() as CharacterBody3D
	add_child(_player)
	_player.set_physics_process(false)
	_player.set("gameplay_active", true)
	_player.call("_resolve_camera")
	await get_tree().process_frame
	var view: Vector2 = get_viewport().get_visible_rect().size
	var look: Vector2 = view * Vector2(0.55, 0.35)
	var action: Vector2 = view * Vector2(0.8, 0.35)
	var layer := CanvasLayer.new()
	add_child(layer)
	var button := Button.new()
	button.position = action - Vector2(30.0, 30.0)
	button.size = Vector2(60.0, 60.0)
	layer.add_child(button)
	await get_tree().process_frame
	_ok(not _player.call("_touch_on_control", look) and _player.call("_touch_on_control", action), "fixture separates free look from visible control")
	_touch(71, look, true)
	_ok(int(_player.get("_look_touch_index")) == 71, "free press reaches actual player input")
	_touch(72, action, true)
	_ok(_player.get("_touch_pos").size() == 1 and float(_player.get("_pinch_dist")) == 0.0, "control press cannot join look pinch")
	_reset()
	_touch(72, action, true)
	_touch(72, action + Vector2(0.0, 200.0), false)
	_ok(not _player.get("_crouch_toggled"), "control-origin swipe cannot crouch")
	_reset()
	_touch(73, look, true)
	_touch(73, look + Vector2(0.0, 200.0), false, true)
	_ok(not _player.get("_crouch_toggled") and _empty(), "cancel releases ownership without crouch")
	_reset()
	_touch(74, look, true, true)
	_ok(_empty(), "canceled press cannot enter trackers")
	_reset()
	_touch(75, look, true)
	_player.set("gameplay_active", false)
	_touch(75, look, false)
	_ok(_empty(), "inactive player clears pending gesture")
	_player.set("gameplay_active", true)
	_reset()
	_touch(76, look, true)
	UIManager.open(&"pause")
	_ok(UIManager.is_hud_blocked(), "modal blocks gameplay input")
	_touch(76, look, false)
	_ok(_empty(), "modal clears pending gesture")
	UIManager.close(&"pause")
	_reset()
	button.hide()
	_touch(77, look, true)
	_touch(78, action, true)
	var before: float = float(_camera.get("_zoom_target"))
	var drag := InputEventScreenDrag.new()
	drag.index = 78
	drag.position = action + Vector2(60.0, 0.0)
	drag.relative = Vector2(60.0, 0.0)
	_send(drag)
	_ok(float(_camera.get("_zoom_target")) > before, "free two-finger gesture reaches real camera zoom")
	_touch(77, look, false)
	_touch(78, drag.position, false)
	_reset()
	_player.queue_free()
	_camera.queue_free()
	layer.queue_free()
	await get_tree().process_frame
	print("[touch-ownership] mode=%s DONE fails=%d" % ["viewport" if _dispatch else "direct", _fails])
	get_tree().quit(0 if _fails == 0 else 1)

func _send(event: InputEvent) -> void:
	if _dispatch:
		# Fixture points are viewport-local, like Control.get_global_rect().
		# Avoid interpreting them as physical window pixels under canvas stretch.
		get_viewport().push_input(event, true)
	else:
		_player.call("_input", event)

func _touch(index: int, point: Vector2, pressed: bool, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	event.canceled = canceled
	_send(event)

func _empty() -> bool:
	return int(_player.get("_look_touch_index")) == -1 and _player.get("_touch_pos").is_empty() and _player.get("_swipe_start").is_empty() and float(_player.get("_pinch_dist")) == 0.0

func _reset() -> void:
	_player.set("_look_touch_index", -1)
	_player.get("_touch_pos").clear()
	_player.get("_swipe_start").clear()
	_player.set("_pinch_dist", 0.0)
	_player.set("_crouch_toggled", false)

func _ok(condition: bool, label: String) -> void:
	if not condition:
		_fails += 1
	print("[touch-ownership] %s %s" % ["OK" if condition else "FAIL", label])
