extends Node
## Regression for scripts/core/qa_launch_guard.gd's copy/restore on a synthetic
## profile (never the real user://): round trip, and every snapshot that must be
## refused (missing, interrupted .tmp, no manifest, damaged) touches nothing.
## The launch lifecycle on the real profile is tools/check.sh's qa_guard_e2e.
## Scene: qa_guard_check_scene.tscn

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

func _untouched(base: String) -> bool:
	return _read(base + "/tls_savegame.save") == "owner-progress" and _read(base + "/saves/slot1.save") == "slot"

func _run(base: String, snap: String) -> void:
	_write(base + "/tls_savegame.save", "owner-progress")
	_write(base + "/saves/slot1.save", "slot")
	_write(base + "/logs/godot.log", "engine log")
	_check(Guard.restore(base, snap) == -1 and _untouched(base), "no snapshot: restore returns -1 and touches nothing")
	_check(Guard.snapshot(base, snap, 4242), "snapshot taken")
	_check(int(Guard.read_manifest(snap).get("pid", -1)) == 4242, "manifest records the owner pid")
	# What a QA run does: overwrite, delete, create; engine logs are not game files.
	_write(base + "/tls_savegame.save", "qa-overwrote")
	DirAccess.remove_absolute(base + "/saves/slot1.save")
	_write(base + "/tls_savegame.save.bak2", "qa-new")
	_write(base + "/logs/godot.log", "engine log 2")
	_check(Guard.restore(base, snap) == 0, "restore reports byte-identical")
	_check(_untouched(base), "overwritten save and deleted slot restored")
	_check(not FileAccess.file_exists(base + "/tls_savegame.save.bak2"), "QA-created file removed")
	_check(_read(base + "/logs/godot.log") == "engine log 2", "engine logs left alone")
	_check(not DirAccess.dir_exists_absolute(snap), "snapshot removed after a verified restore")
	# Snapshots that must never be used: each would otherwise delete the owner's files.
	_write(snap + ".tmp/files/tls_savegame.save", "half-copied")
	_check(Guard.restore(base, snap) == -1 and _untouched(base), "interrupted .tmp copy is not a snapshot")
	Guard.remove_tree(snap + ".tmp")
	_write(snap + "/files/tls_savegame.save", "no manifest")
	_check(Guard.restore(base, snap) == -2 and _untouched(base), "snapshot without a manifest is refused")
	Guard.remove_tree(snap)
	_check(Guard.snapshot(base, snap, 4242), "second snapshot taken")
	_write(snap + "/files/saves/slot1.save", "bit rot")
	_check(Guard.restore(base, snap) == -2 and _untouched(base) and DirAccess.dir_exists_absolute(snap),
		"damaged snapshot (sha256 mismatch) is refused and kept")
