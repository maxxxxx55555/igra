extends RefCounted
## The extra views and switches of the density frames (scripts/tools/_density_frames_runner.gd), kept apart so the runner stays under 300 lines. Each takes the scene tree, reads the district that is loaded
## and returns the view as the runner's dictionary (name, at, look, pitch, stage, light), or {} with a `[density] FAIL` line when the district has nothing to show there.

## The labels whose frames are shot twice in the same run, a detail off ("before") and on ("after"): `v1` (batch A), `story` (the story scenes of W1), `v1d` (the halos, the dust and the cracks of batch A alone, at their
## own strength) and `v1x` (the same at a strength raised to where a rendering fault would show: a diagnostic, never a state of the game).
const SWITCHED: Array[String] = ["v1", "story", "v1d", "v1x"]

static func switch(label: String, tree: SceneTree, on: bool) -> void:
	match label:
		"story":
			story(tree, on)
		"v1d":
			details(tree, on, false)
		"v1x":
			details(tree, on, true)
		_:
			v1(tree, on)

## The story scenes (Session 28, W1) are the last instances of the dressing's batches: the "before" frame draws the batches up to where the scenes begin.
static func story(tree: SceneTree, on: bool) -> void:
	for node_name: String in ["Crates", "Barrels", "Bins", "Litter"]:
		var batch := tree.root.find_child(node_name, true, false) as MultiMeshInstance3D
		if batch != null and batch.has_meta("story_from"):
			batch.multimesh.visible_instance_count = -1 if on else int(batch.get_meta("story_from"))

## The halos, the dust and the cracks of batch A alone (the window interiors stay on); `boosted` raises each strength to where a detail that is drawn at all cannot be missed.
static func details(tree: SceneTree, on: bool, boosted: bool) -> void:
	for node_name: String in ["WindowHalos", "LampMotes", "Cracks"]:
		var node := tree.root.find_child(node_name, true, false) as MultiMeshInstance3D
		if node == null:
			continue
		node.visible = on
		if on and boosted:
			var material := node.material_override as ShaderMaterial
			material.set_shader_parameter("strength", 8.0)
			if node_name == "LampMotes":
				material.set_shader_parameter("size_m", 0.3)

## A find throws a burst of sparkles in front of the player (wow_director.gd) and these runs put the player on pickups: the bursts that are playing are put out, so they neither hide the subject nor differ between the two frames of a pair.
static func clear_bursts(tree: SceneTree) -> void:
	for node: Node in tree.root.get_children():
		if node is VFXBurst:
			node.queue_free()

## The lamps flicker (a sine and a dip to a fifth of their light about six times a second, streetlight_3d.gd), so two frames of one view differed on the ground by where the dip fell, and the shadows with it: for these
## labels the flicker is off and each lamp stands at the mean of its light.
static func pin_lamps(tree: SceneTree) -> void:
	for lamp: Node in tree.get_nodes_in_group("streetlights"):
		lamp.set("lamp_flicker", false)
		var mult: float = float(lamp.get("_light_energy_mult"))
		var spot := lamp.get_node_or_null("SpotLight") as SpotLight3D
		var glow := lamp.get_node_or_null("Glow") as OmniLight3D
		if spot != null:
			spot.light_energy = 1.7 * mult
		if glow != null:
			glow.light_energy = 0.85 * mult

## The view of 10_story: four and a half metres from the first story scene of the district, toward the street, power FULL, by the flashlight (the scenes stand in the block, out of the lamps' pools).
static func story_view(tree: SceneTree, id: StringName) -> Dictionary:
	var dressing: Node = tree.root.find_child("DistrictDressing", true, false)
	var spots: Array = dressing.get_meta("story_spots", []) if dressing != null else []
	if spots.is_empty():
		print("[density] FAIL no story scene stands in %s" % id)
		return {}
	var spot: Vector3 = spots[0]
	var away := Vector3(spot.x, 0.0, spot.z).normalized()
	return {"name": "10_story", "at": Vector3(spot.x + away.x * 4.5, 0.1, spot.z + away.z * 4.5), "look": spot, "pitch": -0.12, "stage": 3, "light": true}

## The views of the diagnostics: 11_pane (2.6 m in front of a pane that is lit from PARTIAL up, looking at it), 12_dust (2.4 m from the pole nearest to the eye of the west street, looking up at the head of its
## lamp) and 13_base (1.4 m from the same pole, looking down at its foot), power FULL, the flashlight off.
static func diag_view(tree: SceneTree, id: StringName, view_name: String) -> Dictionary:
	if view_name == "11_pane":
		return _pane_view(tree, id)
	var lamp := _lamp_at_eye(tree, id)
	if lamp.is_empty():
		return {}
	var foot: Vector3 = lamp[0]
	var head: Vector3 = lamp[1]
	var toward := Vector3(-foot.x, 0.0, -foot.z).normalized()
	if view_name == "12_dust":
		var far := foot + toward * 2.4
		return {"name": view_name, "at": Vector3(far.x, 0.1, far.z), "look": head, "pitch": atan2(head.y - 1.7, 2.4), "stage": 3, "light": false}
	var near := foot + toward * 1.4
	return {"name": view_name, "at": Vector3(near.x, 0.1, near.z), "look": Vector3(foot.x, 0.0, foot.z), "pitch": -atan2(1.7, 1.4), "stage": 3, "light": false}

static func _pane_view(tree: SceneTree, id: StringName) -> Dictionary:
	var skyline: Node = tree.root.find_child("Skyline", true, false)
	var windows := tree.root.find_child("Windows", true, false) as MultiMeshInstance3D
	if skyline == null or windows == null or windows.multimesh.instance_count == 0:
		print("[density] FAIL no pane stands in %s" % id)
		return {}
	var rolls: PackedFloat32Array = skyline.get("_rolls")
	var from := Vector3(-8.0, 3.6, 24.0)
	var best: int = -1
	var best_d: float = INF
	for i in windows.multimesh.instance_count:
		var origin: Vector3 = (windows.global_transform * windows.multimesh.get_instance_transform(i)).origin
		if rolls[i] < 0.25 and origin.y > 2.5 and origin.y < 6.0 and origin.distance_to(from) < best_d:
			best_d = origin.distance_to(from)
			best = i
	if best < 0:
		print("[density] FAIL no pane that is lit at the height of the eye in %s" % id)
		return {}
	var pane: Transform3D = windows.global_transform * windows.multimesh.get_instance_transform(best)
	var at := pane.origin + pane.basis.z.normalized() * 2.6
	return {"name": "11_pane", "at": Vector3(at.x, 0.1, at.z), "look": pane.origin, "pitch": atan2(pane.origin.y - 1.7, 2.6), "stage": 3, "light": false}

## What each small detail of batch A holds when the frames are taken (a line a district): how many instances, how many carry a colour, whether it is shown in the tree, its strength, where the first one stands and its box,
## so a detail that is not seen can be told from one that is not there.
static func probe(tree: SceneTree, id: StringName) -> void:
	for node_name: String in ["WindowHalos", "LampMotes", "Cracks"]:
		var node := tree.root.find_child(node_name, true, false) as MultiMeshInstance3D
		if node == null:
			print("[density] probe district=%s %s: not built" % [id, node_name])
			continue
		var coloured: int = 0
		if node.multimesh.use_colors:
			for i in node.multimesh.instance_count:
				var colour: Color = node.multimesh.get_instance_color(i)
				coloured += 1 if colour.r + colour.g + colour.b > 0.0 else 0
		var first: Vector3 = node.multimesh.get_instance_transform(0).origin if node.multimesh.instance_count > 0 else Vector3.ZERO
		print("[density] probe district=%s %s: count=%d coloured=%d shown=%s strength=%s first=%s box=%s" % [id, node_name, node.multimesh.instance_count, coloured, node.is_visible_in_tree(),
			(node.material_override as ShaderMaterial).get_shader_parameter("strength"), first, node.get_aabb()])

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
	var lamp := _lamp_at_eye(tree, id)
	if lamp.is_empty():
		return {}
	var head: Vector3 = lamp[1]
	var toward := Vector3(-head.x, 0.0, -head.z).normalized()
	return {"name": "09_lamp", "at": Vector3(head.x + toward.x * 5.0, 0.1, head.z + toward.z * 5.0), "look": head, "pitch": 0.42, "stage": 3, "light": false}

## The streetlamp nearest to the eye of the west street as [its foot, its head] (the pole and the lamp of one index are one lamp), or [] with a `[density] FAIL` line.
static func _lamp_at_eye(tree: SceneTree, id: StringName) -> Array[Vector3]:
	var poles := tree.root.find_child("StreetlightPolesBatched", true, false) as MultiMeshInstance3D
	var lamps := tree.root.find_child("StreetlightLampsBatched", true, false) as MultiMeshInstance3D
	var out: Array[Vector3] = []
	if poles == null or lamps == null or lamps.multimesh.instance_count == 0:
		print("[density] FAIL no lamp stands in %s" % id)
		return out
	var eye := Vector2(-8.0, 21.0)
	var nearest: int = 0
	for i in lamps.multimesh.instance_count:
		var head: Vector3 = lamps.multimesh.get_instance_transform(i).origin
		var best: Vector3 = lamps.multimesh.get_instance_transform(nearest).origin
		if Vector2(head.x, head.z).distance_to(eye) < Vector2(best.x, best.z).distance_to(eye):
			nearest = i
	out.append(poles.multimesh.get_instance_transform(nearest).origin)
	out.append(lamps.multimesh.get_instance_transform(nearest).origin)
	return out

## The view of 08_sign, or an empty one (a `[density] FAIL` line, the run goes on) when the district hangs no sign or its atlas holds no letters: the frame must not be the proof that the bake worked.
static func sign_view(tree: SceneTree, id: StringName) -> Dictionary:
	var signs := tree.root.find_child("Signs", true, false) as MultiMeshInstance3D
	if signs == null or signs.multimesh.instance_count == 0:
		print("[density] FAIL no sign hung in %s" % id)
		return {}
	var widest: int = 0
	for i: int in signs.multimesh.instance_count:
		if signs.multimesh.get_instance_custom_data(i).g > signs.multimesh.get_instance_custom_data(widest).g:
			widest = i
	var spot: Transform3D = signs.global_transform * signs.multimesh.get_instance_transform(widest)
	var atlas: Image = ((signs.material_override as ShaderMaterial).get_shader_parameter("atlas") as Texture2D).get_image()
	var ink: int = 0
	for y: int in range(0, atlas.get_height(), 4):
		for x: int in range(0, atlas.get_width(), 4):
			if atlas.get_pixel(x, y).a > 0.5:
				ink += 1
	print("[density] signs district=%s count=%d atlas=%dx%d ink_samples=%d first=%s facing=%s" % [String(id), signs.multimesh.instance_count, atlas.get_width(), atlas.get_height(), ink, spot.origin, spot.basis.z.normalized()])
	if ink < 200:
		print("[density] FAIL the sign atlas of %s holds no letters (%d ink samples)" % [id, ink])
		return {}
	var normal := spot.basis.z.normalized()
	return {"name": "08_sign", "at": Vector3(spot.origin.x + normal.x * 5.0, 0.1, spot.origin.z + normal.z * 5.0), "look": spot.origin, "pitch": -0.08, "stage": 3, "light": true}
