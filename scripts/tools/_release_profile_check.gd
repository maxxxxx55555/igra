extends Node
## The build pipeline queries its disposable profile before any mutating QA gate.

func _ready() -> void:
	var name_: String = str(ProjectSettings.get_setting("application/config/name", ""))
	var custom: String = str(ProjectSettings.get_setting("application/config/custom_user_dir_name", ""))
	if not name_.begins_with("__TLS_QA_") or custom != name_:
		printerr("[release-profile] disposable profile configuration required")
		get_tree().quit(1)
		return
	print("[release-profile] ", JSON.stringify({"name": name_, "path": OS.get_user_data_dir()}))
	print("[release-profile] DONE fails=0")
	get_tree().quit(0)
