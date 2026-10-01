extends Node
## Runner of the rc15 closeout gate (see _closeout_check.gd). Prints one line per check and
## "[closeout] DONE checks=N fails=M"; exits 1 when anything failed.

const Logic := preload("res://scripts/crafting/workbench_logic.gd")
const AlbumScript := preload("res://scripts/ui/photo_album_ui.gd")
const FAR := Vector3(500.0, 0.0, 500.0)
const Status := EnemyRosterData.Status

var _checked: int = 0
var _fails: int = 0
var _player: Node3D = null
var _main: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")

func _ok(cond: bool, what: String) -> void:
	_checked += 1
	if cond:
		print("[closeout] ok   ", what)
	else:
		_fails += 1
		print("[closeout] FAIL ", what)

func _run() -> void:
	SaveSystem.mark_onboard_done()
	GameManager._change_state(GameManager.GameState.PLAYING)
	_main = (load("res://scenes/main_3d.tscn") as PackedScene).instantiate()
	add_child(_main)
	await get_tree().create_timer(3.0).timeout
	_player = get_tree().get_first_node_in_group("player") as Node3D
	_ok(_player != null, "the player spawned")
	if _player == null:
		_finish()
		return
	_check_theme()
	_check_placement()
	await _check_weapons()
	await _check_visibility_and_hiding()
	await _check_workbench()
	await _check_photos()
	await _check_achievements()
	await _check_inventory_and_pause()
	_check_roster()
	await _check_crouch()
	_check_loot()
	await _check_statuses()
	_check_noise_and_pack()
	await _check_settings_effects()
	await _check_stats()
	await _check_bestiary()
	await _check_hints_and_log()
	_check_daily()
	await _check_movement()
	await _check_onboarding_and_death()
	await _check_shop()
	await _check_map()
	await _check_hud_corner()
	await _check_scene_screens_fill_the_window()
	_check_language_survives_a_save()
	_check_respawn_waits_for_the_new_player()
	_check_vitals_are_saved()
	await _check_regeneration_waits_for_peace()
	_check_difficulty()
	await _check_settings_back()
	_finish()

func _finish() -> void:
	print("[closeout] DONE checks=%d fails=%d" % [_checked, _fails])
	get_tree().quit(1 if _fails > 0 else 0)

## A monster standing still in the far corner of the world: its collider answers rays, its AI never runs
## (a disabled process mode would also take the collider out of the physics space).
func _monster(scene: String, at: Vector3 = FAR) -> Node3D:
	var monster := (load("res://scenes/enemies/%s.tscn" % scene) as PackedScene).instantiate() as Node3D
	add_child(monster)
	monster.global_position = at
	monster.set("player_ref", _player)
	monster.set_process(false)
	monster.set_physics_process(false)
	return monster

## The splash and the menu flow can drop the state to MENU mid-run; every section starts in PLAYING.
func _playing() -> void:
	if not GameManager.is_playing():
		GameManager._change_state(GameManager.GameState.PLAYING)

func _slot_of(item: StringName) -> int:
	for i in InventoryManager.slots.size():
		var slot: Variant = InventoryManager.slots[i]
		if slot != null and slot["item_id"] == item:
			return i
	return -1

# ── V03: the heading face is the emboldened Bebas Neue ───────────────────────
func _check_theme() -> void:
	var font := ThemeProvider.build_theme().get_font(&"font", &"Button")
	_ok(font is FontVariation and (font as FontVariation).variation_embolden > 0.0, "V03 ThemeProvider headings use the emboldened Bebas Neue")
	var project_theme := load("res://assets/ui/theme_tls.tres") as Theme
	_ok(project_theme.get_font(&"font", &"Button") is FontVariation, "V03 the project theme Button font is the bold variation")

# ── what the districts now carry ────────────────────────────────────────────
func _check_placement() -> void:
	var weapons_at: Dictionary = {}
	var blueprints_at: Dictionary = {}
	var ammo_at: Dictionary = {}
	var stations_at: Array[StringName] = []
	var beds_at: Array[StringName] = []
	var planks := 0
	for id in DistrictSceneFactory.DISTRICTS:
		ProgressTracker.from_dict({})
		var root := Node3D.new()
		add_child(root)
		DistrictLoot.populate(root, id)
		var hiding := 0
		for node in get_tree().get_nodes_in_group("hiding_spot"):
			if root.is_ancestor_of(node):
				hiding += 1
		_ok(hiding >= 3, "S04 %s has hiding spots (%d)" % [id, hiding])
		for child in root.get_children():
			var script_path: String = str(child.get_script().resource_path) if child.get_script() != null else ""
			if script_path.ends_with("weapon_pickup.gd"):
				weapons_at[id] = str(child.get("weapon_name"))
			elif script_path.ends_with("ammo_pickup.gd"):
				ammo_at[id] = int(ammo_at.get(id, 0)) + 1
			elif script_path.ends_with("craft_station.gd"):
				stations_at.append(id)
			elif script_path.ends_with("bed.gd"):
				beds_at.append(id)
			elif str(child.get("item_id")).trim_prefix("blueprint_") in ProgressTracker.BLUEPRINT_IDS:
				blueprints_at[id] = str(child.get("item_id"))
			elif child.get("item_id") == &"plank":
				planks += int(child.get("amount"))
		root.queue_free()
	_ok(weapons_at == {&"residential": "pistol", &"police": "rifle", &"warehouses": "shotgun"}, "G25 the three guns lie in D2, D7 and D8 (%s)" % str(weapons_at))
	_ok(blueprints_at == {&"residential": "blueprint_enhanced_battery", &"school": "blueprint_uv_flashlight", &"police": "blueprint_strobe_flashlight", &"warehouses": "blueprint_portable_workbench", &"industrial": "blueprint_battery_l2"}, "G21 the five blueprints lie in D2, D4, D7, D8 and D9 (%s)" % str(blueprints_at))
	_ok(stations_at == [&"suburbs", &"police", &"industrial"], "G21 a workbench stands in D1, D7 and D9 (%s)" % str(stations_at))
	_ok(beds_at == [&"suburbs"], "ach_19 the bed stands in D1 (%s)" % str(beds_at))
	_ok(planks == 5, "G21 the boards for the portable workbench lie in D8 (%d)" % planks)
	var ammo_total := 0
	for id in ammo_at:
		ammo_total += int(ammo_at[id])
	_ok(not ammo_at.has(&"suburbs") and ammo_total == 15, "G25 ammo lies in D2-D11, twice from the police on (%d boxes)" % ammo_total)
	ProgressTracker.from_dict({})

# ── G25 / C03: firearms ────────────────────────────────────────────────────
func _check_weapons() -> void:
	_playing()
	ProgressTracker.from_dict({})
	var manager := _player.get_node_or_null("WeaponManager") as WeaponManager
	_ok(manager != null, "G25 the player owns a WeaponManager")
	if manager == null:
		return
	_ok(not manager.has_weapon_equipped() and manager.get_current_weapon() == null, "G25 the player starts empty-handed (melee)")
	_ok(manager.unlock(&"pistol") and ProgressTracker.has_weapon("pistol") and not manager.unlock(&"pistol"), "G25 a gun is found once and kept in ProgressTracker")
	manager.add_ammo(24)
	_ok(manager.reserve() == 24, "G25 ammo goes to the shared reserve")
	manager.cycle([&"pistol"])
	var pistol := manager.get_current_weapon()
	_ok(manager.equipped == &"pistol" and pistol != null and pistol.visible, "G25 the pistol is drawn by its slot")
	manager.cycle([&"pistol"])
	_ok(manager.equipped == &"" and manager.get_current_weapon() == null, "G25 the same slot again lowers the weapon")
	manager.equip(&"pistol")
	var target := _monster("crawler_3d")
	await get_tree().physics_frame
	await get_tree().physics_frame
	var hp0: float = float(target.get("hp"))
	var center := (target.get_node("CollisionShape3D") as Node3D).global_position
	var from := center + Vector3(0.0, 0.0, 6.0)
	var toward := Vector3(0.0, 0.0, -1.0)
	var ammo0 := pistol.current_ammo
	_ok(pistol.fire(from, toward), "G25 the pistol fires")
	_ok(pistol.current_ammo == ammo0 - 1, "G25 a shot costs a round")
	_ok(float(target.get("hp")) < hp0, "G25 a pistol hit hurts the monster (%.1f -> %.1f)" % [hp0, float(target.get("hp"))])
	pistol.current_ammo = 0
	_ok(not pistol.fire(from, toward), "G25 an empty magazine does not fire")
	_ok(pistol.try_reload(), "G25 the reload starts with rounds in reserve")
	await get_tree().create_timer(pistol.reload_time + 0.4).timeout
	_ok(pistol.current_ammo == pistol.max_ammo and manager.reserve() == 24 - pistol.max_ammo, "G25 the reload draws the magazine from the reserve (%d in, %d left)" % [pistol.current_ammo, manager.reserve()])
	manager.take_ammo(manager.reserve())
	pistol.current_ammo = 0
	_ok(not pistol.try_reload(), "G25 no reload without reserve")
	manager.unlock(&"shotgun")
	manager.add_ammo(12)
	manager.equip(&"shotgun")
	var shotgun := manager.get_current_weapon()
	var hp1: float = float(target.get("hp"))
	shotgun.fire(center + Vector3(0.0, 0.0, 3.0), toward)
	_ok(float(target.get("hp")) < hp1, "G25 the shotgun's pellets hurt at close range (%.1f -> %.1f)" % [hp1, float(target.get("hp"))])
	# C03: auto-aim leans toward a living monster near the line of fire, only when the setting is on
	var mark := _monster("crawler_3d", FAR + Vector3(30.0, 0.0, 0.0))
	await get_tree().physics_frame
	var mark_center := (mark.get_node("CollisionShape3D") as Node3D).global_position
	from = mark_center + Vector3(0.0, 0.0, 6.0)
	var to_target := (mark_center - from).normalized()
	var off_line := to_target.rotated(Vector3.UP, deg_to_rad(6.0))
	SettingsManager.set_setting("auto_aim", false)
	_ok(pistol._apply_auto_aim(from, off_line).is_equal_approx(off_line), "C03 auto-aim off leaves the aim alone")
	SettingsManager.set_setting("auto_aim", true)
	var aimed: Vector3 = pistol._apply_auto_aim(from, off_line)
	_ok(aimed.dot(to_target) > off_line.dot(to_target) + 0.001, "C03 auto-aim on pulls the aim toward the monster")
	SettingsManager.set_setting("auto_aim", false)
	# the HUD's two weapon slots
	var hud := _main.get_node_or_null("HUD")
	_ok(hud != null and hud._SLOT_ITEMS.slice(0, 2) == [&"pistol", &"rifle"], "G25 the HUD's first two quick slots are the weapons")
	manager.holster()
	hud._use_quick_slot(0)
	_ok(manager.equipped == &"pistol", "G25 quick slot 1 draws the pistol")
	hud._use_quick_slot(1)
	_ok(manager.equipped == &"shotgun", "G25 quick slot 2 draws the long gun carried (the shotgun)")
	hud._use_quick_slot(1)
	_ok(manager.equipped == &"", "G25 quick slot 2 again lowers it")
	var saved := ProgressTracker.to_dict()
	_ok(saved["weapons"].has("pistol") and saved["weapons"].has("shotgun") and int(saved["ammo"]) >= 0, "G25 weapons and ammo are in the save")
	ProgressTracker.from_dict({"weapons": ["pistol", "bogus"], "ammo": 99999})
	_ok(ProgressTracker.get_weapons() == ["pistol"] and ProgressTracker.ammo == ProgressTracker.MAX_AMMO_RESERVE, "G25 a forged save cannot add a weapon or overfill the reserve")
	target.queue_free()
	mark.queue_free()
	ProgressTracker.from_dict({})

# ── S02 and S04 ─────────────────────────────────────────────────────────────
func _check_visibility_and_hiding() -> void:
	_playing()
	var monster := _monster("crawler_3d")
	await get_tree().physics_frame
	_player.set("flashlight_enabled", true)
	_player.set("current_state", _player.State.WALK)
	var lit: Vector2 = monster._sight_ranges()
	_ok(is_equal_approx(lit.x, 6.0), "S02 flashlight on, walking: the monster's own sight (%.1f m)" % lit.x)
	_player.set("current_state", _player.State.RUN)
	_ok(is_equal_approx(monster._sight_ranges().x, 7.2), "S02 running adds 20%% (%.1f m)" % monster._sight_ranges().x)
	_player.set("current_state", _player.State.CROUCH)
	_ok(is_equal_approx(monster._sight_ranges().x, 3.0), "S02 crouching halves it (%.1f m)" % monster._sight_ranges().x)
	_player.set("current_state", _player.State.WALK)
	_player.set("flashlight_enabled", false)
	var dark: Vector2 = monster._sight_ranges()
	_ok(is_equal_approx(dark.x, 3.0) and is_equal_approx(dark.y, 1.0), "S02 light off halves it and the dark caps it at 3 m (%s)" % str(dark))
	_player.set("current_state", _player.State.CROUCH)
	_ok(is_equal_approx(monster._sight_ranges().x, 1.5), "S02 crouching with the light off: 1.5 m")
	_player.set("current_state", _player.State.WALK)
	_player.set("flashlight_enabled", true)
	# S04: a hiding spot hides, and lets the player out on the street side
	var spot := HidingSpot.new()
	spot.spot_type = "bush"
	spot.exit_dir = Vector3(0.0, 0.0, 1.0)
	add_child(spot)
	spot.global_position = _player.global_position + Vector3(0.0, 0.0, -2.0)
	await get_tree().physics_frame
	var heard: Array[bool] = []
	var conn := func(hiding: bool) -> void: heard.append(hiding)
	EventBus.player_hiding_changed.connect(conn)
	_player.toggle_hiding(spot)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var hud := _main.get_node_or_null("HUD")
	_ok(heard == [true] and float(_player.visibility) == 0.0, "S04 entering a spot: visibility 0 and the event fired")
	_ok(is_equal_approx(monster._sight_ranges().x, 0.0), "S04 a hidden player is seen from 0 m")
	_ok(hud._hide_overlay != null and hud._hide_overlay.visible, "S04 the view dims while hidden")
	_ok(_player.get_collision_exceptions().size() > 0, "S04 the player passes through the spot's own collider")
	_player.toggle_hiding(spot)
	await get_tree().physics_frame
	await get_tree().physics_frame
	EventBus.player_hiding_changed.disconnect(conn)
	_ok(heard == [true, false] and float(_player.visibility) > 0.0, "S04 leaving a spot restores visibility")
	_ok(not hud._hide_overlay.visible, "S04 the dimming ends")
	_ok(_player.global_position.distance_to(spot.global_position) > 1.0 and _player.get_collision_exceptions().is_empty(), "S04 the player steps out on the street side with the collider solid again")
	spot.queue_free()
	monster.queue_free()

# ── G21: blueprints, the workbench, and what they build ─────────────────────
func _check_workbench() -> void:
	_playing()
	ProgressTracker.from_dict({})
	InventoryManager.from_dict({})
	_player.set("battery", 80.0)
	_player.set("flashlight_enabled", true)
	var strobe := Logic.find("strobe_flashlight")
	_ok(not Logic.can_craft(strobe), "G21 no recipe without its blueprint")
	_ok(not _player.trigger_strobe(), "G21 the strobe needs its blueprint and a workbench first")
	InventoryManager.try_add(&"blueprint_strobe_flashlight", 1)
	_ok(ProgressTracker.knows_blueprint("strobe_flashlight") and InventoryManager.count_of(&"blueprint_strobe_flashlight") == 0, "G21 a blueprint is learned on pickup and does not take a slot")
	_ok(not Logic.can_craft(strobe), "G21 a learned recipe still needs its parts")
	InventoryManager.try_add(&"fuse", 2)
	InventoryManager.try_add(&"transformer", 1)
	_ok(Logic.can_craft(strobe), "G21 a learned recipe with its parts can be crafted")
	_ok(Logic.craft(strobe) and ProgressTracker.has_crafted("strobe_flashlight") and InventoryManager.count_of(&"fuse") == 0 and InventoryManager.count_of(&"transformer") == 0, "G21 crafting spends the parts and gives the ability")
	_ok(not Logic.can_craft(strobe), "G21 an ability is crafted once")
	_ok(_player.trigger_strobe(), "G21 the built strobe works")
	# capacity: enhanced battery +20%, level 2 +40%
	InventoryManager.try_add(&"blueprint_enhanced_battery", 1)
	InventoryManager.try_add(&"battery", 2)
	InventoryManager.try_add(&"cable", 1)
	var enhanced := Logic.find("enhanced_battery")
	_ok(Logic.craft(enhanced) and InventoryManager.count_of(&"enhanced_battery") == 1, "G21 the enhanced battery is crafted from two batteries and a cable")
	var max0: float = _player.battery_max
	InventoryManager.use_item(_slot_of(&"enhanced_battery"))
	_ok(is_equal_approx(_player.battery_max, max0 * 1.2) and is_equal_approx(ProgressTracker.battery_bonus, 0.2), "G21 using it raises the flashlight capacity by 20%% (%.0f)" % _player.battery_max)
	InventoryManager.try_add(&"blueprint_battery_l2", 1)
	InventoryManager.try_add(&"battery", 2)
	InventoryManager.try_add(&"cable", 3)
	InventoryManager.try_add(&"transformer", 1)
	Logic.craft(enhanced)
	_ok(Logic.craft(Logic.find("battery_l2")) and InventoryManager.count_of(&"battery_l2") == 1 and InventoryManager.count_of(&"enhanced_battery") == 0, "G21 battery L2 is crafted from an enhanced battery, two cables and a transformer")
	InventoryManager.use_item(_slot_of(&"battery_l2"))
	_ok(is_equal_approx(_player.battery_max, max0 * 1.4), "G21 battery L2 raises the capacity to +40%% (%.0f)" % _player.battery_max)
	# the UV light: 5 damage a second in the cone
	_player.toggle_uv()
	_ok(not bool(_player.get("_uv_on")), "G21 the UV light needs its blueprint and a workbench first")
	InventoryManager.try_add(&"blueprint_uv_flashlight", 1)
	InventoryManager.try_add(&"cable", 3)
	InventoryManager.try_add(&"fuse", 1)
	InventoryManager.try_add(&"battery", 2)
	_ok(Logic.craft(Logic.find("uv_flashlight")), "G21 the UV light is crafted")
	var victim := _monster("crawler_3d", _player.global_position + Vector3(0.0, 0.0, 2.0))
	var pivot := _player.get("flashlight_pivot") as Node3D
	victim.global_position = _player.global_position + (-pivot.global_transform.basis.z).normalized() * 4.0
	await get_tree().physics_frame
	var vhp0: float = float(victim.get("hp"))
	_player.set("flashlight_enabled", true)
	_player.toggle_uv()
	_ok(bool(_player.get("_uv_on")), "G21 the UV light switches on")
	await get_tree().create_timer(1.3).timeout
	var vhp1: float = float(victim.get("hp"))
	_ok(vhp0 - vhp1 >= 3.0, "G21 the UV cone hurts what stands in it (%.1f -> %.1f in 1.3 s)" % [vhp0, vhp1])
	_player.toggle_uv()
	_ok(not bool(_player.get("_uv_on")), "G21 the UV light switches off")
	victim.queue_free()
	# the portable workbench opens the screen anywhere
	InventoryManager.try_add(&"blueprint_portable_workbench", 1)
	InventoryManager.try_add(&"plank", 5)
	InventoryManager.try_add(&"metal", 2)
	InventoryManager.try_add(&"tool", 1)
	_ok(Logic.craft(Logic.find("portable_workbench")), "G21 the portable workbench is crafted from boards, metal and a tool")
	_player.call("_toggle_portable_workbench")
	await get_tree().process_frame
	var screen := UIManager._get_screen(&"workbench")
	_ok(screen != null and screen.visible, "G21 the portable workbench key opens the workbench screen")
	var rows: Array = screen.get("_recipe_btns")
	var shown := 0
	for i in rows.size():
		if (rows[i] as Control).visible:
			shown += 1
	_ok(shown == 8 + 5, "G21 the screen lists the base recipes and the five learned blueprints (%d)" % shown)
	UIManager.close(&"workbench")
	# a result the pack cannot carry gives the parts back: a 2 kg transformer from one transistor, 0.5 kg of room
	InventoryManager.from_dict({})
	var capacity0: float = InventoryManager.stats.capacity_kg
	InventoryManager.try_add(&"scrap", 1)
	InventoryManager.try_add(&"transistor", 1)
	InventoryManager.stats.capacity_kg = InventoryManager.current_weight + 0.5
	var heavy := {"id": "t", "name_key": "x", "result": "transformer", "count": 1, "components": [["transistor", 1]]}
	var crafted: bool = Logic.craft(heavy)
	_ok(not crafted and InventoryManager.count_of(&"transistor") == 1 and InventoryManager.count_of(&"transformer") == 0, "G21 a result the pack cannot carry gives the parts back")
	InventoryManager.stats.capacity_kg = capacity0
	InventoryManager.from_dict({})
	ProgressTracker.from_dict({})
	_player.refresh_battery_max()

# ── G26: the photo album ────────────────────────────────────────────────────
func _check_photos() -> void:
	_playing()
	SaveSystem._photos.clear()
	ProgressTracker.from_dict({})
	_ok(ProgressTracker.photo_total() >= 200, "G26 the game can give 200 photos or more (%d)" % ProgressTracker.photo_total())
	ProgressTracker.unlock_doc("doc_closeout_test")
	ProgressTracker.unlock_doc("doc_closeout_test")
	_ok(SaveSystem.get_photos() == ["doc_doc_closeout_test"], "G26 a found document is a photo, once")
	EventBus.enemy_killed.emit(&"crawler")
	EventBus.enemy_killed.emit(&"minion")
	_ok(SaveSystem.get_photos().has("creature_crawler") and not SaveSystem.get_photos().has("creature_minion"), "G26 the first kill of a monster kind is a photo, a minion is not")
	EventBus.district_stage_changed.emit(&"park", DistrictData.Stage.STREETS)
	EventBus.district_stage_changed.emit(&"park", DistrictData.Stage.FULL)
	_ok(SaveSystem.get_photos().has("district_park_lit") and SaveSystem.get_photos().has("district_park_saved"), "G26 a district lit and saved gives a photo each")
	_ok(not SaveSystem.add_photo("../escape") and not SaveSystem.add_photo("Bad Id"), "G26 a photo id that could be a path is refused")
	_ok(AlbumScript.category_of("creature_crawler") == "creatures" and AlbumScript.category_of("secret_x") == "artifacts" and AlbumScript.category_of("doc_x") == "photos", "G26 the album sorts photos into its three categories")
	AchievementManager._unlocked.erase("ach_09")
	var i := 0
	while SaveSystem.get_photo_count() < 50:
		ProgressTracker.call("_add_photo", "filler_%d" % i)
		i += 1
	_ok(AchievementManager.is_unlocked(&"ach_09"), "G26 the 50th photo unlocks Photographer")
	_ok(not AchievementManager.is_unlocked(&"ach_10"), "G26 Seeker waits for the 100th")
	var album := AlbumScript.new()
	album.set("embedded", true)
	add_child(album)
	await get_tree().process_frame
	_ok(String(album._counter.text).begins_with("%d / " % SaveSystem.get_photo_count()), "G26 the album shows the count (%s)" % album._counter.text)
	album.queue_free()
	var codex_tabs := UIManager._get_screen(&"codex").get_script().TABS as Array
	var has_tab := false
	for tab in codex_tabs:
		if tab["id"] == &"photos":
			has_tab = true
	_ok(has_tab, "G26 the Codex has a Photos tab")
	SaveSystem._photos.clear()
	ProgressTracker.from_dict({})

# ── the achievements that had no trigger ────────────────────────────────────
func _check_achievements() -> void:
	_playing()
	for id in ["ach_06", "ach_07", "ach_08", "ach_11", "ach_12", "ach_13", "ach_14", "ach_15", "ach_16", "ach_18", "ach_19", "ach_20"]:
		AchievementManager._unlocked.erase(id)
	AchievementManager._progress.clear()
	var shadow := _monster("shadow_3d")
	_ok(shadow.get("monster_id") == &"shadow", "the Shadow carries its own id (quests, the bestiary and Shadow Hunter read it)")
	shadow.queue_free()
	for n in 9:
		EventBus.combo_chain_landed.emit()
	EventBus.combo_chain_broken.emit()
	for n in 9:
		EventBus.combo_chain_landed.emit()
	_ok(not AchievementManager.is_unlocked(&"ach_07"), "ach_07 a broken chain starts the count again")
	EventBus.combo_chain_landed.emit()
	_ok(AchievementManager.is_unlocked(&"ach_07"), "ach_07 ten combo-3 chains in a row unlock Combo Master")
	CoinWallet.add(5000)
	AchievementManager._process(1.5)
	_ok(AchievementManager.is_unlocked(&"ach_11"), "ach_11 5000 coins unlock Economist")
	InventoryManager.set("current_weight", 39.5)
	AchievementManager._process(301.0)
	_ok(AchievementManager.is_unlocked(&"ach_08"), "ach_08 five minutes over 39 kg unlock Overloaded")
	InventoryManager.call("_recompute_weight")
	DistrictManager.current_district = "park"
	EventBus.player_detected.emit(&"crawler")
	AchievementManager._on_district_restored(&"park", 3)
	_ok(not AchievementManager.is_unlocked(&"ach_06"), "ach_06 being noticed in District 3 forfeits Quiet as a Mouse")
	AchievementManager._progress.erase("seen_park")
	AchievementManager._on_district_restored(&"park", 3)
	_ok(AchievementManager.is_unlocked(&"ach_06"), "ach_06 District 3 restored unnoticed unlocks it")
	DistrictManager.current_district = "school"
	EventBus.player_damaged.emit(5.0)
	AchievementManager._on_district_restored(&"school", 3)
	_ok(not AchievementManager.is_unlocked(&"ach_12"), "ach_12 damage in District 4 forfeits Without a Scratch")
	AchievementManager._progress.erase("hurt_school")
	AchievementManager._on_district_restored(&"school", 3)
	_ok(AchievementManager.is_unlocked(&"ach_12"), "ach_12 District 4 restored unhurt unlocks it")
	DistrictManager.current_district = "suburbs"
	for n in 5:
		EventBus.hallucination_heard.emit()
	_ok(AchievementManager.is_unlocked(&"ach_20"), "ach_20 five hallucinations unlock Who's There")
	AchievementManager._on_player_died()
	_ok(AchievementManager.is_unlocked(&"ach_15"), "ach_15 dying reaches the Darkness ending")
	ProgressTracker.time_played = 100.0
	SettingsManager.set_setting("hardcore", true)
	AchievementManager._on_game_won()
	SettingsManager.set_setting("hardcore", false)
	_ok(AchievementManager.is_unlocked(&"ach_16") and AchievementManager.is_unlocked(&"ach_18") and AchievementManager.is_unlocked(&"ach_13"), "ach_16 / ach_18 a fast hardcore win unlocks Speedrunner and Iron Man")
	var bed := Node3D.new()
	bed.set_script(load("res://scripts/gameplay/bed.gd"))
	add_child(bed)
	bed.global_position = _player.global_position + Vector3(0.0, 0.0, 3.0)
	_player.set("hp", 10.0)
	bed.call("interact", _player)
	await get_tree().create_timer(2.5).timeout
	_ok(AchievementManager.is_unlocked(&"ach_19") and float(_player.get("hp")) > 10.0, "ach_19 sleeping in the bed heals and unlocks Midsummer Night's Dream")
	bed.queue_free()
	ProgressTracker.from_dict({})

# ── the inventory screen (Tab) and the pause menu's new entries ─────────────
func _check_inventory_and_pause() -> void:
	_playing()
	InventoryManager.from_dict({})
	ProgressTracker.from_dict({})
	InventoryManager.try_add(&"battery", 2)
	InventoryManager.try_add(&"medkit", 1)
	UIManager.open(&"inventory")
	await get_tree().process_frame
	await get_tree().process_frame
	var ui: Control = UIManager._get_screen(&"inventory")
	_ok(ui != null and ui.visible, "V.5 the inventory screen opens")
	_ok(ui._grid.get_child_count() == 2, "V.5 one cell per stack (%d)" % ui._grid.get_child_count())
	var battery_slot := _slot_of(&"battery")
	ui._selected = battery_slot
	ui._refresh()
	_player.set("battery", 10.0)
	ui._on_use()
	await get_tree().process_frame
	_ok(float(_player.get("battery")) > 10.0 and InventoryManager.count_of(&"battery") == 1, "V.5 Use consumes one battery and recharges the light")
	ui._selected = _slot_of(&"medkit")
	ui._refresh()
	ui._on_drop()
	_ok(InventoryManager.count_of(&"medkit") == 1, "V.5 the first press of Drop only asks")
	ui._on_drop()
	_ok(InventoryManager.count_of(&"medkit") == 0, "V.5 the second press throws the stack away")
	ui._on_sort(1)
	ui._on_filter(1)
	_ok(ui._filter == 0, "V.5 the rarity filter narrows the grid")
	ui._on_filter(0)
	UIManager.close(&"inventory")
	_ok(not ui.visible, "V.5 the inventory screen closes")
	UIManager.open(&"pause")
	await get_tree().process_frame
	var pause: Control = UIManager._get_screen(&"pause")
	var texts: Array[String] = []
	for button in pause.find_children("*", "Button", true, false):
		texts.append((button as Button).text)
	for key in ["inventory", "SHOP_COINS", "CRAFT_UPGRADE", "PAUSE_SAVE_QUIT"]:
		_ok(texts.has(LocalizationManager.t(key)), "the pause menu offers %s" % key)
	UIManager.close(&"pause")

# ── difficulty scales the monsters ──────────────────────────────────────────
func _check_difficulty() -> void:
	SettingsManager.set_difficulty(1)
	var normal := _monster("crawler_3d")
	var hp_normal: float = normal.max_hp
	var damage_normal: float = normal.attack_damage
	SettingsManager.set_difficulty(0)
	var easy := _monster("crawler_3d")
	SettingsManager.set_difficulty(2)
	var hard := _monster("crawler_3d")
	SettingsManager.set_difficulty(1)
	_ok(is_equal_approx(easy.max_hp, hp_normal * 0.8) and is_equal_approx(easy.attack_damage, damage_normal * 0.75), "difficulty Easy: monsters at 80%% health, 75%% damage (%.1f / %.1f)" % [easy.max_hp, easy.attack_damage])
	_ok(is_equal_approx(hard.max_hp, hp_normal * 1.2) and is_equal_approx(hard.attack_damage, damage_normal * 1.25), "difficulty Hard: monsters at 120%% health, 125%% damage (%.1f / %.1f)" % [hard.max_hp, hard.attack_damage])
	normal.queue_free()
	easy.queue_free()
	hard.queue_free()

# ── the settings screen reached from the main menu has a way back ───────────
func _check_settings_back() -> void:
	GameManager._change_state(GameManager.GameState.MENU)
	await get_tree().process_frame
	var overlay: Control = UIManager._cache.get(&"main_menu", null)
	_ok(overlay != null and overlay.visible, "MENU1 the menu state opens the main-menu screen")
	Routes.goto(Routes.SETTINGS)
	var reached := false
	for n in 50:
		await get_tree().create_timer(0.2).timeout
		var scene := get_tree().current_scene
		if scene != null and scene.scene_file_path == Routes.SETTINGS:
			reached = true
			break
	_ok(reached, "the Settings scene opens")
	if not reached:
		return
	var menu_screen: Control = UIManager._cache.get(&"main_menu", null)
	_ok(menu_screen == null or not menu_screen.visible, "MENU1 the main-menu screen is gone once Settings is the scene (it covered Settings, Difficulty and Credits)")
	await get_tree().create_timer(0.5).timeout
	var back: Button = null
	for button in get_tree().current_scene.find_children("*", "Button", true, false):
		if (button as Button).text == LocalizationManager.t("Back"):
			back = button
	_ok(back != null, "the Settings scene has a Back button")
	if back == null:
		return
	back.pressed.emit()
	var returned := false
	for n in 50:
		await get_tree().create_timer(0.2).timeout
		var scene := get_tree().current_scene
		if scene != null and scene.scene_file_path == Routes.MENU:
			returned = true
			break
	_ok(returned, "Back returns from Settings to the main menu")

# ── batch 2: the GDD roster table ───────────────────────────────────────────
## GDD 6.2: scene -> [health, damage] at Normal difficulty.
const GDD_ROSTER: Dictionary = {
	"shadow_3d": [30.0, 15.0], "crawler_3d": [50.0, 20.0], "watcher_3d": [80.0, 12.0], "hunter_3d": [120.0, 35.0],
	"destroyer_3d": [200.0, 25.0], "sharpshooter_3d": [60.0, 50.0], "brute_3d": [350.0, 30.0], "burner_3d": [90.0, 15.0],
	"rotter_3d": [140.0, 10.0], "hound_3d": [40.0, 18.0], "tvar_3d": [1200.0, 40.0], "boss_architect_3d": [800.0, 40.0],
}
## GDD 6.2 speed column: a multiple of the player's walk. The roster's own figures are rounded, so 0.45 m/s is the margin.
const GDD_SPEED: Dictionary = {
	"shadow_3d": 1.2, "crawler_3d": 1.5, "watcher_3d": 1.0, "hunter_3d": 0.9, "destroyer_3d": 0.7, "sharpshooter_3d": 0.6,
	"brute_3d": 0.5, "burner_3d": 1.0, "rotter_3d": 0.4, "hound_3d": 1.8, "tvar_3d": 1.0, "boss_architect_3d": 1.1,
}
const SPEED_MARGIN: float = 0.45
const LOOT_ROLLS: int = 600

func _check_roster() -> void:
	SettingsManager.set_difficulty(1)
	var ng_hp: float = NewGamePlus.get_enemy_hp_multiplier() if NewGamePlus.is_ng_plus_active() else 1.0
	var ng_damage: float = NewGamePlus.get_enemy_damage_multiplier() if NewGamePlus.is_ng_plus_active() else 1.0
	for scene in GDD_ROSTER:
		var want: Array = GDD_ROSTER[scene]
		var monster := _monster(scene)
		var hp: float = monster.max_hp
		var damage: float = monster.attack_damage
		_ok(is_equal_approx(hp, float(want[0]) * ng_hp) and is_equal_approx(damage, float(want[1]) * ng_damage),
			"MN2 %s has the GDD health %.0f and damage %.0f (%.1f / %.1f)" % [scene, want[0], want[1], hp, damage])
		var walk := float((_player.get("stats") as Resource).get("walk_speed"))
		var want_speed: float = float(GDD_SPEED[scene]) * walk
		_ok(absf(monster.chase_speed - want_speed) <= SPEED_MARGIN,
			"MN2 %s chases at %.1f m/s, the GDD %.1fx of the %.1f m/s walk is %.1f" % [scene, monster.chase_speed, GDD_SPEED[scene], walk, want_speed])
		monster.queue_free()

# ── CT13 / CT6 / Crouch Input: the capsule, the ceiling, the swipe, the three modes ──
func _swipe(from: Vector2, by: Vector2, hold: float) -> void:
	var press := InputEventScreenTouch.new()
	press.index = 7
	press.pressed = true
	press.position = from
	_player._input(press)
	await get_tree().create_timer(hold).timeout
	var release := InputEventScreenTouch.new()
	release.index = 7
	release.pressed = false
	release.position = from + by
	_player._input(release)

func _check_crouch() -> void:
	_playing()
	SettingsManager.set_setting("crouch_input", 0)
	_player.set("gameplay_active", true)
	var body := _player.get_node("CollisionShape3D") as CollisionShape3D
	var capsule := body.shape as CapsuleShape3D
	_ok(is_equal_approx(capsule.height, 1.6), "CT13 the standing capsule is 1.6 m")
	_player.set("_crouch_held", true)
	_player.set("_crouch_timer", 1.0)
	await get_tree().create_timer(0.5).timeout
	var cam: Variant = _player.get("_fps_cam")
	_ok(is_equal_approx(capsule.height, 1.2), "CT13 crouching shrinks the capsule to 1.2 m (%.2f)" % capsule.height)
	_ok(cam != null and float(cam.fps_eye_height) < 1.4, "CT13 crouching lowers the eye (%.2f)" % float(cam.fps_eye_height))
	var ceiling := StaticBody3D.new()
	var slab := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 0.1, 2.0)
	slab.shape = box
	ceiling.add_child(slab)
	add_child(ceiling)
	ceiling.global_position = _player.global_position + Vector3(0.0, 0.6, 0.0)
	_player.set("_crouch_held", false)
	await get_tree().create_timer(0.4).timeout
	_ok(is_equal_approx(capsule.height, 1.2), "CT13 a low ceiling keeps the player crouched (%.2f)" % capsule.height)
	ceiling.queue_free()
	await get_tree().create_timer(0.4).timeout
	_ok(is_equal_approx(capsule.height, 1.6), "CT13 the player stands up once there is room (%.2f)" % capsule.height)
	# GDD 2.2, touch: a quick swipe down in the look zone toggles the crouch; a slow or short one does not
	var view := get_viewport().get_visible_rect().size
	var start := Vector2(view.x * 0.8, view.y * 0.3)
	await _swipe(start, Vector2(10.0, 200.0), 0.05)
	_ok(bool(_player.get("_crouch_toggled")), "CT6 a quick swipe down toggles the crouch")
	await _swipe(start, Vector2(10.0, 200.0), 0.05)
	_ok(not bool(_player.get("_crouch_toggled")), "CT6 a second swipe stands up")
	await _swipe(start, Vector2(10.0, 200.0), 0.6)
	_ok(not bool(_player.get("_crouch_toggled")), "CT6 a slow drag (a look) does not crouch")
	await _swipe(start, Vector2(10.0, 80.0), 0.05)
	_ok(not bool(_player.get("_crouch_toggled")), "CT6 a short swipe does not crouch")
	await _swipe(Vector2(view.x * 0.1, view.y * 0.3), Vector2(10.0, 200.0), 0.05)
	_ok(not bool(_player.get("_crouch_toggled")), "CT6 a swipe on the joystick side does not crouch")
	# Settings > Crouch Input
	SettingsManager.set_setting("crouch_input", 2)
	_player.set("_crouch_toggled", true)
	_ok(not _player._crouch_wanted(), "Crouch Input Disabled: nothing crouches the player")
	SettingsManager.set_setting("crouch_input", 1)
	_player.set("_crouch_toggled", false)
	_player.set("_crouch_held", true)
	_player.set("_crouch_timer", 0.0)
	_ok(_player._crouch_wanted(), "Crouch Input Button: the key crouches at once")
	SettingsManager.set_setting("crouch_input", 0)
	_ok(not _player._crouch_wanted(), "Crouch Input Long Press: a tap does not crouch")
	_player.set("_crouch_timer", 0.6)
	_ok(_player._crouch_wanted(), "Crouch Input Long Press: a hold crouches")
	_player.set("_crouch_held", false)
	_player.set("_crouch_timer", 0.0)

# ── MN4: a corpse drops loot 30% of the time (a part, a supply, or ammunition for the Sharpshooter) ──
func _check_loot() -> void:
	var scene := get_tree().current_scene
	var crawler := _monster("crawler_3d")
	var before := scene.get_child_count()
	for n in LOOT_ROLLS:
		crawler._maybe_drop_loot()
	var drops := scene.get_children().slice(before)
	var want: float = BaseMonster.LOOT_CHANCE * NewGamePlus.get_loot_chance_multiplier()
	var share := float(drops.size()) / LOOT_ROLLS
	_ok(absf(share - want) < 0.08, "MN4 a corpse drops loot %.0f%% of the time (%d of %d)" % [want * 100.0, drops.size(), LOOT_ROLLS])
	var in_table := true
	for drop in drops:
		in_table = in_table and BaseMonster.LOOT_TABLE.has(drop.item_id)
		drop.queue_free()
	_ok(in_table, "MN4 every drop is a battery, a medkit or scrap")
	var sharp := _monster("sharpshooter_3d")
	before = scene.get_child_count()
	for n in 60:
		sharp._maybe_drop_loot()
	drops = scene.get_children().slice(before)
	var ammo := not drops.is_empty()
	for drop in drops:
		ammo = ammo and String(drop.scene_file_path).ends_with("ammo_pickup.tscn")
		drop.queue_free()
	_ok(ammo, "MN4 the Sharpshooter drops a box of rounds")
	crawler.queue_free()
	sharp.queue_free()

# ── MN6: the statuses a monster inflicts reach the player, and STUN holds the player in place ──
func _check_statuses() -> void:
	var fx: Node = _player.get("status_fx")
	var inflicted := {"crawler_3d": Status.BLEED, "hunter_3d": Status.BLEED, "destroyer_3d": Status.STUN,
		"burner_3d": Status.BURN, "rotter_3d": Status.POISON}
	for scene in inflicted:
		fx.active.clear()
		fx._immune.clear()
		var monster := _monster(scene)
		monster._inflict_statuses(_player)
		_ok(fx.is_active(inflicted[scene]), "MN6 a %s hit puts %s on the player" % [scene, Status.keys()[inflicted[scene]]])
		monster.queue_free()
	fx.active.clear()
	fx._immune.clear()
	_player.apply_status(Status.SLOW, 2.0, 0.0, 0.5)
	_ok(is_equal_approx(fx.speed_multiplier(), 0.5), "MN6 SLOW halves the player's speed")
	fx.active.clear()
	_player.apply_status(Status.STUN, 1.5)
	_ok(fx.speed_multiplier() == 0.0, "MN6 STUN holds the player in place")
	var hud := _main.get_node_or_null("HUD")
	await get_tree().create_timer(0.4).timeout
	_ok(hud._status_icons.has(Status.STUN), "H3.12 the status row shows the STUN icon")
	fx.active.clear()
	fx._immune.clear()
	await get_tree().create_timer(0.4).timeout
	_ok(not hud._status_icons.has(Status.STUN), "H3.12 the icon goes when the status ends")

# ── MN7: noise sends monsters to its source; Hounds and Hunters shout when they see the player ──
func _check_noise_and_pack() -> void:
	var hunter := _monster("hunter_3d")
	var near := _monster("hound_3d", FAR + Vector3(8.0, 0.0, 0.0))
	var far := _monster("crawler_3d", FAR + Vector3(40.0, 0.0, 0.0))
	for monster in [hunter, near, far]:
		monster._change_state(BaseMonster.State.PATROL)
	hunter._change_state(BaseMonster.State.CHASE)
	_ok(near.ai_state == BaseMonster.State.INVESTIGATE, "MN7 a Hunter that sees the player shouts: a Hound 8 m away comes to look")
	_ok(far.ai_state == BaseMonster.State.PATROL, "MN7 a monster 40 m away does not hear the shout")
	EventBus.noise_emitted.emit(Vector2(far.global_position.x, far.global_position.z), 22.0)
	_ok(far.ai_state == BaseMonster.State.INVESTIGATE, "MN7 a gunshot (22 m) sends the monster beside it to investigate")
	var lone := _monster("shadow_3d", FAR + Vector3(0.0, 0.0, -60.0))
	lone._change_state(BaseMonster.State.PATROL)
	EventBus.noise_emitted.emit(Vector2(FAR.x, FAR.z), 22.0)
	_ok(lone.ai_state == BaseMonster.State.PATROL, "MN7 a gunshot 60 m away is not heard")
	for monster in [hunter, near, far, lone]:
		monster.queue_free()

# ── settings that act: Auto-save, Button Size, Text Size, High Contrast ──────
func _check_settings_effects() -> void:
	_playing()
	var coins_before: int = CoinWallet.get_coins()
	CoinWallet.coins = 424242
	SettingsManager.set_setting("autosave", false)
	SaveSystem.autosave()
	var saved: Dictionary = SaveSystem._read_validated(SaveSystem.SAVE_PATH)
	_ok(not JSON.stringify(saved.get("wallet", {})).contains("424242"), "Auto-save off: the autosave writes nothing")
	SettingsManager.set_setting("autosave", true)
	SaveSystem.autosave()
	saved = SaveSystem._read_validated(SaveSystem.SAVE_PATH)
	_ok(JSON.stringify(saved.get("wallet", {})).contains("424242"), "Auto-save on: the autosave writes")
	CoinWallet.coins = coins_before
	var hud := _main.get_node_or_null("HUD")
	SettingsManager.set_setting("button_size", 1.4)
	hud._apply_button_size()
	var cluster := hud.get_node("BottomRight") as Control
	_ok(is_equal_approx(cluster.scale.x, 1.4), "Button Size scales the touch buttons (%.2f)" % cluster.scale.x)
	SettingsManager.set_setting("button_size", 1.0)
	hud._apply_button_size()
	SettingsManager.set_setting("text_size", 2)
	_ok(is_equal_approx(get_tree().root.content_scale_factor, 1.15), "AC3 Text Size Large scales the whole UI (%.2f)" % get_tree().root.content_scale_factor)
	SettingsManager.set_setting("text_size", 1)
	_ok(is_equal_approx(get_tree().root.content_scale_factor, 1.0), "AC3 Text Size Medium is the normal scale")
	var tier_before: int = int(SettingsManager.get_setting("graphics_tier", 2))
	SettingsManager.set_setting("high_contrast", true)
	var env: Environment = SettingsManager._find_environment()
	env.adjustment_contrast = 1.1
	SettingsManager.set_graphics_tier(1 if tier_before != 1 else 2)
	await get_tree().create_timer(0.9).timeout
	_ok(env != null and is_equal_approx(env.adjustment_contrast, 1.3), "AC4 High Contrast survives a graphics tier change")
	SettingsManager.set_graphics_tier(tier_before)
	SettingsManager.set_setting("high_contrast", false)

# ── ST7: the statistics screen (4 tabs, 20+ rows) and the counters behind it ──
func _check_stats() -> void:
	var saved := ProgressTracker.to_dict()
	var forged := saved.duplicate(true)
	forged["shots"] = -5
	forged["distance"] = -1.0
	forged["kills_by"] = {"crawler": 4, "shadow": -2, "x".repeat(40): 9}
	ProgressTracker.from_dict(forged)
	_ok(ProgressTracker.shots == 0 and ProgressTracker.distance == 0.0, "ST7 forged counters are clamped")
	_ok(ProgressTracker.kills_by.size() == 1 and int(ProgressTracker.kills_by.get("crawler", 0)) == 4, "ST7 forged kill rows are dropped")
	ProgressTracker.from_dict(saved)
	ProgressTracker._on_kill(&"crawler")
	_ok(int(ProgressTracker.kills_by.get("crawler", 0)) >= 1, "ST7 a kill is counted by type")
	var made: int = ProgressTracker.crafted
	InventoryManager.from_dict({})
	InventoryManager.try_add(&"metal", 2)
	Logic.craft(Logic.find("lockpick"))
	_ok(ProgressTracker.crafted == made + 1, "ST7 crafting is counted")
	var stats := Control.new()
	stats.set_script(load("res://scripts/ui/stats_ui.gd"))
	add_child(stats)
	await get_tree().process_frame
	var tabs := stats.find_children("*", "TabContainer", true, false)[0] as TabContainer
	_ok(tabs.get_tab_count() == 4, "ST7 four tabs: Overall, Combat, Exploration, Collection")
	var rows := 0
	for tab in tabs.get_children():
		rows += tab.get_child(0).get_child_count()
	_ok(rows >= 20, "ST7 twenty or more rows (%d)" % rows)
	var texts: Array[String] = []
	for label in stats.find_children("*", "Label", true, false):
		texts.append((label as Label).text)
	_ok(texts.has(str(XpManager.get_level())) and texts.has(LocalizationManager.t("STATS_LEVEL")), "ST7 the level row shows the real level")
	stats.queue_free()

# ── E7.15 / E7.16: the bestiary detail names the danger, the habitat and the drops ──
func _check_bestiary() -> void:
	var enc := preload("res://scripts/ui/encyclopedia_ui.gd")
	var expected := {&"shadow": 0, &"watcher": 0, &"crawler": 1, &"hound": 1, &"hunter": 2, &"brute": 2, &"boss": 3, &"tvar": 3}
	for id in expected:
		var level: int = enc.danger_level(Encyclopedia.get_data(id))
		_ok(level == expected[id], "E7.15 %s danger is %s (%d)" % [id, enc.DANGER_KEYS[expected[id]], level])
	Encyclopedia.unlock(&"hunter")
	var ui := Control.new()
	ui.set_script(enc)
	add_child(ui)
	await get_tree().process_frame
	ui._open_detail(&"hunter")
	var texts: Array[String] = []
	for label in ui.find_children("*", "Label", true, false):
		texts.append((label as Label).text)
	for key in ["ENC_STAT_DANGER", "ENC_STAT_HABITAT", "ENC_STAT_LOOT"]:
		_ok(texts.has(LocalizationManager.t(key)), "E7.16 the detail has a %s row" % key)
	_ok(texts.has(LocalizationManager.t("DANGER_HIGH")), "E7.15 the Hunter reads High")
	_ok(texts.any(func(t: String) -> bool: return t.contains(LocalizationManager.name_for("DISTRICT_NAME_", &"park", "park"))), "E7.16 the Hunter's habitat names the park")
	ui.queue_free()

# ── H3.8 / AC7 hints and H3.14 the stamped log ───────────────────────────────
func _check_hints_and_log() -> void:
	_playing()
	var hud := _main.get_node_or_null("HUD")
	SettingsManager.set_setting("hints", true)
	hud._hints_shown.clear()
	hud._bat = 0.1
	hud._flashlight_on = true
	hud._poll_context_hints()
	_ok(hud.notice.text == LocalizationManager.t("HUD_HINT_BATTERY"), "H3.8 a fading light shows the battery hint")
	hud.notice.text = ""
	hud._hints_shown.clear()
	SettingsManager.set_setting("hints", false)
	hud._poll_context_hints()
	_ok(hud.notice.text == "", "AC7 Hints off: no hint")
	SettingsManager.set_setting("hints", true)
	NewGamePlus._active_modifiers = ["keepers_pact"]
	hud._poll_context_hints()
	_ok(hud.notice.text == "", "AC7 the Keeper's Pact silences the hints")
	NewGamePlus._active_modifiers = []
	hud._bat = 1.0
	hud.notice.text = ""
	EventBus.inventory_notice.emit("closeout probe")
	var toasts := _main.get_node("ToastManager")
	var last: Dictionary = toasts._history.back()
	_ok(String(last["text"]) == "closeout probe" and String(last["stamp"]).begins_with("["), "H3.14 the log keeps a pickup notice with its stamp (%s)" % last["stamp"])

# ── DL2: the daily reward grows with the streak ──────────────────────────────
func _check_daily() -> void:
	var m := DailyChallengeManager
	var table := {1: 1.0, 2: 1.0, 3: 1.5, 4: 1.5, 5: 2.0, 6: 2.0, 7: 3.0, 30: 3.0}
	var ok := true
	for days in table:
		ok = ok and m.streak_multiplier(days) == table[days]
	_ok(ok, "DL2 the streak multiplier is x1.5 / x2 / x3 at 3 / 5 / 7 days")
	var streak_before: int = SaveSystem._daily_streak
	var last_before: int = SaveSystem._last_daily_time
	SaveSystem._daily_streak = 4
	SaveSystem._last_daily_time = int(Time.get_unix_time_from_system())
	var base: int = int(m.get_today().get("reward", 0))
	var coins: int = CoinWallet.get_coins()
	m._complete()
	var bonus := 0
	for row in m._streak_rewards:
		if int(row.get("days", -1)) == 5:
			bonus += int(row.get("reward", 0))
	_ok(CoinWallet.get_coins() - coins == roundi(base * 2.0) + bonus, "DL2 the fifth day pays double (%d + %d)" % [roundi(base * 2.0), bonus])
	SaveSystem._daily_streak = streak_before
	SaveSystem._last_daily_time = last_before

# ── the play-through's findings (docs/artifacts/rc15/playthrough_*.txt): a person's pace, solid ground, one dodge per
#    double tap, a light that comes back, the onboarding cards, the death screen ──
func _check_movement() -> void:
	_playing()
	_player.set("gameplay_active", true)
	_player.global_position = Vector3(-8.0, 1.0, -8.0)
	_player.rotation.y = 0.0
	await get_tree().create_timer(0.6).timeout
	var from := _player.global_position
	InputService.set_joy_active(true)
	InputService.set_joy_move_dir(Vector2(0.0, -1.0))
	await get_tree().create_timer(1.0).timeout
	InputService.set_joy_active(false)
	InputService.set_joy_move_dir(Vector2.ZERO)
	var camera := get_viewport().get_camera_3d()
	print("[closeout] note this headless run: active camera %s, first-person view %s" % [str(camera.get_path()) if camera != null else "none", _player.call("_is_fps_view")])
	var walked := Vector2(_player.global_position.x - from.x, _player.global_position.z - from.z).length()
	_ok(walked > 2.0 and walked < 3.6, "MV1 one second of the stick forward walks %.2f m (a person walks 1.4 to 3.5 m/s)" % walked)
	await get_tree().create_timer(0.4).timeout
	_player.global_position = Vector3(-8.0, 6.0, -8.0)
	_player.velocity = Vector3.ZERO
	await get_tree().create_timer(0.5).timeout
	var fell := 6.0 - _player.global_position.y
	_ok(fell > 0.9, "MV2 a fall gathers speed: %.2f m in half a second (g = 9.8 gives 1.2)" % fell)
	await get_tree().create_timer(1.2).timeout
	_ok(_player.is_on_floor(), "MV2 the fall ends on the ground (y %.2f)" % _player.global_position.y)
	var space := _player.get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0.0, 5.0, 0.0), Vector3(0.0, -2.0, 0.0)))
	_ok(not hit.is_empty() and String(hit["collider"].name) == "GroundBody", "MV3 the block between four streets is floor (hit %s)" % [hit["collider"].name if not hit.is_empty() else "nothing"])
	hit = space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(20.0, 8.0, 0.0), Vector3(45.0, 8.0, 0.0)))
	_ok(not hit.is_empty() and absf(float(hit["position"].x) - 32.0) < 0.5, "MV3 a wall stops the player at the building fronts (x %.1f)" % [float(hit["position"].x) if not hit.is_empty() else -1.0])
	# one press is not a dodge; a press, a release and a press within the window is
	_player.set("stamina", 100.0)
	_player.set("_dodge_cooldown", 0.0)
	_player.set("_stun_timer", 0.0)
	_player.set("_tap_age", 99.0)
	_player.set("_tap_held", false)
	for n in 40:
		_player._track_dodge_tap(Vector2(0.0, -1.0), 0.016)
	_ok(is_equal_approx(float(_player.get("stamina")), 100.0), "MV4 holding a direction is not a dodge (stamina %.0f)" % float(_player.get("stamina")))
	for n in 2:
		_player._track_dodge_tap(Vector2.ZERO, 0.016)
		_player._track_dodge_tap(Vector2(0.0, -1.0), 0.016)
	_ok(float(_player.get("stamina")) < 100.0, "MV4 a quick second press after a release is a dodge (stamina %.0f)" % float(_player.get("stamina")))
	await get_tree().create_timer(1.0).timeout
	# the light that went out with the battery comes back with the next charge; a light put out by hand stays out
	_player.set("flashlight_enabled", true)
	_player.set("battery", 0.0)
	await get_tree().create_timer(0.3).timeout
	_ok(not bool(_player.get("flashlight_enabled")), "FL6 at 0% the light goes out")
	_player.add_battery(35.0)
	_ok(bool(_player.get("flashlight_enabled")), "FL6 a battery lights it again")
	_player.toggle_flashlight()
	_player.add_battery(10.0)
	_ok(not bool(_player.get("flashlight_enabled")), "FL6 a light switched off by hand stays off after a recharge")
	_player.toggle_flashlight()
	_player.set("battery", 100.0)

func _check_onboarding_and_death() -> void:
	var was: bool = SaveSystem.is_onboard_done()
	SaveSystem._onboard_done = false
	var cards := CanvasLayer.new()
	cards.set_script(load("res://scripts/ui/onboarding_overlay.gd"))
	add_child(cards)
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(bool(cards.get("_showing")) and get_tree().paused, "ON1 a running game with no profile mark opens the onboarding cards and holds the game")
	var card := cards.find_children("*", "PanelContainer", true, false)[0] as Control
	var off_centre := (card.get_global_rect().get_center() - get_viewport().get_visible_rect().size / 2.0).length()
	_ok(off_centre < 8.0, "ON1 the card sits in the middle of the screen (%.0f px off)" % off_centre)
	for n in 7:
		cards._on_next()
	_ok(not bool(cards.get("_showing")) and not get_tree().paused and SaveSystem.is_onboard_done(), "ON1 seven cards later the game runs and the profile remembers")
	SaveSystem._onboard_done = was
	cards.queue_free()
	_playing()
	# the death screen: the cause, the time, the city and the documents
	var crawler := _monster("crawler_3d", _player.global_position + Vector3(1.0, 0.0, 0.0))
	_player.set("_damage_grace_timer", 0.0)
	_player.set("_iframes", 0.0)
	_player.take_damage(1.0, crawler.global_position)
	_ok(ProgressTracker.last_hit_by == &"crawler", "CB4 a hit remembers the monster that landed it (%s)" % ProgressTracker.last_hit_by)
	var screen := Control.new()
	screen.set_script(load("res://scripts/ui/death_screen.gd"))
	add_child(screen)
	await get_tree().process_frame
	var lines: Array[String] = []
	for label in screen.find_children("*", "Label", true, false):
		lines.append((label as Label).text)
	var all := "\n".join(lines)
	_ok(all.contains(LocalizationManager.name_for("MONSTER_", &"crawler", "Crawler")), "CB4 the death screen names the monster")
	for key in ["DEATH_TIME", "DEATH_DISTRICTS", "DEATH_DOCS"]:
		_ok(all.contains(LocalizationManager.t(key).split("%")[0].strip_edges()), "CB4 the death screen shows %s" % key)
	screen.queue_free()
	crawler.queue_free()
	ProgressTracker.last_hit_by = &""

# ── the play-through's shop finding (docs/stills/playthrough/A06_shop.png): the card was empty and Buy took coins and gave nothing ──
func _shop_owned_count() -> int:
	var owned := 0
	for kind in [ShopItem.Kind.UPGRADE, ShopItem.Kind.SKIN, ShopItem.Kind.BUNDLE]:
		for it in ShopService.catalog_by_kind(kind):
			owned += int(ShopService.is_owned((it as ShopItem).id))
	return owned

func _check_shop() -> void:
	_playing()
	var screens := _main.get_node_or_null("Screens")
	_ok(screens != null, "SH1 the game scene carries the Screens layer")
	if screens == null:
		return
	CoinWallet.spend_clamped(CoinWallet.get_coins())
	screens.show_screen("Shop")
	await get_tree().process_frame
	var grid := screens.find_child("ShopGrid", true, false) as GridContainer
	var want := 0
	for kind in [ShopItem.Kind.UPGRADE, ShopItem.Kind.SKIN, ShopItem.Kind.BUNDLE]:
		want += ShopService.catalog_by_kind(kind).size()
	var cards := grid.get_child_count() if grid != null else -1
	_ok(want > 0 and cards == want, "SH1 the Shop card shows every catalog item (%d cards of %d)" % [cards, want])
	if cards <= 0:
		return
	await get_tree().process_frame
	var close_button := ((screens.get("_screen_data") as Dictionary)["Shop"] as Dictionary)["close_btn"] as Button
	var lowest := 0.0
	for c in grid.get_children():
		lowest = maxf(lowest, (c as Control).get_global_rect().end.y)
	_ok(lowest <= close_button.get_global_rect().position.y, "SH1 every row ends above the Close button (%.0f <= %.0f)" % [lowest, close_button.get_global_rect().position.y])
	var biggest := 0.0
	for icon in grid.find_children("IconTex_*", "TextureRect", true, false):
		biggest = maxf(biggest, (icon as Control).size.x)
	_ok(biggest > 0.0 and biggest <= 30.0, "SH1 the pack icons are the size they were asked for (%.0f px, 128 when the size was lost)" % biggest)
	var buy := grid.get_child(0).find_children("*", "Button", true, false)[0] as Button
	var owned_before := _shop_owned_count()
	buy.pressed.emit()
	_ok(_shop_owned_count() == owned_before and not buy.disabled, "SH1 Buy with an empty wallet buys nothing")
	CoinWallet.add(5000)
	var coins_before := CoinWallet.get_coins()
	buy.pressed.emit()
	_ok(_shop_owned_count() > owned_before and CoinWallet.get_coins() < coins_before and buy.disabled, "SH1 Buy with coins grants the item, spends the price and marks the card (coins %d -> %d)" % [coins_before, CoinWallet.get_coins()])
	var header := screens.find_child("ShopCoinHeader", true, false) as Label
	_ok(header != null and header.text.ends_with(str(CoinWallet.get_coins())), "SH1 the coin header follows the wallet (%s)" % [header.text if header != null else "none"])
	screens.hide_all()
	ShopService.from_dict({})
	UpgradeSystem.reset()
	CoinWallet.spend_clamped(CoinWallet.get_coins())

# ── the play-through's ghost map: MapController built a second city map in the root, and Close, Travel and K closed
#    only one of the two ──
func _city_maps() -> Array[Control]:
	var maps: Array[Control] = []
	for n in get_tree().root.find_children("*", "Control", true, false):
		var script: Script = (n as Control).get_script()
		if script != null and script.resource_path == "res://scripts/ui/city_map.gd":
			maps.append(n as Control)
	return maps

func _check_map() -> void:
	_playing()
	UIManager.open(&"city_map")
	await get_tree().process_frame
	var paths: Array[String] = []
	for m in _city_maps():
		paths.append(str(m.get_path()))
	_ok(paths.size() == 1, "MAP1 one city map exists once K opens it (%d: %s)" % [paths.size(), ", ".join(paths)])
	UIManager.close(&"city_map")
	await get_tree().process_frame
	var shown := 0
	for m in _city_maps():
		shown += int(m.is_visible_in_tree())
	_ok(shown == 0, "MAP1 closing it leaves no map on screen (%d visible)" % shown)

# ── the play-through's flip to English after a retry: a fresh profile's settings said "en" whatever the screen showed ──
func _check_language_survives_a_save() -> void:
	var shown: String = LocalizationManager.current_lang
	var other := "de" if shown != "de" else "fr"
	LocalizationManager.set_language(other)
	_ok(SettingsManager.to_dict()["language"] == other, "LANG1 a save written while the game shows %s carries %s (not the settings default)" % [other, SettingsManager.to_dict()["language"]])
	SettingsManager.save_to_cfg()
	var cfg := ConfigFile.new()
	cfg.load(SettingsManager.CFG_PATH)
	_ok(cfg.get_value("game", "language", "") == other, "LANG1 the settings file carries it too (%s)" % cfg.get_value("game", "language", ""))
	LocalizationManager.set_language(shown)

# ── the play-through's HUD frame: the LOG button of the message log sat on the first label of the stat panel ──
func _check_hud_corner() -> void:
	_playing()
	await get_tree().process_frame
	var log_button := get_tree().root.find_child("LogToggle", true, false) as Button
	var corner := _main.get_node("HUD").get_node("TopLeft") as Control
	_ok(log_button != null and log_button.is_visible_in_tree(), "HUD1 the message-log button is on screen")
	if log_button == null:
		return
	var covered: Array[String] = []
	for c in corner.find_children("*", "Control", true, false):
		var control := c as Control
		if control.is_visible_in_tree() and control.get_global_rect().intersects(log_button.get_global_rect()):
			covered.append(String(control.name))
	_ok(covered.is_empty(), "HUD1 the message-log button covers nothing in the stat panel (%s)" % ", ".join(covered))

# ── the play-through's Retry: the respawn (half health, the battery it died with) went to the dead player of the scene
#    being left, and the reloaded scene started with full health and a full battery ──
func _check_respawn_waits_for_the_new_player() -> void:
	var stand_in := GDScript.new()
	stand_in.source_code = "extends Node
var hp := 0.0
var battery := 100.0
var battery_max := 100.0
var stats = null
"
	stand_in.reload()
	var dead := Node.new()
	dead.set_script(stand_in)
	var fresh := Node.new()
	fresh.set_script(stand_in)
	fresh.set("hp", 100.0)
	GameManager._respawn_battery = 37.0
	GameManager.apply_pending_respawn(dead)
	_ok(GameManager._respawn_battery == 37.0 and float(dead.get("hp")) == 0.0, "RESP1 the dead player of the scene being left does not take the respawn")
	GameManager.apply_pending_respawn(fresh)
	_ok(is_equal_approx(float(fresh.get("hp")), 50.0) and is_equal_approx(float(fresh.get("battery")), 37.0) and GameManager._respawn_battery < 0.0,
		"RESP1 the new player respawns at half health with the battery it died with (hp %.0f, battery %.0f)" % [fresh.get("hp"), fresh.get("battery")])
	dead.free()
	fresh.free()

# ── GDD 10: health, stamina and the battery are saved ──
func _check_vitals_are_saved() -> void:
	_playing()
	_player.set("hp", 61.0)
	_player.set("stamina", 42.0)
	_player.set("battery", 33.0)
	SaveSystem.save_all()
	_player.set("hp", 100.0)
	_player.set("stamina", 100.0)
	_player.set("battery", 100.0)
	_ok(SaveSystem.load_all(), "SV2 the file just written loads")
	SaveSystem.apply_pending_vitals(_player)
	_ok(is_equal_approx(float(_player.get("hp")), 61.0) and is_equal_approx(float(_player.get("stamina")), 42.0) and is_equal_approx(float(_player.get("battery")), 33.0),
		"SV2 health, stamina and battery come back from the save (%.0f / %.0f / %.0f)" % [_player.get("hp"), _player.get("stamina"), _player.get("battery")])
	_ok(SaveSystem._parse_vitals({"hp": NAN, "stamina": 1.0, "battery": 1.0}).is_empty() and SaveSystem._parse_vitals({"hp": "full", "stamina": 1.0, "battery": 1.0}).is_empty() and SaveSystem._parse_vitals(null).is_empty(),
		"SV2 a block with a non-number, a NaN or no dictionary is dropped")
	var forged: Dictionary = SaveSystem._parse_vitals({"hp": 1e9, "stamina": -4.0, "battery": 5.0})
	_ok(forged == {"hp": SaveSystem.MAX_VITAL, "stamina": 0.0, "battery": 5.0}, "SV2 a forged number is clamped (%s)" % str(forged))
	_player.set("hp", 0.0)
	SaveSystem.save_all()
	SaveSystem.load_all()
	_ok(SaveSystem._pending_vitals.is_empty(), "SV2 a dead player saves no vitals (Continue would bring back 0 health)")
	_player.set("hp", 100.0)
	_player.set("stamina", 100.0)
	_player.set("battery", 100.0)
	SaveSystem.save_all()

# ── a person recovers in peace, not in a fight (it was 18 HP/s at every moment) ──
func _check_regeneration_waits_for_peace() -> void:
	_playing()
	_player.set("_damage_grace_timer", 0.0)
	_player.set("_iframes", 0.0)
	_player.set("hp", 50.0)
	_player.set("_since_hurt", 99.0)
	await get_tree().create_timer(1.0).timeout
	var resting := float(_player.get("hp"))
	_ok(resting > 50.5 and resting < 55.0, "HP1 in peace health comes back slowly (%.1f after a second at 50, not 68)" % resting)
	_player.set("hp", 50.0)
	_player.take_damage(10.0, Vector3.ZERO)
	await get_tree().create_timer(2.0).timeout
	var fighting := float(_player.get("hp"))
	_ok(fighting <= 40.0, "HP1 two seconds after a hit nothing has come back (%.1f)" % fighting)
	_player.set("hp", 100.0)

# ── the play-through's New Game+ frame: five scenes had their anchors in the node header, where the engine ignores them ──
func _check_scene_screens_fill_the_window() -> void:
	_playing()
	var window := get_viewport().get_visible_rect().size
	UIManager.open(&"new_game_plus")
	await get_tree().process_frame
	await get_tree().process_frame
	var ngp: Control = UIManager._cache.get(&"new_game_plus", null)
	var rect := ngp.get_global_rect() if ngp != null else Rect2()
	_ok(ngp != null and ngp.visible and rect.size.is_equal_approx(window) and rect.position.length() < 1.0,
		"SCR1 the New Game+ screen covers the window (%s of %s at %s)" % [rect.size, window, rect.position])
	UIManager.close(&"new_game_plus")
	# the skill tree: reachable from a fresh game with the T key (it toggled itself, so it never opened), then centred
	_ok(UIManager._cache.get(&"skill_tree", null) == null, "SCR1 the skill tree has not been opened yet")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_T
	key.keycode = KEY_T
	key.pressed = true
	Input.parse_input_event(key)
	await get_tree().process_frame
	await get_tree().process_frame
	var tree: Control = UIManager._cache.get(&"skill_tree", null)
	_ok(tree != null and tree.visible, "SCR1 the T key opens the skill tree from a fresh game")
	if tree != null:
		var tree_rect := tree.get_global_rect()
		_ok(tree_rect.size.is_equal_approx(window) and tree_rect.position.length() < 1.0, "SCR1 the skill tree covers the window (%s at %s)" % [tree_rect.size, tree_rect.position])
		var branch_tabs := tree.find_children("*", "TabContainer", true, false)[0] as Control
		_ok(branch_tabs.size.y > 200.0, "SCR1 the branch tabs have room for the skills (%.0f px tall; the tab bar alone is about 30)" % branch_tabs.size.y)
	UIManager.close(&"skill_tree")
	key.pressed = false
	Input.parse_input_event(key)
