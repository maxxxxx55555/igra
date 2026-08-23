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
	# Основной и .bak оба битые — load_slot обязан вернуть false, а не мусор.
	var f := FileAccess.open(_path(), FileAccess.WRITE)
	f.store_string("{\"checksum\":\"deadbeef\",\"data_json\":\"{\\\"version\\\":1}\"}")
	f.close()
	if FileAccess.file_exists(_path() + ".bak"):
		DirAccess.remove_absolute(_path() + ".bak")
	var ok: bool = SaveSystem.load_slot(_SLOT)
	_ok(not ok, "чек-сумма не сошлась -> load_slot отказывает, а не подставляет мусор")

func _cleanup() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		var p: String = _path() + suffix
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
	CoinWallet.from_dict({})
