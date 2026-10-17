extends RefCounted
## Session 28 (D1 and S1, the masterpiece pass): the wake radius of the three heavy kinds and the edge sweeps that no check held yet; run after the D1 checks of s28_checks.gd (CLOSEOUT_ONLY=s28).
##   WAKE1  a Hunter, a Watcher or a Destroyer switches itself off out of the camera's view (scripts/components/visibility_enabler.gd) except within wake_m of the player: one 6 m behind the player's back is awake, one in the far corner sleeps
##   BAT0   the Architect takes damage in his second phase only inside the flashlight's beam, so a light that died there (battery 0, no spare) left a fight that could be neither won nor lost: out of the beam he swings now, after a cue,
##          and in the beam he does not
##   PICK1  a pickup on a full pack stays in the world and the pack is as it was
##   SAVE1  a save written while the player is out of the world (the scene swap of a transition) reads back whole and loads, and a fade that a load interrupts still ends
## The other four edge sweeps of the pass are held by older checks that run in every battery: LANG1 (a language switch under an open menu), EX3 (a full pack), EX4 (a dead battery), EX10 (no ad SDK) and HC1 (Hardcore ticked in the middle of a run).

const _S28 := preload("res://scripts/tools/rc16/s28_checks.gd")
const _FAR := Vector3(-600.0, 0.0, 600.0)

static func run(r: Node) -> void:
	r._playing()
	await _wake(r)
	await _battery_in_the_dark(r)
	_pack_full_pickup(r)
	await _save_between_scenes(r)
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
