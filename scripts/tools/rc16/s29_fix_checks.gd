extends RefCounted
## Session 29 (the v10.0.0-ship pass), G-FIX2: the closeout checks of the rows of docs/NITPICK_v1.0.md that were fixed, each one failing on the code it replaced (tools/qa_sim/s26_mutations.py, sets 17 and after).
## DROP1 (N017): what a killed monster drops lies on the floor under it, not at knee height (the owner's first complaint was cubes hanging in the air); CONF1 (N003): the burst of a finished quest is soft sparks (a
## texture, 24 at most), not thirty white squares; FONT1 (N016): the headings of the screens are set in the face of the buttons; SIGN2 (N013): no two signs of a facade overlap; HIDE1 (N004): a hiding spot is a mesh of parts that
## fills the box of its collider, not a bare box; QBAR1 (N025): the one slot of the quick bar at the first frame is a slot, not a plank as long as the bar; STAM1 (N032): at 0 stamina the sprint is off until a quarter
## of the bar is back; QORD1 and TXT1 (N043, N041, N042, N076): the first quests are the ones the first district makes progress on and the quests and the tutorial name the districts, the monsters and the power switch of the game; TUT3 (N066): a pickup completes its hint; BOB1 (N058): the eye bobs at a human cadence; LAMP3 (N065): a lamp dips three times a second at most; BOSSHIT1 and BOSSHIT2 (N059, N060): a hit on the Architect has its feedback and a blow outside the beam says so; MASTER1 (N084): the Master bus ends in a limiter; CUBE4 (N051, N010, the owner's first complaint): the secret, the workbench, the bed, the power switch, the cable box and the generator are meshes of parts resting on the floor, and the secret and the workbench hold no light of their own; SYNC1 (N033): the arm of a Hunter or a Brute comes down when its hit lands, a second after the cue and not at 0.4 s; HUM1 (N027): none of the nine detail loops that were a steady low tone is played, and every loop that is listed exists; FLICK1 (N034): the light of a low battery changes at most three times a second; QUEST1 (N044): the objective list does not come back over a menu when a screen closes. Wired into
## _closeout_check_runner.gd.

const _CONFETTI := "res://scenes/vfx/vfx_confetti.tscn"
const _SIGNS := preload("res://scripts/world/soviet_signs.gd")
const _S29 := preload("res://scripts/tools/rc16/s29_checks.gd")
const _PARTS := preload("res://scripts/art/part_mesh.gd")
const _ATMOSPHERE := preload("res://scripts/world/district_atmosphere.gd")
## The detail loops tools/qa_sim/hum_scan.py read as one steady low tone or rumble (docs/NITPICK_v1.0.md N027): the owner's rule is no hum beds.
const _HUM_LOOPS: Array[String] = ["substation_transformer_buzz", "gas_station_sign_buzz", "substation_cable_hum", "substation_arc_crackle", "gas_station_pump_hum", "industrial_machinery_drone", "park_distant_city_hum", "power_station_generator_thrum", "power_station_breaker_clunk"]
const _ROLLS: int = 80
const _TIGHT_SEEDS: int = 200

static func run(r: Node) -> void:
	_drop_on_floor(r)
	_confetti(r)
	_signs_clear(r)
	_hiding_meshes(r)
	_props(r)
	_no_hum_loops(r)
	_quick_bar(r)
	_stamina_latch(r)
	_strike_with_hit(r)
	_flicker_rate(r)
	_quest_overlay(r)
	_quest_order(r)
	_quest_words(r)
	await _pickup_hint(r)
	_bob_rate(r)
	_lamp_dips(r)
	_boss_hits(r)
	_master_limit(r)
	await _heading_face(r)

static func _confetti(r: Node) -> void:
	var burst := (load(_CONFETTI) as PackedScene).instantiate() as GPUParticles3D
	var textured: bool = burst.get("burst_texture") != null
	var count: int = burst.amount
	burst.free()
	r._ok(textured and count <= 24, "CONF1 the burst of a finished quest is a texture of soft sparks (%s) and %d of them (24 at most)" % [textured, count])

## DROP1: every monster of the roster, killed on the floor, drops its loot at the floor its feet stand on (ANIM7 holds the feet to the floor of the capsule).
static func _drop_on_floor(r: Node) -> void:
	var worst: float = 0.0
	var dropped: int = 0
	for scene: String in _S29._SCENES:
		var monster: Node3D = r._monster(scene)
		var floor_y: float = monster.global_position.y - ((monster.get_node("CollisionShape3D") as CollisionShape3D).shape as CapsuleShape3D).height * 0.5
		var before: int = monster.get_parent().get_child_count()
		for _roll in _ROLLS:
			monster.call("_maybe_drop_loot")
		var drops: Array = monster.get_parent().get_children().slice(before)
		dropped += 1 if not drops.is_empty() else 0
		for drop: Node in drops:
			worst = maxf(worst, absf((drop as Node3D).global_position.y - floor_y))
			drop.queue_free()
		monster.queue_free()
	r._ok(dropped == _S29._SCENES.size() and worst < 0.01, "DROP1 the loot of %d of %d monsters lies on the floor under them (worst gap %.3f m)" % [dropped, _S29._SCENES.size(), worst])

## SIGN2: the layout of the signs of the 11 districts (their own skyline widths and words) and of 200 seeds of a tight one (two faces of 18 m, four signs of 3 m) leaves no two signs of one face closer than the gap.
static func _signs_clear(r: Node) -> void:
	var font: Font = ThemeDB.fallback_font
	var overlaps: int = 0
	for id: StringName in DistrictSceneFactory.DISTRICTS:
		var sky := CitySkyline.new()
		r.add_child(sky)
		sky.build(id, 24.0, true)
		var widths: Array[float] = []
		widths.assign(sky.get("_widths"))
		sky.queue_free()
		var words: Array[String] = _SIGNS.words_of(id)
		var sign_w: Array[float] = []
		for i in _SIGNS.SIGNS:
			sign_w.append(_SIGNS.width_of(_SIGNS.fill_of(words[i % words.size()], font)))
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("signs_" + String(id))
		overlaps += _overlapping(_SIGNS.place(widths, sign_w, rng), sign_w)
	var tight: int = 0
	var faces: Array[float] = [18.0, 18.0]
	var small: Array[float] = [3.0, 3.0, 3.0, 3.0]
	for seed_no in _TIGHT_SEEDS:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_no
		tight += _overlapping(_SIGNS.place(faces, small, rng), small)
	r._ok(overlaps == 0 and tight == 0, "SIGN2 no two signs of a facade overlap: %d pairs in the 11 districts, %d in %d seeds of a tight facade" % [overlaps, tight, _TIGHT_SEEDS])

static func _overlapping(spots: Array[Vector2], sign_w: Array[float]) -> int:
	var pairs: int = 0
	for i in spots.size():
		for j in range(i + 1, spots.size()):
			if spots[i].x == spots[j].x and absf(spots[i].y - spots[j].y) < (sign_w[i] + sign_w[j]) * 0.5 + _SIGNS.GAP - 0.001:
				pairs += 1
	return pairs

## FONT1: the heading of a card (the shop), of the ending and of the skill tree is set in the face of the buttons, not in the body face of a Label.
static func _heading_face(r: Node) -> void:
	var want: Font = ThemeProvider.heading_font()
	var screens: Node = r._main.get_node("Screens")
	screens.call("show_screen", "Shop")
	await r.get_tree().process_frame
	var card_title := (screens.get("_screen_data") as Dictionary)["Shop"]["title_lbl"] as Label
	var shop: bool = card_title.get_theme_font(&"font") == want
	screens.call("hide_all")
	var ending := (load("res://scripts/ui/win_screen.gd") as GDScript).new() as Control
	r.add_child(ending)
	var win: bool = (ending.get("_title") as Label).get_theme_font(&"font") == want
	ending.queue_free()
	var tree := (load("res://scenes/ui/skill_tree_ui.tscn") as PackedScene).instantiate() as Control
	r.add_child(tree)
	var skills: bool = (tree.get("skill_points_label") as Label).get_theme_font(&"font") == want
	tree.queue_free()
	r._ok(want != null and shop and win and skills, "FONT1 the headings of the shop card (%s), of the ending (%s) and of the skill tree (%s) are set in the face of the buttons" % [shop, win, skills])

## The colliders of the six hiding spots as the game shipped them, written out: the check reads them here and not from the table the collider is built from.
const _HIDE_SIZES := {
	"locker": Vector3(0.9, 2.0, 0.7), "dumpster": Vector3(1.8, 1.2, 1.0), "car": Vector3(4.2, 1.4, 2.0),
	"crate": Vector3(1.2, 1.2, 1.2), "bush": Vector3(1.6, 1.1, 1.0), "dark_corner": Vector3(1.6, 2.2, 0.5),
}

## HIDE1: the six kinds of hiding spot are meshes of two surfaces (body and accent), at most 400 triangles, resting on the floor and filling the box of their collider (it keeps its size: the player collides with what is seen).
static func _hiding_meshes(r: Node) -> void:
	var off: Array[String] = []
	for kind: String in _HIDE_SIZES:
		var size: Vector3 = _HIDE_SIZES[kind]
		var spot := HidingSpot.new()
		spot.spot_type = kind
		r.add_child(spot)
		var piece := spot.get_node("Mesh") as MeshInstance3D
		var shape := ((spot.get_node("Body") as Node).get_child(0) as CollisionShape3D).shape as BoxShape3D
		var mesh := piece.mesh as ArrayMesh
		var box: AABB = mesh.get_aabb() if mesh != null else AABB()
		var fine: bool = mesh != null and mesh.get_surface_count() == 2 and shape.size == size and HidingSpot.TYPE_SIZES[kind] == size and box.position.y > -0.01 and box.end.y < size.y + 0.01
		fine = fine and absf(box.position.x) < size.x * 0.5 + 0.01 and box.end.x < size.x * 0.5 + 0.01 and absf(box.position.z) < size.z * 0.5 + 0.01 and box.end.z < size.z * 0.5 + 0.01
		fine = fine and box.size.x >= size.x * 0.85 and box.size.y >= size.y * 0.85 and _PARTS.triangles(mesh) <= 400
		fine = fine and (piece.get_surface_override_material(0) as StandardMaterial3D).albedo_color != (piece.get_surface_override_material(1) as StandardMaterial3D).albedo_color
		fine = fine and (kind != "dumpster" or (piece.get_surface_override_material(0) as StandardMaterial3D).albedo_texture != null)
		if not fine:
			off.append(kind)
		spot.queue_free()
	r._ok(off.is_empty() and HidingSpot.TYPE_SIZES.size() == _HIDE_SIZES.size(), "HIDE1 the %d hiding spots are meshes of two surfaces inside the box of their collider (the sizes of the baseline) and fill it (off: %s)" % [HidingSpot.TYPE_SIZES.size(), off])

## QBAR1: the six slots of the quick bar do not expand (the one slot of an empty run took the 384 px of the whole bar) and the bar centres what is on it.
static func _quick_bar(r: Node) -> void:
	var hud := (load("res://scenes/ui/hud_3d.tscn") as PackedScene).instantiate()
	var bar := hud.get_node("BottomCenter") as HBoxContainer
	var stretched: Array[String] = []
	for i in 6:
		if (bar.get_node("Slot%d" % i) as Control).size_flags_horizontal & Control.SIZE_EXPAND != 0:
			stretched.append("Slot%d" % i)
	var centred: bool = bar.alignment == BoxContainer.ALIGNMENT_CENTER
	hud.free()
	r._ok(stretched.is_empty() and centred, "QBAR1 no slot of the quick bar expands (%s) and the bar centres its slots (%s)" % [stretched, centred])

## STAM1: a sprint that drains the bar to 0 ends there and stays off until a quarter of the bar is back (it refilled in the same frame and the sprint went on at 96 % of its speed).
static func _stamina_latch(r: Node) -> void:
	var player: Node = r._player
	var cap: float = float((player.get("stats") as Resource).get("stamina_max"))
	var held: float = float(player.get("stamina"))
	player.set("stamina", 0.5)
	player.set("_winded", false)
	player.set("current_state", 2)
	player.call("_update_stamina", 0.1)
	var spent: bool = bool(player.get("_winded")) and not bool(player.call("_can_run"))
	player.set("current_state", 1)
	player.call("_update_stamina", 0.1)
	var held_off: bool = float(player.get("stamina")) > 0.0 and not bool(player.call("_can_run"))
	var back_at: float = -1.0
	for _step in 400:
		player.call("_update_stamina", 0.1)
		if not bool(player.get("_winded")):
			back_at = float(player.get("stamina"))
			break
	var resumed: bool = back_at >= cap * 0.25 and back_at < cap * 0.25 + 1.5 and bool(player.call("_can_run"))
	player.set("stamina", held)
	player.set("_winded", false)
	r._ok(spent and held_off and resumed, "STAM1 the sprint ends at 0 stamina (%s), stays off while the bar refills (%s) and is back at %.1f of %.0f (%s)" % [spent, held_off, back_at, cap, resumed])

## FLICK1: the light of a low battery (under 20 %) changes at most three times a second (one change per 340 ms), where it changed on every frame.
static func _flicker_rate(r: Node) -> void:
	var player: Node = r._player
	var light := player.get("flashlight") as SpotLight3D
	var on0: bool = bool(player.get("flashlight_enabled"))
	var battery0: float = float(player.get("battery"))
	var calm0: Variant = SettingsManager.get_setting("reduce_flash", false)
	SettingsManager.set_setting("reduce_flash", false)
	player.set("flashlight_enabled", true)
	player.set("battery", float(player.get("battery_max")) * 0.05)
	player.set("_flicker_next_msec", 0)
	var hold: int = int((player.get_script() as GDScript).get_script_constant_map()["FLICKER_HOLD_MSEC"])
	var last: float = light.light_energy
	var changes: int = 0
	var t0: int = Time.get_ticks_msec()
	for _frame in 240:
		player.call("_update_low_battery_flicker")
		if light.light_energy != last:
			changes += 1
			last = light.light_energy
	var allowed: int = (Time.get_ticks_msec() - t0) / hold + 2
	player.set("battery", battery0)
	player.call("_update_low_battery_flicker")
	player.set("flashlight_enabled", on0)
	SettingsManager.set_setting("reduce_flash", calm0)
	r._ok(changes >= 1 and changes <= allowed, "FLICK1 the light of a 5 %% battery changed %d times in 240 frames (%d allowed for the time they took: one per %d ms)" % [changes, allowed, hold])

## QUEST1: closing a screen shows the HUD again (UIManager._set_hud); the objective list must follow the state, not the signal, or it draws over the main menu after a run.
static func _quest_overlay(r: Node) -> void:
	var overlay := UIManager.get("_quest_hud") as CanvasItem
	GameManager._change_state(GameManager.GameState.PAUSED)
	EventBus.hud_visibility_changed.emit(true)
	var hidden_out_of_play: bool = overlay != null and not overlay.visible
	r._playing()
	UIManager.close_all_blocking()
	EventBus.hud_visibility_changed.emit(true)
	var shown_in_play: bool = overlay != null and overlay.visible
	r._ok(hidden_out_of_play and shown_in_play, "QUEST1 the objective list stays hidden when a screen closes out of play (%s) and shows in play (%s)" % [hidden_out_of_play, shown_in_play])

## HUM1: the table of the detail loops lists none of the nine hums and every loop it lists is a file (the python gate hum_scan.py reads the audio itself; this holds the table).
static func _no_hum_loops(r: Node) -> void:
	var hums: Array[String] = []
	var missing: Array[String] = []
	var listed: int = 0
	for district: StringName in _ATMOSPHERE.DETAIL_BEDS:
		for file: String in (_ATMOSPHERE.DETAIL_BEDS[district] as Dictionary):
			listed += 1
			if _HUM_LOOPS.has(file):
				hums.append(file)
			if not ResourceLoader.exists("res://assets/audio/ambience/district_details/%s.ogg" % file):
				missing.append(file)
	r._ok(hums.is_empty() and missing.is_empty() and listed > 0, "HUM1 the %d detail loops listed hold none of the %d hums (listed: %s) and all of them exist (missing: %s)" % [listed, _HUM_LOOPS.size(), hums, missing])

## SYNC1: a Hunter and a Brute hit 1.0 s after the cue (CHARGE_WINDUP, WINDUP_TIME); the strike pose of their arm peaks at that moment (it peaked at 0.5 s and the arm was back at rest at 0.8 s).
static func _strike_with_hit(r: Node) -> void:
	var off: Array[String] = []
	for scene: String in ["hunter_3d", "brute_3d"]:
		var monster: Node3D = r._monster(scene)
		var consts: Dictionary = (monster.get_script() as GDScript).get_script_constant_map()
		var hit_at: float = float(consts["CHARGE_WINDUP"] if consts.has("CHARGE_WINDUP") else consts["WINDUP_TIME"])
		var rig: Node = monster.get("_rig")
		var arms: Array = rig.get("_arms")
		var tele: Node = monster.get("_telegraph")
		tele.call("cue", hit_at)
		var peak_t: float = -1.0
		if not arms.is_empty():
			var arm := arms[0] as Node3D
			var best: float = -INF
			for step in 160:
				rig.call("update", 0.01, false, 0.0, Vector3.ZERO, int(tele.get("last_cue_msec")), float(tele.get("last_cue_windup")))
				if arm.rotation.x > best:
					best = arm.rotation.x
					peak_t = (step + 1) * 0.01
		if absf(peak_t - hit_at) > 0.06:
			off.append("%s peak %.2f s, hit %.2f s" % [scene, peak_t, hit_at])
		monster.queue_free()
	r._ok(off.is_empty(), "SYNC1 the arm of the Hunter and of the Brute comes down within 0.06 s of the hit (off: %s)" % [off])

## CUBE4: the six props that were bare boxes (a secret threw a light each, 26 of them, and hung 0.8 m over the street): each is a mesh of parts of two surfaces, resting on its origin; the secret and the workbench hold no light.
static func _props(r: Node) -> void:
	var off: Array[String] = []
	var lights: int = 0
	var kinds: Dictionary = {"secret": "res://scenes/props/secret.tscn", "workbench": "res://scripts/gameplay/craft_station.gd", "bed": "res://scripts/gameplay/bed.gd", "switch": "res://scripts/world/power_switch.gd",
		"cable_box": "res://scripts/world/cable_box_interactable.gd", "generator": "res://scripts/generator.gd"}
	for kind: String in kinds:
		var path: String = kinds[kind]
		var prop: Node3D = (load(path) as PackedScene).instantiate() as Node3D if path.ends_with(".tscn") else (load(path) as GDScript).new() as Node3D
		if kind == "switch":
			prop.set("district_id", &"suburbs")
		r.add_child(prop)
		var shown: Array[Node] = prop.find_children("*", "MeshInstance3D", true, false)
		var fine: bool = not shown.is_empty()
		for piece: Node in shown:
			var mesh := (piece as MeshInstance3D).mesh
			fine = fine and mesh is ArrayMesh and mesh.get_surface_count() == 2 and absf(mesh.get_aabb().position.y) < 0.02
		if not fine:
			off.append(kind)
		if kind == "secret" or kind == "workbench":
			lights += prop.find_children("*", "OmniLight3D", true, false).size()
		prop.queue_free()
	r._ok(off.is_empty() and lights == 0, "CUBE4 the secret, the workbench, the bed, the switch, the cable box and the generator are meshes of parts on the floor (off: %s), the secret and the workbench hold %d lights" % [off, lights])

## QORD1: each of the first five quests of the table is one the first district makes progress on: its own repair, or a collect of an item its streets hold (a place of a later district, the cable box of the tenth or a monster of the
## third was the third objective of the first frame). The streets hold two or three of an item (DistrictLoot.PICKUP_AMOUNT), so most of the targets are finished over the next districts and the row says how far the first one goes.
static func _quest_order(r: Node) -> void:
	var home: StringName = DistrictSceneFactory.DISTRICTS[0]
	var crates: Array = []
	crates.append_array(DistrictLoot.REPAIR_PARTS)
	crates.append_array(DistrictLoot.COMMON)
	crates.append_array(DistrictLoot.BY_DISTRICT.get(home, []))
	var rows: Array[String] = []
	var off: Array[String] = []
	for id: String in QuestManager.quests.keys().slice(0, 5):
		var q: Dictionary = QuestManager.quests[id]
		var item := StringName(q.target)
		var here: bool = (q.type == "REPAIR" and item == home) or (q.type == "COLLECT" and crates.has(item))
		var items: int = crates.count(item) * int(DistrictLoot.PICKUP_AMOUNT.get(item, 1))
		rows.append("%s %d of %d" % [q.target, items, q.target_count] if q.type == "COLLECT" else "%s %s" % [q.type, q.target])
		if not here:
			off.append(id)
	r._ok(rows.size() == 5 and off.is_empty(), "QORD1 the first five quests are %s; the first district makes progress on each (off: %s)" % [rows, off])

## TXT1: in every language the quests and the tutorial name what the game holds: the first quest the first district, the second the residential one, the kill quests the monsters they count (Hunter, Destroyer, Sharpshooter) and the
## tutorial and the prompt of the central object its own name. A word is read by its stem (the first word of the name less two letters), so a plural and a case still match.
static func _quest_words(r: Node) -> void:
	var lang0: String = LocalizationManager.current_lang
	var off: Array[String] = []
	var kills: Dictionary = {"Q_KILL_RUNNER_TITLE": "MONSTER_HUNTER", "Q_KILL_TANK_TITLE": "MONSTER_DESTROYER", "Q_KILL_SNIPER_TITLE": "MONSTER_SHARPSHOOTER", "Q_REPAIR_DISTRICT1_TITLE": "DISTRICT_NAME_SUBURBS", "Q_RESTORE_DISTRICT2_TITLE": "DISTRICT_NAME_RESIDENTIAL"}
	for lang: String in LocalizationManager.SUPPORTED:
		LocalizationManager.set_language(lang)
		for key: String in kills:
			if LocalizationManager.t(key).to_lower().find(_stem(LocalizationManager.t(String(kills[key])))) < 0:
				off.append("%s %s" % [lang, key])
		for key: String in ["TUT_GENERATOR", "PROMPT_REPAIR"]:
			if LocalizationManager.t(key).to_lower().find(_stem(LocalizationManager.t("interact_switch"))) < 0:
				off.append("%s %s" % [lang, key])
	LocalizationManager.set_language(lang0)
	r._ok(off.is_empty(), "TXT1 the quests and the tutorial name the districts, the monsters and the power switch of the game in the %d languages (off: %s)" % [LocalizationManager.SUPPORTED.size(), off])

static func _stem(name: String) -> String:
	var word: String = name.get_slice(" ", 0).to_lower()
	return word.substr(0, maxi(word.length() - 2, 4))

## TUT3: an item is picked up by walking over it, which sends no interact: the hint "Pick up what you find" is done by the pickup itself.
static func _pickup_hint(r: Node) -> void:
	var tutorial: Node = r.get_node("/root/TutorialSystem")
	var steps: Array = (tutorial.get_script() as GDScript).get_script_constant_map()["STEPS"]
	var at: int = 0
	for i in steps.size():
		if String((steps[i] as Dictionary)["id"]) == "pickup":
			at = i
	var done0: Array = (tutorial.get("_completed_steps") as Array).duplicate()
	var step0: Variant = tutorial.get("_current_step")
	var active0: Variant = tutorial.get("_tutorial_active")
	var waiting0: Variant = tutorial.get("_waiting_for_action")
	tutorial.set("_tutorial_active", true)
	tutorial.set("_current_step", at)
	tutorial.set("_waiting_for_action", true)
	EventBus.item_picked_up.emit(&"battery", 1)
	var moved: bool = int(tutorial.get("_current_step")) == at + 1
	tutorial.set("_completed_steps", done0)
	tutorial.set("_current_step", step0)
	tutorial.set("_tutorial_active", active0)
	tutorial.set("_waiting_for_action", waiting0)
	await r.get_tree().process_frame
	(tutorial.get("_hint_panel") as Control).visible = false
	r._ok(moved, "TUT3 picking an item up completes the pickup hint (step %d of %d moved on: %s)" % [at, steps.size(), moved])

## BOB1: the eye bobs once a step, at a human cadence: 1.5 to 2.5 Hz walking and 3.5 Hz at most sprinting (it bobbed 3.8 and 6.1 Hz).
static func _bob_rate(r: Node) -> void:
	var consts: Dictionary = (load("res://scripts/core/camera_follow_3d.gd") as GDScript).get_script_constant_map()
	var stats: Resource = load("res://data/balance/player_stats.tres")
	var per_m: float = float(consts["STEP_BOB_RAD_PER_M"])
	var walk: float = per_m * float(stats.get("walk_speed")) / TAU
	var run: float = per_m * float(stats.get("run_speed")) / TAU
	r._ok(walk >= 1.5 and walk <= 2.5 and run <= 3.5, "BOB1 the eye bobs %.1f Hz walking and %.1f Hz sprinting (1.5 to 2.5 and 3.5 at most)" % [walk, run])

## LAMP3: a lit lamp dips at most three times a second (it dipped 5.9 times, a strobe): one lamp run for 4 s in steps of 1/240 s, the dips counted.
static func _lamp_dips(r: Node) -> void:
	var lamp := (load("res://scenes/props/streetlight_3d.tscn") as PackedScene).instantiate() as Node3D
	r.add_child(lamp)
	var spot := lamp.get_node("SpotLight") as SpotLight3D
	lamp.set("_on", true)
	lamp.set("_reduce_flash", false)
	lamp.set("lamp_flicker", true)
	lamp.set("_energy_scale", 1.0)
	lamp.set("_light_energy_mult", 1.0)
	lamp.set("_t", 0.0)
	var dips: int = 0
	var dipping: bool = false
	for _step in 960:
		lamp.call("_process", 1.0 / 240.0)
		var low: bool = spot.light_energy < 0.6
		dips += 1 if low and not dipping else 0
		dipping = low
	lamp.queue_free()
	r._ok(dips >= 1 and dips <= 12, "LAMP3 a lit lamp dipped %d times in 4 s (12 at most: three a second)" % dips)

## BOSSHIT1: a hit on the Architect shows and plays what a hit on any monster does: the damage number and the hit marker of the crosshair (he answered his own take_damage and called none of it).
## BOSSHIT2: in the second phase a blow outside the flashlight beam takes nothing off and says so, once in eight seconds.
static func _boss_hits(r: Node) -> void:
	var boss: Node3D = r._monster("boss_architect_3d")
	var numbers: Array[int] = [0]
	var markers: Array[int] = [0]
	var toasts: Array[int] = [0]
	var on_number := func(_who: Variant, _amount: float) -> void: numbers[0] += 1
	var on_marker := func(state: StringName) -> void: markers[0] += 1 if state == &"hit" else 0
	var on_toast := func(_text: String, _kind: String) -> void: toasts[0] += 1
	EventBus.enemy_damaged.connect(on_number)
	EventBus.crosshair_state_changed.connect(on_marker)
	EventBus.toast_requested.connect(on_toast)
	boss.call("take_damage", 5.0, Vector3(0.0, 0.0, 5.0))
	var hp_first: float = float(boss.get("hp"))
	r._ok(numbers[0] == 1 and markers[0] == 1, "BOSSHIT1 a hit on the Architect gives a damage number (%d) and the hit marker (%d)" % [numbers[0], markers[0]])
	boss.set("phase", 1)
	boss.set("_is_in_flashlight", false)
	boss.call("take_damage", 5.0, Vector3(0.0, 0.0, 5.0))
	boss.call("take_damage", 5.0, Vector3(0.0, 0.0, 5.0))
	r._ok(float(boss.get("hp")) == hp_first and toasts[0] == 1, "BOSSHIT2 two blows outside the beam in the second phase take nothing off (hp %.0f of %.0f) and give one hint (%d)" % [float(boss.get("hp")), hp_first, toasts[0]])
	EventBus.enemy_damaged.disconnect(on_number)
	EventBus.crosshair_state_changed.disconnect(on_marker)
	EventBus.toast_requested.disconnect(on_toast)
	boss.queue_free()

## MASTER1: the Master bus ends in a hard limiter at -1 dB or lower, so what the music, the ambience and a shot add up to cannot pass the full scale at the output (only the Music bus had a limiter).
static func _master_limit(r: Node) -> void:
	var found: float = 99.0
	for i in AudioServer.get_bus_effect_count(0):
		var effect := AudioServer.get_bus_effect(0, i)
		if effect is AudioEffectHardLimiter and AudioServer.is_bus_effect_enabled(0, i):
			found = minf(found, (effect as AudioEffectHardLimiter).ceiling_db)
	r._ok(found <= -1.0, "MASTER1 the Master bus has a hard limiter at %.1f dB (-1 dB or lower)" % found)
