extends SceneTree
func _init():
    var paths = [
        "res://scenes/player_fps.tscn",
        "res://scenes/levels/level_01.tscn",
        "res://scenes/gameplay/checkpoint.tscn",
    ]
    for p in paths:
        var r = ResourceLoader.load(p)
    quit()
