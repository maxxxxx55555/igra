extends RefCounted
## Asks the loader thread for what the districts next to the current one (index +-1 in DISTRICTS) will load when they are
## built: their scene file and the street textures, so a first visit finds them cached instead of reading and parsing them on
## the main thread. The enemy, pickup and effect scenes need no request: they are `preload` constants, resident since their
## scripts compiled. Completed requests must be consumed with load_threaded_get; synchronous load() does not release their
## loader handles. The local cache then keeps those resources warm until this world's owner exits.

var _requested: Array[String] = []
var _pending: Array[String] = []
var _cache: Dictionary = {}

func request_around(district_id: StringName) -> void:
	var ids: Array[StringName] = DistrictSceneFactory.DISTRICTS
	var at: int = ids.find(district_id)
	if at < 0:
		return
	for idx in [at - 1, at + 1]:
		if idx >= 0 and idx < ids.size():
			_request(DistrictSceneFactory.district_scene_path(ids[idx]))
	for texture in [StreetBuilder._TEX_ASPHALT, StreetBuilder._TEX_CONCRETE, CityStreetProps._TEX_BENCH]:
		_request(texture)

func _request(path: String) -> void:
	if _requested.has(path) or not ResourceLoader.exists(path):
		return
	if ResourceLoader.load_threaded_request(path, "", false) == OK:
		_requested.append(path)
		_pending.append(path)

## Poll only completed requests during play, so a background prefetch cannot stall a frame.
func collect_ready() -> void:
	for path: String in _pending.duplicate():
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue
		if status != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			var resource := ResourceLoader.load_threaded_get(path)
			if resource != null:
				_cache[path] = resource
		_pending.erase(path)

## Scene teardown may precede the next poll; drain even requests still in flight before releasing the cache.
func clear() -> void:
	for path in _pending:
		if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			ResourceLoader.load_threaded_get(path)
	_pending.clear()
	_cache.clear()
	_requested.clear()

## Every path asked of the loader so far, each once.
func requested_paths() -> Array[String]:
	return _requested
