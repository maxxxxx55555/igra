extends RefCounted
## Session 29 (the v1.0.0-ship pass), C block, the pickups and the quick bar: MESH1 every item of data/items has a mesh of its own of 400 triangles at most (C1), MAT1 scrap, paper and the rest of the junk give no light, a key's
## accent gives at most 0.6 (C1); CUBE1 no pickup of a district holds a light, CUBE2 a district holds 12 pickups at most, 5 m apart, with the repair parts in stacks of two and the notes on poles, CUBE3 no pickup is a bare box
## (C2, C4); GROUND1 an item lies on the ground, drops in once and turns only when it is a key, a blueprint or a gun (C3); GLOW1 the pools of light under the pickups are 6 at most and fade between 10 and 16 m (C2); WEAPON1 each
## gun has a viewmodel of its own with a part that works on a shot (C6). The tested files are loaded when the checks run, so a tree without them fails the check and does not stop the run. Wired into
## _closeout_check_runner.gd next to s29_look_checks.gd; CLOSEOUT_ONLY=s29 runs it. The quick bar (QSLOT1, QSLOT2, WCMP1) is in s29_bar_checks.gd.

const _Density := preload("res://scripts/tools/rc16/density_checks.gd")
const _MESHES: String = "res://scripts/art/pickup_meshes.gd"
const _PARTS: String = "res://scripts/art/part_mesh.gd"
const _WEAPONS: String = "res://scripts/art/weapon_meshes.gd"
const _SHADOWS: String = "res://scripts/world/contact_shadows.gd"
const _ITEM: String = "res://scenes/pickups/item_pickup_3d.tscn"
const _GUN: String = "res://scenes/pickups/weapon_pickup.tscn"
const FAR := Vector3(0.0, 0.05, -400.0)

static func run(r: Node) -> void:
	r._playing()
	_library(r)
	await _districts(r)
	await _ground(r)
	await _glow(r)
	await _viewmodels(r)
	r._playing()

static func _triangles(mesh: Mesh) -> int:
	return (load(_PARTS) as Script).call("triangles", mesh)

## MESH1, MAT1: the 49 items of data/items, none of them the crate that stands in for an unknown one, none a box, each of 1 to 400 triangles, no two families of one outline.
static func _library(r: Node) -> void:
	if not ResourceLoader.exists(_MESHES) or not ResourceLoader.exists(_PARTS):
		r._ok(false, "MESH1 scripts/art/pickup_meshes.gd and part_mesh.gd exist")
		return
	var lib: Script = load(_MESHES)
	var ids: Array[StringName] = []
	for file in DirAccess.get_files_at("res://data/items"):
		if file.ends_with(".tres"):
			ids.append(StringName(file.trim_suffix(".tres")))
	var families: Dictionary = {}
	var outlines: Dictionary = {}
	var bad: Array[String] = []
	for id in ids:
		var family: StringName = lib.call("family_of", id)
		families[family] = true
		var mesh: Mesh = lib.call("mesh_for", id)
		var tris: int = _triangles(mesh)
		var size: Vector3 = mesh.get_aabb().size
		outlines["%d|%.2f|%.2f|%.2f" % [tris, size.x, size.y, size.z]] = true
		if family == &"crate" or mesh is BoxMesh or tris < 1 or tris > 400:
			bad.append("%s %s %d" % [id, family, tris])
	r._ok(ids.size() == 49 and bad.is_empty() and outlines.size() >= families.size(), "MESH1 %d items in %d families, %d outlines, none a crate or a box or over 400 triangles (%s)" % [ids.size(), families.size(), outlines.size(), bad])
	var dull: bool = true
	for id: StringName in [&"scrap", &"metal", &"gear", &"plank", &"paper", &"document", &"photo", &"audio_log"]:
		for mat: StandardMaterial3D in lib.call("materials_for", id):
			dull = dull and not mat.emission_enabled
	var key_mats: Array = lib.call("materials_for", &"key")
	var key_ok: bool = not (key_mats[0] as StandardMaterial3D).emission_enabled and (key_mats[1] as StandardMaterial3D).emission_energy_multiplier <= 0.6
	var cell_mats: Array = lib.call("materials_for", &"battery")
	r._ok(dull and key_ok and (cell_mats[1] as StandardMaterial3D).emission_enabled, "MAT1 scrap, metal, gear, plank and the pages give no light (%s), a key glows on its bow at 0.6 or less and not on its shank (%s), a cell glows" % [dull, key_ok])

## CUBE1, CUBE2, CUBE3: every district as the game lays it out (default seeds, nothing taken yet, no gun found).
static func _districts(r: Node) -> void:
	var taken0: Dictionary = ProgressTracker._loot_taken.duplicate()
	var guns0: Dictionary = ProgressTracker._weapons.duplicate()
	var pack0: Dictionary = InventoryManager.to_dict()
	ProgressTracker._loot_taken.clear()
	ProgressTracker._weapons.clear()
	var lights: int = 0
	var boxes: int = 0
	var worst: int = 0
	var closest: float = INF
	var nearest: String = ""
	var counts: Array[String] = []
	var gates: bool = true
	var notes: int = 0
	var mounted: int = 0
	var notes_wanted: int = 0
	for id: StringName in DistrictSceneFactory.DISTRICTS:
		var root: Node3D = await _Density._build(r, id)
		DistrictLoot.populate(root, id)
		var all: Array[Node3D] = []
		for node in r.get_tree().get_nodes_in_group(&"pickup"):
			if root.is_ancestor_of(node):
				all.append(node as Node3D)
		var loose: int = 0
		var stacks: Dictionary = {}
		for node in all:
			lights += node.find_children("*", "OmniLight3D", true, false).size()
			for piece in node.find_children("*", "MeshInstance3D", true, false):
				var shown: Mesh = (piece as MeshInstance3D).mesh
				boxes += 1 if shown == null or shown is BoxMesh else 0
			if node.is_in_group(&"document"):
				notes += 1
				mounted += 1 if node.get("mounted") == true and node.global_position.y > 0.9 and node.global_position.y < 1.5 else 0
			else:
				loose += 1
				stacks[node.get("item_id")] = node.get("amount")
		worst = maxi(worst, loose)
		notes_wanted += 1 + (DistrictLoot.LORE_DOCS[id] as Array).size()
		for a in all:
			for b in all:
				var gap: float = Vector2(a.global_position.x - b.global_position.x, a.global_position.z - b.global_position.z).length() if a != b else INF
				if gap < closest:
					closest = gap
					nearest = "%s: %s %s and %s %s" % [id, a.name, a.global_position, b.name, b.global_position]
		for part in DistrictLoot.REPAIR_PARTS:
			gates = gates and int(stacks.get(part, 0)) >= 2
		gates = gates and (not DistrictLoot.BLUEPRINTS.has(id) or stacks.has(DistrictLoot.BLUEPRINTS[id]))
		counts.append("%s %d" % [id, loose])
		root.queue_free()
		await r.get_tree().process_frame
	ProgressTracker._loot_taken = taken0
	ProgressTracker._weapons = guns0
	InventoryManager.from_dict(pack0)
	r._ok(lights == 0, "CUBE1 no pickup of the 11 districts holds a light (%d lights)" % lights)
	r._ok(worst <= 12 and closest >= 5.0 and gates, "CUBE2 at most %d pickups a district (12 allowed) and the nearest two are %.1f m apart (5 allowed; %s), every district holds its repair parts in stacks of two and its blueprint (%s)" % [worst, closest, nearest, counts])
	r._ok(boxes == 0 and notes == notes_wanted and mounted > 0, "CUBE3 no pickup mesh is a bare box (%d), the 11 districts hold %d notes (%d: one on the ground and the lore notes to pin), %d of them pinned on poles" % [boxes, notes, notes_wanted, mounted])

## GROUND1: an item lies on the ground (its mesh rests on the origin of the pickup), drops in once over 0.35 s and does not bob; a medkit does not turn, a key and a gun turn at 0.25 rad/s; Reduce UI Motion keeps all of it still.
static func _ground(r: Node) -> void:
	var calm0: Variant = SettingsManager.get_setting("reduce_ui_motion", false)
	var rows: Array[String] = []
	var ok: bool = FileAccess.get_file_as_string("res://scripts/pickups/item_pickup_3d.gd").find("sin(") < 0 and FileAccess.get_file_as_string("res://scripts/gameplay/weapon_pickup.gd").find("_animate_float") < 0
	for calm: bool in [false, true]:
		SettingsManager.set_setting("reduce_ui_motion", calm)
		for kind: Array in [[_ITEM, &"medkit", 0.0], [_ITEM, &"key", 0.25], [_GUN, &"rifle", 0.25]]:
			var pickup := (load(kind[0]) as PackedScene).instantiate() as Node3D
			if kind[0] == _ITEM:
				pickup.set("item_id", kind[1])
			else:
				pickup.set("weapon_name", String(kind[1]))
			pickup.position = FAR
			r.add_child(pickup)
			await r.get_tree().process_frame
			var piece := pickup.get_node("MeshInstance3D") as MeshInstance3D
			var rest: float = -piece.mesh.get_aabb().position.y
			var start: float = piece.position.y - rest
			await r.get_tree().create_timer(0.5).timeout
			var settled: float = piece.position.y - rest
			var turn0: float = piece.rotation.y
			await r.get_tree().create_timer(1.0).timeout
			var turned: float = piece.rotation.y - turn0
			var low: float = (piece.global_transform * piece.mesh.get_aabb()).position.y - pickup.global_position.y
			var want_turn: float = 0.0 if calm else float(kind[2])
			var row_ok: bool = not (piece.mesh is BoxMesh) and absf(settled) < 0.002 and absf(low) < 0.01 and absf(turned - want_turn) < 0.06 and (start < 0.002 if calm else start > 0.15)
			ok = ok and row_ok
			rows.append("%s %s: starts %.2f over, rests %.3f, bottom %.3f, turns %.2f" % ["still" if calm else "live", kind[1], start, settled, low, turned])
			pickup.queue_free()
	SettingsManager.set_setting("reduce_ui_motion", calm0)
	r._ok(ok, "GROUND1 pickups rest on the ground, drop in 0.25 m once, do not bob and turn only the keys, blueprints and guns (%s)" % [rows])

## GLOW1: the pools of light under the pickups, 6 at most and the nearest, full inside 10 m, half at 13 m and gone at 16 m, none for the pickup that does not glow.
static func _glow(r: Node) -> void:
	if not ResourceLoader.exists(_SHADOWS) or not ResourceLoader.exists(_MESHES):
		r._ok(false, "GLOW1 contact_shadows.gd exists")
		return
	var previous: Camera3D = r.get_viewport().get_camera_3d()  # the district of the run has pickups of its own near the player: the test looks from the far corner
	var eye := Camera3D.new()
	r.add_child(eye)
	eye.global_position = r.FAR + Vector3(0.0, 1.55, 0.0)
	eye.make_current()
	var scene: PackedScene = load(_ITEM)
	var pickups: Array[Node3D] = []
	for i in 9:
		var item := scene.instantiate() as Node3D
		item.set("item_id", &"battery" if i < 8 else &"scrap")
		r.add_child(item)
		item.global_position = Vector3(eye.global_position.x + 2.0 + i, 0.05, eye.global_position.z + 2.0 * (i % 3))
		pickups.append(item)
	var board := (load(_SHADOWS) as Script).new() as MultiMeshInstance3D
	r.add_child(board)
	await r.get_tree().create_timer(0.5).timeout
	var pool := board.get_node_or_null("PickupGlow") as MultiMeshInstance3D
	var shown: int = pool.multimesh.visible_instance_count if pool != null else -1
	var full: float = board.glow_strengths[0] if shown > 0 else 0.0  # a headless run keeps no instance colours: the board keeps what it wrote
	for item in pickups:
		item.global_position = Vector3(eye.global_position.x + 40.0, 0.05, eye.global_position.z)
	pickups[0].global_position = Vector3(eye.global_position.x + 12.4, 0.05, eye.global_position.z)  # 12.5 m from the eye, 1.55 m up
	await r.get_tree().create_timer(0.5).timeout
	var one: int = pool.multimesh.visible_instance_count if pool != null else -1
	var half: float = board.glow_strengths[0] if one > 0 else 0.0
	pickups[0].global_position = Vector3(eye.global_position.x + 40.0, 0.05, eye.global_position.z)
	await r.get_tree().create_timer(0.5).timeout
	var none: int = pool.multimesh.visible_instance_count if pool != null else -1
	r._ok(shown == 6 and one == 1 and none == 0 and full > 0.3 and half > 0.35 * full and half < 0.65 * full, "GLOW1 9 pickups near the camera, 8 of them glowing: %d pools (6 at most), the strength %.2f; one at 12.5 m: %d pool at %.2f (about half); all beyond 16 m: %d" % [shown, full, one, half, none])
	board.queue_free()
	for item in pickups:
		item.queue_free()
	eye.queue_free()
	if is_instance_valid(previous):
		previous.make_current()

## WEAPON1 (C6): each gun is a model of its own, a Body and the part that works (Slide, Bolt, Pump) of 600 triangles at most; a shot sends the part back and it returns; Motion Comfort holds it still.
static func _viewmodels(r: Node) -> void:
	if not ResourceLoader.exists(_WEAPONS):
		r._ok(false, "WEAPON1 scripts/art/weapon_meshes.gd exists")
		return
	var weapons: Script = load(_WEAPONS)
	var moving: Dictionary = weapons.get_script_constant_map()["MOVING"]
	var outlines: Dictionary = {}
	var shapes_ok: bool = true
	for id: StringName in [&"pistol", &"rifle", &"shotgun"]:
		var model: Node3D = weapons.call("model", id)
		var tris: int = 0
		var box := AABB()
		for piece in model.get_children():
			tris += _triangles((piece as MeshInstance3D).mesh)
			box = box.merge((piece as MeshInstance3D).mesh.get_aabb())
		outlines["%.2f|%.2f|%.2f" % [box.size.x, box.size.y, box.size.z]] = true
		shapes_ok = shapes_ok and model.get_child_count() == 2 and model.get_child(0).name == &"Body" and model.get_child(1).name == StringName(moving[id]) and tris <= 600 and tris > 0
		model.free()
	var manager: Node = r._player.get_node_or_null("WeaponManager")
	var guns0: Dictionary = ProgressTracker._weapons.duplicate()
	var worked: bool = false
	var calm: bool = false
	if manager != null and manager.call("unlock", &"pistol"):
		var gun: Node = (manager.get("_weapons") as Dictionary)[&"pistol"]
		var slide := gun.get_node("WeaponModel").get_child(1) as Node3D
		gun.emit_signal("fired")
		await r.get_tree().create_timer(0.04).timeout
		var back: float = slide.position.z
		await r.get_tree().create_timer(0.3).timeout
		worked = back > 0.015 and absf(slide.position.z) < 0.001
		SettingsManager.set_setting("reduce_camera_motion", true)
		gun.emit_signal("fired")
		await r.get_tree().create_timer(0.04).timeout
		calm = absf(slide.position.z) < 0.001
		SettingsManager.set_setting("reduce_camera_motion", false)
		(manager.get("_weapons") as Dictionary).erase(&"pistol")
		gun.queue_free()
	ProgressTracker._weapons = guns0
	r._ok(shapes_ok and outlines.size() == 3 and worked and calm, "WEAPON1 three viewmodels of three outlines, each of 600 triangles at most with a Body and its Slide, Bolt or Pump (%s); a shot sends the slide back and it returns (%s) and not with Motion Comfort (%s)" % [shapes_ok, worked, calm])
