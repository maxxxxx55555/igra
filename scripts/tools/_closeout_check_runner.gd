extends Node
## Runner of the rc15 closeout gate (see _closeout_check.gd). Prints one line per check and
## "[closeout] DONE checks=N fails=M"; exits 1 when anything failed.

const Logic := preload("res://scripts/crafting/workbench_logic.gd")
const AlbumScript := preload("res://scripts/ui/photo_album_ui.gd")
const FAR := Vector3(500.0, 0.0, 500.0)

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
