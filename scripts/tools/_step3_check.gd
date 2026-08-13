extends Node

## Gate этапа 3: сцены с новыми ассетами должны грузиться и инстанцироваться.
func _ready() -> void:
	var bad: int = 0
	for p in ["res://scenes/props/streetlight_3d.tscn", "res://scenes/player/player_3d.tscn",
			"res://scenes/ui/hud_3d.tscn", "res://scenes/main_3d.tscn"]:
		var ps: PackedScene = load(p)
		if ps == null:
			printerr("LOAD FAIL ", p)
			bad += 1
			continue
		var n: Node = ps.instantiate()
		if n == null:
			printerr("INST FAIL ", p)
			bad += 1
			continue
		print("OK ", p, " children=", n.get_child_count())
		n.free()
	for a in ["res://assets/mesh/mesh_streetlight_pole.res", "res://assets/mesh/mesh_bench.res",
			"res://assets/mesh/mesh_house_small.res", "res://assets/mesh/mesh_trash_can.res",
			"res://assets/mesh/mesh_hydrant.res", "res://assets/audio/sfx/amb_lamp_hum.wav",
			"res://assets/audio/sfx/amb_wind.wav", "res://assets/audio/sfx/step_concrete.wav",
			"res://assets/audio/sfx/sfx_flashlight_on.wav", "res://assets/audio/sfx/sfx_flashlight_off.wav",
			"res://assets/ui/ui_heart.svg", "res://assets/ui/ui_battery.svg",
			"res://assets/ui/ui_pause.svg", "res://assets/ui/ui_interact.svg"]:
		if load(a) == null:
			printerr("ASSET FAIL ", a)
			bad += 1
	print("STEP3_CHECK bad=", bad)
	get_tree().quit(bad)
