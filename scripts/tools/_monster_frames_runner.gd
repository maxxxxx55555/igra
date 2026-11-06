extends "res://scripts/tools/_look_frames_runner.gd"
## Monster line-up (session 36, art pass 2): the twelve monsters in the lamplight of the suburbs' street, four to a frame at 4.5 m, the boss among them, each frame dark and then with the flashlight on, every monster
## in the peak of its stride and turned to the camera. Their AI and physics are off, so nothing moves while the frame is taken.
## Windowed: TLS_FRAMES_HASH=<label> tools/qa_sim/guarded_windowed res://scenes/tools/monster_frames_scene.tscn 300
## Frames -> .qa_logs/frames/monsters_<a|b|c>[_lit]_<label>_<UTC>.png. A saved frame proves nothing until it is read.

const BATCHES: Array = [
	["rotter", "hound", "crawler", "hunter"],
	["brute", "tvar", "destroyer", "burner"],
	["shadow", "watcher", "sharpshooter", "boss_architect"],
]
const GAP: float = 1.9
## 4.5 m from the line-up, the eyes a little above the monsters' waists.
const VIEW := {"at": Vector3(-8.0, 0.1, 18.5), "look": Vector3(-8.0, 1.2, 14.0), "pitch": -0.04, "stage": 3, "light": false}

func _run() -> void:
	if not await _enter_game():
		return
	get_window().size = Vector2i(1600, 900)
	_raise(&"suburbs", 3)
	await _transition(&"suburbs", "look")
	_freeze_monsters()
	# the line-up stands on the spawn's street, 4.5 m ahead: the fixed world spot of session 36 is inside the rebuilt blocks now
	var player := _player_node()
	var base: Vector3 = player.global_position
	var fwd := -player.global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var right := fwd.cross(Vector3.UP)
	_place({"at": base, "look": base + fwd * 4.5 + Vector3(0.0, 1.2, 0.0), "pitch": VIEW["pitch"], "stage": 3, "light": false})
	_flashlight(_player_node(), false)
	await get_tree().create_timer(3.0).timeout
	for batch in BATCHES.size():
		var row: Array[Node3D] = []
		for i in (BATCHES[batch] as Array).size():
			row.append(_stand(BATCHES[batch][i], base + fwd * 4.5 + right * (i - 1.5) * GAP, atan2(fwd.x, fwd.z)))
		await get_tree().create_timer(1.0).timeout
		await _both("monsters_" + "abc"[batch])
		for monster in row:
			monster.queue_free()
	print("[lframes] DONE hash=%s" % _hash)
	get_tree().quit(0)

## The frame at the size of the window (the parent shrinks it to 960 x 540): a shape is judged by its detail.
func _frame(state: String) -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.qa_logs/frames/"))
	var file := "%s_%s_%s.png" % [state, _hash, _utc()]
	get_tree().root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://.qa_logs/frames/" + file))
	print("[lframes] frame %s" % file)

## One monster on the street at `at`, facing the player, in the peak of its stride, its AI and physics off.
func _stand(scene: String, at: Vector3, yaw: float) -> Node3D:
	var monster := (load("res://scenes/enemies/%s_3d.tscn" % scene) as PackedScene).instantiate() as Node3D
	monster.set("_music_started", true)
	get_tree().current_scene.add_child(monster)
	var capsule := (monster.get_node("CollisionShape3D") as CollisionShape3D).shape as CapsuleShape3D
	monster.global_position = at + Vector3(0.0, capsule.height * 0.5 + 0.02, 0.0)
	monster.rotation.y = yaw  # facing the camera
	monster.set_physics_process(false)
	monster.set_process(false)
	monster.set("velocity", Vector3(0.0, 0.0, -float(monster.get("chase_speed"))))
	for _i in 40:
		monster.call("_update_anim", 1.0 / 60.0)
	(monster.get("_rig") as Node).set("_gait_phase", 0.25)
	monster.call("_update_anim", 0.0001)
	return monster
