extends Node
## Скриншот запущенной игры для проверки глазами.
##
##   godot --path . --shot                       # docs/MENU_SCREENSHOT.png через 10 с
##   godot --path . --shot=docs/foo.png --shot-delay=4
##   godot --path . --shot=docs/foo.png --shot-scenario=combat
##
## Путь раньше был прибит к рабочему столу конкретной машины — теперь по
## умолчанию пишем в репозиторий, чтобы снимок попадал в отчёт.

const DEFAULT_PATH := "res://docs/MENU_SCREENSHOT.png"
const DEFAULT_DELAY := 10.0

## Сценарии для визуального аудита: заставляют мир дойти до состояния,
## которое иначе руками не собрать в headless-запуске.
const SCENARIOS: PackedStringArray = ["street", "lit", "inventory", "combat"]

func _ready() -> void:
	for a in OS.get_cmdline_args():
		if a == "--shot" or a.begins_with("--shot="):
			_run(_arg_value(a, DEFAULT_PATH), _delay())
			return

func _delay() -> float:
	for a in OS.get_cmdline_args():
		if a.begins_with("--shot-delay="):
			return maxf(0.0, float(_arg_value(a, "")))
	return DEFAULT_DELAY

static func _arg_value(arg: String, fallback: String) -> String:
	var i := arg.find("=")
	return fallback if i < 0 else arg.substr(i + 1)

## Серия снимков за один запуск: --shot-series=2,6,12,20,30
## Один прогон вместо пяти — иначе сравниваешь разные запуски и делаешь
## неверные выводы о том, что происходит со временем.
func _series() -> PackedFloat32Array:
	for a in OS.get_cmdline_args():
		if a.begins_with("--shot-series="):
			var out := PackedFloat32Array()
			for part in _arg_value(a, "").split(",", false):
				out.append(maxf(0.0, float(part)))
			return out
	return PackedFloat32Array()

func _run_series(base: String, marks: PackedFloat32Array) -> void:
	var prev := 0.0
	for i in marks.size():
		await get_tree().create_timer(maxf(0.0, marks[i] - prev)).timeout
		prev = marks[i]
		var img := get_tree().root.get_texture().get_image()
		var p := base.get_basename() + "_%02ds.png" % int(marks[i])
		var err := img.save_png(ProjectSettings.globalize_path(p))
		print("SHOT_%s: %s t=%ds" % ["OK" if err == OK else "FAIL", p, int(marks[i])])
	get_tree().quit(0)

func _scenario() -> String:
	for a in OS.get_cmdline_args():
		if a.begins_with("--shot-scenario="):
			var v := _arg_value(a, "")
			return v if SCENARIOS.has(v) else ""
	return ""

## Ставит мир в состояние, которое иначе нельзя собрать без рук на клавиатуре:
## реально стартует игру и (для combat/inventory/lit) донастраивает её.
func _apply_scenario(name: String) -> void:
	if name.is_empty():
		return
	# ShotTool._ready() выполняется настолько рано (среди автозагрузок), что
	# Bootstrap ещё не видит current_scene и уходит в scenes/ui/splash.tscn
	# (fallback-ветка _bootstrap.gd) вместо прямого boot_loading — splash
	# сам держит экран ~3с (fade 1с + пауза 2с, splash.gd), только потом
	# идёт в BOOT, у которого свой ~3.3с отсчёт до меню. Итого «естественная»
	# загрузка занимает ~6.5с, а не долю секунды — при более раннем вызове
	# Routes.start_game() он гонится с ещё идущим переходом и получается
	# каша из старого и нового экрана на одном кадре.
	await get_tree().create_timer(8.0).timeout
	# Вход в первый район корректно триггерит interstitial (ad_service.gd,
	# district_entered) — это ожидаемое поведение, не баг, но для чистого
	# скриншота сцены оно не нужно.
	var ads := get_node_or_null("/root/AdService")
	if ads:
		ads.enabled = false
	var routes := get_node_or_null("/root/Routes")
	if routes and routes.has_method("start_game"):
		routes.start_game()
	await get_tree().create_timer(6.0).timeout
	match name:
		"lit":
			var dm := get_node_or_null("/root/DistrictManager")
			if dm and dm.has_method("set_stage"):
				dm.set_stage(dm.current_district, 3)
			await get_tree().create_timer(0.5).timeout
		"inventory":
			var inv := _find_by_script(get_tree().root, "inventory_ui.gd")
			if inv and inv.has_method("toggle"):
				inv.toggle()
			await get_tree().create_timer(0.3).timeout
		"combat":
			var player := get_tree().get_first_node_in_group("player")
			var monster := get_tree().get_first_node_in_group("monsters")
			if player is Node3D and monster is Node3D:
				(player as Node3D).global_position = (monster as Node3D).global_position + Vector3(0, 0, 2.5)
			await get_tree().create_timer(1.0).timeout
		_: # "street" — оставить как есть, только дождаться стрима мира.
			pass

static func _find_by_script(root: Node, file_name: String) -> Node:
	var s: Script = root.get_script()
	if s and String(s.resource_path).ends_with(file_name):
		return root
	for c in root.get_children():
		var found := _find_by_script(c, file_name)
		if found:
			return found
	return null

func _run(path: String, delay: float) -> void:
	var marks := _series()
	if not marks.is_empty():
		await _run_series(path, marks)
		return
	await _apply_scenario(_scenario())
	await get_tree().create_timer(delay).timeout
	var img := get_tree().root.get_texture().get_image()
	var abs_path := path if path.begins_with("res://") or path.begins_with("user://") else ProjectSettings.globalize_path(path)
	var err := img.save_png(abs_path)
	if err == OK:
		print("SHOT_OK: ", abs_path, " ", img.get_width(), "x", img.get_height())
	else:
		printerr("SHOT_FAIL: ", abs_path, " код ", err)
	get_tree().quit(0 if err == OK else 1)
