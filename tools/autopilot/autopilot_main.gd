extends Node
## Автопилот: гоняет живую игру со всеми автозагрузками и пишет
## tools/autopilot_report/report.txt. Ноль FAIL — можно релизить.
##
## Запуск:
##   godot --headless --path . res://tools/autopilot/autopilot.tscn
##
## Статические проверки живут в tools/check.sh — здесь только то, что
## требует поднятого движка и реальных автозагрузок.

const REPORT_DIR := "res://tools/autopilot_report"
const REPORT := REPORT_DIR + "/report.txt"
const LOCALES: PackedStringArray = [
	"ar", "de", "en", "es", "fr", "it", "ja", "ko", "pt_BR", "ru", "tr", "zh", "zh_TW",
]

var _lines: Array[String] = []
var _pass := 0
var _fail := 0

func _ready() -> void:
	_run("автозагрузки подняты", _check_autoloads)
	_run("аудио-шины на месте", _check_buses)
	_run("музыка грузится и зациклена", _check_music)
	_run("звуки монстров на диске", _check_sfx)
	_run("локализация: 13 языков, паритет ключей", _check_i18n)
	_run("тема и шрифты грузятся", _check_theme)
	_run("у каждого предмета есть иконка", _check_item_icons)
	_run("ключевые сцены инстанцируются", _check_scenes)
	_run("сохранение переживает круг save->load", _check_save_roundtrip)
	await _run_async("реклама за награду доходит до выдачи", _check_ad_flow)
	_write()
	get_tree().quit(1 if _fail > 0 else 0)

## ─────────────────────────── проверки ───────────────────────────

func _check_autoloads() -> String:
	var need := [
		"EventBus", "GameManager", "Routes", "SaveSystem", "MusicManager",
		"AudioManager", "LocalizationManager", "InventoryManager", "QuestManager",
	]
	var missing: Array[String] = []
	for n in need:
		if get_node_or_null("/root/" + n) == null:
			missing.append(n)
	return "" if missing.is_empty() else "нет автозагрузок: " + ", ".join(missing)

func _check_buses() -> String:
	var bad: Array[String] = []
	for b in ["Master", "Music", "SFX", "Ambient", "UI"]:
		var i := AudioServer.get_bus_index(b)
		if i < 0:
			bad.append(b + " (нет)")
		elif AudioServer.is_bus_mute(i):
			bad.append(b + " (заглушена)")
	return "" if bad.is_empty() else "шины: " + ", ".join(bad)

func _check_music() -> String:
	var mm := get_node_or_null("/root/MusicManager")
	if mm == null:
		return "MusicManager не поднялся"
	var script: Script = mm.get_script()
	var c := script.get_script_constant_map()
	var paths: Array[String] = []
	for p in (c["TRACKS"] as Dictionary).values():
		paths.append(p)
	for p in (c["AMBIENT_BY_DISTRICT"] as Dictionary).values():
		paths.append(p)
	for p in (c["LAYERS"] as Dictionary).values():
		paths.append(p)
	var sting: String = c["STING_PATH"]
	paths.append(sting)

	var bad: Array[String] = []
	var seen := {}
	for p in paths:
		if seen.has(p):
			continue
		seen[p] = true
		if not ResourceLoader.exists(p):
			bad.append(p.get_file() + ": нет на диске")
			continue
		var s := load(p) as AudioStream
		if s == null or s.get_length() <= 0.0:
			bad.append(p.get_file() + ": пустой поток")
			continue
		if p == sting:
			continue  # стингер играет один раз, цикл ему не нужен
		mm._force_loop(s)
		if not _is_looping(s):
			bad.append(p.get_file() + ": цикл не включился")
	_note("проверено треков: %d" % seen.size())
	return "" if bad.is_empty() else "; ".join(bad)

func _check_sfx() -> String:
	var bad: Array[String] = []
	for f in _files_in("res://assets/audio/sfx", ".wav"):
		var s := load(f) as AudioStream
		if s == null or s.get_length() <= 0.0:
			bad.append(f.get_file())
	return "" if bad.is_empty() else "битые sfx: " + ", ".join(bad)

func _check_i18n() -> String:
	var keys := {}
	var bad: Array[String] = []
	for loc in LOCALES:
		var path := "res://data/i18n/%s.json" % loc
		if not FileAccess.file_exists(path):
			bad.append(loc + ": файла нет")
			continue
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(data) != TYPE_DICTIONARY:
			bad.append(loc + ": не JSON-объект")
			continue
		var k := (data as Dictionary).keys()
		k.sort()
		keys[loc] = k
	if keys.has("ru"):
		var ref: Array = keys["ru"]
		for loc in keys:
			if keys[loc] != ref:
				bad.append("%s: расхождение ключей с ru (%d против %d)" % [loc, (keys[loc] as Array).size(), ref.size()])
	_note("языков: %d" % keys.size())
	return "" if bad.is_empty() else "; ".join(bad)

func _check_theme() -> String:
	var t := load("res://assets/ui/theme_tls.tres") as Theme
	if t == null:
		return "theme_tls.tres не грузится"
	if t.default_font == null:
		return "в теме нет шрифта по умолчанию"
	var bad: Array[String] = []
	for f in _files_in("res://assets/fonts", ".ttf"):
		if load(f) == null:
			bad.append(f.get_file())
	return "" if bad.is_empty() else "битые шрифты: " + ", ".join(bad)

## ItemDatabase подхватывает иконку молча: нет файла — предмет останется без
## картинки и в инвентаре будет пустая клетка. Здесь это становится видно.
func _check_item_icons() -> String:
	var db := get_node_or_null("/root/ItemDatabase")
	if db == null:
		return "ItemDatabase не поднялся"
	var bad: Array[String] = []
	var ids: Array = db.all_ids()
	for id in ids:
		var item = db.get_item(id)
		if item == null:
			bad.append(String(id) + ": нет в базе")
		elif item.icon == null:
			bad.append(String(id))
	_note("предметов: %d" % ids.size())
	return "" if bad.is_empty() else "без иконки: " + ", ".join(bad)

func _check_scenes() -> String:
	var bad: Array[String] = []
	for path in [
		"res://scenes/ui/boot_loading.tscn",
		"res://scenes/ui/main_menu.tscn",
		"res://scenes/main_3d.tscn",
	]:
		if not ResourceLoader.exists(path):
			bad.append(path.get_file() + ": нет")
			continue
		var ps := load(path) as PackedScene
		if ps == null or not ps.can_instantiate():
			bad.append(path.get_file() + ": не инстанцируется")
			continue
		var n := ps.instantiate()
		if n == null:
			bad.append(path.get_file() + ": instantiate() вернул null")
		else:
			n.free()
	return "" if bad.is_empty() else "; ".join(bad)

func _check_save_roundtrip() -> String:
	var ss := get_node_or_null("/root/SaveSystem")
	if ss == null:
		return "SaveSystem не поднялся"
	for m in ["save_slot", "load_slot", "delete_slot"]:
		if not ss.has_method(m):
			return "у SaveSystem нет " + m
	var wallet := get_node_or_null("/root/CoinWallet")
	if wallet == null:
		return "CoinWallet не поднялся"

	var slot := 99  # отдельный слот, чтобы не топтать сохранения игрока
	var marker := 4242
	var restore: int = wallet.coins
	wallet.coins = marker
	if not ss.save_slot(slot):
		wallet.coins = restore
		return "save_slot(%d) вернул false" % slot
	wallet.coins = marker + 1000  # портим состояние, загрузка обязана его перебить
	var ok: bool = ss.load_slot(slot)
	var after: int = wallet.coins
	ss.delete_slot(slot)
	wallet.coins = restore
	if not ok:
		return "load_slot(%d) вернул false" % slot
	if after != marker:
		return "монеты не восстановились: ждали %d, получили %d" % [marker, after]
	return ""

## Полный круг: запросили ролик -> заглушка досмотрела -> награда пришла.
## Заодно проверяем, что кулдаун закрывает повторный показ.
func _check_ad_flow() -> String:
	var ad := get_node_or_null("/root/AdService")
	if ad == null:
		return "AdService не поднялся"
	if not ad.is_rewarded_ready():
		return "заглушка сообщает, что ролик не готов"

	var got: Array = []
	var failed: Array = []
	ad.reward_granted.connect(func(id, amount): got.append([id, amount]))
	ad.ad_failed.connect(func(reason): failed.append(reason))

	ad.show_rewarded(&"bonus_coins")
	# Заглушка ждёт 3 с игрового времени, даём запас.
	await get_tree().create_timer(4.0, true, false, true).timeout

	if not failed.is_empty():
		return "осечка: " + String(failed[0])
	if got.is_empty():
		return "награда не пришла за 4 с"
	var id: StringName = got[0][0]
	var amount: int = got[0][1]
	if id != &"bonus_coins":
		return "пришла чужая награда: " + String(id)
	if amount != int(ad.REWARDS[&"bonus_coins"]):
		return "сумма награды %d вместо %d" % [amount, int(ad.REWARDS[&"bonus_coins"])]
	if ad.is_rewarded_ready():
		return "кулдаун не закрыл повторный показ"
	_note("награда: %s x%d, кулдаун %d с" % [id, amount, int(ad.cooldown_left())])
	return ""

## ─────────────────────────── инфраструктура ───────────────────────────

func _run(name: String, fn: Callable) -> void:
	var err: String = fn.call()
	if err == "":
		_pass += 1
		_lines.append("  PASS  " + name)
	else:
		_fail += 1
		_lines.append("  FAIL  " + name + " — " + err)

func _run_async(name: String, fn: Callable) -> void:
	var err: String = await fn.call()
	if err == "":
		_pass += 1
		_lines.append("  PASS  " + name)
	else:
		_fail += 1
		_lines.append("  FAIL  " + name + " — " + err)

func _note(text: String) -> void:
	_lines.append("        " + text)

func _is_looping(s: AudioStream) -> bool:
	if s is AudioStreamWAV:
		return (s as AudioStreamWAV).loop_mode != AudioStreamWAV.LOOP_DISABLED
	return bool(s.get("loop"))

func _files_in(dir: String, ext: String) -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	d.list_dir_begin()
	var f := d.get_next()
	while f != "":
		if not d.current_is_dir() and f.ends_with(ext):
			out.append(dir + "/" + f)
		f = d.get_next()
	d.list_dir_end()
	return out

func _write() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIR))
	var head := "АВТОПИЛОТ  %s\nGodot %s\n%s\n" % [
		Time.get_datetime_string_from_system(),
		Engine.get_version_info().string,
		"─".repeat(60),
	]
	var tail := "%s\nПройдено: %d, провалено: %d\n" % ["─".repeat(60), _pass, _fail]
	var body := head + "\n".join(_lines) + "\n" + tail
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(body)
		f.close()
	print(body)
