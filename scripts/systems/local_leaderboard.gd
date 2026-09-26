extends Node
## Local leaderboard (GOLD MASTER v5 hooks pass): records a run's time,
## kills, districts and ending on every win, kept as a small history
## independent of SaveSystem's save/reset cycle — a New Game must not
## erase a player's past best runs, same reasoning as AchievementManager
## not being touched by SaveSystem.reset_all(). Own tiny file, not the
## main save envelope.

const PATH: String = "user://tls_leaderboard.json"
const MAX_ENTRIES: int = 10

var _runs: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load()
	EventBus.game_won.connect(_on_game_won)

func _on_game_won() -> void:
	var pt := get_node_or_null("/root/ProgressTracker")
	var em := get_node_or_null("/root/EndingsManager")
	var stats: Dictionary = pt.get_stats() if pt != null else {}
	var ending: String = String(em.get_ending()) if em != null else ""
	record_run(float(stats.get("time_played", 0.0)), int(stats.get("kills", 0)),
		int(stats.get("districts", 0)), ending)

## Public so a future headless probe (or the autoplay bot) can exercise
## this without waiting on the real game_won signal chain.
func record_run(time_played: float, kills: int, districts: int, ending: String) -> void:
	_runs.append({
		"time": time_played, "kills": kills, "districts": districts,
		"ending": ending, "unix": Time.get_unix_time_from_system(),
	})
	_runs.sort_custom(func(a, b) -> bool: return a["time"] < b["time"])
	if _runs.size() > MAX_ENTRIES:
		_runs.resize(MAX_ENTRIES)
	_save()

func get_top_runs(n: int = MAX_ENTRIES) -> Array:
	return _runs.slice(0, mini(n, _runs.size()))

func has_runs() -> bool:
	return not _runs.is_empty()

func _save() -> void:
	SaveSystem.write_signed(PATH, _runs)

## SECURITY_SWEEP_V2 #5: the file was unsigned and any Array was adopted as is,
## so a hand edit showed fake records and a non-Dictionary entry raised script
## errors. A tampered signed file is rejected; a pre-rc14 plain file is trusted
## once and re-saved signed (same stance as achievements' legacy file, B7).
## Either way only well-formed entries survive, capped at MAX_ENTRIES.
func _load() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var parsed: Variant = SaveSystem.read_signed(PATH)
	var legacy := false
	if parsed == null:
		parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		legacy = parsed is Array
	if not (parsed is Array):
		return
	_runs = valid_runs(parsed)
	if legacy:
		_save()

static func valid_runs(raw: Array) -> Array:
	var out: Array = []
	for e in raw:
		if not (e is Dictionary):
			continue
		var ok := true
		for k in ["time", "kills", "districts", "unix"]:
			if not (e.get(k) is float or e.get(k) is int) or float(e.get(k)) < 0.0:
				ok = false
		if ok:
			out.append({"time": float(e["time"]), "kills": int(e["kills"]), "districts": clampi(int(e["districts"]), 0, 11),
				"ending": String(e.get("ending", "")), "unix": float(e["unix"])})
	out.sort_custom(func(a, b) -> bool: return a["time"] < b["time"])
	if out.size() > MAX_ENTRIES:
		out.resize(MAX_ENTRIES)
	return out
