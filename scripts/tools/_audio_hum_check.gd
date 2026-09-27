extends Node
## FINAL PERFECTION P0: proves the boot-hum fix holds — no music/ambience
## player may be .playing before the player's first input. Waits several
## idle frames (no input simulated) after boot, then inspects every audio
## player in the tree (rc14: it only read MusicManager's, so AudioManager's
## 55 Hz drone hummed from boot under a green gate).
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
	var players: Array = []
	for n in get_tree().root.find_children("*", "", true, false):
		if n is AudioStreamPlayer or n is AudioStreamPlayer2D or n is AudioStreamPlayer3D:
			players.append(n)
	for p in players:
		if p.playing:
			printerr("[audio-hum] player still playing pre-input: ", p.get_path())
			bad += 1
	if not AudioServer.is_bus_mute(0):
		printerr("[audio-hum] Master is not muted in a QA run (qa_launch_guard.gd)")
		bad += 1
	print("[audio-hum] players checked=", players.size(), " (none may play before the first input) -> bad=", bad)
	get_tree().quit(bad)
