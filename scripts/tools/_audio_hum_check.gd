extends Node
## FINAL PERFECTION P0: proves the boot-hum fix holds — no music/ambience
## player may be .playing before the player's first input. Waits several
## idle frames (no input simulated) after boot, then inspects MusicManager's
## real player nodes directly (not the mood enum, which is state-only now).
## Scene: scenes/tools/audio_hum_check_scene.tscn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")

func _run() -> void:
	for i in range(10):
		await get_tree().process_frame
	var bad: int = 0
	var mm := get_node_or_null("/root/MusicManager")
	if mm == null:
		printerr("[audio-hum] MusicManager missing")
		get_tree().quit(1)
		return
	if mm.get("_audio_unlocked") != false:
		printerr("[audio-hum] _audio_unlocked should still be false pre-input")
		bad += 1
	var players: Array = [mm.get("_a"), mm.get("_b")]
	for key in (mm.get("_layers") as Dictionary):
		players.append(mm._layers[key])
	for p in players:
		if p != null and p is AudioStreamPlayer and (p as AudioStreamPlayer).playing:
			printerr("[audio-hum] player still playing pre-input: ", (p as AudioStreamPlayer).name)
			bad += 1
	print("[audio-hum] players checked=", players.size(), " playing=0 audio_unlocked=false -> bad=", bad)
	get_tree().quit(bad)
