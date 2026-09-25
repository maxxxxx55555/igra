extends RefCounted
## In-process twin of tools/qa_sim/user_data_guard.sh, for QA runners that are
## launched directly instead of through check.sh / headless_suite /
## autoplay_bot. take() copies the game's own user:// files (top level +
## saves/) before the run touches them; restore() writes them back and
## verifies each byte. It only removes files the run itself created, and a
## snapshot with any unreadable file is null, which restore() refuses.

const DIRS: Array[String] = ["user://", "user://saves/"]

static func _list() -> Array[String]:
	var out: Array[String] = []
	for dir in DIRS:
		if DirAccess.dir_exists_absolute(dir):
			for f in DirAccess.get_files_at(dir):
				out.append(dir + f)
	return out

static func take() -> Variant:
	var snap := {}
	for p in _list():
		var bytes := FileAccess.get_file_as_bytes(p)
		if FileAccess.get_open_error() != OK:
			push_error("user-data snapshot: cannot read %s - snapshot abandoned" % p)
			return null
		snap[p] = bytes
	return snap

## Number of files that are not byte-identical afterwards (0 = restored);
## -1 when there is no valid snapshot (nothing is touched then).
static func restore(snap: Variant) -> int:
	if not (snap is Dictionary):
		return -1
	for p in _list():
		if not snap.has(p):
			DirAccess.remove_absolute(p)
	var bad := 0
	for p in snap:
		DirAccess.make_dir_recursive_absolute(String(p).get_base_dir())
		var f := FileAccess.open(p, FileAccess.WRITE)
		if f == null:
			bad += 1
			continue
		f.store_buffer(snap[p])
		f.close()
		if FileAccess.get_file_as_bytes(p) != snap[p]:
			bad += 1
	if _list().size() != snap.size():
		bad += 1
	return bad
