extends Node
## Every successful threaded request must be consumed, including on scene exit.

var _fails: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var loader: RefCounted = load("res://scripts/world/district_preloader.gd").new()
	loader.request_around(&"suburbs")
	var paths: Array = loader.requested_paths().duplicate()
	await _wait_loaded(paths)
	if loader.has_method("collect_ready"):
		loader.collect_ready()
	_ok(_unclaimed(paths).is_empty(), "district prefetch consumes every completed request")
	var warm := not paths.is_empty()
	for path in paths:
		warm = warm and ResourceLoader.has_cached(path)
	_ok(warm, "district resources stay cached while their owner is alive")
	if loader.has_method("clear"):
		loader.clear()
	_cleanup(paths)
	loader = load("res://scripts/world/district_preloader.gd").new()
	loader.request_around(&"school")
	paths = loader.requested_paths().duplicate()
	if loader.has_method("clear"):
		loader.clear()
	_ok(_unclaimed(paths).is_empty(), "scene-exit drain consumes requests without waiting for a poll")
	_cleanup(paths)
	loader = null
	# Repeated requests for the same neighbours must not accumulate loader handles.
	MusicManager._preload_around(&"school")
	MusicManager._preload_around(&"school")
	paths = []
	for id: StringName in [&"park", &"school", &"hospital"]:
		paths.append(MusicManager._ambience_path_for(id))
	await _wait_loaded(paths)
	await get_tree().process_frame
	_ok(_unclaimed(paths).is_empty(), "music prefetch consumes repeated neighbour requests")
	var music_warm := true
	for path in paths:
		var stream: AudioStream = MusicManager._cache.get(path)
		music_warm = music_warm and stream is AudioStreamOggVorbis and stream.loop
	_ok(music_warm, "prefetched music remains cached with looping enabled")
	_cleanup(paths)
	var director := MusicDirector.new()
	add_child(director)
	director._preload_around(&"substation")
	paths = []
	for id: StringName in [&"industrial", &"substation", &"power_station"]:
		paths.append(director._ambience_path_for(id))
	remove_child(director)
	director.queue_free()
	_ok(_unclaimed(paths).is_empty(), "music shutdown drains requests still in flight")
	_cleanup(paths)
	await get_tree().process_frame
	print("[threaded-loader] DONE fails=%d" % _fails)
	get_tree().quit(0 if _fails == 0 else 1)

func _wait_loaded(paths: Array) -> void:
	for _attempt in 300:
		var busy := false
		for path in paths:
			busy = busy or ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS
		if not busy:
			return
		await get_tree().create_timer(0.01).timeout
	_ok(false, "resource requests finish within three seconds")

func _unclaimed(paths: Array) -> Array:
	return paths.filter(func(path: String) -> bool:
		return ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE)

func _cleanup(paths: Array) -> void:
	# Even the red test releases its intentionally unclaimed handles before exit.
	for path in paths:
		for _attempt in 20:
			if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				break
			ResourceLoader.load_threaded_get(path)

func _ok(condition: bool, label: String) -> void:
	if not condition:
		_fails += 1
	print("[threaded-loader] %s %s" % ["OK" if condition else "FAIL", label])
