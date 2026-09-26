extends Node
## Lifecycle probe for QaLaunchGuard on the real profile, driven by
## tools/check.sh's qa_guard_e2e inside the shell user-data guard:
##   -- --write  write user://qa_guard_probe.save, then quit normally
##   -- --die    write it, then kill this process (no _exit_tree, like a crash)
##   -- --noop   quit at once
## Scene: qa_guard_e2e_scene.tscn

const PROBE := "user://qa_guard_probe.save"

func _ready() -> void:
	var mode := "--noop"
	for a in OS.get_cmdline_user_args():
		mode = a
	if mode != "--noop":
		var f := FileAccess.open(PROBE, FileAccess.WRITE)
		f.store_string("qa")
		f.close()
	if mode == "--die":
		OS.kill(OS.get_process_id())
	get_tree().quit(0)
