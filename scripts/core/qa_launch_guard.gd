extends Node
## QA scenes (res://scenes/tools/*, ShotTool's --shot/--shot-scenario) run the
## real game on the owner's user:// profile: New Game (reset_all), autosave,
## forged cfgs. When one is launched without tools/qa_sim/user_data_guard.sh
## around it (TLS_UDG_GUARDED unset), this autoload - registered first - copies
## the game's own files (top level + saves/) to "<profile>.qa_snapshot" before
## any other autoload or the scene runs, and writes them back byte-identical
## when the tree exits. The copy stays on disk until a verified restore, so a
## crash or kill loses nothing: the next unguarded launch restores it first.

const SNAPSHOT_SUFFIX := ".qa_snapshot"
const SUBDIRS: Array[String] = ["", "saves/"]

var _owned_snapshot: String = ""

func _enter_tree() -> void:
	var base := OS.get_user_data_dir()
	var snap := base + SNAPSHOT_SUFFIX
	var guarded := OS.get_environment("TLS_UDG_GUARDED") == "1"
	# An interrupted copy never got as far as the QA scene: the profile is untouched.
	remove_tree(snap + ".tmp")
	if DirAccess.dir_exists_absolute(snap):
		if guarded:
			# The shell guard has already copied the current (dirty) profile and would
			# put it back over a recovery made here - leave the copy for the next launch.
			push_warning("[qa-guard] %s holds the profile from an interrupted QA run; it is restored on the next unguarded launch" % snap)
		else:
			var bad := restore(base, snap)
			if bad == 0:
				print("[qa-guard] restored the profile left by an interrupted QA run")
			else:
				push_error("[qa-guard] could not restore %s (%d mismatch(es)); the copy is kept" % [snap, bad])
	if guarded or not _is_qa_launch() or DirAccess.dir_exists_absolute(snap):
		return
	if snapshot(base, snap):
		_owned_snapshot = snap
	else:
		push_error("[qa-guard] cannot copy the profile - quitting before the QA scene runs")
		get_tree().quit(3)

func _exit_tree() -> void:
	if _owned_snapshot == "":
		return
	var bad := restore(OS.get_user_data_dir(), _owned_snapshot)
	if bad == 0:
		print("[qa-guard] profile restored byte-identical")
	else:
		push_error("[qa-guard] FAIL restore: %d mismatch(es); the copy is kept at %s" % [bad, _owned_snapshot])

static func _is_qa_launch() -> bool:
	for a in OS.get_cmdline_args() + OS.get_cmdline_user_args():
		if a.contains("scenes/tools/") or a.begins_with("--shot"):
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

## Copies base's files into snap. The copy is built in snap + ".tmp" and renamed
## only when complete, so an interrupted copy is never taken for a snapshot.
static func snapshot(base: String, snap: String) -> bool:
	var tmp := snap + ".tmp"
	remove_tree(tmp)
	DirAccess.make_dir_recursive_absolute(tmp + "/saves")
	for rel in files(base):
		if DirAccess.copy_absolute(base + "/" + rel, tmp + "/" + rel) != OK:
			remove_tree(tmp)
			return false
	return DirAccess.rename_absolute(tmp, snap) == OK

## Writes snap back over base, removes base files the snapshot does not have,
## verifies every byte, and deletes snap only when everything matched.
## Returns the mismatch count (0 = restored); -1 = no snapshot, nothing touched.
static func restore(base: String, snap: String) -> int:
	if not DirAccess.dir_exists_absolute(snap):
		return -1
	var wanted := files(snap)
	for rel in files(base):
		if not wanted.has(rel):
			DirAccess.remove_absolute(base + "/" + rel)
	var bad := 0
	for rel in wanted:
		DirAccess.make_dir_recursive_absolute((base + "/" + rel).get_base_dir())
		if DirAccess.copy_absolute(snap + "/" + rel, base + "/" + rel) != OK \
				or FileAccess.get_file_as_bytes(base + "/" + rel) != FileAccess.get_file_as_bytes(snap + "/" + rel):
			bad += 1
	if files(base) != wanted:
		bad += 1
	if bad == 0:
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
