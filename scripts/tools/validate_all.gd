extends SceneTree

func _init() -> void:
	var f := FileAccess.open("res://scripts/tools/validate_list.txt", FileAccess.READ)
	if f == null:
		quit(1)
		return
	var bad: Array[String] = []
	while not f.eof_reached():
		var p := f.get_line().strip_edges()
		if p == "" or p.begins_with("#"):
			continue
		var head := FileAccess.get_file_as_string(p).strip_edges()
		if head.begins_with("@tool"):
			continue
		var res: Resource = ResourceLoader.load(p, "Script", ResourceLoader.CACHE_MODE_IGNORE)
		if res == null or not (res as Script).can_instantiate():
			bad.append(p)
	f.close()
	if bad.is_empty():
		print("[validate_all] OK: all scripts compile")
		quit(0)
	for p in bad:
		print("[validate_all] BAD: ", p)
	quit(1)
