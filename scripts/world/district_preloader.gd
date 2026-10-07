extends RefCounted
## Asks the loader thread for what the districts next to the current one (index +-1 in DISTRICTS) will load when they are
## built: their scene file and the street textures, so a first visit finds them cached instead of reading and parsing them on
## the main thread. The enemy, pickup and effect scenes need no request: they are `preload` constants, resident since their
## scripts compiled. Nothing is collected with load_threaded_get: the loader keeps a finished resource for the game's own load(),
## so the main thread never waits on a request.

var _requested: Array[String] = []

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

## Every path asked of the loader so far, each once.
func requested_paths() -> Array[String]:
	return _requested
