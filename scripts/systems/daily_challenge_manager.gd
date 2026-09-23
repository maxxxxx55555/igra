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
## Серия пройденных дней перевалила за веху из streak_rewards.
signal streak_milestone(days: int)

## Контент-пасс retention принёс 60 шаблонов в content/daily_challenges.json
## (было 30 в data/). Читаем контентный файл, если он есть, и откатываемся на
## старый — на случай частичного чекаута без content/.
const DATA_PATH: String = "res://content/daily_challenges.json"
const DATA_PATH_LEGACY: String = "res://data/daily_challenges.json"
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
## no_flashlight_segment: отрезок — SEGMENT_SECONDS подряд с выключенным
## фонарём. Любое включение обнуляет накопленное, иначе «отрезок» набирался бы
## мерцанием. Стадия района не проверяется намеренно: пройти тёмный район без
## фонаря — как раз то, что ежедневка просит.
const SEGMENT_SECONDS: float = 30.0
var _flashlight_on: bool = false
var _dark_seconds: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_templates()
	_load_state()
	_roll_for_today()
	EventBus.enemy_killed.connect(func(_id): _tick("kill_enemies", 1))
	# "find_secrets" считает и документы, и собственно секреты. Раньше секреты
	# было физически не найти (secret.gd был 2D-нодой и не попадал в
	# интерактивы), поэтому счёт шёл только по документам; теперь настоящая
	# находка тоже обязана двигать ежедневку. Документы при этом остаются:
	# их в игре около сотни против 26 секретов, а цели доходят до 24 в день.
	EventBus.document_unlocked.connect(func(_id): _tick("find_secrets", 1))
	EventBus.secret_found.connect(func(_id): _tick("find_secrets", 1))
	EventBus.streetlight_activated.connect(func(_id): _tick("light_streets", 1))
	EventBus.district_restored.connect(func(_id, _stage): _tick("restore_districts", 1))
	EventBus.photo_captured.connect(func(_path): _tick("photo_subject", 1))
	EventBus.flashlight_state_changed.connect(func(on: bool) -> void:
		_flashlight_on = on
		_dark_seconds = 0.0)

func _process(delta: float) -> void:
	if _completed_today or _today.is_empty():
		return
	if not GameManager.is_playing():
		return
	if String(_today.get("type", "")) == "play_minutes":
		_play_seconds += delta
		if int(_play_seconds / 60.0) > _progress:
			_tick("play_minutes", 1)
	elif String(_today.get("type", "")) == "no_flashlight_segment" and not _flashlight_on:
		_dark_seconds += delta
		if _dark_seconds >= SEGMENT_SECONDS:
			_dark_seconds = 0.0
			_tick("no_flashlight_segment", 1)

func _load_templates() -> void:
	var path := DATA_PATH if ResourceLoader.exists(DATA_PATH) else DATA_PATH_LEGACY
	if not ResourceLoader.exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
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
			streak_milestone.emit(streak)
	return bonus

## Public read for the main-menu card and any future UI.
func get_today() -> Dictionary:
	return _today
func get_progress() -> int:
	return _progress
func is_completed_today() -> bool:
	return _completed_today

## BREAK_REPORT B6: this was plain JSON. Deleting the file reset
## _last_completed_day to its default -1 (never assigned when the file is
## missing), which reads as "not completed today" for any real calendar
## day, letting the same day's challenge (and its coin payout, and streak
## increments each still-same-day completion feeds) be claimed again by
## deleting one file. Same fix as achievements_manager.gd already applies
## to its own separate small file: sign with SaveSystem's existing
## static _sign() (same key/algorithm, no second signing mechanism) rather
## than merge into the main per-slot save - this state is deliberately
## profile-independent (survives New Game, see this file's own header).
## No legacy-plain-json trust-once compat: this system is recent enough
## (GOLD MASTER v5) that there's no real installed base to protect, and a
## missing/forged file just re-rolls today once, same low-cost failure
## mode as a first launch - unlike the main save (B4), there's no case
## here where rejecting outright is a real cost worth a compat exception.
func _save_state() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		var body: String = JSON.stringify({
			"today_id": _today_id, "progress": _progress,
			"last_completed_day": _last_completed_day,
		})
		f.store_string(JSON.stringify({"hmac": SaveSystem.call("_sign", body), "data_json": body}))

func _load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var envelope = JSON.parse_string(f.get_as_text())
	if not (envelope is Dictionary) or not envelope.has("hmac") or not envelope.has("data_json"):
		return
	if String(envelope["hmac"]) != String(SaveSystem.call("_sign", envelope["data_json"])):
		return
	var parsed = JSON.parse_string(String(envelope["data_json"]))
	if parsed is Dictionary:
		_today_id = String(parsed.get("today_id", ""))
		_progress = int(parsed.get("progress", 0))
		_last_completed_day = int(parsed.get("last_completed_day", -1))
