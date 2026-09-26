extends Node
## QA launches (a scene or script under a tools/ folder, ShotTool's --shot and
## --shot-scenario) run the real game on the owner's user:// profile: New Game
## (reset_all), autosave, forged cfgs. When one starts without
## tools/qa_sim/user_data_guard.sh around it (TLS_UDG_GUARDED unset), this
## autoload - registered first - copies the game's own files (top level +
## saves/) to "<profile>.qa_snapshot" before any other autoload or the scene
## runs, and writes them back byte-identical when the tree exits.
##
## The copy carries a manifest (sha256 per file, owner pid), written last and
## made visible by an atomic rename, so an interrupted copy is never used. It
## stays on disk until a verified restore; a crash or kill therefore loses
## nothing, and the next unguarded launch (normal play included) restores it
## first. If the copy cannot be made, the process aborts on the spot
## (OS.crash: quit() would still let the QA scene's first frame run). A copy
## that cannot be restored (damaged, owned by a live QA run, or a failed
## restore) stops normal play too: its saves would be reverted by the restore
## that follows. Release exports carry no tools/ and are never QA launches, so
## the guard does nothing there (a player's --shot must not make a session
## revertible or reach OS.crash).

const SNAPSHOT_SUFFIX := ".qa_snapshot"
const SUBDIRS: Array[String] = ["", "saves/"]
const MANIFEST := "manifest.json"

var _owned_snapshot: String = ""

func _enter_tree() -> void:
	if not OS.is_debug_build():
		return
	# ShotTool lives in export-excluded scripts/tools/, so as an autoload it made every
	# release boot log "Failed to instantiate an autoload"; load it on demand instead.
	if _has_arg("--shot"):
		var shot: Node = load("res://scripts/tools/shot_tool.gd").new()
		shot.name = "ShotTool"
		get_tree().root.add_child.call_deferred(shot)
	var base := OS.get_user_data_dir()
	var snap := base + SNAPSHOT_SUFFIX
	var guarded := OS.get_environment("TLS_UDG_GUARDED") == "1"
	var qa := _is_qa_launch()
	# Leftovers that can never hold owner data: an interrupted copy (.tmp, never
	# renamed) and an interrupted discard (a copy whose manifest was already
	# deleted after a verified restore).
	remove_tree(snap + ".tmp")
	if DirAccess.dir_exists_absolute(snap) and not FileAccess.file_exists(snap + "/" + MANIFEST):
		remove_tree(snap)
	if DirAccess.dir_exists_absolute(snap):
		var manifest := read_manifest(snap)
		var pid := int(manifest.get("pid", -1))
		if manifest.is_empty():
			_block("%s is damaged (a file no longer matches its manifest); it is kept for manual recovery" % snap)
		elif pid != OS.get_process_id() and OS.is_process_running(pid):
			_block("another QA run (pid %d) owns %s; wait for it to exit" % [pid, snap])
		elif guarded:
			# The shell guard copied the current (dirty) profile and would put it back
			# over a recovery made here - leave the copy for the next unguarded launch.
			push_warning("[qa-guard] %s holds the profile from an interrupted QA run; it is restored on the next unguarded launch" % snap)
		else:
			var bad := restore(base, snap)
			if bad == 0:
				print("[qa-guard] restored the profile left by an interrupted QA run")
			else:
				_block("could not restore %s (%d mismatch(es)); the copy is kept" % [snap, bad])
	if guarded or not qa or DirAccess.dir_exists_absolute(snap):
		return
	if snapshot(base, snap, OS.get_process_id()):
		_owned_snapshot = snap
	else:
		_block("cannot copy the profile to %s" % snap)

func _exit_tree() -> void:
	if _owned_snapshot == "":
		return
	var bad := restore(OS.get_user_data_dir(), _owned_snapshot)
	if bad == 0:
		print("[qa-guard] profile restored byte-identical")
	else:
		push_error("[qa-guard] FAIL restore: %d mismatch(es); the copy is kept at %s" % [bad, _owned_snapshot])

## Nothing may reach its first frame on a profile that is not protected.
func _block(why: String) -> void:
	printerr("[qa-guard] ABORT: " + why + " - no launch runs until the profile is restored")
	OS.crash("[qa-guard] ABORT: " + why)

static func _has_arg(prefix: String) -> bool:
	for a in OS.get_cmdline_args() + OS.get_cmdline_user_args():
		if a.begins_with(prefix):
			return true
	return false

static func _is_qa_launch() -> bool:
	for a in OS.get_cmdline_args() + OS.get_cmdline_user_args():
		if a.begins_with("--shot"):
			return true
		if (a.ends_with(".tscn") or a.ends_with(".gd")) and (a.contains("/tools/") or a.begins_with("tools/")):
			return true
	return false

## Relative paths of the game's own files under dir: top level + saves/.
static func files(dir: String) -> Array[String]:
	var out: Array[String] = []
	for sub in SUBDIRS:
		if DirAccess.dir_exists_absolute(dir + "/" + sub):
			for f in DirAccess.get_files_at(dir + "/" + sub):
				out.append(sub + f)
	out.sort()
	return out

## Copies base's files into snap/files with a verified sha256 manifest. Built in
## snap + ".tmp" and renamed only when complete.
static func snapshot(base: String, snap: String, pid: int) -> bool:
	var tmp := snap + ".tmp"
	remove_tree(tmp)
	var sums := {}
	for rel in files(base):
		var dst := tmp + "/files/" + rel
		DirAccess.make_dir_recursive_absolute(dst.get_base_dir())
		var sum := FileAccess.get_sha256(base + "/" + rel)
		if sum == "" or DirAccess.copy_absolute(base + "/" + rel, dst) != OK or FileAccess.get_sha256(dst) != sum:
			remove_tree(tmp)
			return false
		sums[rel] = sum
	DirAccess.make_dir_recursive_absolute(tmp)
	var f := FileAccess.open(tmp + "/" + MANIFEST, FileAccess.WRITE)
	if f == null:
		remove_tree(tmp)
		return false
	f.store_string(JSON.stringify({"pid": pid, "files": sums}))
	f.close()
	return DirAccess.rename_absolute(tmp, snap) == OK

## The manifest when snap is complete and every file still matches it, else {}.
static func read_manifest(snap: String) -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(snap + "/" + MANIFEST))
	if not (data is Dictionary) or not (data.get("files") is Dictionary):
		return {}
	for rel in data["files"]:
		if FileAccess.get_sha256(snap + "/files/" + String(rel)) != String(data["files"][rel]):
			return {}
	return data

## Writes a verified snapshot back over base, removes base files it does not
## list, checks every sha256, and discards the snapshot only when all matched
## (manifest first, so an interrupted discard is recognisable).
## Returns the mismatch count (0 = restored); -1 = no snapshot, -2 = incomplete or
## damaged snapshot. On -1/-2 nothing is touched.
static func restore(base: String, snap: String) -> int:
	if not DirAccess.dir_exists_absolute(snap):
		return -1
	var manifest := read_manifest(snap)
	if manifest.is_empty():
		return -2
	var sums: Dictionary = manifest["files"]
	var wanted: Array[String] = []
	for rel in sums:
		wanted.append(String(rel))
	wanted.sort()
	for rel in files(base):
		if not wanted.has(rel):
			DirAccess.remove_absolute(base + "/" + rel)
	var bad := 0
	for rel in wanted:
		DirAccess.make_dir_recursive_absolute((base + "/" + rel).get_base_dir())
		if DirAccess.copy_absolute(snap + "/files/" + rel, base + "/" + rel) != OK \
				or FileAccess.get_sha256(base + "/" + rel) != String(sums[rel]):
			bad += 1
	if files(base) != wanted:
		bad += 1
	if bad == 0:
		DirAccess.remove_absolute(snap + "/" + MANIFEST)
		remove_tree(snap)
	return bad

## Deletes a directory this guard created (a snapshot or its .tmp) and its contents.
static func remove_tree(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for sub in DirAccess.get_directories_at(dir):
		remove_tree(dir + "/" + sub)
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir + "/" + f)
	DirAccess.remove_absolute(dir)
