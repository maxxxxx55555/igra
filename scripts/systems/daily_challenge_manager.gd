extends Node
## Daily challenge (GOLD MASTER v5 hooks pass): one challenge per calendar
## day, deterministically picked from data/daily_challenges.json (30
## templates) by day-of-year so every player worldwide gets the same
## challenge on the same day. Progress is session-scoped (resets when the
## day rolls over, same as the challenge itself) and driven entirely by
## EventBus signals that already fire in the live 3D game — no new
## tracking machinery. Reward + streak reuse the existing, already-
## persisted SaveSystem.get_daily_streak()/increment_daily_streak().
## Own tiny file (like LocalLeaderboard): survives New Game resets, same
## reasoning as AchievementManager.

signal progress_changed(current: int, target: int)
signal completed(reward: int)

const DATA_PATH: String = "res://data/daily_challenges.json"
const SAVE_PATH: String = "user://tls_daily.json"
const SECONDS_PER_DAY: int = 86400

var _templates: Array = []
var _streak_rewards: Array = []
var _today_id: String = ""
var _today: Dictionary = {}
var _progress: int = 0
var _completed_today: bool = false
var _last_completed_day: int = -1
var _play_seconds: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_templates()
	_load_state()
	_roll_for_today()
	EventBus.enemy_killed.connect(func(_id): _tick("kill_enemies", 1))
	EventBus.document_unlocked.connect(func(_id): _tick("find_secrets", 1))
	EventBus.streetlight_activated.connect(func(_id): _tick("light_streets", 1))
	EventBus.district_restored.connect(func(_id, _stage): _tick("restore_districts", 1))

func _process(delta: float) -> void:
	if _completed_today or _today.is_empty():
		return
	if String(_today.get("type", "")) == "play_minutes" and GameManager.is_playing():
		_play_seconds += delta
		if int(_play_seconds / 60.0) > _progress:
			_tick("play_minutes", 1)

func _load_templates() -> void:
	if not ResourceLoader.exists(DATA_PATH):
		return
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		_templates = parsed.get("templates", [])
		_streak_rewards = parsed.get("streak_rewards", [])

func _today_index() -> int:
	return int(Time.get_unix_time_from_system() / SECONDS_PER_DAY)

func _roll_for_today() -> void:
	if _templates.is_empty():
		return
	var day := _today_index()
	if day == _last_completed_day:
		_completed_today = true
	elif _today_id != "" and _today_id == _id_for_day(day):
		pass  # already rolled, progress carries within the same day
	else:
		_completed_today = false
		_progress = 0
		_play_seconds = 0.0
	_today = _templates[day % _templates.size()]
	_today_id = String(_today.get("id", ""))

func _id_for_day(day: int) -> String:
	return String(_templates[day % _templates.size()].get("id", "")) if not _templates.is_empty() else ""

func _tick(type: String, amount: int) -> void:
	if _completed_today or _today.is_empty():
		return
	if String(_today.get("type", "")) != type:
		return
	_progress = mini(_progress + amount, int(_today.get("target", 0)))
	progress_changed.emit(_progress, int(_today.get("target", 0)))
	_save_state()
	if _progress >= int(_today.get("target", 1)):
		_complete()

func _complete() -> void:
	_completed_today = true
	_last_completed_day = _today_index()
	var reward := int(_today.get("reward", 0))
	var wallet := get_node_or_null("/root/CoinWallet")
	if wallet != null and wallet.has_method("add"):
		wallet.add(reward)
	if SaveSystem != null and SaveSystem.has_method("increment_daily_streak"):
		SaveSystem.increment_daily_streak()
		reward += _streak_bonus(SaveSystem.get_daily_streak())
	completed.emit(reward)
	_save_state()

func _streak_bonus(streak: int) -> int:
	var bonus := 0
	for row in _streak_rewards:
		if streak == int(row.get("days", -1)):
			bonus += int(row.get("reward", 0))
			var wallet := get_node_or_null("/root/CoinWallet")
			if wallet != null and wallet.has_method("add"):
				wallet.add(int(row.get("reward", 0)))
	return bonus

## Public read for the main-menu card and any future UI.
func get_today() -> Dictionary:
	return _today
func get_progress() -> int:
	return _progress
func is_completed_today() -> bool:
	return _completed_today

func _save_state() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({
			"today_id": _today_id, "progress": _progress,
			"last_completed_day": _last_completed_day,
		}))

func _load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		_today_id = String(parsed.get("today_id", ""))
		_progress = int(parsed.get("progress", 0))
		_last_completed_day = int(parsed.get("last_completed_day", -1))
