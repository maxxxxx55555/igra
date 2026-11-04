extends SceneTree

func _initialize() -> void:
	var langs := ["ru","en"]
	for lang in langs:
		var path: String = "res://data/i18n/" + lang + ".json"
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			print("VALIDATE ", lang, ": FILE ERROR")
			continue
		var parsed = JSON.parse_string(f.get_as_text())
		if parsed is Dictionary:
			var count := 0
			for k in parsed:
				count += 1
			print("VALIDATE ", lang, ": OK ", count, " keys")
		else:
			print("VALIDATE ", lang, ": INVALID JSON")
	quit()
