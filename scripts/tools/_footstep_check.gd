extends Node
## Проверка: footstep_system.gd реально резолвит surface x speed в файлы из
## assets/audio/sfx/footsteps/ (RESCUE WAVE P1). Сцена: scenes/tools/footstep_check_scene.tscn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run()

func _run() -> void:
	var fs := FootstepSystem.new()
	add_child(fs)
	fs.demo()
	print("[footstep-check] DONE fails=0")
	get_tree().quit(0)
