extends Node
## A01 bus-graph check (GDD §13, PRODUCTION_BIBLE §3): Master -> Music, SFX (Footsteps,
## Combat, UI, Environment), Voice, Ambient; no Hum. Proves the layout the game loads,
## that every audio player under /root names a bus that exists (none may sit on Master
## itself, the default of a player nobody routed), and that the players this project
## owns land on the bus their sound belongs to.
## Scene: scenes/tools/audio_bus_check_scene.tscn (headless). Ends "[audio-bus] DONE fails=N".

## bus -> [index, send, effect count]. Godot routes a send that points at the same or a
## later index straight to Master, so every send must sit at a lower index than its bus.
const GRAPH := {
	"Master": [0, "", 0],
	"Music": [1, "Master", 2],
	"SFX": [2, "Master", 0],
	"Voice": [3, "Master", 0],
	"Ambient": [4, "Master", 0],
	"UI": [5, "SFX", 0],
	"Footsteps": [6, "SFX", 0],
	"Combat": [7, "SFX", 0],
	"Environment": [8, "SFX", 0],
}

## Players the autoloads build at boot: node path -> the bus they must use.
const ROUTES := {
	"/root/AudioManager/WindLayer": "Environment",
	"/root/AudioManager/ActionLayer": "Combat",
	"/root/AudioManager/HeartbeatLayer": "Combat",
	"/root/AudioManager/BreathLayer": "Combat",
	"/root/MusicManager/MusicA": "Music",
	"/root/MusicManager/MusicB": "Music",
	"/root/MusicManager/Layer_ambient_dark": "Music",
	"/root/MusicManager/Layer_rain": "Environment",
	"/root/MusicManager/Layer_wind": "Environment",
	"/root/MusicManager/ActionSting": "Music",
	"/root/MusicManager/WowCue": "Music",
	"/root/DistrictAtmosphere/DistrictDetailBed": "Ambient",
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")

func _run() -> void:
	for i in 3:
		await get_tree().process_frame
	var fails := _check_graph() + _check_routes() + _check_probes() + _check_players()
	print("[audio-bus] DONE fails=%d" % fails)
	get_tree().quit(0 if fails == 0 else 1)

func _fail(msg: String) -> int:
	printerr("[audio-bus] FAIL ", msg)
	return 1

func _check_graph() -> int:
	var fails := 0
	if AudioServer.get_bus_name(0) != "Master":
		fails += _fail("bus 0 is %s, it must stay Master (QaLaunchGuard mutes index 0)" % AudioServer.get_bus_name(0))
	if AudioServer.get_bus_count() != GRAPH.size():
		fails += _fail("%d buses, want %d (a leftover Hum or a stray bus)" % [AudioServer.get_bus_count(), GRAPH.size()])
	for bus_name: String in GRAPH:
		var want: Array = GRAPH[bus_name]
		var idx: int = AudioServer.get_bus_index(bus_name)
		if idx != int(want[0]):
			fails += _fail("%s sits at index %d, want %d" % [bus_name, idx, want[0]])
			continue
		if AudioServer.get_bus_effect_count(idx) != int(want[2]):
			fails += _fail("%s has %d effects, want %d" % [bus_name, AudioServer.get_bus_effect_count(idx), want[2]])
		if idx == 0:
			continue
		var send := String(AudioServer.get_bus_send(idx))
		if send != String(want[1]) or AudioServer.get_bus_index(send) >= idx:
			fails += _fail("%s sends to %s, want %s at a lower index" % [bus_name, send, want[1]])
	return fails

func _expect(player: Node, want: String) -> int:
	if player == null:
		return _fail("no player to route-check, wanted one on %s" % want)
	var got := String(player.get("bus"))
	if got != want:
		return _fail("%s routes to %s, want %s" % [player.get_path(), got, want])
	return 0

func _check_routes() -> int:
	var fails := 0
	for path: String in ROUTES:
		fails += _expect(get_node_or_null(path), ROUTES[path])
	fails += _expect(get_node("/root/AudioManager").get("_rain"), "Environment")
	return fails

## Players made on demand: fire the public entry points and read the bus of what they build.
func _check_probes() -> int:
	var fails := 0
	var am := get_node("/root/AudioManager")
	var clip: AudioStream = am.call("_gen_click")
	am.play_sound_3d(clip, Vector3.ZERO, -80.0)
	fails += _expect(am.get_child(am.get_child_count() - 1), "Combat")
	am.play_sound_3d(clip, Vector3.ZERO, -80.0, &"Environment")
	fails += _expect(am.get_child(am.get_child_count() - 1), "Environment")
	am.play_sfx(clip, -80.0, &"UI")
	var pooled := false
	for p in am.get("_pool"):
		pooled = pooled or String(p.bus) == "UI"
	if not pooled:
		fails += _fail("play_sfx(bus) left every pooled player on its old bus")
	var ui := get_node("/root/UISFX")
	var first := ui.get_child_count()
	ui.error()
	ui.pickup()
	if ui.get_child_count() == first:
		fails += _fail("UISFX built no player")
	for i in range(first, ui.get_child_count()):
		fails += _expect(ui.get_child(i), "UI")
	var steps := FootstepSystem.new()
	add_child(steps)
	fails += _expect(steps.get_node("FootstepAudio"), "Footsteps")
	return fails

func _check_players() -> int:
	var fails := 0
	var players := 0
	for n in get_tree().root.find_children("*", "", true, false):
		if n is AudioStreamPlayer or n is AudioStreamPlayer2D or n is AudioStreamPlayer3D:
			players += 1
			var bus := String(n.get("bus"))
			if bus == "Master" or AudioServer.get_bus_index(bus) < 0:
				fails += _fail("%s routes to %s, which is Master itself or a missing bus" % [n.get_path(), bus])
	print("[audio-bus] players checked=%d" % players)
	if players == 0:
		fails += _fail("no audio player found under /root")
	return fails
