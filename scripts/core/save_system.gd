extends Node

const SAVE_PATH: String = "user://tls_savegame.save"
const SAVE_VERSION: int = 3
const AUTOSAVE_INTERVAL: float = 30.0
const MAX_SLOTS: int = 4

## RELEASE CONVERGENCE STEP 5 (anti-tamper): the T16 "checksum" was a plain
## SHA-256 of the body — proves *corruption* (bit rot, truncated write) but
## not *authenticity*: anyone can hand-edit data_json and recompute a
## matching sha256_text() with no secret needed. HMAC-SHA256 needs this key
## to produce a valid signature, so a save-editor now has to find the key in
## the binary first, not just re-hash. Honest scope, documented once here so
## it isn't re-litigated per call site: this is a SPEED BUMP, not real
## anti-cheat. The key ships inside the client for an offline single-player
## game with no server to hold a real secret — anyone willing to decompile
## the binary can still forge a signed save. Real server-side anti-cheat is
## impossible without a backend this game doesn't have (see
## docs/KNOWN_ISSUES.md). This still stops the common case (a text editor on
## the JSON) which the old plain hash didn't.
const _HMAC_KEY: String = "TLS-savegame-v1-4f1c9e6b2a8d5f03"

static func _sign(body: String) -> String:
	return Crypto.new().hmac_digest(HashingContext.HASH_SHA256, _HMAC_KEY.to_utf8_buffer(), body.to_utf8_buffer()).hex_encode()

## RELEASE CONVERGENCE STEP 6 (anti "lost phone"): the live save is the one
## Continue reads (SAVE_PATH, via has_save()/load_all()) - the 4-slot API
## below already carries a static-audit note that its own UI is archived/
## unreachable, so export/import targets SAVE_PATH only, not the slots.
## No native Android share-sheet plugin exists in this project (same
## honest scope as win_screen.gd's clipboard Share) - this writes a real
## file to the OS's own Downloads folder, which the player moves to a new
## device however they like (their file manager, a cloud-drive app, a
## cable), then Import reads it back from that same folder. Documented
## owner-facing flow: RELEASE_CHECKLIST.md.
const EXPORT_FILENAME: String = "tls_save_export.json"

## src_path/dest_path/filename default to the real save + real export name;
## _save_integrity_check.gd's fuzz-style gate overrides them to a scratch
## file instead, the same reason its other checks use _SLOT=97 instead of a
## real slot - this must never be able to touch a developer's actual save.
func _export_path(filename: String = EXPORT_FILENAME) -> String:
	return OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS).path_join(filename)

func export_save_to_file(src_path: String = SAVE_PATH, filename: String = EXPORT_FILENAME) -> bool:
	if not FileAccess.file_exists(src_path):
		return false
	var err := DirAccess.copy_absolute(src_path, _export_path(filename))
	return err == OK

## Validates the exported file is a genuine, signature-passing save
## envelope before touching anything - a garbage/foreign file in Downloads
## named the same never reaches dest_path. Backs up the current save to
## .bak first (the same convention _write_atomic() already uses), so an
## accidental import is recoverable the same way a corrupt autosave is.
func import_save_from_file(dest_path: String = SAVE_PATH, filename: String = EXPORT_FILENAME) -> bool:
	var path := _export_path(filename)
	if not FileAccess.file_exists(path) or _read_envelope(path).is_empty():
		return false
	if FileAccess.file_exists(dest_path):
		DirAccess.copy_absolute(dest_path, dest_path + ".bak")
	if DirAccess.copy_absolute(path, dest_path) != OK:
		return false
	# BREAK_REPORT B13: this used to only overwrite the file on disk. The
	# live session's in-memory state never changed, so the next
	# district-enter/secret/puzzle/purchase autosave (_save(), below)
	# immediately clobbered the import with the stale pre-import state.
	if dest_path == SAVE_PATH:
		load_all()
	return true

var _pending_player_pos: Vector3 = Vector3.INF
var _autosave_timer: float = AUTOSAVE_INTERVAL
var _quest_data: Dictionary = {}
var _photos: Array = []
var _daily_streak: int = 0
var _last_daily_time: int = 0
## P1 (FINAL INTEGRATION wave): "seen the onboarding overlay" - deliberately
## NOT touched by reset_all() (a "New Game" reset re-runs progress/inventory/
## quests, not "has this player ever seen the tutorial"), so it survives
## across New Game resets on the same save slot and only ever shows once.
var _onboard_done: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.district_restored.connect(func(_a, _b): _save())
	EventBus.puzzle_solved.connect(func(_a, _b): _save())
	EventBus.purchase_success.connect(func(_a): _save())
	EventBus.secret_found.connect(func(_a): _save())

func _process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	_autosave_timer -= delta
	if _autosave_timer <= 0.0:
		_autosave_timer = AUTOSAVE_INTERVAL
		# BREAK_REPORT B13: this used to write save_slot(4), a slot Continue
		# (load_all() / SAVE_PATH) never reads - the multi-slot picker UI
		# that could load it was archived, so the timer protected nothing.
		# A crash rolled back to the last event-driven _save() (travel,
		# secret, puzzle, purchase), not to within 30 seconds. Writing the
		# real save here is what "protects a crash" actually requires.
		_save()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

## T16: сейв-целостность. Раньше JSON писался напрямую в целевой файл —
## обрыв игры/питания посреди записи оставлял битый .save без возможности
## восстановления. Теперь: temp+rename (атомарно), SHA-256 в конверте,
## .bak — копия предыдущего валидного сейва на случай, если новый бит.

## FINAL HARDENING PASS (STEP 4 anti-tamper): districts-lit + progress
## (documents/secrets - what Endings.evaluate() actually keys off of) get
## their OWN signature, independent of the whole-envelope one below.
## Honest scope: today this is mostly redundant with the outer HMAC
## (both cover consistently-signed data), EXCEPT for the one gap that
## makes it worth having - the outer envelope's backward-compat path
## (_read_envelope) still accepts a pre-HMAC save signed with the old
## unkeyed sha256_text() "checksum" field. A save downgraded to that old
## field name could otherwise have power/progress edited freely and
## re-hashed with no secret needed; this second, independent signature on
## exactly the ending-determining fields still needs the real key even
## then. Verified in _read_envelope() below; a mismatch resets power/
## progress to empty rather than trusting a forged win.
## Signs a JSON round-tripped copy so write and verify see the same text:
## the writer holds ints (stage 2), the verifier holds what JSON.parse gives
## back (2.0), and stringify(2) != stringify(2.0). Signing the raw dict made
## every load fail this check and silently reset all district power and
## ProgressTracker data (found by the G16 respawn regression, suite P2r).
func _sign_progress(power: Dictionary, progress: Dictionary) -> String:
	var canon: Variant = JSON.parse_string(JSON.stringify({"power": power, "progress": progress}))
	return _sign(JSON.stringify(canon))

func _write_atomic(path: String, payload: Dictionary) -> bool:
	if payload.has("power") or payload.has("progress"):
		payload = payload.duplicate()
		payload["progress_hmac"] = _sign_progress(payload.get("power", {}), payload.get("progress", {}))
	# checksum считаем от ТОЙ ЖЕ строки, что попадёт на диск как data_json —
	# JSON.parse превращает int в float, так что пересчёт чек-суммы после
	# парсинга payload заново в stringify() никогда бы не совпал с исходной.
	var body := JSON.stringify(payload)
	var envelope := {"hmac": _sign(body), "data_json": body}
	var tmp_path := path + ".tmp"
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(envelope))
	f.close()
	if FileAccess.file_exists(path):
		_rotate_backups(path)
	var err := DirAccess.rename_absolute(tmp_path, path)
	return err == OK

## STEP 4 anti-tamper: keep the last 3 autosaves, not just 1 - a single
## .bak doesn't help if corruption strikes twice in a row (two autosaves
## after a disk starts failing, or a crash mid-write followed immediately
## by another autosave attempt before anyone notices). .bak = newest,
## .bak3 = oldest of the 3 kept.
const BACKUP_DEPTH: int = 3
func _rotate_backups(path: String) -> void:
	for i in range(BACKUP_DEPTH, 1, -1):
		var src: String = path + (".bak" if i == 2 else ".bak%d" % (i - 1))
		if FileAccess.file_exists(src):
			DirAccess.copy_absolute(src, path + ".bak%d" % i)
	DirAccess.copy_absolute(path, path + ".bak")

## Читает и проверяет конверт по указанному пути; {} если файла нет,
## JSON битый, чек-сумма не сошлась или версия сейва новее движка.
## reason выводится через print() у вызывающей стороны — сама функция
## только классифицирует, чтобы не дублировать текст на каждый return.
func _read_envelope(path: String, out_reason: Array = []) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		if not out_reason.is_empty(): out_reason[0] = "не открылся"
		return {}
	var txt := f.get_as_text()
	f.close()
	var outer := JSON.new()
	if outer.parse(txt) != OK or not (outer.data is Dictionary):
		if not out_reason.is_empty(): out_reason[0] = "битый JSON"
		return {}
	var envelope: Dictionary = outer.data
	var body: String = String(envelope.get("data_json", ""))
	if body.is_empty():
		if not out_reason.is_empty(): out_reason[0] = "не совпала чек-сумма"
		return {}
	# BREAK_REPORT B4 / SECURITY_PATCH_SPEC P-01: the old "checksum" (plain
	# sha256_text(), no key) compat path let anyone forge a save by setting
	# checksum to their own edited body's hash - no secret required at all.
	# There is no cryptographic way to tell an authentic pre-patch legacy
	# file from a forged one, so per the studio-lead directive this is now
	# a real rejection, not a one-time trust: a save without a real "hmac"
	# never loads. This does orphan any genuinely legitimate save written
	# before HMAC signing existed - a real cost, not a free fix (see
	# docs/SECURITY_PATCH_SPEC.md P-01's own "riskiest assumption").
	if not envelope.has("hmac") or _sign(body) != String(envelope["hmac"]):
		if not out_reason.is_empty(): out_reason[0] = "не совпала чек-сумма"
		return {}
	var inner := JSON.new()
	if inner.parse(body) != OK or not (inner.data is Dictionary):
		if not out_reason.is_empty(): out_reason[0] = "битый data_json"
		return {}
	var data: Dictionary = inner.data
	if int(data.get("version", 0)) > SAVE_VERSION:
		if not out_reason.is_empty(): out_reason[0] = "версия сейва новее билда"
		return {}
	data = _verify_progress(data)
	return _migrate(data)

## STEP 4 anti-tamper: recomputes _sign_progress() over the loaded power/
## progress fields and compares to the stored progress_hmac.
## BREAK_REPORT B4: a save with no progress_hmac at all used to skip this
## check entirely and trust power/progress unverified - the exact same
## "just omit the field" bypass as the outer envelope's legacy checksum
## (P-01). Missing the field is now treated the same as failing the check:
## power/progress get reset to empty rather than trusted either way.
func _verify_progress(data: Dictionary) -> Dictionary:
	var expected: String = _sign_progress(data.get("power", {}), data.get("progress", {}))
	if not data.has("progress_hmac") or expected != String(data["progress_hmac"]):
		push_warning("[SaveSystem] district/progress данные не прошли отдельную проверку подписи — сброшены")
		data["power"] = {}
		data["progress"] = {}
	return data

## Save-file versioning (STEP 4): a hook for the next real schema change,
## not a claim one has happened yet. Versions 1-3 have been additive-only
## (new keys read with a safe .get() default elsewhere in this file and in
## every *.from_dict()/load_data() this session touched) - nothing to
## transform. Runs on every load regardless, so the mechanism exists
## before it's needed under time pressure rather than being invented then.
func _migrate(data: Dictionary) -> Dictionary:
	var from_version: int = int(data.get("version", 1))
	if from_version >= SAVE_VERSION:
		return data
	# match from_version:
	#   1: data = _migrate_v1_to_v2(data)  # (no such change has shipped yet)
	data["version"] = SAVE_VERSION
	return data

## Основной файл -> .bak при провале основного (битый/пустой) -> {}.
## TRUTH WAVE P0.2: раньше провал был полностью тихим — залипший битый
## файл никак не давал о себе знать в логах, и следующая загрузка снова
## молча пыталась его прочитать. Теперь: лог о причине, а если и .bak не
## читается — карантин (переименование в .corrupt-<unix>), чтобы файл не
## путался под ногами при следующей попытке и чтобы это было видно на диске.
func _read_validated(path: String) -> Dictionary:
	var main_reason := [""]
	var data := _read_envelope(path, main_reason)
	if not data.is_empty():
		return data
	if main_reason[0] != "":
		push_warning("[SaveSystem] основной сейв не читается (", main_reason[0], "): ", path, " — пробую резервные")
	# STEP 4: try all 3 rotated backups, newest first, not just .bak.
	for i in range(1, BACKUP_DEPTH + 1):
		var suffix: String = ".bak" if i == 1 else ".bak%d" % i
		var bak_reason := [""]
		data = _read_envelope(path + suffix, bak_reason)
		if not data.is_empty():
			push_warning("[SaveSystem] восстановлено из ", suffix, ": ", path)
			return data
	if main_reason[0] != "" and FileAccess.file_exists(path):
		var quarantine := path + ".corrupt-" + str(Time.get_unix_time_from_system())
		DirAccess.rename_absolute(path, quarantine)
		push_warning("[SaveSystem] сейв и резервные копии не читаются — карантин в ", quarantine, ", старт с чистого состояния")
	return {}

func set_checkpoint(_scene_path: String, pos: Vector3) -> void:
	_pending_player_pos = pos
	_save()

func save_all() -> void:
	_save()

func _save() -> void:
	var payload: Dictionary = {
		"version": SAVE_VERSION,
		"wallet": CoinWallet.to_dict(),
		"shop": ShopService.to_dict(),
		"upgrades": UpgradeSystem.to_dict(),
		"inventory": InventoryManager.to_dict(),
		"power": PowerGrid.to_dict(),
		"encyclopedia": Encyclopedia.to_dict(),
		"progress": ProgressTracker.to_dict(),
		"settings": SettingsManager.to_dict(),
		"player_pos": _read_player_pos(),
		"district": _current_district(),
		"quests": QuestManager.serialize(),
		"xp": XpManager.save_data(),
		"skill_tree": SkillTreeManager.save_data(),
		"flashlight": FlashlightUpgradeManager.to_dict(),
		"photos": _photos,
		"daily_streak": _daily_streak,
		"last_daily_time": _last_daily_time,
		"onboard_done": _onboard_done,
	}
	_write_atomic(SAVE_PATH, payload)

func load_all() -> bool:
	var data := _read_validated(SAVE_PATH)
	if data.is_empty():
		return false
	PowerGrid.from_dict(data.get("power", {}))
	CoinWallet.from_dict(data.get("wallet", {}))
	ShopService.from_dict(data.get("shop", {}))
	UpgradeSystem.from_dict(data.get("upgrades", {}))
	InventoryManager.from_dict(data.get("inventory", {}))
	Encyclopedia.from_dict(data.get("encyclopedia", {}))
	ProgressTracker.from_dict(data.get("progress", {}))
	SettingsManager.from_dict(data.get("settings", {}))
	_pending_player_pos = _parse_player_pos(data.get("player_pos", null))
	_quest_data = data.get("quests", {})
	# Прогресс квестов раньше оседал в буфере _quest_data и никому не отдавался:
	# после загрузки все 19 квестов снова были на нуле.
	QuestManager.from_dict(_quest_data)
	# Текущий район раньше хранил только SaveLoad; без него загрузка всегда
	# возвращала игрока в стартовые пригороды.
	var dm := get_node_or_null("/root/DistrictManager")
	var did: String = String(data.get("district", ""))
	# SECURITY_PATCH_SPEC R-03/R-05: a forged/corrupt district id used to be
	# written straight to DistrictManager.current_district with no check -
	# DistrictSceneFactory.build() already falls back safely so this never
	# crashed, but the tainted string persisted as "current district" for
	# every OTHER reader (UI, minimap, achievement/quest conditions).
	if dm != null and not did.is_empty() and dm.DISTRICTS.has(did):
		dm.current_district = did
	_photos = data.get("photos", [])
	_daily_streak = int(data.get("daily_streak", 0))
	_last_daily_time = int(data.get("last_daily_time", 0))
	SkillTreeManager.load_data(data.get("skill_tree", {}))
	XpManager.load_data(data.get("xp", {}))
	# Saves from before C8 round 3 lack the key: keep the cfg-loaded levels.
	FlashlightUpgradeManager.from_dict(data.get("flashlight", FlashlightUpgradeManager.to_dict()))
	_onboard_done = bool(data.get("onboard_done", false))
	return true

func is_onboard_done() -> bool:
	return _onboard_done

func mark_onboard_done() -> void:
	if _onboard_done:
		return
	_onboard_done = true
	_save()

func reset_all() -> void:
	PowerGrid.reset()
	UpgradeSystem.reset()
	CoinWallet.from_dict({})
	ShopService.from_dict({})
	InventoryManager.from_dict({})
	Encyclopedia.from_dict({})
	_pending_player_pos = Vector3.INF
	_quest_data = {}
	QuestManager.reset()
	_photos = []
	_daily_streak = 0
	_last_daily_time = 0
	Endings.reset()
	# TRUTH WAVE P0.2: эти двое сохранялись через SaveSystem (см. _save()/
	# load_all()), но reset_all() их не трогал — "новая игра" стартовала
	# с уровнем/скиллами от прошлого забега на этом сейв-профиле.
	XpManager.reset()
	SkillTreeManager.reset()
	FlashlightUpgradeManager.from_dict({})
	# Тот же класс ошибки, что и TRUTH WAVE P0.2 выше, только про другую
	# систему. ProgressTracker несёт счётчики секретов/убийств/пазлов и список
	# уже найденных секретов. Без сброса «новая игра» стартовала бы со
	# статистикой прошлого забега, а найденные секреты не появились бы
	# заново вовсе (DistrictLoot теперь пропускает те, что помнит
	# ProgressTracker).
	ProgressTracker.from_dict({})
	# GAME_AUDIT P1: same reset gap as XP/skills above, for the district
	# pointer - load_all() sets dm.current_district from the save (line
	# ~304-307), but reset_all() never set it back to the start district, so
	# "New Game" pressed mid-run (death screen, or Play after a save exists)
	# left the player's district pointer stale at wherever they died/quit.
	var dm := get_node_or_null("/root/DistrictManager")
	if dm != null:
		dm.current_district = dm.START_DISTRICT
	# GAME_AUDIT P1: NewGamePlus.reset_for_new_game() deliberately NOT called
	# here, unlike the systems above. victory_screen.gd's NG+ button calls
	# NewGamePlus.activate_ng_plus() then routes straight to the main menu;
	# the only way to actually START that harder run is the menu's "Play"
	# button, which is start_new_game() -> reset_all(). Wiping NG+ here made
	# NG+ unreachable in practice - activating it and starting the run
	# immediately reset it to 0. A genuinely fresh save (NG+ level already 0)
	# is unaffected either way.

## SECURITY_PATCH_SPEC R-03: a forged/corrupt save could supply a
## non-finite (NaN) or wildly-out-of-bounds-but-finite player_pos and it
## was applied directly - Vector3.INF is the existing "no saved position,
## use the district's own spawn" sentinel, so routing a bad value through
## that same sentinel is the natural, minimal fix rather than inventing a
## new failure mode.
func _parse_player_pos(pp) -> Vector3:
	if not (pp is Array) or pp.size() < 3:
		return Vector3.INF
	var v := Vector3(pp[0], pp[1], pp[2])
	return v if v.is_finite() else Vector3.INF

func consume_pending_player_pos() -> Vector3:
	var p := _pending_player_pos
	_pending_player_pos = Vector3.INF
	return p

func set_quest_data(data: Dictionary) -> void:
	_quest_data = data

func get_quest_data() -> Dictionary:
	return _quest_data.duplicate()

func add_photo(photo_id: String) -> bool:
	if photo_id in _photos:
		return false
	_photos.append(photo_id)
	_save()
	return true

func get_photos() -> Array:
	return _photos.duplicate()

func get_photo_count() -> int:
	return _photos.size()

func get_daily_streak() -> int:
	return _daily_streak

func increment_daily_streak() -> void:
	var now := Time.get_unix_time_from_system()
	var last := _last_daily_time
	if now - last > 86400 * 2:
		_daily_streak = 0
	_daily_streak += 1
	_last_daily_time = int(now)
	_save()

func _current_district() -> String:
	var dm := get_node_or_null("/root/DistrictManager")
	return String(dm.current_district) if dm != null else ""

func _read_player_pos() -> Array:
	var p := get_tree().get_first_node_in_group("player")
	if is_instance_valid(p):
		return [p.global_position.x, p.global_position.y, p.global_position.z]
	return [0.0, 0.0, 0.0]

func _get_slot_path(slot: int) -> String:
	return "user://tls_savegame_slot%d.save" % slot

func get_slot_info(slot: int) -> Dictionary:
	var data := _read_validated(_get_slot_path(slot))
	if data.is_empty():
		return {"exists": false}
	var progress = data.get("progress", {})

	# Static audit 2026-09-08: "level" always fell to its else-branch (1)
	# because save_slot() never writes a "current_scene" key at all, and
	# "modified" was hardcoded 0.0 instead of the "timestamp" field that IS
	# saved. "district" is what's actually saved and closest to "level"
	# for this project. Note: this slot API only feeds save_slots_ui.gd/
	# save_slot_entry.gd, both archived/unreachable per KNOWN_ISSUES.md -
	# fixed anyway since it's cheap, but not currently player-visible.
	return {
		"exists": true,
		"level": data.get("district", "") if data.get("district", "") != "" else 1,
		"playtime": progress.get("time_played", 0.0),
		"modified": data.get("timestamp", 0.0),
		"scene": data.get("current_scene", "")
	}

func save_slot(slot: int) -> bool:
	var payload: Dictionary = {
		"version": SAVE_VERSION,
		"wallet": CoinWallet.to_dict(),
		"shop": ShopService.to_dict(),
		"upgrades": UpgradeSystem.to_dict(),
		"inventory": InventoryManager.to_dict(),
		"power": PowerGrid.to_dict(),
		"encyclopedia": Encyclopedia.to_dict(),
		"progress": ProgressTracker.to_dict(),
		"settings": SettingsManager.to_dict(),
		"player_pos": _read_player_pos(),
		"district": _current_district(),
		"quests": QuestManager.serialize(),
		"xp": XpManager.save_data(),
		"skill_tree": SkillTreeManager.save_data(),
		"flashlight": FlashlightUpgradeManager.to_dict(),
		"photos": _photos,
		"daily_streak": _daily_streak,
		"last_daily_time": _last_daily_time,
		"onboard_done": _onboard_done,
		"timestamp": Time.get_unix_time_from_system(),
		"slot_id": slot,
	}
	return _write_atomic(_get_slot_path(slot), payload)

## SECURITY_PATCH_SPEC P-06: every slot shares the same HMAC key with no
## slot identity in the signed body, so a validly-signed save from slot B
## copied over slot A's file loaded cleanly as if it were A's own data -
## not corruption, but a silent profile-swap with no signal to the player.
## slot_id is now part of the signed payload; a file whose slot_id doesn't
## match the slot being loaded is rejected the same as a bad HMAC.
func load_slot(slot: int) -> bool:
	var data := _read_validated(_get_slot_path(slot))
	if data.is_empty():
		return false
	if int(data.get("slot_id", -1)) != slot:
		return false
	PowerGrid.from_dict(data.get("power", {}))
	CoinWallet.from_dict(data.get("wallet", {}))
	ShopService.from_dict(data.get("shop", {}))
	UpgradeSystem.from_dict(data.get("upgrades", {}))
	InventoryManager.from_dict(data.get("inventory", {}))
	Encyclopedia.from_dict(data.get("encyclopedia", {}))
	ProgressTracker.from_dict(data.get("progress", {}))
	SettingsManager.from_dict(data.get("settings", {}))
	_pending_player_pos = _parse_player_pos(data.get("player_pos", null))
	_quest_data = data.get("quests", {})
	QuestManager.from_dict(_quest_data)
	# Mirror load_all(): restore current district so a slot load returns
	# the player to the district they saved in (previously hardcoded
	# suburbs the same way the main save was before TRUTH WAVE P0.2).
	var dm := get_node_or_null("/root/DistrictManager")
	var did: String = String(data.get("district", ""))
	# SECURITY_PATCH_SPEC R-03/R-05: a forged/corrupt district id used to be
	# written straight to DistrictManager.current_district with no check -
	# DistrictSceneFactory.build() already falls back safely so this never
	# crashed, but the tainted string persisted as "current district" for
	# every OTHER reader (UI, minimap, achievement/quest conditions).
	if dm != null and not did.is_empty() and dm.DISTRICTS.has(did):
		dm.current_district = did
	_photos = data.get("photos", [])
	_daily_streak = int(data.get("daily_streak", 0))
	_last_daily_time = int(data.get("last_daily_time", 0))
	_onboard_done = bool(data.get("onboard_done", false))

	# Load skill tree
	if SkillTreeManager:
		SkillTreeManager.load_data(data.get("skill_tree", {}))
	FlashlightUpgradeManager.from_dict(data.get("flashlight", FlashlightUpgradeManager.to_dict()))

	# Load XP
	if XpManager:
		XpManager.load_data(data.get("xp", {}))

	return true

func delete_slot(slot: int) -> bool:
	return _remove_with_backups(_get_slot_path(slot))

## G17: load step 4 falls back through .bak/.bak2/.bak3, so a delete that
## leaves any of them lets the "wiped" save come back.
func _remove_with_backups(path: String) -> bool:
	for suffix in [".bak", ".bak2", ".bak3"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	return FileAccess.file_exists(path) and DirAccess.remove_absolute(path) == OK

func get_all_slots_info() -> Array:
	var result: Array = []
	for i in range(1, MAX_SLOTS + 1):
		var info = get_slot_info(i)
		info["slot"] = i
		info["is_autosave"] = (i == MAX_SLOTS)
		result.append(info)
	return result

## TRUTH WAVE P0: "Reset progress" (settings_screen.gd) and boot-time
## quarantine of an unreadable/mismatched save both need this — reset_all()
## alone only clears autoload state in memory, it never touched the actual
## save files, so a restart would resurrect the old progress via Continue.
func wipe_all_saves() -> void:
	_remove_with_backups(SAVE_PATH)
	for i in range(1, MAX_SLOTS + 1):
		delete_slot(i)
	reset_all()
	# BREAK_REPORT B5: NewGamePlus owns its own save file entirely outside
	# SaveSystem's scope (unlike reset_all() above, which deliberately does
	# NOT touch it - see that function's own comment, activate-then-Play is
	# the real flow). "Reset Progress" is different: the player asked for
	# an actually fresh start, and an earned NG+ level surviving that isn't
	# the same "activate then Play" case reset_all() protects.
	if NewGamePlus:
		NewGamePlus.reset_for_new_game()
	var ngp_path := "user://ng_plus_data.json"
	if FileAccess.file_exists(ngp_path):
		DirAccess.remove_absolute(ngp_path)
