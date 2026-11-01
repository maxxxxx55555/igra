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
	var frontage := root.find_child("FacadeFrontage", true, false) as Node3D
	_expect(frontage != null, "%s missing street-level architectural frontage" % id)
	if frontage != null:
		_expect(frontage.get_child_count() <= 4, "%s frontage exceeds four material batches" % id)
		_expect(frontage.find_children("*", "CollisionObject3D", true, false).is_empty(), "%s frontage changes gameplay collision" % id)
		_expect(frontage.find_children("*", "Light3D", true, false).is_empty(), "%s frontage adds real-time lights" % id)
		for batch: Node in frontage.get_children():
			var mesh := batch as MultiMeshInstance3D
			_expect(mesh != null and mesh.multimesh.instance_count > 0, "%s has an empty frontage batch" % id)
			if mesh != null:
				for i: int in mesh.multimesh.instance_count:
					var transform := mesh.multimesh.get_instance_transform(i)
					_expect(transform.is_finite() and transform.basis.determinant() > 0.0, "%s has invalid architectural geometry" % id)
		_expect(frontage.has_node("EntryFrames") and frontage.has_node("Recesses"), "%s missing visible entry depth" % id)
		_expect(frontage.has_node("RoofHardware"), "%s missing broken roof silhouette" % id)
		frontage.set_detail(0.0)
		_expect(not (frontage.get_node("Metalwork") as Node3D).visible and not (frontage.get_node("RoofHardware") as Node3D).visible, "%s keeps fine architecture on Low tier" % id)
		_expect((frontage.get_node("EntryFrames") as Node3D).visible, "%s loses doorway silhouettes on Low tier" % id)
		frontage.set_detail(2.0)
		_expect((frontage.get_node("Metalwork") as Node3D).visible and (frontage.get_node("RoofHardware") as Node3D).visible, "%s cannot restore architectural detail" % id)
	root.queue_free()
	await get_tree().process_frame

func _expect(ok: bool, message: String) -> void:
	if ok:
		return
	_fails += 1
	print("[premium] [FAIL] ", message)
