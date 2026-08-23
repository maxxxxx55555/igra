extends Node
## Скриншот запущенной игры для проверки глазами.
##
##   godot --path . --shot                       # docs/MENU_SCREENSHOT.png через 10 с
##   godot --path . --shot=docs/foo.png --shot-delay=4
##
## Путь раньше был прибит к рабочему столу конкретной машины — теперь по
## умолчанию пишем в репозиторий, чтобы снимок попадал в отчёт.

const DEFAULT_PATH := "res://docs/MENU_SCREENSHOT.png"
const DEFAULT_DELAY := 10.0

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

func _run(path: String, delay: float) -> void:
	var marks := _series()
	if not marks.is_empty():
		await _run_series(path, marks)
		return
	await get_tree().create_timer(delay).timeout
	var img := get_tree().root.get_texture().get_image()
	var abs_path := path if path.begins_with("res://") or path.begins_with("user://") else ProjectSettings.globalize_path(path)
	var err := img.save_png(abs_path)
	if err == OK:
		print("SHOT_OK: ", abs_path, " ", img.get_width(), "x", img.get_height())
	else:
		printerr("SHOT_FAIL: ", abs_path, " код ", err)
	get_tree().quit(0 if err == OK else 1)
