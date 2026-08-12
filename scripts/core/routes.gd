extends Node
## Routes — единственная таблица сцен и единственный способ их менять.
##
## До этого маршруты были разбросаны по 13 файлам и половина вела в
## res://scenes/levels/level_01.tscn, которого в проекте вообще нет —
## кнопка «Играть» просто ничего не делала. Теперь любой переход идёт
## через goto(); несуществующий путь ловится здесь, а не молча падает.

const BOOT: String = "res://scenes/ui/boot_loading.tscn"
const MENU: String = "res://scenes/ui/main_menu.tscn"
const LOADING: String = "res://scenes/ui/pre_loading.tscn"
## Единственная боевая сцена: игровой мир собирается в ней из районов.
const GAME: String = "res://scenes/main_3d.tscn"
const SETTINGS: String = "res://scenes/ui/settings_screen.tscn"
const DIFFICULTY: String = "res://scenes/ui/difficulty_screen.tscn"
const CREDITS: String = "res://scenes/ui/credits.tscn"

signal route_changed(path: String)

func exists(path: String) -> bool:
	return ResourceLoader.exists(path)

## Основной переход. Снимает паузу и возвращает курсор в корректный режим,
## иначе после смерти/паузы новая сцена стартовала замороженной.
func goto(path: String) -> void:
	if not exists(path):
		push_error("[Routes] нет сцены: %s" % path)
		return
	get_tree().paused = false
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("[Routes] переход не удался (%d): %s" % [err, path])
		return
	route_changed.emit(path)
	if has_node("/root/InputService"):
		get_node("/root/InputService").call_deferred("refresh_mouse_mode")

## Старт новой игры: через экран загрузки в единственный игровой мир.
func start_game() -> void:
	if has_node("/root/GameManager"):
		var gm := get_node("/root/GameManager")
		if gm.has_method("start_new_game"):
			gm.start_new_game()
	goto(LOADING if exists(LOADING) else GAME)

func to_menu() -> void:
	goto(MENU)

func restart_game() -> void:
	goto(GAME)
