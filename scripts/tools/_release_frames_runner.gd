extends "res://scripts/tools/_final_frames_runner.gd"
## Fresh canonical release evidence, including the UI over the world effects.

const FRAMES: Array[String] = ["01_main_menu", "02_district_day_full", "03_district_night_dark", "04_combat", "05_boss", "06_victory_ngplus", "07_skill_tree", "08_shop"]

func _capture(frame: String, _half: bool) -> void:
	if frame not in FRAMES:
		return
	print("[release-frames] capture begin " + frame)
	var hash_: String = OS.get_environment("TLS_CAPTURE_HASH")
	if hash_.is_empty():
		printerr("[release-frames] committed runtime hash required")
		get_tree().quit(1)
		return
	RenderingServer.force_draw.call_deferred()
	await RenderingServer.frame_post_draw
	var stamp: String = Time.get_datetime_string_from_system(true).replace("-", "").replace(":", "") + "Z"
	var dir_: String = "res://docs/stills/mega_release/"
	DirAccess.make_dir_recursive_absolute(dir_)
	var image_: Image = get_tree().root.get_texture().get_image()
	var result: Error = image_.save_png(dir_ + "%s_after_%s_%s.png" % [frame, hash_, stamp])
	print("[release-frames] frame %s result=%d" % [frame, result])
	if result != OK:
		get_tree().quit(1)
