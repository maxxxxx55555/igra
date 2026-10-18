extends RefCounted
## The extra views and switches of the density frames (scripts/tools/_density_frames_runner.gd), kept apart so the runner stays under 300 lines. Each takes the scene tree, reads the district that is loaded
## and returns the view as the runner's dictionary (name, at, look, pitch, stage, light), or {} with a `[density] FAIL` line when the district has nothing to show there.

## The labels whose frames are shot twice in the same run, a detail off ("before") and on ("after"): `v1` (batch A), `story` (the story scenes of W1), `v1d` (the halos and the lamp cones of batch A alone, at their
## own strength), `v1x` (the same at a strength raised to where a rendering fault would show: a diagnostic, never a state of the game) and `v1n` (the control: nothing is switched, so the pair shows how much
## two frames of one view differ by themselves) and `v1t` (the same, as a time series of eight frames with the lamps pinned: `series`).
const SWITCHED: Array[String] = ["v1", "story", "v1d", "v1x", "v1n", "v1t"]

static func switch(label: String, tree: SceneTree, on: bool) -> void:
	match label:
		"story":
			story(tree, on)
		"v1d":
			details(tree, on, false)
		"v1x":
			details(tree, on, true)
		"v1n", "v1t":
			pass
		_:
			v1(tree, on)

## The story scenes (Session 28, W1) are the last instances of the dressing's batches: the "before" frame draws the batches up to where the scenes begin.
static func story(tree: SceneTree, on: bool) -> void:
	for node_name: String in ["Crates", "Barrels", "Bins", "Litter"]:
		var batch := tree.root.find_child(node_name, true, false) as MultiMeshInstance3D
		if batch != null and batch.has_meta("story_from"):
			batch.multimesh.visible_instance_count = -1 if on else int(batch.get_meta("story_from"))

## The halos and the lamp cones of batch A alone (the window interiors stay on); `boosted` raises each strength to 8, or to TLS_FRAMES_STRENGTH when that is set (a sweep of the strength), where a detail that is drawn at all cannot be missed.
static func details(tree: SceneTree, on: bool, boosted: bool) -> void:
	var boost: float = float(OS.get_environment("TLS_FRAMES_STRENGTH")) if OS.has_environment("TLS_FRAMES_STRENGTH") else 8.0
	for node_name: String in ["WindowHalos", "LampCones"]:
		var node := tree.root.find_child(node_name, true, false) as MultiMeshInstance3D
		if node == null:
			continue
		node.visible = on
		if on and boosted:
			(node.material_override as ShaderMaterial).set_shader_parameter("strength", boost)

## A find throws a burst of sparkles in front of the player (wow_director.gd) and these runs put the player on pickups: the bursts that are playing are put out, so they neither hide the subject nor differ between the two frames of a pair.
static func clear_bursts(tree: SceneTree) -> void:
	for node: Node in tree.root.get_children():
		if node is VFXBurst:  # the director keeps its bursts and plays them again: a freed one made its cast fail
			(node as VFXBurst).restart()
			(node as VFXBurst).emitting = false

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

## The view of 10_story: four and a half metres from the first story scene of the district, from the side that no tree, pole, bench, hiding place or thing to use stands in front of, power FULL, by the flashlight (the scenes stand in the block, out of the lamps' pools).
static func story_view(tree: SceneTree, id: StringName) -> Dictionary:
	var dressing: Node = tree.root.find_child("DistrictDressing", true, false)
	var spots: Array = dressing.get_meta("story_spots", []) if dressing != null else []
	if spots.is_empty():
		print("[density] FAIL no story scene stands in %s" % id)
		return {}
	var spot: Vector3 = spots[0]
	var blockers: Array[Vector2] = dressing.call("_keep_clear")  # what the player can use or hide in, then what the dressing batches
	for node_name: String in ["TreeTrunksBatched", "StreetlightPolesBatched", "BenchesBatched"]:
		var batch := tree.root.find_child(node_name, true, false) as MultiMeshInstance3D
		if batch != null:
			for i in batch.multimesh.instance_count:
				var at: Vector3 = batch.multimesh.get_instance_transform(i).origin
				blockers.append(Vector2(at.x, at.z))
	var best: Vector3 = spot + Vector3(4.5, 0.0, 0.0)
	var clearest: float = -1.0
	for step in 8:  # the eight places 4.5 m round the scene: the one whose line of sight passes farthest from a tree, a pole or a bench
		var angle: float = float(step) * TAU / 8.0
		var eye: Vector3 = spot + Vector3(cos(angle), 0.0, sin(angle)) * 4.5
		var gap: float = INF
		for blocker: Vector2 in blockers:
			var passed: Vector2 = Geometry2D.get_closest_point_to_segment(blocker, Vector2(eye.x, eye.z), Vector2(spot.x, spot.z))
			gap = minf(gap, blocker.distance_to(passed))
		if absf(eye.x) < 23.0 and absf(eye.z) < 23.0 and gap > clearest:
			clearest = gap
			best = eye
	return {"name": "10_story", "at": Vector3(best.x, 0.1, best.z), "look": spot, "pitch": -0.12, "stage": 3, "light": true}

## The views of the diagnostics: 11_pane (2.6 m in front of a pane that is lit from PARTIAL up, looking at it), and 12_cone (2.4 m from the pole nearest to the eye of the west street, looking up at the head of its
## lamp), power FULL, the flashlight off.
static func diag_view(tree: SceneTree, id: StringName, view_name: String) -> Dictionary:
	if view_name == "11_pane":
		return _pane_view(tree, id)
	var lamp := _lamp_at_eye(tree, id)
	if lamp.is_empty():
		return {}
	var foot: Vector3 = lamp[0]
	var head: Vector3 = lamp[1]
	var toward := Vector3(-foot.x, 0.0, -foot.z).normalized()
	var far := foot + toward * 2.4
	return {"name": view_name, "at": Vector3(far.x, 0.1, far.z), "look": head, "pitch": atan2(head.y - 1.7, 2.4), "stage": 3, "light": false}

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
	print("[density] probe district=%s LampCones nodes=%d" % [id, tree.root.find_children("LampCones", "MultiMeshInstance3D", true, false).size()])
	for node_name: String in ["WindowHalos", "LampCones"]:
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

## The V1 details of Session 28 (docs/RUN_STATE.md): the window interiors and halos of the skyline and the cone of light of the lamps. `on` false is the district as it stood before them. With the label `v1` every
## view is shot twice in the same run, first with them off ("before") and then on ("after"), so the two frames differ by these details and by nothing else.
static func v1(tree: SceneTree, on: bool) -> void:
	var windows := tree.root.find_child("Windows", true, false) as MultiMeshInstance3D
	if windows != null and windows.material_override is ShaderMaterial:
		(windows.material_override as ShaderMaterial).set_shader_parameter("interior", 1.0 if on else 0.0)
	for node_name: String in ["WindowHalos", "LampDetails"]:
		var node := tree.root.find_child(node_name, true, false) as Node3D
		if node != null:
			node.visible = on

## 09_lamp: six metres from the streetlamp nearest to the eye of the west street, toward the middle of the district, the camera level on the middle of its cone, power FULL, the flashlight off: the whole cone of
## light under the lamp, as it is seen from the street.
static func lamp_view(tree: SceneTree, id: StringName) -> Dictionary:
	var lamp := _lamp_at_eye(tree, id)
	if lamp.is_empty():
		return {}
	var head: Vector3 = lamp[1]
	var toward := Vector3(-head.x, 0.0, -head.z).normalized()
	return {"name": "09_lamp", "at": Vector3(head.x + toward.x * 6.0, 0.1, head.z + toward.z * 6.0), "look": Vector3(head.x, head.y * 0.5, head.z), "pitch": atan2(head.y * 0.5 - 1.7, 6.0), "stage": 3, "light": false}

## A short-lived diagnostic (TLS_FRAMES_EXPERIMENT, a list). Under the flashlight the two additive shaders of V1, the lamp cones and the window halos, are cream pyramids and pale blocks whatever their render modes: `nocone` hides the
## beam cone of the player (a shader of the same kind that is drawn only when the flashlight is on), `prio` gives the two materials a render priority of their own, `premul` draws them with premultiplied alpha and an alpha of 0 (the same
## sum in another blend state; the cones without their back faces); `nolight` and `withlight` are the flashlight's, in the runner.
static func experiment(tree: SceneTree, player: Node3D, name: String) -> void:
	if name == "nocone":
		player.set("cone_amber_ok", false)
	for node_name: String in ["LampCones", "WindowHalos"]:
		var node := tree.root.find_child(node_name, true, false) as MultiMeshInstance3D
		var old := node.material_override as ShaderMaterial
		if name == "prio":
			old.render_priority = 5
		elif name == "premul":
			var fresh := ShaderMaterial.new()
			fresh.shader = Shader.new()
			fresh.shader.code = old.shader.code.replace("blend_add", "blend_premul_alpha").replace("\tALPHA = ", "\tALPHA = 0.0;\n\tALBEDO *= ")
			if node_name == "LampCones":
				fresh.shader.code = fresh.shader.code.replace("cull_disabled", "cull_back")
			for param: String in ["strength", "scale"]:
				if old.get_shader_parameter(param) != null:
					fresh.set_shader_parameter(param, old.get_shader_parameter(param))
			node.material_override = fresh

## The time series of a view (label `v1t`, nothing switched): eight consecutive frames of it, each with the mean brightness of the lower half of the picture and the energy of the lamp nearest to the camera and of the
## moon, so a ground that lights and darkens between two frames can be told from a lamp or a moon that does: `[density] series district=<id> view=<name> frame=<i> lower=<mean> spot=<e> glow=<e> moon=<e>`.
static func series(tree: SceneTree, id: StringName, view_name: String) -> void:
	var eye: Vector3 = tree.root.get_camera_3d().global_position
	var nearest: Node3D = null
	for lamp: Node in tree.get_nodes_in_group("streetlights"):
		if nearest == null or (lamp as Node3D).global_position.distance_to(eye) < nearest.global_position.distance_to(eye):
			nearest = lamp as Node3D
	var spot := nearest.get_node_or_null("SpotLight") as SpotLight3D if nearest != null else null
	var glow := nearest.get_node_or_null("Glow") as OmniLight3D if nearest != null else null
	var moons: Array[Node] = tree.root.find_children("*", "DirectionalLight3D", true, false)
	for i in 8:
		await RenderingServer.frame_post_draw
		var img := tree.root.get_texture().get_image()
		img.resize(64, 36)
		var sum: float = 0.0
		for y in range(18, 36):
			for x in 64:
				sum += img.get_pixel(x, y).get_luminance()
		print("[density] series district=%s view=%s frame=%d lower=%.4f spot=%.3f glow=%.3f moon=%.3f" % [id, view_name, i, sum / 1152.0, spot.light_energy if spot != null else -1.0,
			glow.light_energy if glow != null else -1.0, (moons[0] as DirectionalLight3D).light_energy if not moons.is_empty() else -1.0])

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
