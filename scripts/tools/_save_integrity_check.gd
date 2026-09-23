extends Node
## Гейт T16: сейв переживает обрыв записи и битые байты.
## Сцена: scenes/tools/save_integrity_check_scene.tscn

const _SLOT: int = 97  # заведомо вне MAX_SLOTS, чтобы не задеть реальные сейвы

var _fails: int = 0

func _ready() -> void:
	await get_tree().process_frame
	_check_round_trip()
	_check_bak_recovery()
	_check_corrupt_rejected()
	_check_backup_rotation()
	_check_progress_signature()
	_check_legacy_checksum_rejected()
	_check_missing_progress_hmac_rejected()
	_check_fuzz_50_mutants()
	_check_export_import()
	_cleanup()
	print("[save-integrity] DONE fails=", _fails)
	get_tree().quit(0 if _fails == 0 else 1)

func _ok(cond: bool, what: String) -> void:
	if cond:
		print("[save-integrity] OK  ", what)
	else:
		_fails += 1
		print("[save-integrity] FAIL ", what)

func _path() -> String:
	return "user://tls_savegame_slot%d.save" % _SLOT

func _check_round_trip() -> void:
	CoinWallet.from_dict({})
	CoinWallet.add(777)
	var wrote: bool = SaveSystem.save_slot(_SLOT)
	_ok(wrote, "save_slot пишет файл")
	_ok(FileAccess.file_exists(_path()), "файл слота существует")
	CoinWallet.from_dict({})
	var loaded: bool = SaveSystem.load_slot(_SLOT)
	_ok(loaded, "load_slot читает файл")
	_ok(CoinWallet.get_coins() == 777, "данные пережили save->load (%d)" % CoinWallet.get_coins())

func _check_bak_recovery() -> void:
	# .bak появляется только при повторной записи поверх существующего файла.
	CoinWallet.from_dict({})
	CoinWallet.add(111)
	SaveSystem.save_slot(_SLOT)
	CoinWallet.from_dict({})
	CoinWallet.add(222)
	SaveSystem.save_slot(_SLOT)
	_ok(FileAccess.file_exists(_path() + ".bak"), ".bak создаётся при перезаписи")
	# Портим основной файл — load_slot должен откатиться на .bak.
	var f := FileAccess.open(_path(), FileAccess.WRITE)
	f.store_string("не json{{{")
	f.close()
	CoinWallet.from_dict({})
	var recovered: bool = SaveSystem.load_slot(_SLOT)
	_ok(recovered, "битый основной файл -> восстановление из .bak")
	_ok(CoinWallet.get_coins() == 111, ".bak содержит предыдущее валидное состояние (%d)" % CoinWallet.get_coins())

func _check_corrupt_rejected() -> void:
	# Основной и все резервные копии битые — load_slot обязан вернуть false.
	var f := FileAccess.open(_path(), FileAccess.WRITE)
	f.store_string("{\"checksum\":\"deadbeef\",\"data_json\":\"{\\\"version\\\":1}\"}")
	f.close()
	_remove_all_backups()
	var ok: bool = SaveSystem.load_slot(_SLOT)
	_ok(not ok, "чек-сумма не сошлась -> load_slot отказывает, а не подставляет мусор")

## STEP 4 anti-tamper: 3 rotated backups, not just 1 - write 4 times and
## confirm the newest 3 all exist (and hold the expected values), oldest
## rotated out.
func _check_backup_rotation() -> void:
	_remove_all_backups()
	for coins in [10, 20, 30, 40]:
		CoinWallet.from_dict({})
		CoinWallet.add(coins)
		SaveSystem.save_slot(_SLOT)
	_ok(FileAccess.file_exists(_path() + ".bak") and FileAccess.file_exists(_path() + ".bak2")
		and FileAccess.file_exists(_path() + ".bak3"), "3 резервные копии существуют после 4 записей")
	CoinWallet.from_dict({})
	SaveSystem.load_slot(_SLOT)
	var main_coins: int = CoinWallet.get_coins()
	# The newest bak holds the write immediately before the current main
	# (30, since main=40) - restore it via the real recovery path (corrupt
	# main, let load_slot fall back) rather than reading the file directly.
	var f2 := FileAccess.open(_path(), FileAccess.WRITE)
	f2.store_string("не json{{{")
	f2.close()
	CoinWallet.from_dict({})
	SaveSystem.load_slot(_SLOT)
	_ok(main_coins == 40 and CoinWallet.get_coins() == 30,
		"ротация хранит 3 последних состояния по порядку (было %d, .bak дал %d)" % [main_coins, CoinWallet.get_coins()])
	# Re-corrupt main + newest bak - load_slot must reach .bak2 (20).
	var f3 := FileAccess.open(_path(), FileAccess.WRITE)
	f3.store_string("не json{{{"); f3.close()
	var f4 := FileAccess.open(_path() + ".bak", FileAccess.WRITE)
	f4.store_string("не json{{{"); f4.close()
	CoinWallet.from_dict({})
	SaveSystem.load_slot(_SLOT)
	_ok(CoinWallet.get_coins() == 20, ".bak2 достижим, когда основной и .bak оба биты (%d)" % CoinWallet.get_coins())
	_remove_all_backups()

func _remove_all_backups() -> void:
	for suffix in [".bak", ".bak2", ".bak3"]:
		if FileAccess.file_exists(_path() + suffix):
			DirAccess.remove_absolute(_path() + suffix)

## STEP 4 anti-tamper: forging a district-FULL/progress state independent
## of the whole-envelope signature must not survive - see save_system.gd
## _sign_progress()'s comment for exactly what this protects against.
func _check_progress_signature() -> void:
	CoinWallet.from_dict({})
	PowerGrid.from_dict({})
	SaveSystem.save_slot(_SLOT)
	var f := FileAccess.open(_path(), FileAccess.READ)
	var txt := f.get_as_text()
	f.close()
	var outer := JSON.new()
	outer.parse(txt)
	var envelope: Dictionary = outer.data
	var inner := JSON.new()
	inner.parse(String(envelope["data_json"]))
	var data: Dictionary = inner.data
	# Forge "all districts full" directly in the parsed body, bypassing the
	# real PowerGrid entirely - exactly the attack _sign_progress() exists
	# to catch, since data["progress_hmac"] here is still the ORIGINAL
	# signature over the ORIGINAL (untampered) power/progress.
	# Shape must match PowerGrid.to_dict()'s real output ({"stages": {id:
	# int}}) - BREAK_REPORT B4 verification found this used to be the
	# wrong flat shape ({"suburbs": {"stage": 3}}), which from_dict()'s own
	# `d.get("stages", {})` silently ignores entirely: the forgery never
	# reached PowerGrid regardless of whether the signature check worked,
	# so this assertion passed for the wrong reason on both sides of B4.
	data["power"] = {"stages": {"suburbs": 3}}
	var forged_body := JSON.stringify(data)
	# Re-sign the OUTER envelope with the real key so this isn't just
	# re-testing "checksum mismatch -> reject" - the point is the outer
	# envelope can be perfectly valid and the forgery still gets caught.
	var forged: Dictionary = {"hmac": SaveSystem.call("_sign", forged_body), "data_json": forged_body}
	var wf := FileAccess.open(_path(), FileAccess.WRITE)
	wf.store_string(JSON.stringify(forged))
	wf.close()
	SaveSystem.load_slot(_SLOT)
	var restored: Dictionary = (PowerGrid.to_dict().get("stages", {}) as Dictionary)
	_ok(int(restored.get("suburbs", 0)) != 3,
		"forged district-FULL state is rejected even with a valid outer envelope")

## BREAK_REPORT B4 / SECURITY_PATCH_SPEC P-01: a plain "checksum" (unkeyed
## sha256_text(), no secret) used to be trusted once when "hmac" was absent -
## anyone can compute a correct sha256 of their own forged body, no key
## needed. Confirms the CORRECT checksum for a forged body is still rejected
## now (this used to be the exact bypass; wrong-checksum rejection is
## already covered by _check_corrupt_rejected above, a different case).
func _check_legacy_checksum_rejected() -> void:
	CoinWallet.from_dict({})
	CoinWallet.add(50)
	SaveSystem.save_slot(_SLOT)
	var f := FileAccess.open(_path(), FileAccess.READ)
	var txt := f.get_as_text()
	f.close()
	var outer := JSON.new()
	outer.parse(txt)
	var body: String = String((outer.data as Dictionary)["data_json"])
	# A real forger's move: drop "hmac", compute the correct plain checksum
	# of a body they edited freely (here just reusing the real body is
	# enough to prove the point - even a byte-perfect legitimate body with
	# no hmac must now be refused). Clear backups first (same reason
	# _check_corrupt_rejected does) - _read_validated falls back to a real
	# signed .bak otherwise, which would pass for the wrong reason.
	_remove_all_backups()
	var legacy: Dictionary = {"checksum": body.sha256_text(), "data_json": body}
	var wf := FileAccess.open(_path(), FileAccess.WRITE)
	wf.store_string(JSON.stringify(legacy))
	wf.close()
	var ok: bool = SaveSystem.load_slot(_SLOT)
	_ok(not ok, "legacy checksum-only envelope (correct checksum, no hmac) is rejected, not trusted-once")
	_remove_all_backups()

## BREAK_REPORT B4: a save missing "progress_hmac" entirely used to skip
## the district/progress signature check altogether (trusted unverified) -
## the same "just omit the field" bypass as the legacy checksum above, one
## layer in. Now treated the same as a failed check: wiped, not trusted.
func _check_missing_progress_hmac_rejected() -> void:
	CoinWallet.from_dict({})
	PowerGrid.from_dict({})
	SaveSystem.save_slot(_SLOT)
	var f := FileAccess.open(_path(), FileAccess.READ)
	var txt := f.get_as_text()
	f.close()
	var outer := JSON.new()
	outer.parse(txt)
	var envelope: Dictionary = outer.data
	var inner := JSON.new()
	inner.parse(String(envelope["data_json"]))
	var data: Dictionary = inner.data
	data["power"] = {"stages": {"suburbs": 3}}
	data.erase("progress_hmac")
	var forged_body := JSON.stringify(data)
	var forged: Dictionary = {"hmac": SaveSystem.call("_sign", forged_body), "data_json": forged_body}
	var wf := FileAccess.open(_path(), FileAccess.WRITE)
	wf.store_string(JSON.stringify(forged))
	wf.close()
	SaveSystem.load_slot(_SLOT)
	var restored: Dictionary = (PowerGrid.to_dict().get("stages", {}) as Dictionary)
	_ok(int(restored.get("suburbs", 0)) != 3,
		"missing progress_hmac is treated as failed, not skipped (valid outer envelope, no progress_hmac at all)")

## RELEASE CONVERGENCE STEP 4: 50 mutants of a real signed save, each a
## different byte-level corruption/tamper of the same template. "Graceful"
## here means what a headless run can actually prove: the process reaches
## the next mutant every time (a real crash would kill the whole gate, not
## just fail one assertion) AND CoinWallet never ends up in a state
## save_system.gd's own clamp couldn't have produced (see coin_wallet.gd
## from_dict — [0, MAX_COINS]). It does not claim to detect every possible
## exploit, only that corrupt bytes can't crash or desync the game state.
func _check_fuzz_50_mutants() -> void:
	CoinWallet.from_dict({})
	CoinWallet.add(555)
	SaveSystem.save_slot(_SLOT)
	_remove_all_backups()  # isolate: no fallback crutch for this pass
	var f := FileAccess.open(_path(), FileAccess.READ)
	var template: PackedByteArray = f.get_buffer(f.get_length())
	f.close()

	seed(20260912)  # deterministic, matches touch_probe's fuzz convention
	for i in range(50):
		var mutant := template.duplicate()
		match i % 5:
			0:  # single byte flip at a rotating offset
				if mutant.size() > 0:
					var idx: int = i % mutant.size()
					mutant[idx] = mutant[idx] ^ 0xFF
			1:  # truncate to a fraction of the original
				mutant = mutant.slice(0, maxi(1, mutant.size() * (i % 5 + 1) / 10))
			2:  # append garbage bytes
				for _b in range(i % 20 + 1):
					mutant.append(randi() % 256)
			3:  # zero out a chunk (simulates a partial write / disk-full)
				var start: int = (i * 7) % maxi(1, mutant.size())
				var stop: int = mini(mutant.size(), start + 16)
				for j in range(start, stop):
					mutant[j] = 0
			_:  # empty file
				mutant = PackedByteArray()
		var wf := FileAccess.open(_path(), FileAccess.WRITE)
		wf.store_buffer(mutant)
		wf.close()
		CoinWallet.from_dict({})
		var loaded: bool = SaveSystem.load_slot(_SLOT)
		# Whether it loaded (legacy/valid-enough envelope) or refused
		# (mismatched signature/broken JSON), coins must stay a real,
		# clamped int — never NaN, never out of CoinWallet's own bound.
		var c: int = CoinWallet.get_coins()
		var sane: bool = c >= 0 and c <= CoinWallet.MAX_COINS
		if not sane:
			_ok(false, "fuzz mutant %d left coins out of bounds (%d, loaded=%s)" % [i, c, loaded])
	# Reaching this line at all is the crash proof: a real engine crash on
	# any of the 50 mutants above would have killed the process mid-loop,
	# never printing this or the final DONE line.
	_ok(true, "fuzz: 50/50 mutants processed without crashing the process")
	_remove_all_backups()

## RELEASE CONVERGENCE STEP 6 (anti "lost phone"): a fully scratch path on
## both ends (a fake "save" file that isn't SAVE_PATH, a fake export
## filename that isn't EXPORT_FILENAME) - never touches a real save or a
## real Downloads file, same reason as _SLOT=97 above.
const _SCRATCH_SAVE: String = "user://tls_savegame_TESTONLY.save"
const _SCRATCH_EXPORT: String = "tls_save_export_TESTONLY.json"

func _check_export_import() -> void:
	if FileAccess.file_exists(_SCRATCH_SAVE):
		DirAccess.remove_absolute(_SCRATCH_SAVE)
	_ok(not SaveSystem.export_save_to_file(_SCRATCH_SAVE, _SCRATCH_EXPORT),
		"экспорт отказывает, если сейва ещё нет")

	# A real signed save (built via the normal slot machinery, then copied
	# to the scratch path) must round-trip through export -> import cleanly.
	CoinWallet.from_dict({})
	CoinWallet.add(333)
	SaveSystem.save_slot(_SLOT)
	DirAccess.copy_absolute(_path(), _SCRATCH_SAVE)
	_ok(SaveSystem.export_save_to_file(_SCRATCH_SAVE, _SCRATCH_EXPORT), "экспорт пишет файл в Downloads")

	CoinWallet.from_dict({})
	CoinWallet.add(999)
	SaveSystem.save_slot(_SLOT)
	DirAccess.copy_absolute(_path(), _SCRATCH_SAVE)  # scratch now holds 999, export still holds 333
	_ok(SaveSystem.import_save_from_file(_SCRATCH_SAVE, _SCRATCH_EXPORT), "импорт читает файл из Downloads")
	DirAccess.copy_absolute(_SCRATCH_SAVE, _path())
	CoinWallet.from_dict({})
	SaveSystem.load_slot(_SLOT)
	_ok(CoinWallet.get_coins() == 333, "импорт вернул исходные (333) данные, не последние (999) — было %d" % CoinWallet.get_coins())

	# Garbage placed at the export filename must be refused, not imported.
	var dl_path: String = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS).path_join(_SCRATCH_EXPORT)
	var gf := FileAccess.open(dl_path, FileAccess.WRITE)
	gf.store_string("не json{{{")
	gf.close()
	_ok(not SaveSystem.import_save_from_file(_SCRATCH_SAVE, _SCRATCH_EXPORT), "импорт отказывает на битом файле экспорта")

	for p: String in [_SCRATCH_SAVE, _SCRATCH_SAVE + ".bak", dl_path]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
	CoinWallet.from_dict({})

func _cleanup() -> void:
	for suffix: String in ["", ".bak", ".bak2", ".bak3", ".tmp"]:
		var p: String = _path() + suffix
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
	# The 50-mutant fuzz pass's quarantine path is timestamped
	# (SaveSystem._read_validated()'s ".corrupt-<unix>") so it can't be
	# named up front — sweep user:// for this slot's leftovers instead of
	# littering the save directory across repeated gate runs.
	var stem: String = _path().get_file() + ".corrupt-"
	var da := DirAccess.open("user://")
	if da != null:
		for fname in da.get_files():
			if fname.begins_with(stem):
				da.remove(fname)
	CoinWallet.from_dict({})
