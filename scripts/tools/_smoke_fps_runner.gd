extends Node

const MAIN := "res://scenes/main_3d.tscn"

var _phase: int = 0
var _t: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var eb := get_node_or_null("/root/EventBus")
	if eb:
		eb.connect("game_state_changed", func(v: int) -> void: print("[SMOKE] state->", v))
	_phase = 1

func _process(delta: float) -> void:
	_t += delta
	if _phase == 1 and _t > 1.5:
		var gm := get_node_or_null("/root/GameManager")
		print("[SMOKE] menu_state: ", gm != null and gm.has_method("is_menu") and (is_instance_valid(gm) and gm.is_menu()))
		if gm and gm.has_method("start_new_game"):
			gm.start_new_game()
			_phase = 2
			_t = 0.0
	elif _phase == 2 and _t > 6.0:
		_report()
		print("[SMOKE] DONE")
		get_tree().quit(0)
	elif _phase == 3 and _t > 40.0:
		print("[SMOKE] WATCHDOG QUIT")
		get_tree().quit(1)

func _report() -> void:
	_phase = 3
	var gm := get_node_or_null("/root/GameManager")
	var playing: bool = gm != null and gm.has_method("is_playing") and (is_instance_valid(gm) and gm.is_playing())
	var player := get_tree().get_first_node_in_group("player")
	var p_ok := player != null and player.is_inside_tree()
	var cam: Camera3D = null
	var cone_ok: bool = false
	if p_ok:
		cone_ok = player.get_node_or_null("ModelPivot/FlashlightPivot/Flashlight") != null
		cam = get_tree().root.get_node_or_null("Main3D/Camera3D") as Camera3D
		if cam == null:
			cam = get_viewport().get_camera_3d()
	var cam_fps: bool = cam != null and cam.get("fps_mode") == true
	var monsters := get_tree().get_nodes_in_group("shadow").size() + get_tree().get_nodes_in_group("destroyers").size()
	var pickups := get_tree().get_nodes_in_group("pickups").size()
	var nav_ok := get_tree().get_first_node_in_group("nav_region") != null
	print("[SMOKE] playing=", playing, " player=", p_ok, " flashlight=", cone_ok,
		" fps_cam=", cam_fps, " monsters=", monsters, " pickups=", pickups, " nav=", nav_ok)
	_check_input_wiring(player)

func _check_input_wiring(player: Node3D) -> void:
	var isv := get_node_or_null("/root/InputService")
	if isv == null:
		print("[SMOKE] input: InputService missing")
		return
	isv.request_attack()
	var phase: String = player.get("_attack_phase")
	isv.request_jump()
	var jbuf: float = player.get("_jump_buffer_timer")
	isv.request_flashlight()
	var fl: bool = player.get("flashlight_enabled")
	print("[SMOKE] input: attack_phase=", phase, " jump_buf=", "%.2f" % jbuf,
		" flashlight_toggled=", fl)
