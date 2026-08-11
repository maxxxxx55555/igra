# tools/scene_smoke.gd
extends SceneTree

func _init():
    var paths = [
        "res://scenes/ui/main_menu.tscn",
        "res://scenes/ui/menu.tscn",
        "res://scenes/ui/settings.tscn",
        "res://scenes/ui/settings_screen.tscn",
        "res://scenes/ui/difficulty.tscn",
        "res://scenes/ui/difficulty_screen.tscn",
        "res://scenes/ui/pause_menu.tscn",
        "res://scenes/ui/game_over.tscn",
        "res://scenes/tools/game_test.tscn",
    ]
    var fails = 0
    for p in paths:
        var r = load(p)
        var n = r.instantiate() if r else null
        if n == null:
            printerr("SMOKE FAIL: ", p); fails += 1
        else:
            print("SMOKE OK: ", p); n.free()
    print("SMOKE RESULT fails=", fails)
    quit(0 if fails == 0 else 1)