extends Node

var _fails: int = 0

func _ready() -> void:
	for id: StringName in DistrictSceneFactory.DISTRICTS:
		await _check_district(id)
	print("[premium] DONE fails=", _fails)
	get_tree().quit(1 if _fails > 0 else 0)

func _check_district(id: StringName) -> void:
	var scene := load(DistrictSceneFactory.district_scene_path(id)) as PackedScene
	var root := scene.instantiate() as Node3D
	add_child(root)
	for i in 8:
		await get_tree().process_frame
	for node_name in ["FacadeTrim", "WindowSills", "FacadePipes", "CurbMM", "RoadDamageMM", "UrbanSetDressing"]:
		_expect(root.find_child(node_name, true, false) != null, "%s missing %s" % [id, node_name])
	root.queue_free()
	await get_tree().process_frame

func _expect(ok: bool, message: String) -> void:
	if ok:
		return
	_fails += 1
	print("[premium] [FAIL] ", message)
