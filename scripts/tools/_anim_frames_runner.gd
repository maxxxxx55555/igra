extends Node
## Pose frames of the monster rig (WORKQUEUE A9), shot in a viewport of its own (the menu of the game would cover the window). Each monster stands on a lit floor and shows the peak of its stride and the passing pose; the commonest ones also the rest, the windup, the
## strike and the recovery of an attack; three die in three steps. Windowed: TLS_FRAMES_HASH=<hash> tools/qa_sim/guarded_windowed res://scenes/tools/anim_frames_scene.tscn 240
## Frames -> .qa_logs/frames/<state>_<monster>_<hash>_<UTC>.png (the AF3 name: the code tree and the capture time). A saved frame proves nothing until it is read.

const OUT: String = "res://.qa_logs/frames/"
const SIZE := Vector2i(640, 480)
const DT: float = 1.0 / 60.0
const STRIDE: Array[String] = ["shadow_3d", "crawler_3d", "hunter_3d", "watcher_3d", "destroyer_3d", "rotter_3d", "hound_3d", "brute_3d", "burner_3d", "sharpshooter_3d", "tvar_3d", "boss_architect_3d"]
const ATTACK: Array[String] = ["shadow_3d", "crawler_3d", "hunter_3d", "watcher_3d", "destroyer_3d", "rotter_3d"]
const DEATH: Array[String] = ["rotter_3d", "hunter_3d", "destroyer_3d"]

var _hash: String = "unknown"
var _vp: SubViewport
var _cam: Camera3D
var _shots: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")

func _utc() -> String:
	var d := Time.get_datetime_dict_from_system(true)
	return "%04d%02d%02dT%02d%02d%02dZ" % [d["year"], d["month"], d["day"], d["hour"], d["minute"], d["second"]]

func _stage() -> void:
	_vp = SubViewport.new()
	_vp.size = SIZE
	_vp.own_world_3d = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.09, 0.10, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.52, 0.57)
	env.ambient_light_energy = 0.9
	var world := WorldEnvironment.new()
	world.environment = env
	_vp.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -40.0, 0.0)
	sun.light_energy = 1.3
	_vp.add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40.0, 40.0)
	ground.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.29, 0.27)
	ground.material_override = mat
	_vp.add_child(ground)
	_cam = Camera3D.new()
	_cam.fov = 45.0
	_vp.add_child(_cam)
	_cam.make_current()

## A monster on the floor, facing -Z, its physics and its AI off: the frames are made by calling its _update_anim by hand.
func _spawn(scene: String) -> Node3D:
	var monster := (load("res://scenes/enemies/%s.tscn" % scene) as PackedScene).instantiate() as Node3D
	monster.set("_music_started", true)
	_vp.add_child(monster)
	var capsule := (monster.get_node("CollisionShape3D") as CollisionShape3D).shape as CapsuleShape3D
	monster.position = Vector3(0.0, capsule.height * 0.5, 0.0)
	monster.set_physics_process(false)
	monster.set_process(false)
	var top: float = 3.4 if scene.begins_with("boss") else capsule.height + 0.3
	_cam.global_position = Vector3(1.0, 0.0, -0.35).normalized() * maxf(4.0, top * 2.3) + Vector3(0.0, top * 0.55, 0.0)
	_cam.look_at(Vector3(0.0, top * 0.5, 0.0))
	return monster

func _shot(state: String, scene: String) -> void:
	await RenderingServer.frame_post_draw
	var img := _vp.get_texture().get_image()
	var file := "%s_%s_%s_%s.png" % [state, scene.trim_suffix("_3d"), _hash, _utc()]
	img.save_png(ProjectSettings.globalize_path(OUT + file))
	_shots += 1
	print("[anim] frame %s" % file)

func _steps(monster: Node3D, frames: int) -> void:
	for _i in frames:
		monster.call("_update_anim", DT)

func _stride(monster: Node3D, scene: String) -> void:
	var rig: Node = monster.get("_rig")
	monster.set("velocity", Vector3(0.0, 0.0, -float(monster.get("chase_speed"))))
	_steps(monster, 40)
	rig.set("_gait_phase", 0.25)
	monster.call("_update_anim", 0.0001)
	await _shot("stride_peak", scene)
	rig.set("_gait_phase", 0.5)
	monster.call("_update_anim", 0.0001)
	await _shot("stride_pass", scene)
	monster.set("velocity", Vector3.ZERO)
	_steps(monster, 60)

func _attack(monster: Node3D, scene: String) -> void:
	await _shot("rest", scene)
	(monster.get("_telegraph") as Node).call("cue")
	_steps(monster, 23)
	await _shot("windup", scene)
	_steps(monster, 5)
	await _shot("strike", scene)
	_steps(monster, 20)
	await _shot("recover", scene)

func _death(scene: String) -> void:
	var monster := _spawn(scene)
	monster.call("take_damage", 99999.0)
	var steps: Array[int] = [9, 15, 25]
	for i in steps.size():
		_steps(monster, steps[i])
		await _shot("death_%d" % (i + 1), scene)
	monster.queue_free()

func _run() -> void:
	_hash = OS.get_environment("TLS_FRAMES_HASH") if OS.has_environment("TLS_FRAMES_HASH") else "unknown"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_stage()
	for scene in STRIDE:
		var monster := _spawn(scene)
		await _stride(monster, scene)
		if ATTACK.has(scene):
			await _attack(monster, scene)
		monster.queue_free()
	for scene in DEATH:
		await _death(scene)
	print("[anim] DONE frames=%d" % _shots)
	get_tree().quit(0)
