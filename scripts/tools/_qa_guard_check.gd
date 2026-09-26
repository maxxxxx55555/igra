extends Node
## Regression for scripts/core/qa_launch_guard.gd on a synthetic profile (never the
## real user://): snapshot/restore round trip, an interrupted copy is not taken for
## a snapshot, a missing snapshot touches nothing. Scene: qa_guard_check_scene.tscn

const Guard := preload("res://scripts/core/qa_launch_guard.gd")

var _fails: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := OS.get_cache_dir() + "/tls_qa_guard_check_%d" % OS.get_process_id()
	Guard.remove_tree(root)
	_run(root + "/profile", root + "/profile" + Guard.SNAPSHOT_SUFFIX)
	Guard.remove_tree(root)
	print("[qa-guard-check] DONE fails=%d" % _fails)
	get_tree().quit(0 if _fails == 0 else 1)

func _check(cond: bool, what: String) -> void:
	if not cond:
		_fails += 1
	print("[qa-guard-check] %s %s" % ["OK  " if cond else "FAIL", what])

func _write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()

func _read(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else "<missing>"

func _run(base: String, snap: String) -> void:
	_write(base + "/tls_savegame.save", "owner-progress")
	_write(base + "/saves/slot1.save", "slot")
	_write(base + "/logs/godot.log", "engine log")
	_check(Guard.restore(base, snap) == -1 and _read(base + "/tls_savegame.save") == "owner-progress",
		"no snapshot: restore returns -1 and touches nothing")
	_check(Guard.snapshot(base, snap), "snapshot taken")
	# What a QA run does: overwrite, delete, create; engine logs are not game files.
	_write(base + "/tls_savegame.save", "qa-overwrote")
	DirAccess.remove_absolute(base + "/saves/slot1.save")
	_write(base + "/tls_savegame.save.bak2", "qa-new")
	_write(base + "/logs/godot.log", "engine log 2")
	_check(Guard.restore(base, snap) == 0, "restore reports byte-identical")
	_check(_read(base + "/tls_savegame.save") == "owner-progress", "overwritten save restored")
	_check(_read(base + "/saves/slot1.save") == "slot", "deleted slot restored")
	_check(not FileAccess.file_exists(base + "/tls_savegame.save.bak2"), "QA-created file removed")
	_check(_read(base + "/logs/godot.log") == "engine log 2", "engine logs left alone")
	_check(not DirAccess.dir_exists_absolute(snap), "snapshot removed after a verified restore")
	# An interrupted copy (.tmp, never renamed) must not be restored over the profile.
	_write(snap + ".tmp/tls_savegame.save", "half-copied")
	_check(Guard.restore(base, snap) == -1 and _read(base + "/tls_savegame.save") == "owner-progress",
		"interrupted .tmp copy is not taken for a snapshot")
