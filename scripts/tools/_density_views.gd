extends RefCounted
## The extra views and switches of the density frames (scripts/tools/_density_frames_runner.gd), kept apart so the runner stays under 300 lines. Each takes the scene tree, reads the district that is loaded
## and returns the view as the runner's dictionary (name, at, look, pitch, stage, light), or {} with a `[density] FAIL` line when the district has nothing to show there.

## The V1 details of Session 28 (docs/RUN_STATE.md): the window interiors and halos of the skyline, the dust and the cracks of the lamps. `on` false is the district as it stood before them. With the label `v1` every
## view is shot twice in the same run, first with them off ("before") and then on ("after"), so the two frames differ by these details and by nothing else.
static func v1(tree: SceneTree, on: bool) -> void:
	var windows := tree.root.find_child("Windows", true, false) as MultiMeshInstance3D
	if windows != null and windows.material_override is ShaderMaterial:
		(windows.material_override as ShaderMaterial).set_shader_parameter("interior", 1.0 if on else 0.0)
	for node_name: String in ["WindowHalos", "LampDust"]:
		var node := tree.root.find_child(node_name, true, false) as Node3D
		if node != null:
			node.visible = on

## 09_lamp: five metres from the streetlamp nearest to the eye of the west street, toward the middle of the district, the camera tilted up at its head, power FULL, the flashlight off: the dust in the cone of
## the lamp and the cracks at the foot of its pole.
static func lamp_view(tree: SceneTree, id: StringName) -> Dictionary:
	var lamps := tree.root.find_child("StreetlightLampsBatched", true, false) as MultiMeshInstance3D
	if lamps == null or lamps.multimesh.instance_count == 0:
		print("[density] FAIL no lamp stands in %s" % id)
		return {}
	var eye := Vector2(-8.0, 21.0)
	var nearest: Vector3 = lamps.multimesh.get_instance_transform(0).origin
	for i in lamps.multimesh.instance_count:
		var head: Vector3 = lamps.multimesh.get_instance_transform(i).origin
		if Vector2(head.x, head.z).distance_to(eye) < Vector2(nearest.x, nearest.z).distance_to(eye):
			nearest = head
	var toward := Vector3(-nearest.x, 0.0, -nearest.z).normalized()
	return {"name": "09_lamp", "at": Vector3(nearest.x + toward.x * 5.0, 0.1, nearest.z + toward.z * 5.0), "look": nearest, "pitch": 0.42, "stage": 3, "light": false}
