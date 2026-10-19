extends RefCounted
## Session 28 (D1 and S1, the masterpiece pass): the wake radius of the three heavy kinds and the edge sweeps that no check held yet; run after the D1 checks of s28_checks.gd (CLOSEOUT_ONLY=s28).
##   WAKE1  a Hunter, a Watcher or a Destroyer switches itself off out of the camera's view (scripts/components/visibility_enabler.gd) except within wake_m of the player: one 6 m behind the player's back is awake, one in the far corner sleeps
##   BAT0   the Architect takes damage in his second phase only inside the flashlight's beam, so a light that died there (battery 0, no spare) left a fight that could be neither won nor lost: out of the beam he swings now, after a cue,
##          and in the beam he does not
##   PICK1  a pickup on a full pack stays in the world and the pack is as it was
##   SAVE1  a save written while the player is out of the world (the scene swap of a transition) reads back whole and loads, and a fade that a load interrupts still ends
##   V1A    the details of V1 batch A stand where they should (a check of the mechanism; the frames judge whether they are a gain): at the High tier the panes carry the window shader with their interiors on, every pane has
##          a halo and every lamp a cone of light; the cone is hidden at DARK and shown with the power
##   V1B    the cones and the halos sort after the other transparent objects (the render priority of WindowHalos.RENDER_PRIORITY, above 0): at the default the flashlight turned the cones into cream pyramids and the halos into pale blocks
##   BURST1 every burst scene (scenes/vfx) keeps the scale of its particles: a billboard drops it unless the material keeps it, so each particle was the 1 m of its quad and the confetti of a find hid the screen
##   MOTE1  the dust motes in the beams of the lamps (scripts/effects/dust_motes.gd) keep the scale of their particles for the same reason: 2.5 to 6 cm, and not smudges of 1 m
##   ENDC1  the title of every ending is read against the panel of the win screen at 3 to 1 or better (the dark ending's was 1.1 to 1: the one line that says which ending it is could not be read)
##   STORY1 every district holds two or three story scenes (story_props.gd), each 2.6 m from a hiding place and 2.2 m or more from anything the player can use or hide in, inside the ring, and each has its line;
##          the three kinds all stand somewhere. The district is built the way the game builds it (the loot, hence the hiding places, before the dressing): a bare scene has no hiding place to anchor a scene to
##   STORY2 a player who walks into the trigger of a scene (made where the world is empty, so the check does not depend on the placement that STORY1 holds) hears its line once and the trigger ends with the visit: the physics
##          wiring (the layer of the trigger, the group of the body), not the handler
## The other five edge sweeps of the pass are held by older checks that run in every battery: LANG1 (a language switch under an open menu), EX3 (a full pack), EX4 (a dead battery), EX10 (no ad SDK) and HC1 (Hardcore ticked in the middle of a run).

const _S28 := preload("res://scripts/tools/rc16/s28_checks.gd")
const _Density := preload("res://scripts/tools/rc16/density_checks.gd")
const _StoryProps := preload("res://scripts/world/story_props.gd")
const _LampDetails := preload("res://scripts/world/lamp_details.gd")
const _Win := preload("res://scripts/ui/win_screen.gd")
const _Halos := preload("res://scripts/world/window_halos.gd")
const _Motes := preload("res://scripts/effects/dust_motes.gd")
const _FAR := Vector3(-600.0, 0.0, 600.0)

static func run(r: Node) -> void:
	r._playing()
	await _wake(r)
	await _battery_in_the_dark(r)
	_pack_full_pickup(r)
	await _save_between_scenes(r)
	await _v1_nodes(r)
	_burst_scale(r)
	_ending_titles(r)
	await _story_scenes(r)
	var walk: String = await _walk_into(r)
	r._ok(walk == "ok", "STORY2 a walk into a story trigger is heard once and ends it: %s" % walk)
	r._playing()

static func _wake(r: Node) -> void:
	var player: Node3D = r._player
	var near: Node3D = r._monster("hunter_3d", player.global_position + player.global_transform.basis.z * 6.0)
	var far: Node3D = r._monster("hunter_3d", _FAR)
	await r.get_tree().create_timer(0.8).timeout
	var awake: bool = near.process_mode != Node.PROCESS_MODE_DISABLED
	var asleep: bool = far.process_mode == Node.PROCESS_MODE_DISABLED
	near.queue_free()
	far.queue_free()
	r._ok(awake and asleep, "WAKE1 a Hunter 6 m behind the player is awake (%s) and one in the far corner sleeps (%s): the heavy kinds switch off out of the view and stay on within the wake radius" % [awake, asleep])

static func _battery_in_the_dark(r: Node) -> void:
	var boss: Node3D = r._monster("boss_architect_3d", _FAR + Vector3(0.0, 0.0, 400.0))
	var victim: Node3D = _S28._stand_in(r, _S28._VICTIM_SRC, boss.global_position + Vector3(0.8, 0.0, 0.0))
	var telegraph: Node = boss.get("_telegraph")
	boss.set("player_ref", victim)
	boss.set("_music_started", true)
	boss.set("phase", 1)
	boss.call("_ensure_hp")
	boss.set("attack_timer", 0.0)
	boss.set("_is_in_flashlight", false)
	var hp0: float = float(boss.get("hp"))
	boss.call("take_damage", 50.0)
	var immune: bool = is_equal_approx(float(boss.get("hp")), hp0)
	boss.call("_tick_p2", 0.016)
	var dark_cue: bool = int(telegraph.get("last_cue_msec")) >= 0
	telegraph.set("last_cue_msec", -1)
	boss.set("attack_timer", 0.0)
	boss.set("_is_in_flashlight", true)
	boss.call("_tick_p2", 0.016)
	var lit_cue: bool = int(telegraph.get("last_cue_msec")) >= 0
	await r.get_tree().create_timer(0.7).timeout
	var swung: bool = int(victim.get("hit_msec")) >= 0
	boss.queue_free()
	victim.queue_free()
	r._ok(immune and dark_cue and swung and not lit_cue, "BAT0 the Architect in his second phase takes nothing out of the beam (%s) and swings there after a cue (cue %s, hit %s); inside the beam he does not swing (%s)" % [immune, dark_cue, swung, lit_cue])

static func _pack_full_pickup(r: Node) -> void:
	var player: Node3D = r._player
	var pack: Dictionary = InventoryManager.to_dict()
	for i in InventoryManager.slots.size():
		InventoryManager.slots[i] = {"item_id": &"scrap", "count": 999}
	InventoryManager.call("_recompute_weight")
	var pickup := (load("res://scenes/pickups/item_pickup_3d.tscn") as PackedScene).instantiate() as Node3D
	pickup.set("item_id", &"metal")
	pickup.set("amount", 1)
	r.add_child(pickup)
	pickup.global_position = _FAR
	pickup.call("_on_body_entered", player)
	var stayed: bool = is_instance_valid(pickup) and not bool(pickup.get("_picked_up")) and not pickup.is_queued_for_deletion()
	var unchanged: bool = InventoryManager.count_of(&"metal") == 0
	pickup.queue_free()
	InventoryManager.from_dict(pack)
	r._ok(stayed and unchanged, "PICK1 a pickup on a full pack stays in the world (%s) and the pack gains nothing (%s)" % [stayed, unchanged])

static func _save_between_scenes(r: Node) -> void:
	var player: Node3D = r._player
	player.remove_from_group("player")
	SaveSystem.save_all()
	player.add_to_group("player")
	var data: Dictionary = SaveSystem._read_envelope(SaveSystem.SAVE_PATH)
	var vitals: Variant = data.get("vitals", null)
	var position: Variant = data.get("player_pos", null)
	var whole: bool = not data.is_empty() and vitals is Dictionary and (vitals as Dictionary).is_empty() and position is Array and (position as Array).is_empty()
	var loaded: bool = SaveSystem.load_all()
	FadeTransition.fade_to(func() -> void: SaveSystem.load_all(), 0.05)
	await r.get_tree().create_timer(0.6).timeout
	var fade_ended: bool = not bool(FadeTransition.get("_busy"))
	r._ok(whole and loaded and fade_ended and GameManager.is_playing(), "SAVE1 a save written with the player out of the world reads back whole (%s: no vitals, no position) and loads (%s); a load inside a fade leaves the fade ended (%s)" % [whole, loaded, fade_ended])

static func _v1_nodes(r: Node) -> void:
	var tier0: Variant = SettingsManager.get_setting("graphics_tier", 2)
	SettingsManager.set_setting("graphics_tier", 2)
	var root: Node3D = await _Density._build(r, &"suburbs")
	var props: Node = root.get_node("Props")
	var windows := props.find_child("Windows", true, false) as MultiMeshInstance3D
	var halos := props.find_child("WindowHalos", true, false) as MultiMeshInstance3D
	var cones := props.find_child("LampCones", true, false) as MultiMeshInstance3D
	var lamps := props.get_node("StreetlightLampsBatched") as MultiMeshInstance3D
	var panes_ok: bool = windows != null and windows.material_override is ShaderMaterial and is_equal_approx(float((windows.material_override as ShaderMaterial).get_shader_parameter("interior")), 1.0)
	var halos_ok: bool = halos != null and windows != null and halos.multimesh.instance_count == windows.multimesh.instance_count and halos.visible
	var cones_ok: bool = cones != null and cones.multimesh.instance_count == lamps.multimesh.instance_count
	var details: Node = props.find_child("LampDetails", true, false)
	var stage_ok: bool = false
	if details != null and cones != null:
		details.call("_apply_stage", 3)
		var shown: bool = cones.visible and is_equal_approx(float((cones.material_override as ShaderMaterial).get_shader_parameter("strength")), _LampDetails.STRENGTH_BY_STAGE[3])
		details.call("_apply_stage", 0)
		stage_ok = shown and not cones.visible
	var priority_ok: bool = _Halos.RENDER_PRIORITY > 0 and cones != null and halos != null and (cones.material_override as ShaderMaterial).render_priority == _Halos.RENDER_PRIORITY \
		and (halos.material_override as ShaderMaterial).render_priority == _Halos.RENDER_PRIORITY
	SettingsManager.set_setting("graphics_tier", tier0)
	root.queue_free()
	r._ok(panes_ok and halos_ok and cones_ok and stage_ok, "V1A the details of batch A stand: window shader %s, halos %s, light cones %s, the cone follows the power %s" % [panes_ok, halos_ok, cones_ok, stage_ok])
	r._ok(priority_ok, "V1B the cones and the halos sort after the other transparent objects (render priority %d): the flashlight turned them into cream pyramids and pale blocks at the default" % _Halos.RENDER_PRIORITY)

## WCAG contrast of two colours (the relative luminance of each from its linear channels).
static func _contrast(a: Color, b: Color) -> float:
	var la: float = a.srgb_to_linear().get_luminance()
	var lb: float = b.srgb_to_linear().get_luminance()
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)

static func _ending_titles(r: Node) -> void:
	var worst: float = INF
	var which: String = ""
	for id: String in EndingsManager.ENDING_DATA:
		var ratio: float = _contrast(EndingsManager.ENDING_DATA[id]["color"], _Win.BG)
		if ratio < worst:
			worst = ratio
			which = id
	r._ok(worst >= 3.0, "ENDC1 every ending title is read against the win screen at 3 to 1 or better: the worst is %s at %.2f to 1" % [which, worst])

static func _burst_scale(r: Node) -> void:
	var bad: Array[String] = []
	var bursts: int = 0
	for file: String in DirAccess.get_files_at("res://scenes/vfx"):
		var node: Node = (load("res://scenes/vfx/" + file) as PackedScene).instantiate()
		if node is VFXBurst:
			r.add_child(node)
			bursts += 1
			var material := ((node as VFXBurst).draw_pass_1 as QuadMesh).material as StandardMaterial3D
			if material == null or not material.billboard_keep_scale:
				bad.append(file)
		node.free()
	r._ok(bursts >= 7 and bad.is_empty(), "BURST1 every burst keeps the scale of its particles (%d bursts): %s" % [bursts, bad])
	var motes: Node = _Motes.new()
	r.add_child(motes)
	var mote_quad := (motes.get_child(0) as GPUParticles3D).draw_pass_1 as QuadMesh
	r._ok((mote_quad.material as StandardMaterial3D).billboard_keep_scale, "MOTE1 the dust motes in the beams keep the scale of their particles (2.5 to 6 cm, not the 1 m of their quad)")
	motes.free()

## A district the way the game builds it: the scene, then the loot with its three hiding places, and the dressing a frame later (street_props.gd builds deferred), which anchors the story scenes to the hiding places.
static func _district_with_loot(r: Node, id: StringName) -> Node3D:
	var root := (load(DistrictSceneFactory.district_scene_path(id)) as PackedScene).instantiate() as Node3D
	var trigger: Node = root.get_node("DistrictTrigger")
	root.remove_child(trigger)  # a trigger box on the player would announce a district that was not entered
	trigger.free()
	r.add_child(root)
	DistrictLoot.populate(root, id)
	for i in 6:
		await r.get_tree().process_frame
	return root

static func _story_scenes(r: Node) -> void:
	var tier0: Variant = SettingsManager.get_setting("graphics_tier", 2)
	SettingsManager.set_setting("graphics_tier", 2)
	var counts: Array[int] = []
	var bad: Array[String] = []
	var kinds: Dictionary = {}
	for id: StringName in DistrictSceneFactory.DISTRICTS:
		var root: Node3D = await _district_with_loot(r, id)
		var dressing: Node = root.get_node("Props/DistrictDressing")
		var spots: Array = dressing.get_meta("story_spots", [])
		var clear: Array = dressing.get("_clear")
		var hooks: Array[Area3D] = []
		for child: Node in dressing.get_children():
			if child is Area3D and String(child.name).begins_with("StoryHook_"):
				hooks.append(child as Area3D)
				kinds[String(child.name)] = true
		var fine: bool = hooks.size() == spots.size() and spots.size() >= 2 and spots.size() <= 3
		for spot: Vector3 in spots:
			var nearest: float = INF
			for other: Vector2 in clear:
				nearest = minf(nearest, other.distance_to(Vector2(spot.x, spot.z)))
			fine = fine and nearest > 2.19 and nearest < 2.61 and absf(spot.x) < 24.0 and absf(spot.z) < 24.0
		counts.append(spots.size())
		if not fine:
			bad.append("%s %d" % [id, spots.size()])
		root.queue_free()
		await r.get_tree().process_frame
	SettingsManager.set_setting("graphics_tier", tier0)
	r._ok(bad.is_empty() and kinds.size() == 3, "STORY1 the story scenes: %s a district (two or three each, off by: %s), the three kinds stand: %s" % [counts, bad, kinds.keys()])

## STORY2 makes the trigger of a camp where the world is empty, puts the real player in it, runs the physics, and wants the notice of its kind exactly once and the trigger gone. "ok", or what was wrong.
static func _walk_into(r: Node) -> String:
	var holder := Node3D.new()
	r.add_child(holder)
	_StoryProps.hook(holder, _FAR, "camp")
	var hook := holder.get_child(0) as Area3D
	var line: String = LocalizationManager.t(_StoryProps.LINE_KEYS["camp"])
	var heard: Array[String] = []
	var listen := func(message: String) -> void: heard.append(message)
	EventBus.inventory_notice.connect(listen)
	var player: Node3D = r._player
	var from: Vector3 = player.global_position
	player.global_position = Vector3(_FAR.x, 0.0, _FAR.z)
	for i in 5:
		await r.get_tree().physics_frame
	player.global_position = from
	for i in 3:
		await r.get_tree().physics_frame
	EventBus.inventory_notice.disconnect(listen)
	var gone: bool = not is_instance_valid(hook) or hook.is_queued_for_deletion()
	holder.queue_free()
	if heard.count(line) != 1 or line.begins_with("STORY_"):
		return "heard %s, wanted exactly one [%s]" % [heard, line]
	return "ok" if gone else "the trigger stays after the visit"
