extends RefCounted
## Session 29 (the v10.0.0-ship pass), E1 the sounds that left WAV for OGG. SFX1 every cue file that a monster script names resolves to a stream with a length: BaseMonster.cue_path takes the OGG
## when it shipped and the WAV of a clip under half a second otherwise, so a partial conversion cannot silence a monster (a missing file makes play_cue return, and no gate sees a silent monster).
## WIND1 the wind layer of the AudioManager loops: it was the only layer of the manager that was not forced to, so it played its 5.7 s once at the first input and stopped. Wired into _closeout_check_runner.gd.

static func run(r: Node) -> void:
	_cues(r)
	_wind(r)

## The names are the literals of the `"file":` rows of the monster scripts, the ones _set_cues gets.
static func _cues(r: Node) -> void:
	var rx := RegEx.new()
	rx.compile('"file":\\s*"([A-Za-z0-9_]+)"')
	var names: Dictionary = {}
	for f: String in DirAccess.get_files_at("res://scripts/enemies"):
		if f.ends_with(".gd"):
			for m: RegExMatch in rx.search_all(FileAccess.get_file_as_string("res://scripts/enemies/" + f)):
				names[m.get_string(1)] = true
	var bad: Array[String] = []
	for cue_name: String in names:
		var path: String = BaseMonster.cue_path(cue_name)
		var stream: AudioStream = load(path) as AudioStream if not path.is_empty() else null
		if stream == null or stream.get_length() < 0.05:
			bad.append(cue_name)
	r._ok(names.size() >= 30 and bad.is_empty(), "SFX1 every monster cue file resolves to a stream (%d cues, unresolved %s)" % [names.size(), bad.slice(0, 4)])

static func _wind(r: Node) -> void:
	var am: Node = r.get_node_or_null("/root/AudioManager")
	var layer: AudioStreamPlayer = am.get("_wind") if am != null else null
	var s: AudioStream = layer.stream if layer != null else null
	var loops: bool = (s is AudioStreamOggVorbis and (s as AudioStreamOggVorbis).loop) or (s is AudioStreamWAV and (s as AudioStreamWAV).loop_mode != AudioStreamWAV.LOOP_DISABLED)
	r._ok(loops, "WIND1 the wind layer of the AudioManager loops (%s)" % [s.get_class() if s != null else "no stream"])
