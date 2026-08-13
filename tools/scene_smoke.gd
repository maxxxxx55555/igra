extends SceneTree
## Дым-тест: каждая ключевая сцена должна грузиться и инстанцироваться.
##
## Ловит то, чего не видит статика: битые ext_resource, несуществующие
## свойства нод, ошибки в _init/_ready при создании узла.
##
## Запуск: godot --headless --script res://tools/scene_smoke.gd

const PATHS: Array[String] = [
	"res://scenes/ui/boot_loading.tscn",
	"res://scenes/ui/splash.tscn",
	"res://scenes/ui/main_menu.tscn",
	"res://scenes/ui/menu.tscn",
	"res://scenes/ui/settings_screen.tscn",
	"res://scenes/ui/difficulty_screen.tscn",
	"res://scenes/ui/pause_menu.tscn",
	"res://scenes/ui/game_over.tscn",
	"res://scenes/ui/hud_3d.tscn",
	"res://scenes/ui/confirm_quit.tscn",
	"res://scenes/ui/stats_screen.tscn",
	"res://scenes/player/player_3d.tscn",
	"res://scenes/pickups/item_pickup_3d.tscn",
	"res://scenes/pickups/document_pickup.tscn",
	"res://scenes/props/streetlight_3d.tscn",
	"res://scenes/environment/world_env.tscn",
	"res://scenes/tools/game_test.tscn",
]

func _init() -> void:
	var fails: int = 0
	for p in PATHS:
		if not ResourceLoader.exists(p):
			printerr("SMOKE FAIL (нет файла): ", p)
			fails += 1
			continue
		var packed: PackedScene = load(p) as PackedScene
		if packed == null:
			printerr("SMOKE FAIL (не загрузилась): ", p)
			fails += 1
			continue
		var node: Node = packed.instantiate()
		if node == null:
			printerr("SMOKE FAIL (не инстанцировалась): ", p)
			fails += 1
			continue
		print("SMOKE OK: ", p)
		node.free()
	print("SMOKE RESULT fails=", fails)
	quit(0 if fails == 0 else 1)
